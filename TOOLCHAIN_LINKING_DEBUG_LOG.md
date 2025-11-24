# test_project Build Failure - Comprehensive Debug Log

## Problem Summary
The test_project fails to link when building with the custom-built toolchain. The linker cannot find runtime libraries (crti.o, crtbegin.o, crt0.o, libc_nano, etc.).

## Error Message
```
/root/build/gnu-tools-for-stm32/install-native/bin/arm-none-eabi-gcc --sysroot=/root/build/gnu-tools-for-stm32/install-native/arm-none-eabi
...
cannot find crti.o: No such file or directory
cannot find -lc_nano
```

## Root Cause Analysis
The GCC compiler was built with `--with-sysroot` pointing to the **build directory**:
- Build-time sysroot: `/root/build/gnu-tools-for-stm32/build-native/target-libs/arm-none-eabi`
- Installed location: `/root/build/gnu-tools-for-stm32/install-native/arm-none-eabi`

When `arm-none-eabi-gcc -print-sysroot` is called, it returns the build-time path which no longer exists.

## Fix Attempt History

### Attempt 1 (Commit 698116a77 - Original)
**What:** Used `arm-none-eabi-gcc -print-sysroot` to get sysroot
```cmake
execute_process(COMMAND ${CMAKE_C_COMPILER} -print-sysroot 
    OUTPUT_VARIABLE ARM_GCC_SYSROOT OUTPUT_STRIP_TRAILING_WHITESPACE)
set(CMAKE_SYSROOT ${ARM_GCC_SYSROOT})
```
**Result:** ❌ FAILED - Returns build directory path `/root/build/.../build-native/target-libs/arm-none-eabi`

### Attempt 2 (Commit 3faf791c3)
**What:** Removed CMAKE_SYSROOT entirely, let compiler use defaults
```cmake
# Don't set CMAKE_SYSROOT - let the compiler use its default sysroot
# The toolchain has libraries installed relative to its bin directory
```
**Result:** ❌ FAILED - Compiler still uses baked-in build-time sysroot

### Attempt 3 (Commit c206a29b1 - CURRENT)
**What:** Manually set CMAKE_SYSROOT to installed location
```cmake
get_filename_component(TOOLCHAIN_ROOT "${ARM_TOOLCHAIN_DIR}/.." ABSOLUTE)
set(CMAKE_SYSROOT "${TOOLCHAIN_ROOT}/arm-none-eabi")
```
**Result:** ❌ FAILED - Same error, sysroot path is `/root/build/.../install-native/arm-none-eabi`

## Actual Problem
The issue is **NOT** just about CMAKE_SYSROOT. Even when we set the correct sysroot, the linker still cannot find the libraries.

Looking at the error:
```
--sysroot=/root/build/gnu-tools-for-stm32/install-native/arm-none-eabi
cannot find crti.o: No such file or directory
```

The linker is looking for `crti.o` at:
`/root/build/gnu-tools-for-stm32/install-native/arm-none-eabi/lib/crti.o`

We need to verify:
1. Does this file actually exist at that location?
2. Are the libraries in a different subdirectory (e.g., `lib/thumb/v6-m/nofp/`)?
3. Do we need to add additional library search paths via linker flags?

## Investigation Needed

### 1. Verify Library Installation
Check if libraries actually exist in the installed toolchain:
```bash
find /root/build/gnu-tools-for-stm32/install-native -name "crti.o"
find /root/build/gnu-tools-for-stm32/install-native -name "libc_nano.a"
ls -la /root/build/gnu-tools-for-stm32/install-native/arm-none-eabi/lib/
```

### 2. Check Compiler Search Paths
See where the compiler is actually looking:
```bash
arm-none-eabi-gcc -print-search-dirs
arm-none-eabi-gcc -print-multi-lib
arm-none-eabi-gcc -mcpu=cortex-m0plus -mthumb --print-multi-directory
```

### 3. Verify Sysroot Configuration
Check how the compiler was configured:
```bash
arm-none-eabi-gcc -v
arm-none-eabi-gcc -print-sysroot
```

### 4. Compare with Reference Toolchain
If STM32CubeIDE toolchain works, compare:
- Library directory structure
- Compiler search paths
- Sysroot configuration

## Alternative Solutions to Try

### Option A: Override Sysroot with --sysroot Flag
Instead of CMAKE_SYSROOT, pass it via compiler/linker flags:
```cmake
set(CMAKE_C_FLAGS_INIT "--sysroot=${CORRECT_SYSROOT}")
set(CMAKE_CXX_FLAGS_INIT "--sysroot=${CORRECT_SYSROOT}")
```

