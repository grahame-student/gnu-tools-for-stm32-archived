#!/bin/bash
# Common configuration setup for toolchain build scripts
# This file should be sourced after build-common.sh

# Set up BUILD_OPTIONS (similar to build-toolchain.sh)
BUILD_OPTIONS="-g -O2"

# Set up environment flags with proper library paths
ENV_CFLAGS=" -I$BUILDDIR_NATIVE/host-libs/zlib/include $BUILD_OPTIONS "
ENV_CPPFLAGS=" -I$BUILDDIR_NATIVE/host-libs/zlib/include "
ENV_LDFLAGS=" -L$BUILDDIR_NATIVE/host-libs/zlib/lib
              -L$BUILDDIR_NATIVE/host-libs/usr/lib "

# GCC configuration options with prerequisite library paths
GCC_CONFIG_OPTS=" --build=$BUILD --host=$HOST_NATIVE
                  --with-gmp=$BUILDDIR_NATIVE/host-libs/usr
                  --with-mpfr=$BUILDDIR_NATIVE/host-libs/usr
                  --with-mpc=$BUILDDIR_NATIVE/host-libs/usr
                  --with-isl=$BUILDDIR_NATIVE/host-libs/usr "

# Binutils configuration options
BINUTILS_CONFIG_OPTS=" --build=$BUILD --host=$HOST_NATIVE "

# Newlib configuration options
NEWLIB_CONFIG_OPTS=" --build=$BUILD --host=$HOST_NATIVE "

# GDB configuration options with prerequisite library paths
GDB_CONFIG_OPTS=" --build=$BUILD --host=$HOST_NATIVE
                  --with-gmp=$BUILDDIR_NATIVE/host-libs/usr
                  --with-mpfr=$BUILDDIR_NATIVE/host-libs/usr
                  --with-libexpat-prefix=$BUILDDIR_NATIVE/host-libs/usr "
