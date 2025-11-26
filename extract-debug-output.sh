#!/bin/bash
# Extract all diagnostic and debug output from build logs
#
# Usage: ./extract-debug-output.sh <build-log-file>
#
# This script extracts all startup file debug information (including EXTRA_PARTS
# diagnostics), multilib configuration decisions, and toolchain diagnostics
# from a build log file and saves them to separate files.

set -e
set -u

if [ $# -eq 0 ]; then
    echo "Usage: $0 <build-log-file>"
    echo ""
    echo "Example:"
    echo "  $0 workflow-build.log"
    echo ""
    echo "Output files:"
    echo "  - startup_debug.txt     : Startup file installation tracking + EXTRA_PARTS diagnostics"
    echo "  - multilib_debug.txt    : Multilib configuration decisions (ml_toplevel_p, MULTIDO)"
    echo "  - toolchain_diag.txt    : Toolchain configuration and final state"
    echo "  - all_debug.txt         : Combined output from all sources"
    exit 1
fi

BUILD_LOG="$1"

if [ ! -f "$BUILD_LOG" ]; then
    echo "Error: Build log file not found: $BUILD_LOG"
    exit 1
fi

echo "Extracting debug output from: $BUILD_LOG"
echo ""

# Extract startup file debug information
echo "Extracting STARTUP_DEBUG output..."
grep "STARTUP_DEBUG:" "$BUILD_LOG" > startup_debug.txt || echo "(No STARTUP_DEBUG output found)"

# Extract multilib configuration debug information  
echo "Extracting MULTILIB_DEBUG output..."
grep "MULTILIB_DEBUG:" "$BUILD_LOG" > multilib_debug.txt || echo "(No MULTILIB_DEBUG output found)"

# Extract toolchain diagnostics
echo "Extracting TOOLCHAIN_DIAG output..."
grep "TOOLCHAIN_DIAG:" "$BUILD_LOG" > toolchain_diag.txt || echo "(No TOOLCHAIN_DIAG output found)"

# Create combined output file
echo "Creating combined output..."
{
    echo "============================================"
    echo "COMBINED DEBUG OUTPUT"
    echo "============================================"
    echo ""
    echo "========== STARTUP FILE DEBUG =========="
    cat startup_debug.txt 2>/dev/null || echo "(No startup debug output)"
    echo ""
    echo "========== MULTILIB CONFIGURATION DEBUG =========="
    cat multilib_debug.txt 2>/dev/null || echo "(No multilib debug output)"
    echo ""
    echo "========== TOOLCHAIN DIAGNOSTICS =========="
    cat toolchain_diag.txt 2>/dev/null || echo "(No toolchain diagnostics)"
} > all_debug.txt

# Show summary
echo ""
echo "Extraction complete!"
echo ""
echo "Output files created:"
echo "  - startup_debug.txt     ($(wc -l < startup_debug.txt 2>/dev/null || echo 0) lines)"
echo "  - multilib_debug.txt    ($(wc -l < multilib_debug.txt 2>/dev/null || echo 0) lines)"
echo "  - toolchain_diag.txt    ($(wc -l < toolchain_diag.txt 2>/dev/null || echo 0) lines)"
echo "  - all_debug.txt         ($(wc -l < all_debug.txt 2>/dev/null || echo 0) lines)"
echo ""
echo "Quick commands:"
echo "  View startup debug:     cat startup_debug.txt"
echo "  View multilib debug:    cat multilib_debug.txt"
echo "  View diagnostics:       cat toolchain_diag.txt"
echo "  View all:               cat all_debug.txt"
