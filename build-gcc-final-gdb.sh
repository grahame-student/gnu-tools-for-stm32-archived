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
# This is a workaround. Better approach is have a t-* to set this flag via
# CRTSTUFF_T_CFLAGS
make -j"$JOBS" CCXXFLAGS="$BUILD_OPTIONS" \
        LDFLAGS_FOR_TARGET="--specs=nosys.specs" \
        CXXFLAGS_FOR_TARGET="-g -Os -ffunction-sections -fdata-sections -fno-exceptions" \
        INHIBIT_LIBC_CFLAGS="-DUSE_TM_CLONE_REGISTRY=0"
make install

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