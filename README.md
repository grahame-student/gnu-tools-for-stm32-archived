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
Include librdimon-v2m.a in delivery for both Newlib variants            | Support rdimon on Cortex-A by including librdimon-v2m.a for the Newlib-nano. |

## Backports

### Binutils

- [DWARF LTO debug sections vs. .stabstr](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=15407e7e0d42a46de5534df22eec933fc45178a3)
- [pr27590 testcase fixes](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=fba7f7533c97d03d86f648a42375212c38980706)
- [elf: Handle .gnu.debuglto\_.debug\_\* sections](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=3818d4ab066ee40b976513b247b5da5f20379b66)

### GCC

- [testsuite: Fix expand-return CMSE test for Armv8.1-M \[PR115253\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=bf9c877c4c9939274520a3f694037a9921ba9878)
- [arm: Zero/Sign extends for CMSE security on Armv8-M.baseline \[PR115253\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=319081d614dec354ae415472121e0e8ebc4b1402)
- [testsuite: Verify r0-r3 are extended with CMSE](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=08ca81e4b49bda153d678a372df7f7143a94f4ad)
- [arm: Zero/Sign extends for CMSE security](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=dabd742cc25f8992c24e639510df0965dbf14f21)
- [testsuite: Remove .exe suffix in prune\_gcc\_output](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=9081759b7ea5f7f1b17ea2a09cc438115c219ca1)
- [testsuite: Support single-precision in g++.dg/eh/arm-vfp-unwind.C](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=8e2c293f02745d47948fff19615064e4b34c1776)
- [debug/96383 - emit debug info for used external functions](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=c6ef9d8d3f11221df1ea6358b8d4e79e42f074fb)
- [testsuite: Require gnu-tm support for pr94856.C](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=fc8f44e06b183707150d4a0937e7c8506984edf1)
- [arm: \[testsuite\] Skip thumb2-cond-cmp tests on Cortex-M \[PR94595\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=ef11f5b37b0a62dbad9ed37613a3799dc98f6f8b)
- [lto: set nthreads\_var to 1 if it is zero](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=cab1b0ebc00ea53040afcbe4b91e653a87915092)
- [add alignment to enable store merging in strict-alignment targets](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=758abf1ae3139a5e3d556fd2cc5636c813629547)
- [testsuite/arm: Add arm\_dsp\_ok effective target and use it in arm/acle/dsp\_arith.c](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=3c3c0042736846c469cddd70d56eca7239dbad01)
- [testsuite: Add arm\_arch\_v7a\_ok effective-target to pr57351.c](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=1ca642d785c49e9e0b28651b190720267703f023)
- [c: Add support for \_\_FILE\_NAME\_\_ macro (PR c/42579)](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=1a9b3f04c11eb467a8dc504a37dad57a371a0d4c)
- [fixincludes/fixfixes.c: Fix 'set but not used' warning.](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=21138a4e9ba536b46b28c2d6eb2c114ffbadc42a)
- [libgcc/config/arm/fp16.c: Make \_internal functions static inline](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=9fcedcc39153cb3cfa08ebab20aef6cdfb9ed609)
- [libstdc++: Fix build error in \<bits/regex\_error.h\>](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=29216f56d002982f10c33056f4b3d7f07e164122)
- [libstdc++-v3/libsupc++/eh\_call.cc: Avoid "set but not used" warning](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=55bdee9af3cff04192c64a573fa1767b48918efa)
- [libstdc++-v3/libsupc++/eh\_call.cc: Avoid warning with -fno-exceptions.](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=fb00a9fc397c5fc487218f7a84069837460f88ee)
- [libstdc++-v3/include/bits/regex\_error.h: Avoid warning with -fno-exceptions.](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=b32d2ea8c29203519fbd9c5e90b06941e7cd75f3)
- [testsuite/arm: Add arm\_cmse\_hw effective target](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=e9046be4ffa0a941b15315317a90b437f2c1ac28)
- [match any program name when pruning collect messages](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=eda72164ade26fe3886515dd55dd9716ff076140)

### GDB

- [gdb: check for empty strings in get\_standard\_cache\_dir/get\_standard\_config\_dir](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=6abd4cf281deda4b1eb2d569a2729a485105e553)
- [gdbsupport: Use LOCALAPPDATA to determine cache dir](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=60a7223fdd196d540f87504833166f558c95c035)

### Newlib

- [nano-malloc: Fix redefined compilation warning](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=522cdab5416071545d29d79b58d1e6828f30e4a0)
