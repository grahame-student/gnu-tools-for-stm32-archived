#!/bin/bash
set -e
set -x
set -u
set -o pipefail

# Source common build functions and variables
. $(dirname $0)/build-common.sh

# Add toolchain binaries to PATH
prepend_path PATH $INSTALLDIR_NATIVE/bin

# Build GCC final pass with C++ support
echo "Task [III-4] /$HOST_NATIVE/gcc-final/"

# Create the symlink expected by the build
rm -f $INSTALLDIR_NATIVE/arm-none-eabi/usr
ln -s . $INSTALLDIR_NATIVE/arm-none-eabi/usr

rm -rf $BUILDDIR_NATIVE/gcc-final && mkdir -p $BUILDDIR_NATIVE/gcc-final

pushd $BUILDDIR_NATIVE/gcc-final
$SRCDIR/$GCC/configure --target=$TARGET \
    --prefix=$INSTALLDIR_NATIVE \
    --libexecdir=$INSTALLDIR_NATIVE/lib \
    --infodir=$INSTALLDIR_NATIVE_DOC/info \
    --mandir=$INSTALLDIR_NATIVE_DOC/man \
    --htmldir=$INSTALLDIR_NATIVE_DOC/html \
    --pdfdir=$INSTALLDIR_NATIVE_DOC/pdf \
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
    --with-sysroot=$BUILDDIR_NATIVE/target-libs/arm-none-eabi \
    --build=$BUILD \
    --host=$HOST_NATIVE \
    $GCC_CONFIG_OPTS \
    "${GCC_CONFIG_OPTS_LCPP}" \
    "--with-pkgversion=$PKGVERSION" \
    ${MULTILIB_LIST}

make -j$JOBS CCXXFLAGS="$BUILD_OPTIONS" \
        LDFLAGS_FOR_TARGET="--specs=nosys.specs" \
        CXXFLAGS_FOR_TARGET="-g -Os -ffunction-sections -fdata-sections -fno-exceptions"
make install
popd

# Clean up GCC final build artifacts  
rm -rf $BUILDDIR_NATIVE/gcc-final
rm -rf $BUILDDIR_NATIVE/target-libs

# Build GDB
echo "Task [III-6] /$HOST_NATIVE/gdb/"
rm -rf $BUILDDIR_NATIVE/gdb && mkdir -p $BUILDDIR_NATIVE/gdb

pushd $BUILDDIR_NATIVE/gdb
saveenv
saveenvvar CFLAGS "$ENV_CFLAGS"
saveenvvar CPPFLAGS "$ENV_CPPFLAGS"
saveenvvar LDFLAGS "$ENV_LDFLAGS"

$SRCDIR/$GDB/configure \
    --target=$TARGET \
    --prefix=$INSTALLDIR_NATIVE \
    --infodir=$INSTALLDIR_NATIVE_DOC/info \
    --mandir=$INSTALLDIR_NATIVE_DOC/man \
    --htmldir=$INSTALLDIR_NATIVE_DOC/html \
    --pdfdir=$INSTALLDIR_NATIVE_DOC/pdf \
    --disable-nls \
    --disable-sim \
    --disable-gas \
    --disable-binutils \
    --disable-ld \
    --disable-gprof \
    --with-libexpat \
    --with-lzma=no \
    --with-system-gdbinit=$INSTALLDIR_NATIVE/$HOST_NATIVE/arm-none-eabi/lib/gdbinit \
    --with-zstd=no \
    $GDB_CONFIG_OPTS \
    --with-python=no \
    '--with-gdb-datadir=${prefix}/arm-none-eabi/share/gdb' \
    "--with-pkgversion=$PKGVERSION"

make -j$JOBS
make install
restoreenv
popd

# Clean up GDB build artifacts
rm -rf $BUILDDIR_NATIVE/gdb

# Make toolchain binaries available in PATH
ln -sf /root/build/gnu-tools-for-stm32/install-native/bin/* /usr/local/bin/

# Final aggressive cleanup of all build artifacts
rm -rf build-native
find /root/build/gnu-tools-for-stm32 -name "*.o" -delete 2>/dev/null || true
find /root/build/gnu-tools-for-stm32 -name "*.la" -delete 2>/dev/null || true
find /root/build/gnu-tools-for-stm32 -type d -empty -delete 2>/dev/null || true

echo "GCC final and GDB build completed successfully"