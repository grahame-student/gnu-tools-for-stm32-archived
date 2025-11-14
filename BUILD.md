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

**Build Time**: A full container build typically takes approximately **2 hours** on current CI infrastructure. The sum of individual build stages is approximately 100 minutes; the remaining time includes Docker image setup, layer caching, and other overhead. Individual stages complete:
- Bootstrap (prerequisites): ~5 minutes
- Binutils + GCC First: ~20 minutes
- Newlib: ~10 minutes
- GCC Final + GDB: ~60 minutes
- Runtime libs finalization: ~5 minutes

> **Note:** Stage timings are approximate and exclude Docker overhead such as image pulls, layer caching, and setup operations.

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

- Ubuntu 22.04 (or compatible Linux distribution)
- autoconf2.69 (binutils/gcc/gdb require version 2.69 specifically)
- automake (1.16+)
- autogen (for generating Makefile.in from Makefile.def)
- libtool
- bison
- build-essential
- flex
- git
- python3
- texinfo
- texlive

**Note**: Ubuntu 22.04+ ships with autoconf 2.71 by default, but binutils/gcc/gdb require exactly version 2.69. Install the `autoconf2.69` package explicitly.

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

## Toolchain Validation

The repository includes an automated validation workflow that verifies the generated toolchain by building a test project and comparing the output against reference artifacts.

### Validation Workflow

The validation is performed automatically via GitHub Actions (`.github/workflows/validate-toolchain.yml`) on every pull request. The workflow:

1. **Builds the Docker container** - Creates a complete toolchain image
2. **Builds the test project** - Uses the containerized toolchain to build `test_project/`
3. **Compares artifacts** - Validates that generated `.elf`, `.map`, `.hex`, and `.bin` files match the reference files
4. **Reports results** - Fails the build if any discrepancies are detected

### Using the Docker Container for Custom Projects

The Docker container includes a generic entrypoint script (`build-cmake-project.sh`) that can build any CMake project targeting the ARM toolchain.

**Requirements for projects**:
- Must have a `CMakeLists.txt` file
- Must have an `arm-none-eabi-gcc.cmake` toolchain file

**Usage**:
```bash
# Build the Docker container
docker build -t gnu-tools-for-stm32 .

# Build your project using the container
docker run --rm \
  -v /path/to/your/project:/project:ro \
  -v /path/to/output:/build \
  gnu-tools-for-stm32 \
  /project /build
```

The entrypoint script accepts two arguments:
1. **Project directory** - Path to directory containing CMakeLists.txt and arm-none-eabi-gcc.cmake
2. **Build directory** - Path where build artifacts will be generated

**Example with test_project**:
```bash
# From the repository root
docker run --rm \
  -v "$(pwd)/test_project:/project:ro" \
  -v "$(pwd)/build_output:/build" \
  gnu-tools-for-stm32 \
  /project /build

# Check generated artifacts
ls -lh build_output/
```

### Manual Validation

To manually validate the toolchain without Docker:

1. **Build the toolchain** using local build scripts (see above)
2. **Add toolchain to PATH**:
   ```bash
   export PATH="$PWD/install-native/bin:$PATH"
   ```
3. **Build the test project**:
   ```bash
   cd test_project
   mkdir build
   cd build
   cmake -G "Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=../arm-none-eabi-gcc.cmake ..
   cmake --build . --verbose -- -j 4
   ```
4. **Compare artifacts**:
   ```bash
   cmp nucleo-u083rc.elf ../reference/nucleo-u083rc.elf
   cmp nucleo-u083rc.map ../reference/nucleo-u083rc.map
   cmp nucleo-u083rc.hex ../reference/nucleo-u083rc.hex
   cmp nucleo-u083rc.bin ../reference/nucleo-u083rc.bin
   ```

### Reference Artifacts

The reference artifacts in `test_project/reference/` were built using:
- **Toolchain**: STM32CubeIDE 1.19.0 (GNU Tools for STM32 13.3.rel1)
- **Target**: STM32U083RC (Cortex-M0+)
- **Build Configuration**: Debug mode with `-O0` optimization

These reference files serve as the baseline for validation. Any changes to the toolchain that affect code generation will be detected by the validation workflow.
