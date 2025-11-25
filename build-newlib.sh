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

# Set target-specific compilation flags
saveenvvar CFLAGS_FOR_TARGET '-g -Os -ffunction-sections -fdata-sections -fno-unroll-loops -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -DSMALL_MEMORY'

# Regenerate autotools files (configure, Makefile.in, etc.)
# NOTE: The regenerate_autotools function is defined in build-common.sh.
# It requires GNU Autotools (autoconf 2.69, automake >= 1.15, autogen).
# The function ensures these versions are available before proceeding.
regenerate_autotools "$SRCDIR/$NEWLIB"

echo "Task [III-2] /$HOST_NATIVE/newlib/"
rm -rf "$BUILDDIR_NATIVE/newlib" && mkdir -p "$BUILDDIR_NATIVE/newlib"

pushd "$BUILDDIR_NATIVE/newlib"
# Convert NEWLIB_CONFIG_OPTS to array for proper word splitting (robust pattern)
newlib_opts=()
if [ -n "$NEWLIB_CONFIG_OPTS" ]; then
    read -ra newlib_opts <<< "$NEWLIB_CONFIG_OPTS"
fi
"$SRCDIR/$NEWLIB/configure" \
    "${newlib_opts[@]+"${newlib_opts[@]}"}" \
    --target="$TARGET" \
    --prefix="$INSTALLDIR_NATIVE" \
    --infodir="$INSTALLDIR_NATIVE_DOC/info" \
    --mandir="$INSTALLDIR_NATIVE_DOC/man" \
    --htmldir="$INSTALLDIR_NATIVE_DOC/html" \
    --pdfdir="$INSTALLDIR_NATIVE_DOC/pdf" \
    --enable-newlib-io-long-long \
    --enable-newlib-io-long-double \
    --enable-newlib-register-fini \
    --disable-newlib-supplied-syscalls \
    --disable-nls

make -j"$JOBS"
make install

# DEBUG: Check if crt0.o was installed  
echo "=== DEBUG: Checking for crt0.o after newlib install ==="
echo "Searching for crt0.o and related files in install directory:"
find "$INSTALLDIR_NATIVE/arm-none-eabi/lib" -name "*crt*.o" 2>/dev/null | head -20 || echo "No crt*.o files found"
echo "Contents of root lib directory:"
# shellcheck disable=SC2012
ls -la "$INSTALLDIR_NATIVE/arm-none-eabi/lib/"*.o 2>/dev/null | head -10 || echo "No .o files in root lib"
echo "Contents of thumb/v6-m/nofp multilib:"
# shellcheck disable=SC2012
ls -la "$INSTALLDIR_NATIVE/arm-none-eabi/lib/thumb/v6-m/nofp/"*.o 2>/dev/null | head -10 || echo "No .o files in thumb/v6-m/nofp"
echo "=== END DEBUG ==="

popd

# Restore environment
restoreenv

# Clean up newlib build artifacts
rm -rf "$BUILDDIR_NATIVE/newlib"

# Clean up any remaining object files and libtool files
find build-native -name "*.o" -delete 2>/dev/null || true
find . -name "*.la" -delete 2>/dev/null || true

echo "Newlib build completed successfully"