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

Patch                                                          | Description |
---------------------------------------------------------------|--------------- |
Fix for long path issues on Windows                            | Windows has a limit of the number of characters in paths to files. This fix allows up to 248 characters in paths to GCC toolchain binaries and up to 4096 characters for all files processed by the GCC tools. Without the patch the latter limit is about 150 characters. |
Provide Newlib string function compatible with all platforms   | Adds aliases for Newlib string functions. Enables the functions to be called on all target platforms without changing the target source code. Useful for unit testing of target source code on Windows. |
Provide compatibility with IAR EW projects                     | Adds pre-processor symbol \_\_FILE\_NAME\_\_ which is used in IAR EW. Will be required for import of IAR EW projects. |
Correct stack usage for functions with inline assembler        | Required by Stack Analyzer advanced debug function in CubeIDE. |
Reduce Newlib code size by 10-30%                              | Updates the GCC build scripts for Newlib to use -Os instead of -O2. Beneficial in most embedded projects. |
Prepare for calculation of cyclomatic complexity               | Provides the ability to calculate cyclomatic complexity of the target source code processed by GCC. The patch integrates the plugin into GCC binaries. |
Include librdimon-v2m.a in delivery for both Newlib variants   | Support rdimon on Cortex-A by including librdimon-v2m.a for the Newlib-nano. |

## Backports

### Binutils

- [Debug info is lost for functions only called from functions marked with cmse\_nonsecure\_entr](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=e4fbcd83c2423221ddde99d50b432df7dda06f5f)
- [Add support for the .gnu.sgstubs section to the linker for ARM/ELF based targets.](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=b29f2fda4f189a008f5f2017d403976c988ad63e)

### GCC

