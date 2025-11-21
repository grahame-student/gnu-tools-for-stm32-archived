# Build Instructions

## Building with Docker (Recommended)

The easiest way to build this project is using the Docker container with the pre-built toolchain:

```bash
# Pull the toolchain container
docker pull ghcr.io/grahame-student/gnu-tools-for-stm32:latest

# Build the project (from repository root)
docker run --rm \
  -v $(pwd)/test_project:/project:ro \
  -v $(pwd)/build-output:/output \
  ghcr.io/grahame-student/gnu-tools-for-stm32:latest \
  /project /output
```

The build artifacts will be available in the `build-output` directory.

## Building Locally

From the `test_project` directory, run:

```bash
cmake -G "Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=./arm-none-eabi-gcc.cmake .
cmake --build . --verbose -- -j 4
```

Note: This requires the ARM GCC toolchain to be installed and available in your PATH or in one of the locations specified in `arm-none-eabi-gcc.cmake`.

## Build Artifacts

The build process generates the following artifacts:
- `nucleo-u083rc.elf` - Executable and Linkable Format file
- `nucleo-u083rc.map` - Memory map file
- `nucleo-u083rc.hex` - Intel HEX format file
- `nucleo-u083rc.bin` - Raw binary file

## Validation

Reference artifacts built with STM32CubeIDE 1.19.0 are located in the `reference/` directory. The Docker-based build should produce byte-identical artifacts.
