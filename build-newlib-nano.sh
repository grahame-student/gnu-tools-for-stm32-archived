#!/bin/bash
set -e
set -x
set -u
set -o pipefail

# Source common build functions and variables
. "$(dirname "$0")/build-common.sh"

# Source common toolchain configuration
. "$(dirname "$0")/build-toolchain-config.sh"

# Save environment before setting variables
saveenv

# Add toolchain binaries to PATH
prepend_path PATH "$INSTALLDIR_NATIVE/bin"

# Set target-specific compilation flags for nano variant
# These flags optimize for size and enable nano-specific features
saveenvvar CFLAGS_FOR_TARGET '-g -Os -ffunction-sections -fdata-sections -fno-unroll-loops -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -DSMALL_MEMORY'

echo "Task [III-3] /$HOST_NATIVE/newlib-nano/"
rm -rf "$BUILDDIR_NATIVE/newlib-nano" && mkdir -p "$BUILDDIR_NATIVE/newlib-nano"

pushd "$BUILDDIR_NATIVE/newlib-nano"

# Convert NEWLIB_CONFIG_OPTS to array for proper word splitting (robust pattern)
newlib_opts=()
if [ -n "$NEWLIB_CONFIG_OPTS" ]; then
    read -ra newlib_opts <<< "$NEWLIB_CONFIG_OPTS"
fi

# Configure newlib with nano optimizations
# Note: Install prefix is the temporary target-libs directory, not the final install location
# The nano libraries will be copied to the final location by build-gcc-final-gdb.sh
"$SRCDIR/$NEWLIB/configure" \
    "${newlib_opts[@]+"${newlib_opts[@]}"}" \
    --target="$TARGET" \
    --prefix="$BUILDDIR_NATIVE/target-libs" \
    --disable-newlib-supplied-syscalls \
    --enable-newlib-reent-check-verify \
    --enable-newlib-reent-small \
    --enable-newlib-retargetable-locking \
    --disable-newlib-fvwrite-in-streamio \
    --disable-newlib-fseek-optimization \
    --disable-newlib-wide-orient \
    --enable-newlib-nano-malloc \
    --disable-newlib-unbuf-stream-opt \
    --enable-lite-exit \
    --enable-newlib-global-atexit \
    --enable-newlib-nano-formatted-io \
    --disable-nls

make -j"$JOBS"
make install

popd

# Restore environment
restoreenv

# Clean up newlib-nano build artifacts
rm -rf "$BUILDDIR_NATIVE/newlib-nano"

# Clean up any remaining object files and libtool files
find build-native -name "*.o" -delete 2>/dev/null || true
find . -name "*.la" -delete 2>/dev/null || true

echo "Newlib nano build completed successfully"
