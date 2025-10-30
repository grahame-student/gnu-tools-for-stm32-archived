#!/bin/bash
# Script to regenerate autoconf/automake generated files
# This should be run before the build process

set -e
set -u

echo "=========================================="
echo "Regenerating autotools files..."
echo "This may take several minutes..."
echo "=========================================="

# Function to regenerate files in a directory
regenerate_autotools() {
    local dir="$1"
    
    if [ ! -f "$dir/configure.ac" ] && [ ! -f "$dir/configure.in" ]; then
        return
    fi
    
    echo ""
    echo "Processing $dir..."
    pushd "$dir" > /dev/null
    
    # Run autoreconf to regenerate everything
    # -f: force (overwrite files)
    # -i: install missing auxiliary files
    # The recursive option is not needed as autoreconf will handle subdirectories
    autoreconf -fi
    
    popd > /dev/null
}

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"

# List of top-level packages that need autotools regeneration
# These are the main packages that the build scripts directly configure
PACKAGES=(
    "binutils"
    "expat"
    "gcc"
    "gdb"
    "gmp"
    "isl"
    "libiconv"
    "mpc"
    "mpfr"
    "newlib"
    "zlib-1.2.12"
)

# Regenerate for each package
for pkg in "${PACKAGES[@]}"; do
    if [ -d "$SRC_DIR/$pkg" ]; then
        regenerate_autotools "$SRC_DIR/$pkg"
    else
        echo "Warning: Package directory not found: $SRC_DIR/$pkg"
    fi
done

echo ""
echo "=========================================="
echo "Autotools regeneration complete."
echo "=========================================="
