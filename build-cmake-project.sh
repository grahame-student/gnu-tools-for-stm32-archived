#!/bin/bash
# Generic Docker entrypoint script for building CMake projects with ARM toolchain
# 
# This script validates and builds any CMake project targeting ARM Cortex-M/A processors
# using the arm-none-eabi-gcc toolchain.
#
# Usage:
#   build-cmake-project.sh <project_dir> <build_dir>
#
# Arguments:
#   project_dir - Directory containing CMakeLists.txt and arm-none-eabi-gcc.cmake
#   build_dir   - Directory where build artifacts will be generated
#
# Requirements:
#   - CMakeLists.txt must exist in project_dir
#   - arm-none-eabi-gcc.cmake must exist in project_dir
#   - arm-none-eabi-gcc toolchain must be available in PATH

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit if any command in a pipeline fails

# Function to display usage information
usage() {
    echo "Usage: $0 <project_dir> <build_dir>"
    echo ""
    echo "Arguments:"
    echo "  project_dir - Directory containing CMakeLists.txt and arm-none-eabi-gcc.cmake"
    echo "  build_dir   - Directory where build artifacts will be generated"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/test_project /path/to/build"
    exit 1
}

# Function to validate required files exist
validate_project() {
    local project_dir=$1
    
    echo "=== Validating project directory: $project_dir ==="
    
    if [ ! -d "$project_dir" ]; then
        echo "ERROR: Project directory does not exist: $project_dir"
        exit 1
    fi
    
    if [ ! -f "$project_dir/CMakeLists.txt" ]; then
        echo "ERROR: CMakeLists.txt not found in $project_dir"
        exit 1
    fi
    
    if [ ! -f "$project_dir/arm-none-eabi-gcc.cmake" ]; then
        echo "ERROR: arm-none-eabi-gcc.cmake not found in $project_dir"
        exit 1
    fi
    
    echo "✓ CMakeLists.txt found"
    echo "✓ arm-none-eabi-gcc.cmake found"
}

# Function to validate toolchain is available
validate_toolchain() {
    echo ""
    echo "=== Validating ARM toolchain ==="
    
    if ! command -v arm-none-eabi-gcc &> /dev/null; then
        echo "ERROR: arm-none-eabi-gcc not found in PATH"
        exit 1
    fi
    
    echo "✓ arm-none-eabi-gcc found: $(which arm-none-eabi-gcc)"
    echo "  Version: $(arm-none-eabi-gcc --version | head -1)"
}

# Function to build the CMake project
build_project() {
    local project_dir=$1
    local build_dir=$2
    
    echo ""
    echo "=== Building CMake project ==="
    echo "Project directory: $project_dir"
    echo "Build directory: $build_dir"
    
    # Create build directory if it doesn't exist
    mkdir -p "$build_dir"
    
    # Change to build directory
    cd "$build_dir"
    
    # Configure CMake with the ARM toolchain
    echo ""
    echo "--- Configuring CMake ---"
    cmake -G "Unix Makefiles" \
          -DCMAKE_TOOLCHAIN_FILE="$project_dir/arm-none-eabi-gcc.cmake" \
          "$project_dir"
    
    # Build the project
    echo ""
    echo "--- Building project ---"
    cmake --build . --verbose -- -j "$(nproc)"
    
    echo ""
    echo "=== Build completed successfully ==="
    
    # List generated artifacts
    echo ""
    echo "Generated artifacts:"
    ls -lh -- *.elf *.map *.hex *.bin 2>/dev/null || echo "  (No standard artifacts found)"
}

# Main script execution
main() {
    # Check arguments
    if [ $# -ne 2 ]; then
        echo "ERROR: Invalid number of arguments"
        usage
    fi
    
    local project_dir="$1"
    local build_dir="$2"
    
    # Convert to absolute paths
    project_dir=$(realpath "$project_dir")
    build_dir=$(realpath "$build_dir")
    
    echo "================================================================"
    echo "Generic CMake Project Builder for ARM Toolchain"
    echo "================================================================"
    
    # Validate project structure
    validate_project "$project_dir"
    
    # Validate toolchain availability
    validate_toolchain
    
    # Build the project
    build_project "$project_dir" "$build_dir"
    
    echo ""
    echo "================================================================"
    echo "Build process completed successfully"
    echo "================================================================"
}

# Run main function
main "$@"
