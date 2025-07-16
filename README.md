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

Patch                                                                | Description |
---------------------------------------------------------------------|--------------- |
Fix for long path issues on Windows                                  | Windows has a limit of the number of characters in paths to files. This fix allows up to 248 characters in paths to GCC toolchain binaries and up to 4096 characters for all files processed by the GCC tools. Without the patch the latter limit is about 150 characters. |
Provide Newlib string function compatible with all platforms         | Adds aliases for Newlib string functions. Enables the functions to be called on all target platforms without changing the target source code. Useful for unit testing of target source code on Windows. |
Provide compatibility with IAR EW projects                           | Adds pre-processor symbol \_\_FILE_NAME\_\_ which is used in IAR EW. Will be required for import of IAR EW projects. |
Enable debugging of functions in target libraries libg or libg\_nano | Updates the GCC build scripts for libg and libg\_nano in Newlib, so that debug symbols are not stripped. |
Correct stack usage for functions with inline assembler              | Required by Stack Analyzer advanced debug function in CubeIDE. |
Reduce Newlib code size by 10-30%                                    | Updates the GCC build scripts for Newlib to use -Os instead of -O2. Beneficial in most embedded projects. |
Prepare for calculation of cyclomatic complexity                     | Provides the ability to calculate cyclomatic complexity of the target source code processed by GCC. The patch integrates the plugin into GCC binaries. |
Include librdimon-v2m.a in delivery for both Newlib variants         | Support rdimon on Cortex-A by including librdimon-v2m.a for the Newlib-nano. |

## Backports

### Binutils

- [string merge section map output](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=9dd98830e85cf98aafa224e485b3823210a20350)
- [ld: fix alignment issue for ARM thumb long branch stub using PureCode section](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=014a7c0fa36ecc41918e5793052dd3ae8372efe5)

### GCC

- [arm: Always use vmov.f64 instead of vmov.f32 with MVE](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=37c21d4c6ad0afe2aacdd6384b9efa96f5754169)
- [libstdc++: Remove some more unconditional uses of atomics](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=b9b9d0a7db098e2b7e6894dca98ddd551067cad1)
- [testsuite: Tweak xfail bogus g++.dg/warn/Wstringop-overflow-4.C:144, PR106120](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=e935151bad1c2a02dc6a31fce3cc21b17d616243)
- [tree-optimization/111294 - backwards threader PHI costing](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=d45ddc2c04e471d0dcee016b6edacc00b8341b16)
- [c++/modules: anon union member of as-base class \[PR112580\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=f931bd7725f5cea948dd55ac370b5b9fd9a00198)
- [c-family: -Waddress-of-packed-member and casts](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=b7e4a4c626eeeb32c291d5bbbaa148c5081b6bfd)
- [analyzer: deal with -fshort-enums](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=3cbab07b08d2f3a3ed34b6ec12e67727c59d285c)
- [testsuite: Prune warning about size of enums](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=6d8b9b772e0b3969e6b3fcf0363d6afcce2e65c9)
- [testsuite: Verify -fshort-enums and -fno-short-enums in pr33738.C](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=479dab62b828f93d6be48241178dbf654bdd33e7)
- [testsuite: Add -fno-short-enums to pr97315-1.C](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=10bf0357750972e20dc702997f2930eab1c1be17)
- [testsuite: remove -fwrapv from signbit-5.c](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=67eaf67360e434dd5969e1c66f043e3c751f9f52)
- [testsuite: Add -fwrapv to signbit-5.c](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=5a3387938d4d95717cac29eecd0ba53e0ef9094d)
- [Make mve_fp_fpu\[12\].c accept single or double precision FPU](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=c7e87e82435b918084f305386b12b8fbcdcf3307)
- [testsuite: Disable finite math only for test  \[PR115826\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=7793f5b4194253acaac0b53d8a1c95d9b5c8f4bb)
- [arm: testsuite: fix issues relating to fp16 alternative testing](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=d9459129ea8f8c3cbd6150b90e842decba7952a3)
- [testsuite: Align testcase with implementation \[PR105090\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=4f6f63f2cfcc62d6d893f301ea6aa4f6365624ba)
- [testsuite: Remove gcc.dg/tree-ssa/scev-3.c -4.c and 5.c](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=0f3bac474e8f6563a59f814ccf7609ced48b1157)
- [testsuite: Cut down 27_io/basic_istream/.../94749.cc for simulators](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=273a33b285b426be4e4b7213ecc090d088f9cd69)
- [testsuite: fix the condition bug in tsvc s176](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=45b7da5f4951c3e9e5187487d611d16ff8cf148f)

### GDB

- [libctf: Return CTF_ERR in ctf_type_resolve_unsliced PR 30836](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=0f79aa900f3a69780dde1e934ffe21e30236934e)
- [libctf: Sanitize error types for PR 30836](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=998a4f589d68503f79695f180fdf1742eeb0a39d)
