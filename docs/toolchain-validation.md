# Toolchain Validation Workflows

This document describes the automated validation system for the GNU Tools for STM32 toolchain.

## Overview

The validation system ensures that the custom-built ARM GCC toolchain produces byte-identical output to the official STM32CubeIDE toolchain by:

1. Building a test CMake project using the Docker container
2. Comparing the generated artifacts with reference files
3. Failing the build if any differences are detected

## Workflow Architecture

### Workflow Files

1. **`build-container.yml`** - Builds and publishes the toolchain container
   - Triggers: Push to main, pull requests, manual
   - Pushes to GHCR only on main branch or manual trigger
   - Uses GitHub Actions cache for build layers

2. **`validate-toolchain-reusable.yml`** - Reusable validation workflow
   - Contains common validation logic to minimize duplication
   - Pulls container, builds test project, compares artifacts
   - Used by both main and PR validation workflows

3. **`validate-toolchain.yml`** - Validates released toolchain
   - Triggers: After container build completes on main, manual
   - Pulls pre-built container from GHCR
   - Uses reusable workflow for validation

4. **`validate-toolchain-pr.yml`** - Validates PRs
   - Triggers: Pull requests
   - **Two separate jobs to avoid disk space issues:**
     - Job 1: Build container and save as GitHub Actions artifact
     - Job 2: Download artifact, load container, and validate (separate runner)
   - Uses GitHub Actions artifacts instead of pushing to GHCR
   - Container artifact auto-deleted after 1 day
   - Does not clutter GHCR with PR containers

### Disk Space Optimization

The PR validation workflow uses a **two-job architecture** to prevent disk space issues:

```
┌─────────────────────────────────────┐
│ Job 1: build-container              │
│ - Free up disk space                │
│ - Build Docker container            │
│ - Export to tar file                │
│ - Compress with gzip                │
│ - Upload as GitHub Actions artifact │
│ - Container layers cached in GHA    │
└─────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│ Job 2: validate                     │
│ - Fresh runner (no build artifacts) │
│ - Download artifact                 │
│ - Load container from tar           │
│ - Build test project                │
│ - Compare with reference            │
│ - Artifact auto-deleted after 1 day │
└─────────────────────────────────────┘
```

**Why separate jobs?**
- Building the container requires ~30-40GB of disk space for layers
- Using the container requires space for the test project build
- Keeping both in the same job caused frequent disk exhaustion
- Separate jobs run on different runners with fresh disk space

**Why GitHub Actions artifacts instead of GHCR?**
- Avoids pushing temporary PR containers to GHCR
- Automatic cleanup after 1 day retention period
- No manual cleanup required
- Keeps GHCR clean with only main branch images

### Container Tagging Strategy

- **Main branch**: `ghcr.io/{owner}/gnu-tools-for-stm32:latest`
- **SHA tags**: `ghcr.io/{owner}/gnu-tools-for-stm32:{branch}-{sha}`
- **Pull requests**: Not pushed to GHCR; stored as GitHub Actions artifacts instead

## Entrypoint Script

**File**: `build-cmake-project.sh`

Generic script that can build any CMake project with an ARM toolchain:

```bash
build-cmake-project.sh <project_path> [output_path]
```

**Requirements for projects:**
- Must contain `CMakeLists.txt` at the root
- Must contain `arm-none-eabi-gcc.cmake` toolchain file at the root
- Toolchain file should search for toolchain in: `/root/build/gnu-tools-for-stm32/install-native/bin`

**Features:**
- Validates required files exist before building
- Runs CMake configure and build
- Copies build artifacts (`.elf`, `.map`, `.hex`, `.bin`) to output directory
- Returns non-zero exit code on failure

## Validation Process

1. **Build**: CMake project is built in the Docker container
2. **Extract**: Build artifacts are copied to output directory
3. **Compare**: Each artifact is compared byte-by-byte with reference file
4. **Report**: Differences trigger build failure with detailed output

## Reference Artifacts

**Location**: `test_project/reference/`

**Source**: Built with STM32CubeIDE 1.19.0

**Files:**
- `nucleo-u083rc.elf` - Executable and Linkable Format
- `nucleo-u083rc.map` - Memory map
- `nucleo-u083rc.hex` - Intel HEX format
- `nucleo-u083rc.bin` - Raw binary

**Validation**: The custom toolchain must produce byte-identical files.

## Cross-Platform Toolchain File

**File**: `test_project/arm-none-eabi-gcc.cmake`

**Features:**
- Automatically detects Windows vs. Linux/Docker environment
- Handles executable suffix (`.exe` on Windows, none on Linux)
- Searches for toolchain in multiple locations:
  - Docker: `/root/build/gnu-tools-for-stm32/install-native/bin`
  - Windows: STM32CubeIDE installation path
- Validates compiler exists before using it

## Troubleshooting

### Validation Fails with Artifact Differences

1. Check if reference files are up-to-date
2. Review diff output for `.map` files
3. Verify toolchain versions match (GCC, Binutils, Newlib)
4. Check for timestamp or build path differences

### Disk Space Issues

- Ensure using separate jobs for build and validation
- Verify disk cleanup step runs before build
- Check GitHub Actions runner has sufficient space
- Review Docker cache settings

### Container Pull Failures

- Verify container was pushed successfully
- Check GHCR authentication is working
- Ensure container tag is correct
- For PRs, verify container was built in previous job

### CMake Configuration Fails

- Check toolchain file is present
- Verify toolchain path is correct
- Ensure CMake version is compatible (3.15+)
- Review CMake configure output for errors

## Future Enhancements

Potential improvements to the validation system:

1. **Parameterized artifacts**: Make artifact names configurable for reusability
2. **Multiple test projects**: Validate with different target architectures
3. **Performance benchmarks**: Track build time and artifact size
4. **Automated reference updates**: Generate new references when toolchain is updated
5. **Differential analysis**: Show detailed comparison for binary differences

## Maintenance

When updating the toolchain:

1. Update reference artifacts if toolchain changes affect output
2. Update documentation if validation process changes
3. Test validation workflows on PRs before merging
4. Monitor disk space usage and adjust cleanup if needed
5. Keep Docker base image and dependencies up-to-date
