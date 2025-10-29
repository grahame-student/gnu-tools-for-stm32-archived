#!/bin/bash
set -e
set -x
set -u
set -o pipefail

# Source common build functions and variables
. $(dirname $0)/build-common.sh

# Source common toolchain configuration
. $(dirname $0)/build-toolchain-config.sh

# Add toolchain binaries to PATH
prepend_path PATH $INSTALLDIR_NATIVE/bin

# Set target-specific compilation flags
saveenvvar CFLAGS_FOR_TARGET '-g -Os -ffunction-sections -fdata-sections -fno-unroll-loops -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -DSMALL_MEMORY'

echo "Task [III-2] /$HOST_NATIVE/newlib/"
rm -rf $BUILDDIR_NATIVE/newlib && mkdir -p $BUILDDIR_NATIVE/newlib

pushd $BUILDDIR_NATIVE/newlib
$SRCDIR/$NEWLIB/configure \
    $NEWLIB_CONFIG_OPTS \
    --target=$TARGET \
    --prefix=$INSTALLDIR_NATIVE \
    --infodir=$INSTALLDIR_NATIVE_DOC/info \
    --mandir=$INSTALLDIR_NATIVE_DOC/man \
    --htmldir=$INSTALLDIR_NATIVE_DOC/html \
    --pdfdir=$INSTALLDIR_NATIVE_DOC/pdf \
    --enable-newlib-io-long-long \
    --enable-newlib-io-long-double \
    --enable-newlib-register-fini \
    --disable-newlib-supplied-syscalls \
    --disable-nls

make -j$JOBS
make install
popd

# Clean up newlib build artifacts
rm -rf $BUILDDIR_NATIVE/newlib

# Clean up any remaining object files and libtool files
find build-native -name "*.o" -delete 2>/dev/null || true
find . -name "*.la" -delete 2>/dev/null || true

echo "Newlib build completed successfully"