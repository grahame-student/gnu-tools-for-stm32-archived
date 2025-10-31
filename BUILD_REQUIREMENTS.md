# Build Requirements

This repository contains the source code for GNU Tools for STM32, which requires regeneration of autotools files before building.

## Required Tools

The following tools must be installed before building:

### Essential Build Tools
- **autoconf** (version 2.69 or later) - Ubuntu 20.04 provides version 2.69
- **automake** (version 1.15 or later)
- **libtool** (version 2.4 or later)
- **m4** (GNU M4 1.4.16 or later)
- **gettext** - Required for libiconv
- **autopoint** - Part of gettext, required for libiconv

### Standard Development Tools
- **gcc** or compatible C compiler
- **g++** or compatible C++ compiler
- **make** (GNU Make recommended)

## Installation on Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y build-essential autoconf automake \
                        libtool m4 gettext autopoint pkg-config
```

## Building from Source

### Step 1: Regenerate Autotools Files

Before building, you must first regenerate the configure scripts and Makefiles that were removed from version control:

```bash
./autogen.sh
```

**Note:** This step may take 30-45 minutes as it regenerates build files for multiple large packages including GCC, binutils, GDB, and their dependencies.

### Step 2: Build Prerequisites

Build the prerequisite libraries:

```bash
./build-prerequisites.sh
```

### Step 3: Build the Toolchain

Build the complete toolchain:

```bash
./build-toolchain.sh
```

## Automated Regeneration

The build scripts have been updated to automatically call `autogen.sh` if needed. A marker file `.autotools_generated` is created after successful regeneration to avoid unnecessary reruns.

## Package-Specific Notes

### GCC, Binutils, GDB, Newlib
These packages require autoconf 2.69. Ubuntu 20.04's autoconf package provides version 2.69, which is exactly what's needed.

**Note:** These are complex multi-directory projects. While autogen.sh regenerates most autotools files, the top-level auxiliary scripts (install-sh, missing, config.guess, config.sub, etc.) are kept in version control to ensure reliable builds. These files are needed by the top-level configure scripts.

### libiconv
This package only uses autoconf (not automake) and requires special handling with `aclocal` before running `autoconf`. The autogen.sh script handles this automatically.

### zlib
This package does NOT use autotools. It has a hand-written configure script and Makefile.in which are kept in version control.

### Other Packages
Packages like expat, gmp, isl, mpc, and mpfr use standard autotools and can be regenerated with the current autoconf version.

## Troubleshooting

### "Please use exactly Autoconf 2.69" Error
This means autoconf 2.69 is not installed. On Ubuntu 20.04, install it using:
```bash
sudo apt-get install autoconf
```
Note: Ubuntu 20.04's autoconf package is version 2.69.

### Missing Macro Errors
If you see errors about missing macros (e.g., `AM_LANGINFO_CODESET`), ensure gettext and autopoint are installed:
```bash
sudo apt-get install gettext autopoint
```

### Permission Errors
Ensure all shell scripts are executable:
```bash
chmod +x autogen.sh build-*.sh
```

## Why Were Generated Files Removed?

Autotools-generated files (configure scripts, Makefile.in files, etc.) were removed from version control to:

1. Reduce repository size significantly (2.5+ million lines removed)
2. Follow standard open-source development practices
3. Ensure developers work with fresh, regenerated build files
4. Make it easier to update to newer autotools versions in the future

The files are regenerated locally during the build process and are ignored by git (see `.gitignore`).
