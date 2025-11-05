# checkov:skip=CKV_DOCKER_3: "Ensure that a user for the container has been created"
# GitHub actions require that the docker image use the root user
# https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions#user

# 22.04 is the first ubuntu version to include automake-1.16
FROM ubuntu:22.04 AS bootstrap

##########################################
### Bootstrap: Install Build Tools    ###
##########################################
RUN ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime && \
    sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get --yes upgrade && \
    apt-get install --yes --no-install-recommends \
        autoconf2.69 \
        automake \
        autogen \
        libtool \
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

WORKDIR /root/build/gnu-tools-for-stm32
RUN chmod +x build-binutils-gcc-first.sh && \
    ./build-binutils-gcc-first.sh

##########################################
### Stage 2: Newlib                   ###
##########################################
FROM binutils-gcc-first AS newlib

WORKDIR /root/build/gnu-tools-for-stm32
RUN chmod +x build-newlib.sh && \
    ./build-newlib.sh

##########################################
### Stage 3: GCC Final + GDB          ###
##########################################
FROM newlib AS gcc-final-gdb

WORKDIR /root/build/gnu-tools-for-stm32
RUN chmod +x build-gcc-final-gdb.sh && \
    ./build-gcc-final-gdb.sh

##########################################
### Stage 4: Runtime Libraries        ###
### Finalizes runtime library         ###
### installation (libstdc++, newlib)  ###
### and removes build artifacts       ###
##########################################
FROM gcc-final-gdb AS runtime-libs

WORKDIR /root/build/gnu-tools-for-stm32
RUN chmod +x build-runtime-libs-finalize.sh && \
    ./build-runtime-libs-finalize.sh

##########################################
### Main: Final Stage                 ###
##########################################
FROM runtime-libs AS main

# Final stage - toolchain is ready for use with runtime libraries
WORKDIR /root/build/gnu-tools-for-stm32