- [testsuite: Fix expand-return CMSE test for Armv8.1-M \[PR115253\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=bf9c877c4c9939274520a3f694037a9921ba9878)
- [arm: Zero/Sign extends for CMSE security on Armv8-M.baseline \[PR115253\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=319081d614dec354ae415472121e0e8ebc4b1402)
- [testsuite: Verify r0-r3 are extended with CMSE](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=08ca81e4b49bda153d678a372df7f7143a94f4ad)
- [arm: Zero/Sign extends for CMSE security](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=dabd742cc25f8992c24e639510df0965dbf14f21)
- [reassoc: Handle OFFSET\_TYPE like POINTER\_TYPE in optimize\_range\_tests\_cmp\_bitwise \[PR107029\[](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=cb8f25c5dc9f6d5207c826c2dafe25f68458ceaf)
- [reassoc: Fix up recent regression in optimize\_range\_tests\_cmp\_bitwise \[PR106958\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=9ac9fde961f76879f0379ff3b2494a2f9ac915f7)
- [Disallow pointer operands for \|, ^ and partly & \[PR106878\]](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=645ef01a463f15fc230e2155719c7a12cec89acf)
- [Disallow pointer and offset types on some gimple](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=2f1686ff70b25fceb04ca2ffc0a450fb682913ef)
- [c++: Allow module name to be a single letter on Windows](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=d30e98b54d6a5124bb48b10b593e264f048d38aa)
- [libcpp/remap: Only override if string matched](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=711f56ad9093b18197ca82415317f4a3748d45ae)
- [c++: Use in-process client when networking is disabled](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=97752b7c446e513677e9d49b0c57427d41aaebde)
- [IRA: Make sure array is big enough](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=48e5d0f2eca05391fbb99e5b4ec79405d496f8c1)
- [lto: Always quote path to touch](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=47db37ed477f29ac52c4484c260138d15e44a36b)
- [c++: Tolerate cdtors returning this in constexpr](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=5ce08ecb15b2501abea7215e3fc59646ef7a73f9)
- [Improve sorry message for -fzero-call-used-regs](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=6efc494a24bb423f1f9ef8dbdc65ca189072eb8d)
- [c: Add support for \_\_FILE\_NAME\_\_ macro (PR c/42579)](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=1a9b3f04c11eb467a8dc504a37dad57a371a0d4c)
- [Introduce -nostdlib++ option](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=fc2fb4fd547fb39d76237a3a1a50f5c4f3646936)
- [testsuite: Windows paths use \\ and not /](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=9df85f331fa78ddfdbbe3b0fd5ff3727d2f57333)
- [testsuite: Verify that module-mapper is available](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=20d2a8c24f3ca487ffd35fefcc9b1562bb10b609)
- [arm: Allow to override location of .gnu.sgstubs section](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=d201bd1aab513266eb7f3adabfb3fafc6578228f)
- [testsuite: Sanitize fails for SP FPU on Arm](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=ecaa9ca6a8bce7d3aec8b7486f5252f82735bdb0)
- [libstdc++: Reduce \<random\> test iterations for simulators](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=e3b8b4f7814c54543d9b7ea3ee8cf2cb9cff351d)
- [libstdc++ testsuite: Don't run lwg3464.cc tests on simulators](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=baf98320ac6cd56da0c0b460fb94e3b87a79220d)
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
- [Adjust expected output for LP32 \[PR100451\].](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=c232f07b931e3e4cb7cbd96e47b161f1c390f21d) (partial)
- [testuite: Add pthread check to dg-module-cmi for omp module testing](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=f0e40ea0640aa0b324ec17e72154997468f33bc7)
- [testuite: Check pthread for omp module testing](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=a911287e13d1a1f95259cb60c57293eabc2a27b9)
- [fixed-point/composite-type: add -Wno-array-parameter](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=f0ccbe10f152b55fb809264d2ae11c724ab09ff6)
- [testsuite: Remove .exe suffix in prune\_gcc\_output](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=9081759b7ea5f7f1b17ea2a09cc438115c219ca1)
- [testsuite: Support single-precision in g++.dg/eh/arm-vfp-unwind.C](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=8e2c293f02745d47948fff19615064e4b34c1776)
- [testsuite: Add arm\_arch\_v7a\_ok effective-target to pr57351.c](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=1ca642d785c49e9e0b28651b190720267703f023)
- [testsuite/arm: Add arm\_cmse\_hw effective target](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=e9046be4ffa0a941b15315317a90b437f2c1ac28) (partial)
- [testsuite: gluefile file need to be prefixed](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=9d503515ceebc778a5c2958f7459367c34f1fed0)
- [testsuite: Fix mistransformed gcov](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=e91d51457532da6c2179b23359435f06d89488e7)
- [gcov: Respect triplet when looking for gcov](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=34b9a03353d3fdc5c57f2708469d0df78c6d6508)
- [libstdc++: Fix testsuite for skipping gdb tests on remote/non-native target](https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=817766f4dd2f6f3fdea2c4e6e22358b0b6b06d0d)


### GDB

- [gdb/arm: PR 29738 Cache value for stack pointers for dwarf2 frames](https://sourceware.org/pipermail/gdb-patches/2022-November/193394.html) (pending review)
- [gdb/arm: Include FType bit in EXC\_RETURN pattern on v8m](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=8db533e7d6d28db1be0ae4c95ddea7aa3a6224c8)
- [gdb/arm: Fix obvious typo in b0b23e06c3a](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=f3f7ecc942f3844559142b933aa40b5ef75e3d5e)
- [gdb/arm: Ensure that stack pointers are in sync](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=b0b23e06c3a2e3b92d6f12d99650c7d1cc5d939c)
- [gdb/arm: Update active msp/psp when switching stack](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=4d9fd8683fd48f081cb205afed07ba69f9aed134)
- [gdb/arm: Fix M-profile EXC\_RETURN](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=23295de1317433210cb0303ef304e68763607c78)
- [gdb/arm: fix IPSR field test in arm\_m\_exception\_cache ()](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=b2e9e754e122d97511bbd6b990e38a23dafb6176)
- [gdb/arm: Terminate frame unwinding in M-profile lockup](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=8b73ee207c9c4b2d692a82a29d1cee2dcfa07394)
- [gdb/arm: Don't rely on loop detection to stop unwinding](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=619cce4cac9b7ad5f4604cd5a63933e71515e16f)
- [gdb/arm: Stop unwinding on error, but do not assert](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=ce6c3d253b97961801bc045d10b7fd022578fd03)
- [gdb/arm: Handle lazy FPU state preservation](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=60c90d8c6d4b8345b41ab6a0b4d5169d5f78edb3)
- [\[Arm\] Cleanup arm\_m\_exception\_cache](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=df4860daad8ffa29e0185e543a0a2aae32f7a925)
- [gdb/arm: Sync sp with other \*sp registers](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=a6e4a48c02acf29d6bec2ff63fc909b57cf4bc78)
- [gdb/arm: Use if-else if instead of switch](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=42e11f363c5e2c5e750e9b9b67fbae511d83974d)
- [\[arm\] Rename arm\_cache\_is\_sp\_register to arm\_is\_alternative\_sp\_register](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=d65edaa0bc3f24537ecde3735b1fa041f36f4ab8)
- [gdb/arm: Only stack S16..S31 when FPU registers are secure](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=69b46464badb01340a88d0ee57cdef0b7fdf545e)
- [gdb/arm: Unwind Non-Secure callbacks from Secure](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=8c9ae6df3c244a7a738085ab461cb098df1d46f6)
- [gdb/arm: Update the value of active sp when base sp changes](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=10245fe8171a292dcf50051a33ec5bae7b08cb54)
- [gdb/arm: Make sp alias for one of the other stack pointers](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=b9b66a3a5740dfa0cf929a9c9abcdbaabe989358)
- [gdb/arm: Track msp and psp](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=0d12d61b9a646f317d9793492971c9a28f83b754)
- [gdb/arm: Fetch initial sp value prior to compare](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=fe642a5b1411502000af9d169122522065dff9ca)
- [gdb/arm: Document and fix exception stack offsets](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=2d9cf99d9a6c701de912d3e95ea3ffa134af4c62)
- [gdb/arm: Simplify logic for updating addresses](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=1ef3351b7b11e3d3bcdccdbc1bf2690ce35a70ba)
- [gdb/arm: Terminate unwinding when LR is 0xffffffff](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=148ca9dd5cf96049c0db17c1230e4b96c0ac054a)
- [\[arm\] Don't use special treatment for PC](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=46c7fd95fc42466a5a8c3b3d70925f1a8af68de3)
- [\[arm\] Add support for FPU registers in prologue unwinder](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=de76473c2d9fadca1374992fdd22887a799c2e3e)
- [\[arm\] d0..d15 are 64-bit each, not 32-bit](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=39fc7ff66b30f1581d4a1a97e6857b6bfcccf860)
- [\[arm\] Cleanup: use hex for offsets](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=1d2eeb660f0885807320792ee18c033b34522225)
- [gdb/arm: Extend arm\_m\_addr\_is\_magic to support FNC\_RETURN, add unwind-secure-frames command](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=ef273377587d440f4aa248265147d5e75f86a018)
- [gdb/arm: Add support for multiple stack pointers on Cortex-M](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=ae7e2f45aa4798be449f282bbf75ad41e73f055e)
- [gdb/arm: Introduce arm\_cache\_init](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=0824193fd31467b6ff39132d0d72aaa9c01cc9aa)
- [gdb/arm: Define MSP and PSP registers for M-Profile](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=9074667a8583b33ff1b9590232c15e67f2d1d607)
- [gdb/arm: Fix prologue analysis to support vpush](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=fcaa1071d7921c4f7c7592a10ed7b84830ec8c49)

### Newlib

- [Restore \_lock initialization in non-single threaded mode](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=dd1122e21cb4ea78ce4c5894787c8f085469f9dd)
- [newlib: info: tweak iconv node to avoid collisions](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=c8d521033751fbcccdc8ce93f22521e32c6fc6ed)
- [Rerun automake in newlib/](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=0b6342c97f08765e9873b3c52d61657c2aa596e5)
- [Implement sysconf for Arm](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=5230eb7f8c6b43c71d7e38d138935c48de930b76)
- [Don't allocate another header when merging chunks](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=a68e99f8839e4697790077c8a77b506d528cc674)
- [Used chunk needs to be removed from free\_list](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=0455ea28ce2bfa83ca36ec37b9c9fb00c54bbe54)
- [Fix problem with \_newlib\_version.h not being filled in correctly](https://sourceware.org/git/?p=newlib-cygwin.git;a=commit;h=64a11fded15b92b56b91d65fd5b2851245f69299)
