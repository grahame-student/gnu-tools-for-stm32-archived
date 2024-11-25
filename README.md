# DISCLAIMER

### This version is not recommended for development with Cortex-M23 or Cortex-M33 since [CVE-2024-0151](https://nvd.nist.gov/vuln/detail/CVE-2024-0151) is not mitigated.

# GNU Tools for STM32

This repository contains sources and build scripts for **GNU Tools for STM32** C/C++ bare-metal toolchain included into [STM32CubeIDE](https://www.st.com/en/development-tools/stm32cubeide.html) advanced development platform and part of the [STM32Cube](https://www.st.com/en/ecosystems/stm32cube.html) software ecosystem. It is based on [ARM GNU Toolchain](https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain) sources, with patches improving use in embedded systems.

## Components

* GNU C/C++ Compiler (GCC) - [Upstream source code repository](git://gcc.gnu.org/git/gcc.git)
* GNU Binutils - [Upstream source code repository](git://sourceware.org/git/binutils-gdb.git)
* GDB - [Upstream source code repository](git://sourceware.org/git/binutils-gdb.git)
* Newlib - [Upstream source code repository](git://sourceware.org/git/Newlib-cygwin.git)

## License

See [LICENSE.md](LICENSE.md)

## Host Platforms

* GNU/Linux
* Windows
* macOs

## Communication and support

For communication and support, please refer to:

- [ST Support Center](https://my.st.com/ols#/ols/) for any defect
- ST Community [MCUs](https://community.st.com/t5/stm32cubeide-mcus/bd-p/stm32-mcu-cubeide-forum) or [MPUs](https://community.st.com/t5/stm32cubeide-mpus/bd-p/stm32-mpu-cubeide-forum) forums

## Patches

Patch                                                                   | Description |
------------------------------------------------------------------------|--------------- |
Fix for long path issues on Windows                                     | Windows has a limit of the number of characters in paths to files. This fix allows up to 248 characters in paths to GCC toolchain binaries and up to 4096 characters for all files processed by the GCC tools. Without the patch the latter limit is about 150 characters. |
Provide Newlib string function compatible with all platforms            | Adds aliases for Newlib string functions. Enables the functions to be called on all target platforms without changing the target source code. Useful for unit testing of target source code on Windows. |
Provide compatibility with IAR EW projects                              | Adds pre-processor symbol \_\_FILE\_NAME\_\_ which is used in IAR EW. Will be required for import of IAR EW projects. |
Enable debugging of functions in target libraries libg or libg\_nano    | Updates the GCC build scripts for libg and libg\_nano in newlib, so that debug symbols are not stripped. |
Correct stack usage for functions with inline assembler                 | Required by Stack Analyzer advanced debug function in CubeIDE. |
Reduce Newlib code size by 10-30%                                       | Updates the GCC build scripts for Newlib to use -Os instead of -O2. Beneficial in most embedded projects. |
Enable user config of malloc() pagesize in Newlib                       | Provides the ability to set the page size used when allocating memory in malloc(). Done by implementing sysconfig. Without the fix, the default page size is 4 Kbyte which may consume a lot memory in some applications. Applies to the build of the C standard library Newlib. |
Prepare for calculation of cyclomatic complexity                        | Provides the ability to calculate cyclomatic complexity of the target source code processed by GCC. The patch integrates the plugin into GCC binaries. |
Fix for "Comma at end of enum list" warning                             | Eliminates warning by removing the trailing comma in enum-type lists. Applies to host libraries used in the build of GCC. |
Fix for "Conversion from void\* to char" warning                        | Eliminates conversion warning. Applies to the build of GCC and Binutils. |
Fix for "Return from \_exit()" warning                                  | Eliminates warning by adding a while(1) - statement. This prevents return from the \_exit() function. Applies to the build of the C standard library Newlib. |

## Backports

### GCC

- [\[c-family\] Backport fix for PCH / PR61250.](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=e451b91356d3e642f212d7183d8c23a47fb9903f)
- [libiberty/pex-win32.c: Initialize orig\_err](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=946b73c1132a7b6e0fb05ac9ef79f0a72858ce65)
- [libstdc++-v3/libsupc++/eh\_call.cc: Avoid "set but not used" warning](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=55bdee9af3cff04192c64a573fa1767b48918efa)
- [fixincludes/fixfixes.c: Fix 'set but not used' warning.](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=21138a4e9ba536b46b28c2d6eb2c114ffbadc42a)
- [libstdc++: Fix build error in \<bits/regex\_error.h\>](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=29216f56d002982f10c33056f4b3d7f07e164122)
- [libstdc++-v3/include/bits/regex\_error.h: Avoid warning with -fno-exceptions.](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=b32d2ea8c29203519fbd9c5e90b06941e7cd75f3)
- [libgcc/config/arm/fp16.c: Make \_internal functions static inline](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=9fcedcc39153cb3cfa08ebab20aef6cdfb9ed609)
- [libstdc++-v3/libsupc++/eh\_call.cc: Avoid warning with -fno-exceptions.](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=fb00a9fc397c5fc487218f7a84069837460f88ee)

### GDB

- [Fix PR win32/24284: tcp\_auto\_retry doesn't work in MinGW](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=16d01f9cd49f553a958a69ad3c9f781ebd402da8)
- [Update libiberty with latest sources from gcc mainline](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=d750c713c9a34c8835e8e60370708cae675edb40)

### libiconv

- [Fix link error when compiling with gcc -O0.](https://git.savannah.gnu.org/gitweb/?p=libiconv.git;a=commit;h=b29089d8b43abc8fba073da7e6dccaeba56b2b70)
