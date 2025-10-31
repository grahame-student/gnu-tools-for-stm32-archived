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
    local use_autoconf269="$2"
    
    if [ ! -f "$dir/configure.ac" ] && [ ! -f "$dir/configure.in" ]; then
        return
    fi
    
    echo ""
    echo "Processing $dir..."
    pushd "$dir" > /dev/null
    
    # Run autoreconf to regenerate everything
    # -f: force (overwrite files)
    # -i: install missing auxiliary files
    # Some packages (gcc, binutils, gdb, newlib) require autoconf 2.69
    # Ubuntu 20.04's autoconf package is version 2.69, so we just use autoreconf
    # libiconv is special - it only uses autoconf, not automake
    if [ "$(basename "$dir")" = "libiconv" ]; then
        # libiconv uses autoconf only and needs srcm4 directory
        # Need to run aclocal first to gather macros
        aclocal -I m4 -I srcm4
        autoconf
    else
        # Use autoreconf for all packages (Ubuntu 20.04 has autoconf 2.69)
        autoreconf -fi
    fi
    
    popd > /dev/null
}

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"

# List of top-level packages that need autotools regeneration
# These are the main packages that the build scripts directly configure
# Format: "package_name:use_autoconf269"
# 
# NOTE: binutils, gcc, gdb, and newlib are NOT included because their top-level
# Makefile.in and auxiliary files are kept in version control for reliable builds.
# These complex multi-directory projects have their generated files committed.
# 
# zlib is also NOT included as it uses a hand-written configure script, not autotools.
PACKAGES=(
    "expat:no"
    "gmp:no"
    "isl:no"
    "libiconv:no"
    "mpc:no"
    "mpfr:no"
)

# Regenerate for each package
for pkg_spec in "${PACKAGES[@]}"; do
    pkg="${pkg_spec%%:*}"
    use_269="${pkg_spec##*:}"
    
    if [ -d "$SRC_DIR/$pkg" ]; then
        regenerate_autotools "$SRC_DIR/$pkg" "$use_269"
    else
        echo "Warning: Package directory not found: $SRC_DIR/$pkg"
    fi
done

echo ""
echo "=========================================="
echo "Autotools regeneration complete."
echo "=========================================="

# Create marker file to indicate successful completion
touch "$SCRIPT_DIR/.autotools_generated"
