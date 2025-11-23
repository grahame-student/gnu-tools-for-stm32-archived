# Docker Build Optimization

## Overview

This document describes the incremental build optimization strategy implemented in the Dockerfile to improve build times, reduce layer sizes, and maximize Docker layer caching.

## Build Stages

The Dockerfile uses multi-stage builds with the following stages:

1. **bootstrap** - Install build tools and build prerequisite libraries (GMP, MPFR, MPC, ISL, Expat, zlib)
   - Note: libiconv source is copied but only built for MinGW (Windows) builds, not in Docker native builds
2. **binutils-gcc-first** - Build GNU Binutils and GCC first pass (C compiler only)
3. **newlib** - Build Newlib C standard library
4. **gcc-final-gdb** - Build GCC final pass (with C++) and GDB debugger
5. **runtime-libs** - Finalize runtime libraries
6. **main** - Final image with complete toolchain

## Incremental Copying Strategy

### Bootstrap Stage (Optimized)

The bootstrap stage uses **incremental copying** to minimize the layer size and improve cache reusability:

```dockerfile
# Copy only what's needed for bootstrap
COPY build-common.sh build-toolchain-config.sh build-prerequisites.sh /root/build/gnu-tools-for-stm32/
COPY src/gcc/gcc/BASE-VER /root/build/gnu-tools-for-stm32/src/gcc/gcc/BASE-VER
COPY src/gmp /root/build/gnu-tools-for-stm32/src/gmp
COPY src/mpfr /root/build/gnu-tools-for-stm32/src/mpfr
COPY src/mpc /root/build/gnu-tools-for-stm32/src/mpc
COPY src/isl /root/build/gnu-tools-for-stm32/src/isl
COPY src/expat /root/build/gnu-tools-for-stm32/src/expat
COPY src/zlib-1.2.12 /root/build/gnu-tools-for-stm32/src/zlib-1.2.12
COPY src/libiconv /root/build/gnu-tools-for-stm32/src/libiconv
```

**Benefits:**
- Bootstrap layer size: ~102M (vs ~2GB if all sources were copied)
- Changes to GCC, GDB, Binutils, or Newlib sources don't invalidate bootstrap cache
- Faster rebuilds when only main toolchain sources change

**Libraries built in Docker native build:**
- zlib, GMP, MPFR, MPC, ISL, Expat
- Note: libiconv is copied but only built for MinGW (Windows) targets, not in Docker builds which use `--skip_steps=mingw`

**Files excluded from bootstrap:**
- Main toolchain sources: `src/gcc/*`, `src/gdb/*`, `src/binutils/*`, `src/newlib/*` (except BASE-VER)
- Documentation: `docs/`, `README.md`, `BUILD.md`, etc.
- Test project: `test_project/`
- Other build scripts used in later stages

### Binutils-GCC-First Stage (Optimized)

The binutils-gcc-first stage uses **incremental copying** to minimize the layer size and improve cache reusability:

```dockerfile
# Copy only what's needed for binutils-gcc-first
COPY build-binutils-gcc-first.sh /root/build/gnu-tools-for-stm32/
COPY src/binutils /root/build/gnu-tools-for-stm32/src/binutils
COPY src/gcc /root/build/gnu-tools-for-stm32/src/gcc
```

**Benefits:**
- Binutils-gcc-first layer size: ~2.5G (includes binutils, gcc sources, and built binaries)
- Installed binaries: ~345M
- Changes to Newlib or GDB sources don't invalidate binutils-gcc-first cache
- Faster rebuilds when only later-stage sources change
- Build time: ~12 minutes

**Components built:**
- GNU Binutils (assembler, linker, binary utilities)
- GCC First Pass (C compiler only, no standard library)

**Files excluded from binutils-gcc-first:**
- Later-stage sources: `src/newlib/*`, `src/gdb/*`
- Documentation: `docs/`, `README.md`, `BUILD.md`, etc.
- Test project: `test_project/`
- Other build scripts used in later stages

### Newlib Stage (Optimized)

The newlib stage uses **incremental copying** to minimize the layer size and improve cache reusability:

```dockerfile
# Copy only what's needed for newlib
COPY build-newlib.sh /root/build/gnu-tools-for-stm32/
COPY src/newlib /root/build/gnu-tools-for-stm32/src/newlib
```

**Benefits:**
- Newlib layer size: ~2.6G (includes newlib sources and built libraries)
- Installed libraries: target-specific libraries in `install-native/arm-none-eabi/lib/`
- Changes to GDB sources don't invalidate newlib cache
- Faster rebuilds when only later-stage sources change

