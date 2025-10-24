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
    # Clean up build artifacts to free up space
    rm -rf build-native/zlib build-native/gmp build-native/mpfr \
           build-native/mpc build-native/isl build-native/expat

##########################################
### Main: Build GNU Tools for STM32   ###
##########################################
FROM bootstrap AS main

#######################
### Build Toolchain ###
#######################
WORKDIR /root/build/gnu-tools-for-stm32
RUN ./build-toolchain.sh --skip_steps=mingw,mingw-gdb-with-python,manual
