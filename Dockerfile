# checkov:skip=CKV_DOCKER_3: "Ensure that a user for the container has been created"
# GitHub actions require that the docker image use the root user
# https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions#user

# 20.04 is the last ubuntu version to use automake-1.15 which is required to build the gnu-tools
FROM ubuntu:20.04 AS bootstrap

##########################################
### Bootstrap: Install Build Tools    ###
##########################################
RUN ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime && \
    sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get --yes upgrade && \
    apt-get install --yes --no-install-recommends \
        automake-1.15 \
        bison \
        build-essential \
        flex \
        git \
        python3 \
        texinfo \
        texlive && \
    rm -rf /var/lib/apt/lists/*

# Create build area and copy sources
RUN mkdir -p /root/build/gnu-tools-for-stm32/
COPY . /root/build/gnu-tools-for-stm32/

# Build bootstrap prerequisites (foundational libraries needed by GCC)
WORKDIR /root/build/gnu-tools-for-stm32
RUN ./build-prerequisites.sh --skip_steps=mingw && \
    # Clean up temporary build directories to free up space.
    # Note: Installed libraries in build-native/host-libs/usr/lib/ are preserved for the toolchain build.
    rm -rf build-native/zlib build-native/gmp build-native/mpfr \
           build-native/mpc build-native/isl build-native/expat

##########################################
### Stage 1: Binutils + GCC First    ###
##########################################
FROM bootstrap AS binutils-gcc-first

# Create dedicated build script for binutils and GCC first pass
WORKDIR /root/build/gnu-tools-for-stm32
RUN cat > build-binutils-gcc-first.sh << 'EOF'
#!/bin/bash
set -e
set -x
set -u
set -o pipefail

# Source common build functions and variables
. $(dirname $0)/build-common.sh

cd $SRCDIR

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
EOF

# Make script executable and run it
RUN chmod +x build-binutils-gcc-first.sh && \
    ./build-binutils-gcc-first.sh

##########################################
### Stage 2: Newlib                   ###
##########################################
FROM binutils-gcc-first AS newlib

# Create dedicated build script for newlib
WORKDIR /root/build/gnu-tools-for-stm32
RUN cat > build-newlib.sh << 'EOF'
#!/bin/bash
set -e
set -x
set -u
set -o pipefail

# Source common build functions and variables
. $(dirname $0)/build-common.sh

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
EOF

# Make script executable and run it
RUN chmod +x build-newlib.sh && \
    ./build-newlib.sh

##########################################
### Stage 3: GCC Final + GDB          ###
##########################################  
FROM newlib AS gcc-final-gdb

# Create dedicated build script for GCC final and GDB
WORKDIR /root/build/gnu-tools-for-stm32
RUN cat > build-gcc-final-gdb.sh << 'EOF'
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
EOF

# Make script executable and run it
RUN chmod +x build-gcc-final-gdb.sh && \
    ./build-gcc-final-gdb.sh

##########################################
### Main: Final Stage                 ###
##########################################
FROM gcc-final-gdb AS main

# Final stage - toolchain is ready for use
WORKDIR /root/build/gnu-tools-for-stm32
