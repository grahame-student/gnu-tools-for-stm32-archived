#!/bin/bash
set -e
set -x
set -u
set -o pipefail

# Source common build functions and variables
. $(dirname $0)/build-common.sh

# Source common toolchain configuration
. $(dirname $0)/build-toolchain-config.sh

cd $SRCDIR

# Regenerate autotools files for binutils if needed
regenerate_autotools $SRCDIR/$BINUTILS

# Build binutils
echo "Task [III-0] /$HOST_NATIVE/binutils/"
mkdir -p $BUILDDIR_NATIVE
rm -rf $INSTALLDIR_NATIVE && mkdir -p $INSTALLDIR_NATIVE
rm -rf $BUILDDIR_NATIVE/binutils && mkdir -p $BUILDDIR_NATIVE/binutils

pushd $BUILDDIR_NATIVE/binutils
saveenv
saveenvvar CFLAGS "$ENV_CFLAGS"
saveenvvar CPPFLAGS "$ENV_CPPFLAGS"
saveenvvar LDFLAGS "$ENV_LDFLAGS"

$SRCDIR/$BINUTILS/configure \
    --build=$BUILD \
    --host=$HOST_NATIVE \
    --target=$TARGET \
    --prefix=$INSTALLDIR_NATIVE \
    --infodir=$INSTALLDIR_NATIVE_DOC/info \
    --mandir=$INSTALLDIR_NATIVE_DOC/man \
    --htmldir=$INSTALLDIR_NATIVE_DOC/html \
    --pdfdir=$INSTALLDIR_NATIVE_DOC/pdf \
    --enable-plugins \
    --disable-nls \
    --enable-deterministic-archives \
    $BINUTILS_CONFIG_OPTS

make -j$JOBS
make install
restoreenv
popd

# Clean up binutils build artifacts immediately
rm -rf $BUILDDIR_NATIVE/binutils

# Build GCC first pass
echo "Task [III-1] /$HOST_NATIVE/gcc-first/"
rm -rf $BUILDDIR_NATIVE/gcc-first && mkdir -p $BUILDDIR_NATIVE/gcc-first

pushd $BUILDDIR_NATIVE/gcc-first
saveenv
saveenvvar CFLAGS "$ENV_CFLAGS"
saveenvvar CPPFLAGS "$ENV_CPPFLAGS"
saveenvvar LDFLAGS "$ENV_LDFLAGS"

$SRCDIR/$GCC/configure --target=$TARGET \
    --prefix=$INSTALLDIR_NATIVE \
    --libexecdir=$INSTALLDIR_NATIVE/lib \
    --infodir=$INSTALLDIR_NATIVE_DOC/info \
    --mandir=$INSTALLDIR_NATIVE_DOC/man \
    --htmldir=$INSTALLDIR_NATIVE_DOC/html \
    --pdfdir=$INSTALLDIR_NATIVE_DOC/pdf \
    --enable-checking=release \
    --enable-languages=c \
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
    --without-headers \
    --with-python-dir=share/gcc-arm-none-eabi \
    --with-sysroot=$INSTALLDIR_NATIVE/arm-none-eabi \
    --build=$BUILD \
    --host=$HOST_NATIVE \
    $GCC_CONFIG_OPTS \
    "${GCC_CONFIG_OPTS_LCPP}" \
    "--with-pkgversion=$PKGVERSION" \
    ${MULTILIB_LIST}

make -j$JOBS all-gcc
make install-gcc
restoreenv
popd

# Clean up GCC first build artifacts
rm -rf $BUILDDIR_NATIVE/gcc-first

# Clean up some installed files we don't need
pushd $INSTALLDIR_NATIVE
rm -rf bin/arm-none-eabi-gccbug || true
rm -rf lib/libiberty.a || true
rm -rf include || true
popd

# Clean up any remaining object files and libtool files
find build-native -name "*.o" -delete 2>/dev/null || true
find . -name "*.la" -delete 2>/dev/null || true

echo "Binutils and GCC first pass build completed successfully"