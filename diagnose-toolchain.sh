#!/bin/bash
set -e

# Toolchain Diagnostic Script
# Outputs clearly marked diagnostic information for troubleshooting linking issues
# Filter logs with: grep "TOOLCHAIN_DIAG"

DIAG_PREFIX="TOOLCHAIN_DIAG:"

echo "${DIAG_PREFIX} =========================================="
echo "${DIAG_PREFIX} Toolchain Diagnostic Report"
echo "${DIAG_PREFIX} =========================================="
echo ""

# Find the compiler
COMPILER=$(find /root/build/gnu-tools-for-stm32/install-native -name "arm-none-eabi-gcc" -type f 2>/dev/null | head -1)
if [ -z "$COMPILER" ]; then
    echo "${DIAG_PREFIX} ERROR: arm-none-eabi-gcc not found"
    exit 1
fi

echo "${DIAG_PREFIX} Compiler: $COMPILER"
echo ""

# 1. Compiler version and configuration
echo "${DIAG_PREFIX} --- Compiler Version and Config ---"
$COMPILER -v 2>&1 | while IFS= read -r line; do
    echo "${DIAG_PREFIX} $line"
done
echo ""

# 2. Print sysroot
echo "${DIAG_PREFIX} --- Sysroot Configuration ---"
SYSROOT=$($COMPILER -print-sysroot 2>&1)
echo "${DIAG_PREFIX} Sysroot: $SYSROOT"
echo ""

# 3. Search directories
echo "${DIAG_PREFIX} --- Compiler Search Directories ---"
$COMPILER -print-search-dirs 2>&1 | while IFS= read -r line; do
    echo "${DIAG_PREFIX} $line"
done
echo ""

# 4. Multilib configuration
echo "${DIAG_PREFIX} --- Multilib Configuration ---"
$COMPILER -print-multi-lib 2>&1 | while IFS= read -r line; do
    echo "${DIAG_PREFIX} $line"
done
echo ""

# 5. Cortex-M0+ specific multilib directory
echo "${DIAG_PREFIX} --- Cortex-M0+ Multilib Directory ---"
MULTIDIR=$($COMPILER -mcpu=cortex-m0plus -mthumb -print-multi-directory 2>&1)
echo "${DIAG_PREFIX} Multi-dir: $MULTIDIR"
echo ""

# 6. Find critical runtime libraries
echo "${DIAG_PREFIX} --- Locating Runtime Libraries ---"
for lib in crti.o crtn.o crtbegin.o crtend.o crt0.o libc_nano.a libgcc.a; do
    echo "${DIAG_PREFIX} Searching for: $lib"
    find /root/build/gnu-tools-for-stm32/install-native -name "$lib" 2>/dev/null | while IFS= read -r path; do
        echo "${DIAG_PREFIX}   Found: $path"
    done
done
echo ""

# 7. Directory structure
echo "${DIAG_PREFIX} --- arm-none-eabi Directory Structure ---"
if [ -d "/root/build/gnu-tools-for-stm32/install-native/arm-none-eabi/lib" ]; then
    find /root/build/gnu-tools-for-stm32/install-native/arm-none-eabi/lib -type d 2>/dev/null | head -20 | while IFS= read -r dir; do
        echo "${DIAG_PREFIX}   $dir"
    done
else
    echo "${DIAG_PREFIX}   WARNING: /root/build/gnu-tools-for-stm32/install-native/arm-none-eabi/lib not found"
fi
echo ""

# 8. Check if sysroot exists and list contents
echo "${DIAG_PREFIX} --- Sysroot Directory Contents ---"
if [ -d "$SYSROOT" ]; then
    echo "${DIAG_PREFIX} Sysroot exists: $SYSROOT"
    # shellcheck disable=SC2012
    ls -la "$SYSROOT" 2>/dev/null | while IFS= read -r line; do
        echo "${DIAG_PREFIX}   $line"
    done
else
    echo "${DIAG_PREFIX} WARNING: Sysroot does not exist: $SYSROOT"
fi
echo ""

echo "${DIAG_PREFIX} =========================================="
echo "${DIAG_PREFIX} End of Diagnostic Report"
echo "${DIAG_PREFIX} To extract: grep 'TOOLCHAIN_DIAG' logfile.txt"
echo "${DIAG_PREFIX} =========================================="
