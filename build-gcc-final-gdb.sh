#!/bin/bash
set -e
set -x
set -u
set -o pipefail

# Source common build functions and variables
. "$(dirname "$0")/build-common.sh"

# Source common toolchain configuration
. "$(dirname "$0")/build-toolchain-config.sh"

# Add toolchain binaries to PATH
saveenv
prepend_path PATH "$INSTALLDIR_NATIVE/bin"

# Regenerate autotools files for gcc if needed
regenerate_autotools "$SRCDIR/$GCC"

# Build GCC final pass with C++ support
echo "Task [III-4] /$HOST_NATIVE/gcc-final/"

# Create the symlink expected by the build
rm -f "$INSTALLDIR_NATIVE/arm-none-eabi/usr"
ln -s . "$INSTALLDIR_NATIVE/arm-none-eabi/usr"

rm -rf "$BUILDDIR_NATIVE/gcc-final" && mkdir -p "$BUILDDIR_NATIVE/gcc-final"

pushd "$BUILDDIR_NATIVE/gcc-final"

# DEBUG: Add verbose debugging to config-ml.in to capture multilib decisions
# Create a wrapper script that adds debug output before calling the real config-ml.in
if [ -f "$SRCDIR/$GCC/config-ml.in" ]; then
    echo "STARTUP_DEBUG: === Instrumenting config-ml.in for verbose multilib debugging ==="
    cp "$SRCDIR/$GCC/config-ml.in" "$SRCDIR/$GCC/config-ml.in.original"
    
    # Insert debug output after the ml_toplevel_p decision
    # shellcheck disable=SC2016
    sed -i '/^if \[ "\${ml_toplevel_p}" = yes \]; then/i\
echo "MULTILIB_DEBUG: ml_toplevel_p=${ml_toplevel_p}" >&2\
echo "MULTILIB_DEBUG: enable_multilib=${enable_multilib}" >&2\
echo "MULTILIB_DEBUG: with_multisubdir=${with_multisubdir}" >&2\
echo "MULTILIB_DEBUG: srcdir=${srcdir}" >&2\
echo "MULTILIB_DEBUG: ml_realsrcdir=${ml_realsrcdir}" >&2\
if [ -f ${ml_realsrcdir}/../config-ml.in ]; then\
  echo "MULTILIB_DEBUG: config-ml.in found at ${ml_realsrcdir}/../config-ml.in" >&2\
else\
  echo "MULTILIB_DEBUG: config-ml.in NOT found at ${ml_realsrcdir}/../config-ml.in" >&2\
fi
' "$SRCDIR/$GCC/config-ml.in"
    
    sed -i '/^  ml_do=.*MAKE/a\
echo "MULTILIB_DEBUG: Setting ml_do to MAKE (multilibs ENABLED)" >&2
' "$SRCDIR/$GCC/config-ml.in"
    
    sed -i '/^  ml_do=true$/a\
echo "MULTILIB_DEBUG: Setting ml_do to true (multilibs DISABLED)" >&2
' "$SRCDIR/$GCC/config-ml.in"
    
    echo "STARTUP_DEBUG: config-ml.in instrumented for debugging"
fi

# Build configure options arrays to avoid word splitting issues
# MULTILIB_LIST may be empty/modified for different builds
multilib_opts=()
if [ -n "$MULTILIB_LIST" ]; then
    read -ra multilib_opts <<< "$MULTILIB_LIST"
fi

# Note: GCC_CONFIG_OPTS is intentionally not quoted as it contains multiple
# configure options that need to be word-split. It's a controlled variable
# from build-toolchain-config.sh and is safe to expand.
# shellcheck disable=SC2086
"$SRCDIR/$GCC/configure" --target="$TARGET" \
    --prefix="$INSTALLDIR_NATIVE" \
    --libexecdir="$INSTALLDIR_NATIVE/lib" \
    --infodir="$INSTALLDIR_NATIVE_DOC/info" \
    --mandir="$INSTALLDIR_NATIVE_DOC/man" \
    --htmldir="$INSTALLDIR_NATIVE_DOC/html" \
    --pdfdir="$INSTALLDIR_NATIVE_DOC/pdf" \
    --enable-checking=release \
    --enable-languages=c,c++ \
    --enable-plugins \
    --disable-decimal-float \
    --disable-libffi \
    --disable-libgomp \
    --disable-libmudflap \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libstdcxx-pch \
    --disable-nls \
    --disable-shared \
    --disable-threads \
    --disable-tls \
    --with-gnu-as \
    --with-gnu-ld \
    --with-newlib \
    --with-headers=yes \
    --with-python-dir=share/gcc-arm-none-eabi \
    --with-sysroot="$INSTALLDIR_NATIVE/arm-none-eabi" \
    --build="$BUILD" \
    --host="$HOST_NATIVE" \
    $GCC_CONFIG_OPTS \
    "${GCC_CONFIG_OPTS_LCPP}" \
    "--with-pkgversion=$PKGVERSION" \
    "${multilib_opts[@]+"${multilib_opts[@]}"}"

