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
Provide compatibility with IAR EW projects                           | Adds pre-processor symbol \_\_FILE\_NAME\_\_ which is used in IAR EW. Will be required for import of IAR EW projects. |
Enable debugging of functions in target libraries libg or libg\_nano | Updates the GCC build scripts for libg and libg\_nano in Newlib, so that debug symbols are not stripped. |
Correct stack usage for functions with inline assembler              | Required by Stack Analyzer advanced debug function in CubeIDE. |
Reduce Newlib code size by 10-30%                                    | Updates the GCC build scripts for Newlib to use -Os instead of -O2. Beneficial in most embedded projects. |
Prepare for calculation of cyclomatic complexity                     | Provides the ability to calculate cyclomatic complexity of the target source code processed by GCC. The patch integrates the plugin into GCC binaries. |
Include librdimon-v2m.a in delivery for both Newlib variants         | Support rdimon on Cortex-A by including librdimon-v2m.a for the Newlib-nano. |

## Backports

### Binutils

- [libctf: Return CTF\_ERR in ctf\_type\_resolve\_unsliced PR 30836](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=0f79aa900f3a69780dde1e934ffe21e30236934e)
- [libctf: Sanitize error types for PR 30836](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=998a4f589d68503f79695f180fdf1742eeb0a39d)

### GCC

