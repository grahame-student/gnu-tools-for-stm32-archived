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
# GCC_CONFIG_OPTS and MULTILIB_LIST may be empty/modified for different builds
gcc_opts=()
if [ -n "$GCC_CONFIG_OPTS" ]; then
    read -ra gcc_opts <<< "$GCC_CONFIG_OPTS"
fi

multilib_opts=()
if [ -n "$MULTILIB_LIST" ]; then
    read -ra multilib_opts <<< "$MULTILIB_LIST"
fi

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
    --with-sysroot="$BUILDDIR_NATIVE/target-libs/arm-none-eabi" \
    --build="$BUILD" \
    --host="$HOST_NATIVE" \
    "${gcc_opts[@]+"${gcc_opts[@]}"}" \
    "${GCC_CONFIG_OPTS_LCPP}" \
    "--with-pkgversion=$PKGVERSION" \
    "${multilib_opts[@]+"${multilib_opts[@]}"}"

make -j"$JOBS" CCXXFLAGS="$BUILD_OPTIONS" \
        LDFLAGS_FOR_TARGET="--specs=nosys.specs" \
        CXXFLAGS_FOR_TARGET="-g -Os -ffunction-sections -fdata-sections -fno-exceptions"
make install
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

# Build configure options array to avoid word splitting issues
# GDB_CONFIG_OPTS may be empty for some builds
gdb_opts=()
if [ -n "$GDB_CONFIG_OPTS" ]; then
    read -ra gdb_opts <<< "$GDB_CONFIG_OPTS"
fi

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
    "${gdb_opts[@]+"${gdb_opts[@]}"}" \
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