# Passing USE_TM_CLONE_REGISTRY=0 via INHIBIT_LIBC_CFLAGS to disable
# transactional memory related code in crtbegin.o.
# This is a workaround. Better approach is to have a t-* to set this flag via
# CRTSTUFF_T_CFLAGS
make -j"$JOBS" CCXXFLAGS="$BUILD_OPTIONS" \
        LDFLAGS_FOR_TARGET="--specs=nosys.specs" \
        CXXFLAGS_FOR_TARGET="-g -Os -ffunction-sections -fdata-sections -fno-exceptions" \
        INHIBIT_LIBC_CFLAGS="-DUSE_TM_CLONE_REGISTRY=0"
make install

# DEBUG: Comprehensive multilib build diagnostics
echo "STARTUP_DEBUG: === GCC Final Multilib Build Diagnostics ==="

# 1. Check how many multilib directories were created during configure
echo "STARTUP_DEBUG: Multilib directories created by configure:"
find "$BUILDDIR_NATIVE/gcc-final/arm-none-eabi" -mindepth 1 -maxdepth 3 -type d -name "libgcc" 2>/dev/null | wc -l | sed 's/^/STARTUP_DEBUG:   Total: /'

# 2. Check which directories actually have build artifacts
echo "STARTUP_DEBUG: Multilib directories with libgcc.a (actually built):"
find "$BUILDDIR_NATIVE/gcc-final/arm-none-eabi" -name "libgcc.a" 2>/dev/null | sed 's/^/STARTUP_DEBUG:   /' || echo "STARTUP_DEBUG:   None found"

# 3. Check MULTIDO value from the generated Makefile
echo "STARTUP_DEBUG: MULTIDO value from generated libgcc Makefile:"
grep "^MULTIDO" "$BUILDDIR_NATIVE/gcc-final/arm-none-eabi/libgcc/Makefile" 2>/dev/null | sed 's/^/STARTUP_DEBUG:   /' || echo "STARTUP_DEBUG:   Makefile not found"

# 4. Check enable_multilib from config.status
echo "STARTUP_DEBUG: enable_multilib value from config.status:"
grep "enable_multilib" "$BUILDDIR_NATIVE/gcc-final/arm-none-eabi/libgcc/config.status" 2>/dev/null | head -3 | sed 's/^/STARTUP_DEBUG:   /' || echo "STARTUP_DEBUG:   config.status not found"

# 5. Check if config-ml.in was invoked
echo "STARTUP_DEBUG: Check if config-ml.in modified the Makefile:"
grep -E "Adding multilib support|with_multisubdir" "$BUILDDIR_NATIVE/gcc-final/config.log" 2>/dev/null | tail -5 | sed 's/^/STARTUP_DEBUG:   /' || echo "STARTUP_DEBUG:   No evidence in config.log"

# 6. List all directories that entered make (check for make output)
echo "STARTUP_DEBUG: Directories that were entered during make (from build artifacts):"
# shellcheck disable=SC2038
find "$BUILDDIR_NATIVE/gcc-final/arm-none-eabi" -name "*.o" -o -name "*.a" 2>/dev/null | xargs -r dirname | sort -u | head -15 | sed 's/^/STARTUP_DEBUG:   /'

# 7. Check startup files
echo "STARTUP_DEBUG: Searching for crt*.o in install directory:"
find "$INSTALLDIR_NATIVE" -name "crt*.o" 2>/dev/null | sed 's/^/STARTUP_DEBUG:   /' || echo "STARTUP_DEBUG:   No crt*.o in install dir"

echo "STARTUP_DEBUG: Searching for crt*.o in build directory:"
find "$BUILDDIR_NATIVE/gcc-final/arm-none-eabi" -name "crt*.o" 2>/dev/null | sed 's/^/STARTUP_DEBUG:   /' || echo "STARTUP_DEBUG:   No crt*.o in build dir"