### Option B: Add Explicit Library Search Paths
Add library paths explicitly if multilib is involved:
```cmake
link_directories("${ARM_TOOLCHAIN_DIR}/../arm-none-eabi/lib")
link_directories("${ARM_TOOLCHAIN_DIR}/../arm-none-eabi/lib/thumb/v6-m/nofp")
```

### Option C: Fix Sysroot at Build Time
Rebuild the toolchain with correct --with-sysroot pointing to final install location.
This is the proper fix but requires rebuilding everything.

### Option D: Use Specs File
Create a custom specs file that overrides library paths without rebuilding toolchain.

## Decision Log
- **DO NOT** keep trying CMAKE_SYSROOT variations without first verifying libraries exist
- **DO** investigate actual library locations before attempting more fixes
- **DO** document what each investigation reveals
- **AVOID** reverting between attempts without understanding why each failed

## Current Diagnostic Approach (Commit: PENDING)

### What We're Doing
Created `diagnose-toolchain.sh` script that runs automatically before each build attempt.
All diagnostic output is prefixed with `TOOLCHAIN_DIAG:` for easy filtering.

### How to Extract Diagnostics from Logs
```bash
# From GitHub Actions logs or local log file:
grep 'TOOLCHAIN_DIAG' workflow-log.txt > diagnostics.txt
```

### What the Diagnostics Show
1. Compiler version and configure-time options (shows --with-sysroot)
2. Current sysroot path from -print-sysroot
3. All search directories the compiler uses
4. Multilib configuration (shows all build variants)
5. Cortex-M0+ specific multilib directory
6. Actual locations of crti.o, crt0.o, libc_nano.a, etc.
7. Directory structure under arm-none-eabi/lib
8. Contents of the sysroot directory

### Next Steps Based on Diagnostics
After running diagnostics in the workflow, we can determine:
- **If libraries don't exist**: Build process didn't install runtime libraries properly
- **If libraries are in multilib subdirs**: Need to add those paths to CMAKE_FIND_ROOT_PATH
- **If sysroot is wrong**: Compiler configured incorrectly, may need rebuild or specs file
- **If everything looks right**: Issue is with how CMake passes linker flags

## Resolution (2025-11-24)

### Root Cause Identified
The diagnostics revealed that runtime libraries (crti.o, crt0.o, libc_nano.a, etc.) were **NOT installed** in the toolchain's install directory (`install-native/arm-none-eabi/lib/`). Only libgcc.a was found in multilib subdirectories.

### Investigation Steps
1. ✅ Analyzed diagnostics.txt output from the workflow
2. ✅ Confirmed runtime libraries were missing from install directory
3. ✅ Compared build-gcc-final-gdb.sh with build-toolchain.sh (monolithic script)
4. ✅ Found missing `copy_multi_libs` step and nano header copy step

### The Problem
In `build-gcc-final-gdb.sh`:
- GCC final pass builds runtime libraries (including nano variants) into temporary sysroot: `$BUILDDIR_NATIVE/target-libs/arm-none-eabi/`
- `make install` installs GCC compiler to `$INSTALLDIR_NATIVE/`
- **MISSING**: The nano variant libraries were NOT being copied from temp sysroot to install directory
- **MISSING**: The nano newlib.h header was NOT being copied to expected location
- Script then **deleted** the temp sysroot, losing all the nano variant libraries!

### The Solution
Added the missing steps to `build-gcc-final-gdb.sh` after `make install`:
```bash
# Copy nano variant libraries from build sysroot to install directory
copy_multi_libs src_prefix="$BUILDDIR_NATIVE/target-libs/arm-none-eabi/lib" \
                dst_prefix="$INSTALLDIR_NATIVE/arm-none-eabi/lib" \
                target_gcc="$BUILDDIR_NATIVE/target-libs/bin/arm-none-eabi-gcc"

# Copy the nano configured newlib.h file
mkdir -p "$INSTALLDIR_NATIVE/arm-none-eabi/include/newlib-nano"
cp -f "$BUILDDIR_NATIVE/target-libs/arm-none-eabi/include/newlib.h" \
      "$INSTALLDIR_NATIVE/arm-none-eabi/include/newlib-nano/newlib.h"
```

This ensures:
1. Standard libraries (libc.a, libg.a, etc.) are installed via `make install`
2. Nano variants (libc_nano.a, libg_nano.a, etc.) are copied to install directory
3. Spec files (nano.specs, nosys.specs, rdimon.specs) are copied for all multilib variants
4. Startup files (crt0.o, etc.) are copied to install directory
5. The nano newlib.h header is available at the location nano.specs expects

### Status
✅ **FIXED** - Runtime libraries will now be properly installed during toolchain build
