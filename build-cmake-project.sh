#!/bin/bash
# Generic CMake project build entrypoint for Docker container
#
# This script builds any CMake project that uses the arm-none-eabi-gcc toolchain.
# It validates that required files exist, runs CMake configure and build, and
# copies build artifacts to an output directory for validation.
#
# Usage: build-cmake-project.sh <project_path> [output_path]
#   project_path: Path to CMake project directory (must contain CMakeLists.txt and arm-none-eabi-gcc.cmake)
#   output_path:  Optional output directory for build artifacts (default: /output)

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Default output directory
OUTPUT_DIR="${2:-/output}"

# Validate arguments
if [ $# -lt 1 ]; then
    echo "ERROR: Missing required argument"
    echo "Usage: $0 <project_path> [output_path]"
    echo ""
    echo "Arguments:"
    echo "  project_path: Path to CMake project directory"
    echo "  output_path:  Optional output directory for artifacts (default: /output)"
    exit 1
fi

PROJECT_PATH="$1"

# Validate project path exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "ERROR: Project path does not exist: $PROJECT_PATH"
    exit 1
fi

# Validate required files exist
if [ ! -f "$PROJECT_PATH/CMakeLists.txt" ]; then
    echo "ERROR: CMakeLists.txt not found in $PROJECT_PATH"
    exit 1
fi

if [ ! -f "$PROJECT_PATH/arm-none-eabi-gcc.cmake" ]; then
    echo "ERROR: arm-none-eabi-gcc.cmake toolchain file not found in $PROJECT_PATH"
    exit 1
fi

echo "=== Building CMake Project ==="
echo "Project path: $PROJECT_PATH"
echo "Output path: $OUTPUT_DIR"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Create a temporary build directory outside the project path
# This allows the project to be mounted read-only
BUILD_DIR=$(mktemp -d)
trap "rm -rf \"$BUILD_DIR\"" EXIT

echo "Using build directory: $BUILD_DIR"
cd "$BUILD_DIR"

# Configure CMake with the toolchain file
echo ""
echo "=== Configuring CMake ==="
cmake -G "Unix Makefiles" \
    -DCMAKE_TOOLCHAIN_FILE="$PROJECT_PATH/arm-none-eabi-gcc.cmake" \
    -DCMAKE_BUILD_TYPE=Release \
    "$PROJECT_PATH"

# Build the project
echo ""
echo "=== Building Project ==="
cmake --build . --verbose -- -j "$(nproc)"

# Copy build artifacts to output directory
echo ""
echo "=== Copying Build Artifacts ==="

# Enable nullglob to handle cases where no files match the pattern
shopt -s nullglob

# Find all .elf, .map, .hex, and .bin files in the build directory
ARTIFACTS_FOUND=0
for artifact in *.elf *.map *.hex *.bin; do
    if [ -f "$artifact" ]; then
        echo "Copying $artifact to $OUTPUT_DIR/"
        cp "$artifact" "$OUTPUT_DIR/"
        ARTIFACTS_FOUND=$((ARTIFACTS_FOUND + 1))
    fi
done

shopt -u nullglob

if [ $ARTIFACTS_FOUND -eq 0 ]; then
    echo "WARNING: No build artifacts found"
fi

# List output directory contents
echo ""
echo "=== Build Artifacts in $OUTPUT_DIR ==="
ls -lh "$OUTPUT_DIR/"

echo ""
echo "=== Build Complete ==="
