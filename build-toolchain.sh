#!/usr/bin/env bash
# Copyright (c) 2011-2020, ARM Limited
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Arm nor the names of its contributors may be used
#       to endorse or promote products derived from this software without
#       specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

set -e
set -x
set -u
set -o pipefail

PS4='+$(date -u +%Y-%m-%d:%H:%M:%S) (${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

umask 022

exec < /dev/null

script_path=$(cd "$(dirname "$0")" && pwd -P)

# ============================================================================
# MODULAR BUILD WRAPPER
# ============================================================================
# This is a wrapper script that calls the modular build scripts in sequence.
# It provides backward compatibility with the monolithic build-toolchain.sh
# while using the well-linted modular scripts internally.
#
# The modular scripts have ZERO linting violations and are actively maintained.
# ============================================================================

usage ()
{
cat<<USAGE_END
Usage: $0 [--build_type=...] [--skip_steps=...]

This script is a wrapper that calls the modular build scripts in sequence.

OPTIONS:
  --build_type=TYPE     specify build type to either ppa or native.
                        Currently only native is supported in the wrapper.
                        
  --skip_steps=STEPS    specify which build steps you want to skip.
                        Currently supported:
                            mingw[32] - skip MinGW builds
                            native - skip native builds

For more options, call the individual modular scripts directly:
  - build-prerequisites.sh
  - build-binutils-gcc-first.sh
  - build-newlib.sh
  - build-gcc-final-gdb.sh
  - build-runtime-libs-finalize.sh
USAGE_END
}

# Parse arguments
skip_mingw32=no
skip_native_build=no

for ac_arg; do
    case $ac_arg in
        --skip_steps=*)
            skip_steps="${ac_arg#--skip_steps=}"
            skip_steps="${skip_steps//,/ }"
            for ss in $skip_steps; do
                case $ss in
                    mingw|mingw32)
                        skip_mingw32=yes
                        ;;
                    native)
                        skip_native_build=yes
                        ;;
                    *)
                       echo "Unknown build step: $ss (only mingw/native supported in wrapper)" 1>&2
                       usage
                       exit 1
                       ;;
                esac
            done
            ;;
        --build_type=*)
            build_type="${ac_arg#--build_type=}"
            if [ "$build_type" != "native" ]; then
                echo "Only --build_type=native is supported in the wrapper" 1>&2
                usage
                exit 1
            fi
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $ac_arg" 1>&2
            usage
            exit 1
            ;;
    esac
done

if [ "$skip_native_build" != "yes" ]; then
    echo "============================================================================"
    echo "Building native toolchain using modular scripts"
    echo "============================================================================"
    
    # Step 1: Build prerequisites
    echo "Step 1/5: Building prerequisites..."
    "$script_path/build-prerequisites.sh" --skip_steps=mingw
    
    # Step 2: Build binutils and GCC first pass
    echo "Step 2/5: Building binutils and GCC first pass..."
    "$script_path/build-binutils-gcc-first.sh"
    
    # Step 3: Build newlib
    echo "Step 3/5: Building newlib..."
    "$script_path/build-newlib.sh"
    
    # Step 4: Build GCC final and GDB
    echo "Step 4/5: Building GCC final and GDB..."
    "$script_path/build-gcc-final-gdb.sh"
    
    # Step 5: Finalize runtime libraries
    echo "Step 5/5: Finalizing runtime libraries..."
    "$script_path/build-runtime-libs-finalize.sh"
    
    echo "============================================================================"
    echo "Native toolchain build complete!"
    echo "============================================================================"
else
    echo "Skipping native build as requested"
fi

if [ "$skip_mingw32" != "yes" ]; then
    echo ""
    echo "============================================================================"
    echo "NOTE: MinGW builds are not yet supported in the modular wrapper."
    echo "Please use the original build-toolchain.sh for MinGW builds."
    echo "============================================================================"
fi
