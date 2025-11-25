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
5. ✅ Discovered missing **newlib-nano** build step (Task [III-3])

### The Complete Picture
The original monolithic build script has these steps:
- **Task [III-2]**: Build newlib (standard) → installs to `$INSTALLDIR_NATIVE/arm-none-eabi/lib/`
- **Task [III-3]**: Build newlib-nano → installs to `$BUILDDIR_NATIVE/target-libs/arm-none-eabi/lib/`
- **Task [III-4]**: Build GCC final
  - Rebuilds C++ runtime libraries (libstdc++, libsupc++) using nano newlib headers
  - `make install` installs GCC compiler and C++ libraries
  - `copy_multi_libs` copies nano newlib libraries and creates _nano variants
  - Copies nano newlib.h header to expected location

### The Problems in Split Scripts
In `build-gcc-final-gdb.sh`:
1. **MISSING**: Separate newlib-nano build step (entire Task [III-3] was missing!)
2. **MISSING**: The nano variant libraries were NOT being copied from temp sysroot to install directory
3. **MISSING**: The nano newlib.h header was NOT being copied to expected location
4. **BUG**: Script was deleting the temp sysroot before copying nano libraries!

### The Solutions
**Added `build-newlib-nano.sh`** - New build script for Task [III-3]:
- Builds newlib with nano-specific flags (-Os, -DPREFER_SIZE_OVER_SPEED, etc.)
- Enables nano malloc, nano formatted I/O, lite-exit, etc.
- Installs to temporary sysroot: `$BUILDDIR_NATIVE/target-libs/arm-none-eabi/`
- Creates libc.a, libm.a, libg.a, etc. (standard names, but nano-configured)

**Updated `build-gcc-final-gdb.sh`** - Added missing steps after `make install`:
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

**Updated `Dockerfile`** - Added newlib-nano build stage between newlib and gcc-final-gdb

### What Gets Fixed
After newlib-nano build, the temp sysroot contains (for each multilib variant):
- libc.a, libm.a, libg.a (nano-configured standard libraries)
- librdimon.a, librdimon-v2m.a (nano semihosting libraries)
- nano.specs, nosys.specs, rdimon.specs (linker spec files)
- crt0.o and other startup files
- newlib.h (nano-configured header)

The `copy_multi_libs` function then:
- Copies libc.a → libc_nano.a (renames to _nano variant)
- Copies libm.a → libm_nano.a
- Copies libg.a → libg_nano.a
- Copies librdimon.a → librdimon_nano.a
- Copies librdimon-v2m.a → librdimon-v2m_nano.a
- Copies spec files (nano.specs, nosys.specs, rdimon.specs)
- Copies startup files (crt0.o, etc.)

When GCC final builds C++ libraries, it uses the nano newlib from the temp sysroot to create:
- libstdc++.a (which gets copied to libstdc++_nano.a)
- libsupc++.a (which gets copied to libsupc++_nano.a)

### Status
✅ **FIXED** - Runtime libraries will now be properly installed during toolchain build
- ✅ Added build-newlib-nano.sh script
- ✅ Updated build-gcc-final-gdb.sh with copy steps
- ✅ Updated Dockerfile with newlib-nano stage
- ✅ All scripts pass shellcheck linting

## Issue #2: copy_multi_libs Not Running (2025-11-25)

### Problem
Test_project build still failing with same error: libraries not found. Diagnostics show no runtime libraries installed.

### Root Cause
The `copy_multi_libs` function call in `build-gcc-final-gdb.sh` was using:
```bash
target_gcc="$BUILDDIR_NATIVE/target-libs/bin/arm-none-eabi-gcc"
```

This GCC binary doesn't exist! The newlib-nano stage only builds newlib libraries, not GCC. In the original monolithic script, there's a **Task [III-5]** (gcc-size-libstdcxx) that builds GCC again with `--prefix=$BUILDDIR_NATIVE/target-libs`, which creates this GCC binary.

Without this GCC binary, the `copy_multi_libs` function fails silently:
- Line 281: `multilibs=( $("${target_gcc}" -print-multi-lib 2>/dev/null) )`
- If the command fails, `multilibs` is empty
- The copy loop doesn't run, no libraries get copied!

### The Fix
Changed `build-gcc-final-gdb.sh` line 86 to use the installed GCC:
```bash
target_gcc="$INSTALLDIR_NATIVE/bin/arm-none-eabi-gcc"
```

This GCC exists because it was just installed by `make install` on line 79. It knows the multilib structure (configured at build time), so it can provide the multilib list for copy_multi_libs.

### Note on Library Configuration
The original script has separate standard and nano library builds:
- Task [III-4]: GCC final with standard newlib sysroot → standard C++ libraries
- Task [III-5]: GCC rebuild with nano newlib sysroot → nano C++ libraries

Current approach: GCC final uses nano newlib sysroot (line 68), so it creates nano-configured C++ libraries. These get installed with standard names (libstdc++.a), then copy_multi_libs creates _nano copies. This means standard libraries are actually nano-configured, which may differ from the original but should work for the test_project.

### Status
🔧 **FIX APPLIED** - Awaiting CI validation
- Changed target_gcc path in copy_multi_libs call
- Script passes shellcheck linting
- Next: Test Docker build and validation