**Components built:**
- Newlib C standard library (libc.a, libm.a, libg.a, crt0.o startup files)

**Files excluded from newlib:**
- Later-stage sources: `src/gdb/*`
- Documentation: `docs/`, `README.md`, `BUILD.md`, etc.
- Test project: `test_project/`
- Other build scripts used in later stages

### GCC-Final-GDB Stage (Optimized)

The gcc-final-gdb stage uses **incremental copying** to minimize the layer size and improve cache reusability:

```dockerfile
# Copy only what's needed for gcc-final-gdb
COPY build-gcc-final-gdb.sh /root/build/gnu-tools-for-stm32/
COPY src/gdb /root/build/gnu-tools-for-stm32/src/gdb
```

**Benefits:**
- GCC-final-gdb layer size: ~3.0G (includes gdb sources and built binaries)
- Installed toolchain: complete C/C++ compiler and debugger
- Changes to documentation or test projects don't invalidate gcc-final-gdb cache
- Faster rebuilds when only auxiliary files change
- Build time: ~15 minutes

**Components built:**
- GCC Final Pass (C++ compiler with libstdc++, libsupc++)
- GDB (GNU Debugger for ARM targets)

**Files excluded from gcc-final-gdb:**
- Documentation: `docs/`, `README.md`, `BUILD.md`, etc.
- Test project: `test_project/`
- Other build scripts not needed for this stage

### Runtime-Libs Stage (Optimized)

The runtime-libs stage uses **incremental copying** to minimize the layer size and improve cache reusability:

```dockerfile
# Copy only what's needed for runtime-libs finalization
COPY build-runtime-libs-finalize.sh /root/build/gnu-tools-for-stm32/
```

**Benefits:**
- Runtime-libs layer size: minimal (no new sources, just finalization script)
- Changes to documentation, test projects, or any other files don't invalidate runtime-libs cache
- Maximum cache reusability
- Final cleanup removes all source directories and build artifacts

**Operations performed:**
- No new compilation (verification and cleanup only)
- Verifies runtime libraries are installed
- Creates symlinks for toolchain binaries in `/usr/local/bin/`
- Removes all build artifacts and source directories
- Displays summary of installed libraries and headers

**Files excluded from runtime-libs:**
- All source directories (removed during housekeeping)
- Documentation: `docs/`, `README.md`, `BUILD.md`, etc.
- Test project: `test_project/`
- All other files not needed for finalization

**Note:** build-common.sh, build-toolchain-config.sh, and src/gcc/gcc/BASE-VER are already present from the bootstrap stage, so only the finalization script needs to be copied.

## Housekeeping

The Dockerfile includes cleanup operations to reduce layer sizes:

### Bootstrap Stage
```dockerfile
RUN ./build-prerequisites.sh --skip_steps=mingw && \
    # Clean up temporary build directories
    rm -rf build-native/zlib build-native/gmp build-native/mpfr \
           build-native/mpc build-native/isl build-native/expat
```

**What's kept:** Installed libraries in `build-native/host-libs/` (needed by later stages)  
**What's removed:** Temporary build directories for individual libraries

### Binutils-GCC-First Stage
```dockerfile
RUN ./build-binutils-gcc-first.sh && \
    # Build artifacts already cleaned by build script:
    # - build-native/binutils (removed after building)
    # - build-native/gcc-first (removed after building)
    # - *.o object files (removed via find)
    # - *.la libtool files (removed via find)
    # Additional housekeeping:
    rm -rf build-native/*.log build-native/*.txt 2>/dev/null || true && \
    find build-native -type d -name ".deps" -exec rm -rf {} + 2>/dev/null || true && \
    find . -name "*~" -delete 2>/dev/null || true && \
    find . -name "*.orig" -delete 2>/dev/null || true && \
    find . -name "*.rej" -delete 2>/dev/null || true
```

**What's kept:** 
- Installed binaries in `install-native/bin/`
- Installed libraries in `install-native/lib/`  

**What's removed:** 
- Build directories: `build-native/binutils/`, `build-native/gcc-first/`
- Build artifacts: `*.o`, `*.la`, `.deps/` directories
- Temporary files: logs, backup files

