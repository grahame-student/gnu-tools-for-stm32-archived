# Structured Investigation Plan: Startup Files Not Installed

## Current Status (2025-11-25 18:27 UTC)

### Fixes Applied
1. ✅ Sysroot: Changed to `$INSTALLDIR_NATIVE/arm-none-eabi` (commit 0cd0f53)
2. ✅ INHIBIT_LIBC_CFLAGS: Added `-DUSE_TM_CLONE_REGISTRY=0` (commit 0cd0f53)
3. ✅ Make variables: Kept CCXXFLAGS (reverted from CXXFLAGS change, commit 33b14b2)

### Diagnostics Results (After Fixes)
- ✅ Sysroot correctly configured: `/root/build/.../install-native/arm-none-eabi`
- ✅ libc_nano.a found in 39 multilib directories  
- ✅ libgcc.a found in 39 multilib directories
- ❌ crt0.o NOT found (should come from newlib)
- ❌ crti.o, crtn.o NOT found (should come from GCC libgcc)
- ❌ crtbegin.o, crtend.o NOT found (should come from GCC libgcc)

## Hypothesis Tree

### Hypothesis #1: Startup files are NOT being built at all
**Test**: Check build logs for compilation of crt*.S and crtstuff.c files
**Expected**: Should see `arm-none-eabi-gcc -c crt0.S`, `gcc -c crti.S`, etc.
**Dead ends**: None yet
**Status**: TODO

### Hypothesis #2: Startup files ARE built but NOT installed
**Test**: Check if files exist in build directories before cleanup
**Expected**: Files in `build-native/newlib/arm-none-eabi/libgloss/arm/` or `build-native/gcc-final/arm-none-eabi/libgcc/`
**Dead ends**: Build directories are deleted in cleanup, hard to verify
**Status**: TODO

### Hypothesis #3: newlib configure disables crt0.o installation
**Test**: Check newlib configure output for MAY_SUPPLY_SYSCALLS
**Expected**: Should be FALSE (we use `--disable-newlib-supplied-syscalls`)
**Dead ends**: None yet
**Status**: TODO

### Hypothesis #4: GCC configure disables libgcc extra_parts
**Test**: Check if EXTRA_PARTS variable is set in libgcc Makefile
**Expected**: Should see `extra_parts="crtbegin.o crtend.o crti.o crtn.o"`
**Dead ends**: None yet
**Status**: TODO

### Hypothesis #5: Make targets for extra_parts are not invoked
**Test**: Check if `libgcc-extra-parts` target exists and is called
**Expected**: Should be dependency of `all` or `all-target-libgcc`
**Dead ends**: None yet
**Status**: TODO

### Hypothesis #6: Multilib configuration prevents startup files
**Test**: Check if startup files are only built for default multilib
**Expected**: Should be built for ALL 39 multilib variants
**Dead ends**: None yet
**Status**: TODO

## Methodical Testing Plan

### Step 1: Verify newlib crt0.o installation (HIGHEST PRIORITY)
```bash
# Download latest CI build log
# Search for: "crt0.o" compilation or installation
# Check if newlib's `make install` installs crt0.o
```

**Questions to answer**:
- Does newlib build crt0.o for each multilib?
- Does `make install` copy it to install directory?
- Is it being cleaned up accidentally?

### Step 2: Verify GCC libgcc extra_parts compilation
```bash
# Search build log for:
# - "crti.S" or "crtn.S" compilation
# - "crtstuff.c" compilation  
# - "libgcc-extra-parts" make target
```

**Questions to answer**:
- Is libgcc being configured with extra_parts?
- Are the extra_parts being compiled?
- Are they being installed by `make install`?

### Step 3: Compare with working toolchain
If available, compare:
- Directory structure of working vs. broken toolchain
- Output of `arm-none-eabi-gcc -v` for both
- Multilib library directories

### Step 4: Minimal reproduction
Try to manually build one multilib variant:
```bash
# In gcc libgcc build directory
cd build-native/gcc-final/arm-none-eabi/libgcc
make crti.o crtn.o crtbegin.o crtend.o
ls -la *.o
```

## Investigation Log

### 2025-11-25 18:27 - Starting Structured Investigation

**Action**: Created methodical investigation plan with hypothesis tree
**Next**: Execute Step 1 - verify newlib crt0.o installation

### 2025-11-25 18:30 - Enhanced Debug Logging Implemented

**Actions taken**:
1. Added debug output to build-newlib.sh (after make install)
   - Searches for all *crt*.o files in install directory
   - Lists root lib directory contents
   - Lists sample multilib (thumb/v6-m/nofp) contents

2. Added debug output to build-gcc-final-gdb.sh (after make install)
   - Searches for crt*.o in install directory
   - Searches for crt*.o in build directory (before cleanup)
   - Lists sample libgcc multilib directory contents

3. Enhanced diagnose-toolchain.sh
   - Now shows actual FILE listings, not just directory structure
   - Shows files in both newlib and GCC lib directories
   - Provides concrete evidence of what's installed

**What we'll learn from next CI build**:
- ✅ Do startup files exist in newlib build artifacts?
- ✅ Do startup files exist in GCC libgcc build artifacts?
- ✅ Does make install copy them to the install directory?
- ✅ If they exist, what are the exact paths?
- ✅ If they don't exist, at what stage do they fail?

**Next steps**:
- Wait for CI build with enhanced debug logging
- Extract debug sections from build log
- Analyze findings and update hypothesis tree
- Apply targeted fix based on evidence

### Key Insights from Code Review

**newlib crt0.o installation** (from Makefile.inc):
- Line 2: `if !MAY_SUPPLY_SYSCALLS multilibtool_DATA += %D%/crt0.o`
- Condition: Only installed if MAY_SUPPLY_SYSCALLS is FALSE
- Our config: `--disable-newlib-supplied-syscalls` sets this to FALSE
- Expected: crt0.o SHOULD be installed to each multilib directory

**GCC libgcc startup files** (from Makefile.in):
- Line 60: `EXTRA_PARTS = @extra_parts@` (set by configure from config.host)
- Line 64: `extra-parts = libgcc-extra-parts` (make target)
- Line 1106: `all: $(extra-parts)` (default target depends on it)
- Line 78: `INSTALL_PARTS = $(EXTRA_PARTS)` (what gets installed)
- Line 1196: install target calls install-leaf which installs INSTALL_PARTS
- Expected: crti.o, crtn.o, crtbegin.o, crtend.o SHOULD be built and installed

**config.host for ARM**:
- Sets: `extra_parts="crtbegin.o crtend.o crti.o crtn.o"`
- These should be configured into EXTRA_PARTS automatically

### Current Hypothesis Priority

**Most likely**: Configuration or make variables preventing build (Hypothesis #4, #5)
**Less likely**: Files built but not installed (Hypothesis #2)
**Least likely**: Files installed then deleted (Hypothesis #3)

The debug logging will definitively answer these questions.

