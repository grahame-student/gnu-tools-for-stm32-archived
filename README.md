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

## Backports

### GCC
- [libiberty/pex-win32.c: Initialize orig\_err](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=946b73c1132a7b6e0fb05ac9ef79f0a72858ce65)
- [testsuite: Fix expand-return CMSE test for Armv8.1-M \[PR115253\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=cf5f9171bae1f5f3034dc9a055b77446962f1a8c)
- [arm: Zero/Sign extends for CMSE security on Armv8-M.baseline \[PR115253\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=65bd0655ece268895e5018e393bafb769e201c78)
- [testsuite: Verify r0-r3 are extended with CMSE](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=d9c89402b54be4c15bb3c7bcce3465f534746204)
- [arm: Zero/Sign extends for CMSE security](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=441e194abcf3211de647d74c892f90879ae9ca8c)
- [\[testsuite\] scanasm.exp: Fix target-selector handling in check-function-bodies](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=93674a72309f986c9ace2d6060916053a00da2a1)
- [testsuite: Tweak check-function-bodies interface](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=7ed2d6cbd094871a0dd23f2d433b962d5f462936) (partial)
- [testsuite: Add target/xfail argument to check-function-bodies](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=4c33b2daeb5a87aedef77993971db1a1a1c291e6)
- [\[PATCH, GCC/ARM, 3/10\] Save/restore FPCXTNS in nsentry functions](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=e0e4be48a9892195f11d1b608793c3a30b640f54) (partial)
- [Add dg test for matching function bodies](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=4d706ff86ea86868615558e92407674a4f4b4af9) (partial)
- [fixincludes/fixfixes.c: Fix 'set but not used' warning.](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=21138a4e9ba536b46b28c2d6eb2c114ffbadc42a)
- [libgcc/config/arm/fp16.c: Make \_internal functions static inline](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=9fcedcc39153cb3cfa08ebab20aef6cdfb9ed609)
- [libstdc++: Fix build error in \<bits/regex\_error.h\>](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=29216f56d002982f10c33056f4b3d7f07e164122)
- [libstdc++-v3/libsupc++/eh\_call.cc: Avoid "set but not used" warning](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=55bdee9af3cff04192c64a573fa1767b48918efa)
- [libstdc++-v3/libsupc++/eh\_call.cc: Avoid warning with -fno-exceptions.](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=fb00a9fc397c5fc487218f7a84069837460f88ee)
- [libstdc++-v3/include/bits/regex\_error.h: Avoid warning with -fno-exceptions.](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=b32d2ea8c29203519fbd9c5e90b06941e7cd75f3)
- [Update libiberty with latest sources from gcc mainline](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=d750c713c9a34c8835e8e60370708cae675edb40)
- [Fix PR win32/24284: tcp\_auto\_retry doesn't work in MinGW](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=16d01f9cd49f553a958a69ad3c9f781ebd402da8)
- [match any program name when pruning collect messages](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=eda72164ade26fe3886515dd55dd9716ff076140)
- [update polytypes.c -flax-vector-conversions msg](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=542f73539db1433303a4dd16bd2cfc5e7e12eda8)
- [\[testsuite,arm\] use arm\_fp\_dp\_ok effective-target](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=07f8bcc6ea9f3c0850a56a7431d866178d5cee92)
- [\[testsuite,arm\] cmp-2.c: Move double-precision tests to cmp-3.c](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=2a0eaca3e9c88eb82579c75b393bd11d84d4da61)
- [\[testsuite,arm\] target-supports.exp: Add arm\_fp\_dp\_ok effective-target](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=8001f59c82b98c4348e00183fe83621d649dafca)
- [\[testsuite\]\[arm\] Add missing quotes to expected warning messages.](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=73c1f2f00e29ead11de64c8131a52cdf33a04897)

### GDB

- [Check -shared is available for pr87906\_0.C](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=930dd62797816f510957e824a115528650cd04ad)

### Newlib

- [libc/time: Move internal newlib tz-structs into own header](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=7ed952000c2e43f4297fe247f0331e50a14cd688)
- [libc/include/wchar.h: Remove parameter name](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=ea275093c179fea636470173509615eb6bddad0f)
- [libc/include/inttypes.h: Remove parameter name](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=615cf4bdce0de86e57bdc27e008a35dd713e483f)
- [libc/include/math.h: Remove parameter name](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=4c49accf8997da21be19be0396b2a88f33b9f949)
