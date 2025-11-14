#!/bin/bash
# Copyright (c) 2011-2020, ARM Limited
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Arm nor the names of its contributors may be used
#       to endorse or promote products derived from this software without
#       specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

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
    cd "$build_dir" || { echo "ERROR: Failed to change to build directory: $build_dir"; exit 1; }
    
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
    shopt -s nullglob
    artifacts=( *.elf *.map *.hex *.bin )
    if [ ${#artifacts[@]} -gt 0 ]; then
        ls -lh -- "${artifacts[@]}"
    else
        echo "  (No standard artifacts found)"
    fi
    shopt -u nullglob
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
    
    # Validate that project_dir exists before converting to absolute path
    if [ ! -d "$project_dir" ]; then
        echo "ERROR: Project directory does not exist: $project_dir"
        exit 1
    fi
    
    # Convert to absolute paths
    project_dir=$(realpath "$project_dir")
    build_dir=$(realpath -m "$build_dir")  # -m allows non-existent build_dir
    
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
