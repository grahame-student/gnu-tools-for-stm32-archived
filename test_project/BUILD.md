# Build instructions

## Using Docker (Recommended)

The easiest way to build this test project is using the GNU Tools for STM32 Docker container:

```bash
# From the repository root
docker build -t gnu-tools-for-stm32 .

# Build the test project
docker run --rm \
  -v "$(pwd)/test_project:/project:ro" \
  -v "$(pwd)/build_output:/build" \
  gnu-tools-for-stm32 \
  /project /build
```

The generated artifacts will be in `build_output/`:
- `nucleo-u083rc.elf` - Executable and Linkable Format file
- `nucleo-u083rc.map` - Memory map file
- `nucleo-u083rc.hex` - Intel HEX format file
- `nucleo-u083rc.bin` - Raw binary file

## Using CMake directly

From the `test_project` directory, run:

```bash
cmake -G "Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=./arm-none-eabi-gcc.cmake .
cmake --build . --verbose -- -j 4
```

**Note**: This requires the ARM toolchain (`arm-none-eabi-gcc`) to be available in your system PATH or in the location specified in `arm-none-eabi-gcc.cmake`.

## Reference Artifacts

The `reference/` directory contains artifacts built with STM32CubeIDE 1.19.0 (GNU Tools for STM32 13.3.rel1). These serve as the baseline for validating that the toolchain produces identical output.
