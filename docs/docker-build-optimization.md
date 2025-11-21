# Docker Build Optimization

## Overview

This document describes the incremental build optimization strategy implemented in the Dockerfile to improve build times, reduce layer sizes, and maximize Docker layer caching.

## Build Stages

The Dockerfile uses multi-stage builds with the following stages:

1. **bootstrap** - Install build tools and build prerequisite libraries (GMP, MPFR, MPC, ISL, Expat, zlib, libiconv)
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

**Files excluded from bootstrap:**
- Main toolchain sources: `src/gcc/*`, `src/gdb/*`, `src/binutils/*`, `src/newlib/*` (except BASE-VER)
- Documentation: `docs/`, `README.md`, `BUILD.md`, etc.
- Test project: `test_project/`
- Other build scripts used in later stages

### Later Stages (To Be Optimized)

Currently, the `binutils-gcc-first` stage uses a blanket copy:

```dockerfile
# TODO: Future optimization - copy incrementally per stage
COPY . /root/build/gnu-tools-for-stm32/
```

This is intentional to keep the initial optimization focused and manageable. Future PRs can incrementally optimize each stage.

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

### Future Housekeeping Opportunities
- Clean up source directories after they're no longer needed
- Remove intermediate build artifacts in `gcc-final-gdb` stage
- Remove documentation and tests from source trees before copying

## Layer Size Reporting

Each optimized stage includes size reporting for visibility:

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

## Maximizing Cache Reusability

### Building with Cache

Docker automatically caches layers. To build:

```bash
# Build entire toolchain
docker build -t gnu-tools-for-stm32 .

# Build specific stage (useful for testing)
docker build --target bootstrap -t gnu-tools-for-stm32:bootstrap .
docker build --target binutils-gcc-first -t gnu-tools-for-stm32:binutils-gcc-first .
```

### Preserving Cache When Builds Fail

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
   ```

3. **Check cached images:**
   ```bash
   docker images | grep gnu-tools-for-stm32
   ```

### Using BuildKit for Advanced Caching

Docker BuildKit provides more advanced caching options:

```bash
# Enable BuildKit (if not already enabled)
export DOCKER_BUILDKIT=1

# Build with inline cache
docker build --build-arg BUILDKIT_INLINE_CACHE=1 -t gnu-tools-for-stm32 .

# Export cache to a registry (for CI/CD)
docker build --cache-to type=registry,ref=myregistry.com/gnu-tools-for-stm32:cache .

# Import cache from a registry
docker build --cache-from type=registry,ref=myregistry.com/gnu-tools-for-stm32:cache .
```

### Cache Invalidation Scenarios

The Docker cache will be invalidated (rebuilt) when:

1. **Bootstrap stage:**
   - Build scripts change (`build-common.sh`, `build-toolchain-config.sh`, `build-prerequisites.sh`)
   - Bootstrap library sources change (gmp, mpfr, mpc, isl, expat, zlib, libiconv)
   - GCC version changes (`src/gcc/gcc/BASE-VER`)
   - Ubuntu base image updates

2. **Later stages:**
   - Currently: **ANY** file in the repository changes (due to blanket `COPY .`)
   - After optimization: Only relevant sources for each stage

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

- **Full build:** (TODO: measure after complete build)

## Future Optimization Opportunities

1. **Stage 1 (binutils-gcc-first):**
   - Copy only: `src/binutils/`, `src/gcc/`, build scripts
   - Exclude: `src/newlib/`, `src/gdb/`, docs, test_project

2. **Stage 2 (newlib):**
   - Copy only: `src/newlib/`, build script
   - Exclude: `src/gdb/`, docs, test_project

3. **Stage 3 (gcc-final-gdb):**
   - Copy only: `src/gdb/`, build script
   - Exclude: docs, test_project

4. **Exclude test and doc directories:**
   - Use `.dockerignore` or selective COPY to exclude:
     - `src/*/tests/`
     - `src/*/doc/`
     - `src/*/examples/`

5. **Multi-architecture builds:**
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