# 8. Sample multilib directory contents
echo "STARTUP_DEBUG: Sample multilib dir (thumb/v6-m/nofp/libgcc/) contents:"
# shellcheck disable=SC2012
ls -1 "$BUILDDIR_NATIVE/gcc-final/arm-none-eabi/thumb/v6-m/nofp/libgcc/" 2>/dev/null | head -20 | sed 's/^/STARTUP_DEBUG:   /' || echo "STARTUP_DEBUG:   Directory not found or empty"

echo "STARTUP_DEBUG: Root libgcc directory (arm-none-eabi/libgcc/) file count:"
find "$BUILDDIR_NATIVE/gcc-final/arm-none-eabi/libgcc" -maxdepth 1 -type f 2>/dev/null | wc -l | sed 's/^/STARTUP_DEBUG:   Files: /'

echo "STARTUP_DEBUG: ============================================"

# Copy nano variant libraries from build sysroot to install directory
# The GCC final build creates nano variants (built with -Os for size optimization)
# in the temporary build sysroot. These need to be copied to the install location.
copy_multi_libs src_prefix="$BUILDDIR_NATIVE/target-libs/arm-none-eabi/lib" \
                dst_prefix="$INSTALLDIR_NATIVE/arm-none-eabi/lib" \
                target_gcc="$INSTALLDIR_NATIVE/bin/arm-none-eabi-gcc"

# Copy the nano configured newlib.h file into the location that nano.specs expects it to be.
mkdir -p "$INSTALLDIR_NATIVE/arm-none-eabi/include/newlib-nano"
cp -f "$BUILDDIR_NATIVE/target-libs/arm-none-eabi/include/newlib.h" \
      "$INSTALLDIR_NATIVE/arm-none-eabi/include/newlib-nano/newlib.h"

restoreenv
popd

# DEBUG: Restore original config-ml.in if we modified it
if [ -f "$SRCDIR/$GCC/config-ml.in.original" ]; then
    echo "STARTUP_DEBUG: Restoring original config-ml.in"
    mv "$SRCDIR/$GCC/config-ml.in.original" "$SRCDIR/$GCC/config-ml.in"
fi

# Clean up GCC final build artifacts
rm -rf "$BUILDDIR_NATIVE/gcc-final"
rm -rf "$BUILDDIR_NATIVE/target-libs"

# Build GDB
echo "Task [III-6] /$HOST_NATIVE/gdb/"
rm -rf "$BUILDDIR_NATIVE/gdb" && mkdir -p "$BUILDDIR_NATIVE/gdb"

pushd "$BUILDDIR_NATIVE/gdb"
saveenv
saveenvvar CFLAGS "$ENV_CFLAGS"
saveenvvar CPPFLAGS "$ENV_CPPFLAGS"
saveenvvar LDFLAGS "$ENV_LDFLAGS"

# Note: GDB_CONFIG_OPTS is intentionally not quoted as it contains multiple
# configure options that need to be word-split. It's a controlled variable
# from build-toolchain-config.sh and is safe to expand.
# shellcheck disable=SC2086
"$SRCDIR/$GDB/configure" \
    --target="$TARGET" \
    --prefix="$INSTALLDIR_NATIVE" \
    --infodir="$INSTALLDIR_NATIVE_DOC/info" \
    --mandir="$INSTALLDIR_NATIVE_DOC/man" \
    --htmldir="$INSTALLDIR_NATIVE_DOC/html" \
    --pdfdir="$INSTALLDIR_NATIVE_DOC/pdf" \
    --disable-nls \
    --disable-sim \
    --disable-gas \
    --disable-binutils \
    --disable-ld \
    --disable-gprof \
    --with-libexpat \
    --with-lzma=no \
    --with-system-gdbinit="$INSTALLDIR_NATIVE/$HOST_NATIVE/arm-none-eabi/lib/gdbinit" \
    --with-zstd=no \
    $GDB_CONFIG_OPTS \
    --with-python=no \
    "--with-gdb-datadir=\${prefix}/arm-none-eabi/share/gdb" \
    "--with-pkgversion=$PKGVERSION"

make -j"$JOBS"
make install
restoreenv
popd

# Clean up GDB build artifacts
rm -rf "$BUILDDIR_NATIVE/gdb"

echo "GCC final and GDB build completed successfully"