### Newlib Stage
```dockerfile
RUN ./build-newlib.sh && \
    # Build artifacts already cleaned by build script:
    # - build-native/newlib (removed after building)
    # - *.o object files (removed via find)
    # - *.la libtool files (removed via find)
    # Additional housekeeping:
    rm -rf build-native/*.log build-native/*.txt 2>/dev/null || true && \
    find build-native -type d -name ".deps" -exec rm -rf {} + 2>/dev/null || true && \
    find . -name "*~" -delete 2>/dev/null || true && \
    find . -name "*.orig" -delete 2>/dev/null || true && \
    find . -name "*.rej" -delete 2>/dev/null || true
```

**What's kept:** 
- Installed libraries in `install-native/arm-none-eabi/lib/`
- Previously installed binaries from earlier stages

**What's removed:** 
- Build directories: `build-native/newlib/`
- Build artifacts: `*.o`, `*.la`, `.deps/` directories
- Temporary files: logs, backup files

### GCC-Final-GDB Stage
```dockerfile
RUN ./build-gcc-final-gdb.sh && \
    # Build artifacts already cleaned by build script:
    # - build-native/gcc-final (removed after building)
    # - build-native/gdb (removed after building)
    # - build-native/target-libs (removed after building)
    # Additional housekeeping:
    rm -rf build-native/*.log build-native/*.txt 2>/dev/null || true && \
    find build-native -type d -name ".deps" -exec rm -rf {} + 2>/dev/null || true && \
    find . -name "*~" -delete 2>/dev/null || true && \
    find . -name "*.orig" -delete 2>/dev/null || true && \
    find . -name "*.rej" -delete 2>/dev/null || true
```

**What's kept:** 
- Complete installed toolchain in `install-native/`
- Source directories (needed for runtime-libs verification)

**What's removed:** 
- Build directories: `build-native/gcc-final/`, `build-native/gdb/`, `build-native/target-libs/`
- Build artifacts: `*.o`, `*.la`, `.deps/` directories
- Temporary files: logs, backup files

### Runtime-Libs Stage
```dockerfile
RUN ./build-runtime-libs-finalize.sh && \
    # Build artifacts already cleaned by build-runtime-libs-finalize.sh:
    # - build-native/ directory (removed completely)
    # - *.o object files (removed via find)
    # - *.la libtool files (removed via find)
    # - Empty directories (removed via find)
    # Additional housekeeping for final image size reduction:
    rm -rf src/ && \
    rm -rf *.log *.txt 2>/dev/null || true && \
    find . -name "*~" -delete 2>/dev/null || true && \
    find . -name "*.orig" -delete 2>/dev/null || true && \
    find . -name "*.rej" -delete 2>/dev/null || true && \
    find . -type d -name "autom4te.cache" -exec rm -rf {} + 2>/dev/null || true
```

**What's kept:** 
- Complete installed toolchain in `install-native/`
- Build scripts for reference

**What's removed:** 
- All source directories: `src/` (no longer needed after build)
- All build directories: `build-native/` (already removed by script)
- All build artifacts: `*.o`, `*.la`
- Temporary files: logs, backup files, autotools cache

## Layer Size Reporting

Each optimized stage includes size reporting for visibility:

**Bootstrap Stage:**
```dockerfile
RUN echo "=== Bootstrap Stage: Building prerequisite libraries ===" && \
    echo "Layer size before build:" && du -sh /root/build/gnu-tools-for-stm32 && \
    ./build-prerequisites.sh --skip_steps=mingw && \
    echo "=== Housekeeping: Cleaning up build artifacts ===" && \
    rm -rf build-native/zlib build-native/gmp build-native/mpfr \
           build-native/mpc build-native/isl build-native/expat && \
    echo "Layer size after build and cleanup:" && du -sh /root/build/gnu-tools-for-stm32 && \
    echo "Installed libraries size:" && du -sh build-native/host-libs
```

**Binutils-GCC-First Stage:**
```dockerfile
RUN echo "=== Binutils-GCC-First Stage: Building binutils and gcc first pass ===" && \
    echo "Layer size before build:" && du -sh /root/build/gnu-tools-for-stm32 && \
    chmod +x build-binutils-gcc-first.sh && \
    ./build-binutils-gcc-first.sh && \
    echo "=== Housekeeping: Cleaning up build artifacts ===" && \
    rm -rf build-native/*.log build-native/*.txt 2>/dev/null || true && \
    find build-native -type d -name ".deps" -exec rm -rf {} + 2>/dev/null || true && \
    find . -name "*~" -delete 2>/dev/null || true && \
    find . -name "*.orig" -delete 2>/dev/null || true && \
    find . -name "*.rej" -delete 2>/dev/null || true && \
    echo "Layer size after build and cleanup:" && du -sh /root/build/gnu-tools-for-stm32 && \
    echo "Installed binaries size:" && du -sh install-native/bin
```