- [testsuite: Fix expand-return CMSE test for Armv8.1-M \[PR115253\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=3d9e4eedb6b1f43e5d0cd46c9aa06caf7c2d3500)
- [arm: Zero/Sign extends for CMSE security on Armv8-M.baseline \[PR115253\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=55c1687d542e40f0d4ad1d3dc624695a1854d967)
- [testsuite: Verify r0-r3 are extended with CMSE](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=d9c89402b54be4c15bb3c7bcce3465f534746204)
- [arm: Zero/Sign extends for CMSE security](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=441e194abcf3211de647d74c892f90879ae9ca8c)
- [Disallow pointer operands for |, ^ and partly & \[PR106878\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=645ef01a463f15fc230e2155719c7a12cec89acf)
- [Properly honor param\_max\_fsm\_thread\_path\_insns in backwards threader](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=353fd1ec3df92fbe66ce1513c5a86bdd5c5e22d1)
- [libstdc++: Fix std::random\_device::entropy() for non-posix targets](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=26c68b8c31f637cc01f4bf511f9a0ca714231161)
- [tree-optimization/67196 - normalize use predicates earlier](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=61051ee5cfd59ee292984641d02caac85f6dfac3)
- [tree-optimization/99412 - reassoc and reduction chains](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=b073f2b098ba7819450d6c14a0fb96cb1c09f242)
- [\[PR40457\] \[arm\] expand SI-aligned movdi into pair of movsi](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=acddf6665f067bc98a2529a699b1d4509a7387cb)
- [-Wdangling-pointer: don't mark SSA lhs sets as stores](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=fdac2bea53bf5e7214352e2afd5542254c3156cb)
- [libstdc++: Add preprocessor checks to \<experimental/internet\> \[PR100285\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=793ed718b522b15e2d758eca953feeec1979fe2c)
- [c++: Allow module name to be a single letter on Windows](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=d30e98b54d6a5124bb48b10b593e264f048d38aa)
- [libcpp/remap: Only override if string matched](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=711f56ad9093b18197ca82415317f4a3748d45ae)
- [c++: Use in-process client when networking is disabled](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=97752b7c446e513677e9d49b0c57427d41aaebde)
- [lto: Always quote path to touch](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=47db37ed477f29ac52c4484c260138d15e44a36b)
- [Improve sorry message for -fzero-call-used-regs](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=6efc494a24bb423f1f9ef8dbdc65ca189072eb8d)
- [Introduce -nostdlib++ option](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=fc2fb4fd547fb39d76237a3a1a50f5c4f3646936)
- [testsuite: Cut down 27\_io/basic\_istream/.../94749.cc for simulators](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=273a33b285b426be4e4b7213ecc090d088f9cd69)
- [testsuite: fix proc unsupported overriding in modules.exp \[PR108899\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=673a2a6445a79bcce5ba433d6bbec4b99a1bc7c6)
- [testsuite: Fix up modules.exp \[PR108899\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=5592679df783547049efc6d73727c5ff809ec302)
- [testsuite: Skip module\_cmi\_p and related unsupported module test](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=5344482c4d3ae0618fa8f5ed38f8309db43fdb82)
- [c++: testsuite: require lto\_incremental in pr90990\_0.C](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=614db2317e6519db9c77523498f5f14b860818d2)
- [\[PR105224\] C++ modules and AAPCS/ARM EABI clash on inline key methods](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=3d1d3ece9bc5a1baa2feb4bf231b709c097b8434)
- [\[PR102706\] \[testsuite\] -Wno-stringop-overflow vs Warray-bounds](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=4505270128ef70538ea345f292e3eb85a5369eaf)
- [\[PR51534\] \[arm\] split out pr51534 test for softfp](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=cc9cc5a9a5fb0c16532a16b87fbd155037a7ed89)
- [\[PR42093\] \[arm\] \[thumb2\] disable tree-dce for test](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=31aaa6ef5a952d4f64fb04010459f28e0e793702)
- [testsuite: Require vectors of doubles for pr97428.c](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=cda68d77b2835b67fc80abe7ec4d71de1065bb21)
- [xfail fp-uint64-convert-double-\* on all arm targets](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=2d6a0fd3bddb9341f1512c21fcc55b3d39d9cd0e)
- [\[arm\] xfail fp-uint64-convert-double tests](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=a82c119b1e9e45861ac04df8736917f396e1b740)
- [\[PATCH\] testsuite: constraint some of fp tests to hard\_float](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=ff01849dccd4355ac6491c04eff8b2e39ecee70e)
- [testsuite: Accept pmf-vbit-in-delta extra warning](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=1a45573d3d7b0098116f4ccde5d9be5d32b5653a)
- [\[testsuite\] \[arm/aarch64\] -fno-short-enums for auto-init-\[12\].c](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=c690779637e1c4b1b7768d3e76c9dd4e2aa49f6a)
- [testsuite: fix the condition bug in tsvc s176](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=45b7da5f4951c3e9e5187487d611d16ff8cf148f)
- [\[testsuite\] tsvc: skip include malloc.h when unavailable](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=2f20d6296087cae51f55eeecb3efefe786191fd6)
- [testsuite: Windows paths use \ and not /](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=9df85f331fa78ddfdbbe3b0fd5ff3727d2f57333)
- [testsuite: Verify that module-mapper is available](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=20d2a8c24f3ca487ffd35fefcc9b1562bb10b609)
- [arm: Allow to override location of .gnu.sgstubs section](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=d201bd1aab513266eb7f3adabfb3fafc6578228f)
- [testsuite: Sanitize fails for SP FPU on Arm](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=ecaa9ca6a8bce7d3aec8b7486f5252f82735bdb0)
- [libstdc++: Reduce \<random\> test iterations for simulators](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=e3b8b4f7814c54543d9b7ea3ee8cf2cb9cff351d)
- [testsuite: 'b' instruction can't do long enough jumps](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=1a46a0a8b30405ea353a758971634dabeee89eaf)
- [testsuite: Windows reports errors with CreateProcess](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=fa8e3a055a082e38aeab2561a5016b01ebfd6ebd)
- [testsuite: /dev/null is not accessible on Windows](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=5fe2e4f87e512407c5c560dfec2fe48ba099c807)
- [\[testsuite\]\[arm\] Fix cmse-15.c expected output](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=b22baa40d7465addf01373a0555a79fdf63dfa72)
- [libstdc++: Fix broken dg-prune-output](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=7069d03ba4ad6133225b89d433d9e86f0b0745b8)
- [testsuite: Only run test on target if VMA == LMA](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=5fb71366da6ec5cd4dbc0262c6747804e319a7b7)
- [testsuite: Do not prefix linker script with "-Wl,"](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=86291da0057d01efdaba71f28cad80b69dc703a4)
- [testsuite: Colon is reserved on Windows](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=3bb2d70d38027c43b437dee98ee1a7a15843682f)
- [testsuite: Skip intrinsics test if arm](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=9a8212db2dd8373f5649ccd21028edd14303eb82)
- [testsuite: Skip intrinsics test if arm](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=f5072839c46acd185f40a5692aca06fac4ed6a48)
- [testsuite: gluefile file need to be prefixed](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=9d503515ceebc778a5c2958f7459367c34f1fed0)
- [testsuite: Fix mistransformed gcov](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=e91d51457532da6c2179b23359435f06d89488e7)
- [gcov: Respect triplet when looking for gcov](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=34b9a03353d3fdc5c57f2708469d0df78c6d6508)

### GDB

- [libctf: Return CTF\_ERR in ctf\_type\_resolve\_unsliced PR 30836](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=0f79aa900f3a69780dde1e934ffe21e30236934e)
- [libctf: Sanitize error types for PR 30836](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=998a4f589d68503f79695f180fdf1742eeb0a39d)
- [Rename split\_style::DOT](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=fe26aa95336c0ddec01b407b990caf2c758fd93f)

### Newlib

- [newlib: Add missing prototype for \_getentropy](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=a9e8e3d1cb8235f513f4d8434509acf287494fcf)
- [Add stub for getentropy](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=b9e867d088935d9f0bf312e6dbf3e4976850dfd3)
