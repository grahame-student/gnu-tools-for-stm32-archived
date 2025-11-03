#!/bin/bash
set -e
set -x
set -u
set -o pipefail

# Source common build functions and variables
. $(dirname $0)/build-common.sh

# Source common toolchain configuration
. $(dirname $0)/build-toolchain-config.sh

echo "Task [III-7] /$HOST_NATIVE/runtime-libs-finalize/"
echo "Finalizing runtime library installation and cleaning up build artifacts..."

# Verify runtime libraries are installed
echo "Verifying runtime libraries..."
test -d "$INSTALLDIR_NATIVE/arm-none-eabi/lib" || { echo "Error: Runtime libraries not found"; exit 1; }

# Display sample of installed libraries
ls -la "$INSTALLDIR_NATIVE/arm-none-eabi/lib"/*.a | head -10 || true

# Make toolchain binaries available in PATH
echo "Making toolchain binaries available in /usr/local/bin..."
for bin in "$INSTALLDIR_NATIVE"/bin/*; do
  [ -e "$bin" ] || { echo "No binaries found in $INSTALLDIR_NATIVE/bin/"; break; }
  ln -sf "$bin" /usr/local/bin/
done

# Clean up all remaining build artifacts to save space
echo "Cleaning up build artifacts..."
rm -rf "$BUILDDIR_NATIVE"

# Clean up any remaining object files and libtool files
find "$ROOT" -name "*.o" -delete 2>/dev/null || true
find "$ROOT" -name "*.la" -delete 2>/dev/null || true

# Clean up empty directories
find "$ROOT" -type d -empty -delete 2>/dev/null || true

# Display summary of installed libraries
echo "Runtime libraries installed successfully:"
echo "  Libraries: $(find "$INSTALLDIR_NATIVE/arm-none-eabi/lib" -name '*.a' | wc -l) archive files"
echo "  Headers: $(find "$INSTALLDIR_NATIVE/arm-none-eabi/include" -name '*.h' 2>/dev/null | wc -l || echo 0) header files"

echo "Runtime library installation and cleanup completed successfully"