**Newlib Stage:**
```dockerfile
RUN echo "=== Newlib Stage: Building newlib C standard library ===" && \
    echo "Layer size before build:" && du -sh /root/build/gnu-tools-for-stm32 && \
    chmod +x build-newlib.sh && \
    ./build-newlib.sh && \
    echo "=== Housekeeping: Cleaning up build artifacts ===" && \
    rm -rf build-native/*.log build-native/*.txt 2>/dev/null || true && \
    find build-native -type d -name ".deps" -exec rm -rf {} + 2>/dev/null || true && \
    find . -name "*~" -delete 2>/dev/null || true && \
    find . -name "*.orig" -delete 2>/dev/null || true && \
    find . -name "*.rej" -delete 2>/dev/null || true && \
    echo "Layer size after build and cleanup:" && du -sh /root/build/gnu-tools-for-stm32 && \
    echo "Installed libraries size:" && du -sh install-native/arm-none-eabi/lib 2>/dev/null || echo "Libraries not yet installed"
```

**GCC-Final-GDB Stage:**
```dockerfile
RUN echo "=== GCC-Final-GDB Stage: Building GCC final pass and GDB ===" && \
    echo "Layer size before build:" && du -sh /root/build/gnu-tools-for-stm32 && \
    chmod +x build-gcc-final-gdb.sh && \
    ./build-gcc-final-gdb.sh && \
    echo "=== Housekeeping: Cleaning up build artifacts ===" && \
    rm -rf build-native/*.log build-native/*.txt 2>/dev/null || true && \
    find build-native -type d -name ".deps" -exec rm -rf {} + 2>/dev/null || true && \
    find . -name "*~" -delete 2>/dev/null || true && \
    find . -name "*.orig" -delete 2>/dev/null || true && \
    find . -name "*.rej" -delete 2>/dev/null || true && \
    echo "Layer size after build and cleanup:" && du -sh /root/build/gnu-tools-for-stm32 && \
    echo "Installed toolchain size:" && du -sh install-native/
```

**Runtime-Libs Stage:**
```dockerfile
RUN echo "=== Runtime-Libs Stage: Finalizing runtime libraries ===" && \
    echo "Layer size before finalization:" && du -sh /root/build/gnu-tools-for-stm32 && \
    chmod +x build-runtime-libs-finalize.sh && \
    ./build-runtime-libs-finalize.sh && \
    echo "=== Housekeeping: Final cleanup operations ===" && \
    rm -rf src/ && \
    rm -rf *.log *.txt 2>/dev/null || true && \
    find . -name "*~" -delete 2>/dev/null || true && \
    find . -name "*.orig" -delete 2>/dev/null || true && \
    find . -name "*.rej" -delete 2>/dev/null || true && \
    find . -type d -name "autom4te.cache" -exec rm -rf {} + 2>/dev/null || true && \
    echo "Layer size after finalization and cleanup:" && du -sh /root/build/gnu-tools-for-stm32 && \
    echo "Final toolchain size:" && du -sh install-native/
```

## Maximizing Cache Reusability

### GitHub Actions Workflow Caching (Recommended)

The repository's container build workflow (`.github/workflows/build_container_dryrun.yml`) is configured with **automatic caching** using GitHub Actions cache with a **single-job strategy** for optimal cache performance:

**Build Critical Stages** (runs on all PRs)
```yaml
# Bootstrap stage is built and cached separately
- name: Build and Cache Bootstrap Stage
  uses: docker/build-push-action@v6.18.0
  with:
    target: bootstrap
    cache-from: type=gha,scope=bootstrap
    cache-to: type=gha,mode=max,scope=bootstrap

# Binutils-GCC-First stage is built and cached separately
- name: Build and Cache Binutils-GCC-First Stage
  uses: docker/build-push-action@v6.18.0
  with:
    target: binutils-gcc-first
    cache-from: |
      type=gha,scope=bootstrap
      type=gha,scope=binutils-gcc-first
    cache-to: type=gha,mode=max,scope=binutils-gcc-first

# Newlib stage is built and cached separately
- name: Build and Cache Newlib Stage
  uses: docker/build-push-action@v6.18.0
  with:
    target: newlib
    cache-from: |
      type=gha,scope=bootstrap
      type=gha,scope=binutils-gcc-first
      type=gha,scope=newlib
    cache-to: type=gha,mode=max,scope=newlib

# GCC-Final-GDB stage is built and cached separately
- name: Build and Cache GCC-Final-GDB Stage
  uses: docker/build-push-action@v6.18.0
  with:
    target: gcc-final-gdb
    cache-from: |
      type=gha,scope=bootstrap
      type=gha,scope=binutils-gcc-first
      type=gha,scope=newlib
      type=gha,scope=gcc-final-gdb
    cache-to: type=gha,mode=max,scope=gcc-final-gdb

# Runtime-Libs stage is built and cached separately
- name: Build and Cache Runtime-Libs Stage
  uses: docker/build-push-action@v6.18.0
  with:
    target: runtime-libs
    cache-from: |
      type=gha,scope=bootstrap
      type=gha,scope=binutils-gcc-first
      type=gha,scope=newlib
      type=gha,scope=gcc-final-gdb
      type=gha,scope=runtime-libs
    cache-to: type=gha,mode=max,scope=runtime-libs
```

**Benefits:**
- **Automatic cache preservation:** All stage caches (bootstrap through runtime-libs) are saved even if later stages fail
- **Shared cache across runs:** Subsequent workflow runs reuse cached layers
- **No manual intervention:** Cache is managed automatically by GitHub Actions
- **Scoped caching:** Each stage has separate cache scopes for better isolation
- **Incremental builds:** Changes to later stages don't invalidate earlier stage caches
- **Single-job efficiency:** Docker local cache works optimally within a single job
- **Complete validation:** All build stages are validated in CI

### Local Development Caching

For local development, Docker automatically caches layers:

```bash
# Build entire toolchain
docker build -t gnu-tools-for-stm32 .

# Build specific stage (useful for testing)
docker build --target bootstrap -t gnu-tools-for-stm32:bootstrap .
docker build --target binutils-gcc-first -t gnu-tools-for-stm32:binutils-gcc-first .
docker build --target newlib -t gnu-tools-for-stm32:newlib .
docker build --target gcc-final-gdb -t gnu-tools-for-stm32:gcc-final-gdb .
docker build --target runtime-libs -t gnu-tools-for-stm32:runtime-libs .
```

### Preserving Cache When Builds Fail

**In GitHub Actions:**
- The workflow is configured with `continue-on-error: true` for the full build step
- Bootstrap, binutils-gcc-first, and newlib caches are always saved, even if later stages fail
- The workflow explicitly builds each stage separately to ensure they're cached
- Subsequent runs automatically reuse the cached layers

**In Local Development:**
If a build fails, Docker **automatically preserves** the cache for all successfully completed stages. You can:

1. **Rebuild from cached layers:**
   ```bash
   # Just run docker build again - it will use cached layers
   docker build -t gnu-tools-for-stm32 .
   ```

2. **Build intermediate stages explicitly to verify cache:**
   ```bash
   # Build just the bootstrap stage
   docker build --target bootstrap -t gnu-tools-for-stm32:bootstrap .
   
   # Build up to binutils-gcc-first
   docker build --target binutils-gcc-first -t gnu-tools-for-stm32:stage1 .
   
   # Build up to newlib
   docker build --target newlib -t gnu-tools-for-stm32:newlib .
   
   # Build up to gcc-final-gdb
   docker build --target gcc-final-gdb -t gnu-tools-for-stm32:gcc-final-gdb .
   
   # Build up to runtime-libs
   docker build --target runtime-libs -t gnu-tools-for-stm32:runtime-libs .
   ```

3. **Check cached images:**
   ```bash
   docker images | grep gnu-tools-for-stm32
   ```

### Using BuildKit for Advanced Caching

**GitHub Actions:** BuildKit is automatically enabled in the workflow via `docker/setup-buildx-action`.

**Local Development:** Docker BuildKit provides more advanced caching options:

```bash
# Enable BuildKit (if not already enabled)
export DOCKER_BUILDKIT=1

# Build with inline cache
docker build --build-arg BUILDKIT_INLINE_CACHE=1 -t gnu-tools-for-stm32 .

# Use GitHub Actions cache locally (requires GitHub CLI auth)
docker buildx build \
  --cache-from type=gha \
  --cache-to type=gha,mode=max \
  -t gnu-tools-for-stm32 .
```

For local development with registry caching:

