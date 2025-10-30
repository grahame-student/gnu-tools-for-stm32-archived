# Build Instructions

This document describes how to build the GNU Tools for STM32 toolchain, either using Docker or manually with the build scripts.

## Build Order

The toolchain is built in the following order:

### 1. Prerequisites (bootstrap)
**Script**: `build-prerequisites.sh`
- Builds foundational libraries needed by GCC (GMP, MPFR, MPC, ISL, EXPAT, zlib)
- These are host libraries installed in `build-native/host-libs/`

### 2. Binutils + GCC First Pass
**Script**: `build-binutils-gcc-first.sh`
- Builds GNU Binutils (assembler, linker, etc.)
- Builds GCC first pass (C compiler only, without headers)
- Required to build the C library

### 3. Newlib (C Library)
**Script**: `build-newlib.sh`
- Builds newlib, the C standard library for embedded systems
- Provides libc, libm, and other C runtime libraries
- Uses the GCC first pass compiler

### 4. GCC Final + GDB
**Script**: `build-gcc-final-gdb.sh`
- Builds GCC final pass with C++ support (creates libstdc++)
- Builds GDB debugger
- This is the complete compiler toolchain

### 5. Runtime Libraries Finalization
**Script**: `build-runtime-libs-finalize.sh`
- Verifies runtime libraries are installed correctly
- Links toolchain binaries to `/usr/local/bin/`
- Cleans up intermediate build artifacts
- Provides summary of installed libraries

## Docker Build

The Dockerfile follows the same build order using multi-stage builds:

```dockerfile
bootstrap → binutils-gcc-first → newlib → gcc-final-gdb → runtime-libs → main
```

To build with Docker:
```bash
docker build -t gnu-tools-for-stm32 .
```

To build up to a specific stage:
```bash
docker build --target runtime-libs -t gnu-tools-for-stm32:runtime-libs .
```

## Local Build

For a local build outside Docker, run the build scripts in order:

```bash
# 1. Build prerequisites
./build-prerequisites.sh --skip_steps=mingw

# 2. Build binutils and GCC first pass
./build-binutils-gcc-first.sh

# 3. Build newlib
./build-newlib.sh

# 4. Build GCC final and GDB
./build-gcc-final-gdb.sh

# 5. Finalize runtime libraries
./build-runtime-libs-finalize.sh
```

## Build Variables

The build uses variables defined in:
- `build-common.sh` - Common functions and paths
- `build-toolchain-config.sh` - Configuration options

Key directories:
- `$ROOT` - Build root directory
- `$SRCDIR` - Source code directory
- `$BUILDDIR_NATIVE` - Native build artifacts directory
- `$INSTALLDIR_NATIVE` - Installation directory for the toolchain

## Requirements

- Ubuntu 20.04 (or compatible Linux distribution)
- automake-1.15
- bison
- build-essential
- flex
- git
- python3
- texinfo
- texlive

## Output

The built toolchain will be installed in:
- Binaries: `install-native/bin/`
- Libraries: `install-native/arm-none-eabi/lib/`
- Headers: `install-native/arm-none-eabi/include/`

Runtime libraries include:
- `libc.a` - C standard library
- `libg.a` - C library with debugging support
- `libm.a` - Math library
- `libstdc++.a` - C++ standard library
- `libsupc++.a` - C++ runtime support
- Various nano variants (e.g., `libc_nano.a`) for size-optimized builds
