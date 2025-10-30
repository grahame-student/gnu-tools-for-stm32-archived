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
# Runtime libraries (newlib, libstdc++, etc.) are already built and installed 
# in install-native/arm-none-eabi/lib/ by previous stages.
# This stage verifies their presence and performs final cleanup.
RUN set -e && \
    # Verify runtime libraries are installed
    echo "Verifying runtime libraries..." && \
    test -d install-native/arm-none-eabi/lib || { echo "Error: Runtime libraries not found"; exit 1; } && \
    ls -la install-native/arm-none-eabi/lib/*.a | head -10 && \
    # Make toolchain binaries available in PATH
    ln -sf /root/build/gnu-tools-for-stm32/install-native/bin/* /usr/local/bin/ && \
    # Clean up all remaining build artifacts to save space
    rm -rf build-native && \
    find /root/build/gnu-tools-for-stm32 -name "*.o" -delete 2>/dev/null || true && \
    find /root/build/gnu-tools-for-stm32 -name "*.la" -delete 2>/dev/null || true && \
    find /root/build/gnu-tools-for-stm32 -type d -empty -delete 2>/dev/null || true && \
    # Display summary of installed libraries
    echo "Runtime libraries installed successfully:" && \
    echo "  Libraries: $(find install-native/arm-none-eabi/lib -name '*.a' | wc -l) archive files" && \
    echo "  Headers: $(find install-native/arm-none-eabi/include -name '*.h' 2>/dev/null | wc -l || echo 0) header files" && \
    echo "Runtime library installation and cleanup completed"

##########################################
### Main: Final Stage                 ###
##########################################
FROM runtime-libs AS main

# Final stage - toolchain is ready for use with runtime libraries
WORKDIR /root/build/gnu-tools-for-stm32