```bash
# Export cache to a registry (for CI/CD)
docker build --cache-to type=registry,ref=myregistry.com/gnu-tools-for-stm32:cache .

# Import cache from a registry
docker build --cache-from type=registry,ref=myregistry.com/gnu-tools-for-stm32:cache .
```

### Cache Invalidation Scenarios

The Docker cache will be invalidated (rebuilt) when:

1. **Bootstrap stage:**
   - Build scripts change (`build-common.sh`, `build-toolchain-config.sh`, `build-prerequisites.sh`)
   - Bootstrap library sources change (gmp, mpfr, mpc, isl, expat, zlib)
   - libiconv source changes (copied but not built in Docker native builds)
   - GCC version changes (`src/gcc/gcc/BASE-VER`)
   - Ubuntu base image updates

2. **Binutils-gcc-first stage:**
   - Build script changes (`build-binutils-gcc-first.sh`)
   - Binutils source changes (`src/binutils/*`)
   - GCC source changes (`src/gcc/*`)
   - Any changes that invalidate bootstrap stage

3. **Newlib stage:**
   - Build script changes (`build-newlib.sh`)
   - Newlib source changes (`src/newlib/*`)
   - Any changes that invalidate earlier stages

4. **GCC-Final-GDB stage:**
   - Build script changes (`build-gcc-final-gdb.sh`)
   - GDB source changes (`src/gdb/*`)
   - Any changes that invalidate earlier stages

5. **Runtime-Libs stage:**
   - Build script changes (`build-runtime-libs-finalize.sh`)
   - Any changes that invalidate earlier stages
   - Note: Changes to documentation, test projects, or other auxiliary files do NOT invalidate this stage

## Testing Cache Effectiveness

To test if cache is working:

1. **Build twice and compare times:**
   ```bash
   time docker build --target bootstrap -t test1 .
   # Make no changes
   time docker build --target bootstrap -t test2 .
   # Second build should be much faster (uses cache)
   ```

2. **Modify a file and see cache impact:**
   ```bash
   # Build once
   docker build --target bootstrap -t test1 .
   
   # Modify a main toolchain source (shouldn't affect bootstrap)
   touch src/gcc/gcc/tree.c
   
   # Rebuild - should still use cache for bootstrap
   docker build --target bootstrap -t test2 .
   # Bootstrap should show "CACHED" in build output
   ```

3. **Check build output for cache hits:**
   ```
   #7 [bootstrap  2/13] RUN ln -fs /usr/share/zoneinfo/Europe/London ...
   #7 CACHED
   ```

## Size Metrics

Current layer sizes (as of optimization):

- **Bootstrap stage:** ~102M (after cleanup)
  - Installed libraries: ~9.1M
  - Source files: ~93M

- **Binutils-gcc-first stage:** ~2.5G (after cleanup)
  - Installed binaries: ~345M
  - Source files (binutils + gcc): ~1.8G
  - Build artifacts and host libs: ~370M

- **Newlib stage:** ~2.6G (after cleanup)
  - Installed libraries: target-specific libraries in `install-native/arm-none-eabi/lib/`
  - Source files (newlib): ~72M
  - Build artifacts: cleaned after build

- **GCC-Final-GDB stage:** ~3.0G (after cleanup)
  - Installed toolchain: complete C/C++ compiler and debugger
  - Source files (gdb): varies
  - Build artifacts: cleaned after build

- **Runtime-Libs stage:** minimal (after cleanup)
  - Final toolchain in `install-native/`
  - All source directories removed: `src/` (saves ~2G)
  - All build directories removed: `build-native/` (already removed by script)
  - Final image size: TBD (to be measured during build)

## Future Optimization Opportunities

1. **Exclude test and doc directories:**
   - Use `.dockerignore` or selective COPY to exclude:
     - `src/*/tests/`
     - `src/*/doc/`
     - `src/*/examples/`

2. **Multi-architecture builds:**
   - Use BuildKit's cache mounts for cross-compilation

## Best Practices

1. **Build incrementally:** Test each stage in isolation
2. **Monitor cache hits:** Look for "CACHED" in build output
3. **Clean up within RUN commands:** Combine commands to reduce layer sizes
4. **Use .dockerignore:** Exclude unnecessary files from build context
5. **Tag intermediate stages:** Makes it easier to debug and test

## References

- [Docker Multi-stage Builds](https://docs.docker.com/develop/develop-images/multistage-build/)
- [Docker BuildKit](https://docs.docker.com/build/buildkit/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
