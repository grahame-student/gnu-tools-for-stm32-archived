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

error () {
    set +u
    echo "$0: error: $*" >&2
    exit 1
}

warning () {
    set +u
    echo "$0: warning: $*" >&2
    set -u
}

copy_dir() {
    set +u
    mkdir -p "$2"

    (cd "$1" && tar cf - .) | (cd "$2" && tar xf -)
    set -u
}

copy_dir_clean() {
    set +u
    mkdir -p "$2"
    (cd "$1" && tar cf - \
        --exclude=CVS --exclude=.svn --exclude=.git --exclude=.pc \
        --exclude="*~" --exclude=".#*" \
        --exclude="*.orig" --exclude="*.rej" \
        .) | (cd "$2" && tar xf -)
    set -u
}

# Create source package excluding source control information
#   parameter 1: base dir of the source tree
#   parameter 2: dirname of the source tree
#   parameter 3: target package name
#   parameter 4-10: additional excluding
# This function will create bz2 package for files under param1/param2,
# excluding unnecessary parts, and create package named param2.
pack_dir_clean() {
    set +u
    tar cjfh $3 \
        --exclude=CVS --exclude=.svn --exclude=.git --exclude=.pc \
        --exclude="*~" --exclude=".#*" \
        --exclude="*.orig" --exclude="*.rej" $4 $5 $6 $7 $8 $9 ${10} \
        -C $1 $2
    set -u
}

# Clean all global shell variables except for those needed by build scripts
clean_env () {
    set +u
    local var_list
    var_list=$(export | grep "^declare -x" | sed -e "s/declare -x //" | cut -d"=" -f1 | grep -E '[[:upper:]]+\b')

    for var in $var_list ; do
        case "$var" in
        WORKSPACE | SRC_VERSION)
            ;;
        DEJAGNU | DISPLAY | HOME | LD_LIBRARY_PATH | LOGNAME | PATH | PWD | SHELL | SHLVL | TERM | USER | USERNAME | XAUTHORITY)
            ;;
        com.apple.*)
            ;;
        LSB_* | LSF_* | LS_* | EGO_* | HOSTTYPE | TMPDIR)
            ;;
        LP_ENABLE_WRAP_*)
            ;;
        *)
            unset "$var"
            ;;
        esac
    done

    export LANG=C
    set -u
}

# Start a new stack level to save variables
# Must call this before saving any variables
saveenv () {
    set +u
    # Increment stack level
    stack_level=$((stack_level + 1))
    eval stack_list_$stack_level=
    set -u
}

# Save a variable to current stack level, and set new value to this var.
# If a variable has been saved, won't save it. Just set new value
# Must be called when stack_level > 0
# $1: variable name
# $2: new variable value
saveenvvar () {
    set +u
    if [ $stack_level -le 0 ]; then
        error Must call saveenv before calling saveenvvar
    fi
    local varname="$1"
    local newval="$2"
    eval local oldval=\"\${$varname}\"
    eval local saved=\"\${level_saved_${stack_level}_${varname}}\"
    if [ "x$saved" = "x" ]; then
        # The variable wasn't saved in the level before. Save it
        eval local temp=\"\${stack_list_$stack_level}\"
        eval stack_list_$stack_level=\"$varname $temp\"
        eval save_level_${stack_level}_$varname=\"$oldval\"
        eval level_saved_${stack_level}_$varname="yes"
        eval level_preset_${stack_level}_${varname}=\"\${$varname+set}\"
        #echo Save $varname: \"$oldval\"
    fi
    eval export $varname=\"$newval\"
    #echo $varname set to \"$newval\"
    set -u
}

# Restore all variables that have been saved in current stack level
restoreenv () {
    set +u
    if [ $stack_level -le 0 ]; then
        error "Trying to restore from an empty stack"
    fi

    eval local list=\"\${stack_list_$stack_level}\"
    local varname
    for varname in $list; do
        eval local varname_preset=\"\${level_preset_${stack_level}_${varname}}\"
        if [ "x$varname_preset" = "xset" ] ; then
            eval $varname=\"\${save_level_${stack_level}_$varname}\"
        else
            unset $varname
        fi
        eval level_saved_${stack_level}_$varname=
        # eval echo $varname restore to \\\"\"\${$varname}\"\\\"
    done
    # Decrement stack level
    stack_level=$((stack_level - 1))
    set -u
}

prependenvvar() {
    set +u
    eval local oldval=\"\$$1\"
    saveenvvar "$1" "$2$oldval"
    set -u
}

prepend_path() {
    set +u
    eval local old_path="\"\$$1\""
    if [ x"$old_path" == "x" ]; then
        prependenvvar "$1" "$2"
    else
        prependenvvar "$1" "$2:"
    fi
    set -u
}

# Breaks a hard link (created with ln) between one or more files
break_hardlink() {
    if [ $# -ne 1 ] ; then
        warning "break_hardlink: Missing argument"
        return 0
    fi
    local filename="$1"

    if [ ! -f "$filename" ] ; then
        error "break_hardlink: Argument is not a file ($filename)"
        return 1
    fi

    local dir=$(dirname -- "$filename")
    local tmp=$(TMPDIR=$dir mktemp)
    cp -p -- "$filename" "$tmp"
    mv -f -- "$tmp" "$filename"
}

# Strip binary files as in "strip binary" form, for both native(linux/mac) and mingw.
strip_binary() {
    set +e
    if [ $# -ne 2 ] ; then
        warning "strip_binary: Missing arguments"
        return 0
    fi
    local strip="$1"
    local bin="$2"

    file $bin | grep -q -e "\bELF\b" -e "\bPE\b" -e "\bPE32\b" -e "\bMach-O\b"
    if [ $? -eq 0 ]; then
        $strip $bin 2>/dev/null || true
    fi

    set -e
}

# Copy target libraries from each multilib directories.
# Usage copy_multi_libs dst_prefix=... src_prefix=... target_gcc=...
copy_multi_libs() {
    local -a multilibs
    local multilib
    local multi_dir
    local src_prefix
    local dst_prefix
    local src_dir
    local dst_dir
    local target_gcc

    for arg in "$@" ; do
        eval "${arg// /\\ }"
    done

    multilibs=( $("${target_gcc}" -print-multi-lib 2>/dev/null) )
    for multilib in "${multilibs[@]}" ; do
        multi_dir="${multilib%%;*}"
        src_dir=${src_prefix}/${multi_dir}
        dst_dir=${dst_prefix}/${multi_dir}
        cp -f "${src_dir}/libstdc++.a" "${dst_dir}/libstdc++_nano.a"
        cp -f "${src_dir}/libsupc++.a" "${dst_dir}/libsupc++_nano.a"
        cp -f "${src_dir}/libc.a" "${dst_dir}/libc_nano.a"
        cp -f "${src_dir}/libg.a" "${dst_dir}/libg_nano.a"
        cp -f "${src_dir}/librdimon.a" "${dst_dir}/librdimon_nano.a"
        cp -f "${src_dir}/librdimon-v2m.a" "${dst_dir}/librdimon-v2m_nano.a"
        cp -f "${src_dir}/nano.specs" "${dst_dir}/"
        cp -f "${src_dir}/rdimon.specs" "${dst_dir}/"
        cp -f "${src_dir}/nosys.specs" "${dst_dir}/"
        cp -f "${src_dir}/"*crt0.o "${dst_dir}/"
    done
}

# Regenerate autotools files (configure, Makefile.in, etc.) for a library
# This is needed because these generated files are no longer stored in git
# Usage: regenerate_autotools <library_src_dir>
regenerate_autotools() {
    set +u
    if [ $# -ne 1 ] ; then
        warning "regenerate_autotools: Missing argument"
        return 1
    fi
    local lib_src_dir="$1"
    
    if [ ! -d "$lib_src_dir" ] ; then
        error "regenerate_autotools: Directory does not exist ($lib_src_dir)"
        return 1
    fi
    
    # Check if configure and essential autotools files already exist (already regenerated)
    # We check for configure and at least one Makefile.in
    # Note: aclocal.m4 may not exist for all projects (e.g., binutils uses autogen)
    if [ -f "$lib_src_dir/configure" ] && \
       find "$lib_src_dir" -maxdepth 1 -name "Makefile.in" -print -quit | grep -q .; then
        echo "Autotools files already exist in $lib_src_dir, skipping regeneration"
        return 0
    fi
    
    echo "Regenerating autotools files in $lib_src_dir"
    pushd "$lib_src_dir" > /dev/null
    
    # Run autoreconf to regenerate all autotools files
    # -i: install missing auxiliary files
    # -f: force regeneration even if files exist
    
    # Determine which autoreconf to use
    # Bootstrap libraries (gmp, mpfr, mpc, isl, expat, libiconv) use modern autoconf 2.71 (Ubuntu 24.04 default)
    # binutils/gcc/gdb/newlib require autoconf 2.69 for reproducible builds
    # We use 'autoconf2.69' explicitly only for binutils/gcc/gdb/newlib
    local autoreconf_cmd="autoreconf"
    local lib_name=$(basename "$lib_src_dir")
    if [ "$lib_name" = "binutils" ] || [ "$lib_name" = "gcc" ] || [ "$lib_name" = "gdb" ] || [ "$lib_name" = "newlib" ]; then
        # Check if we need to use autoconf2.69 explicitly
        local autoconf_version=$(autoconf --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+' || echo "")
        if [ "$autoconf_version" != "2.69" ] && which autoconf2.69 > /dev/null 2>&1; then
            # autoconf default is not 2.69, so use autoconf2.69 explicitly for these components
            # Set AUTOCONF and related variables to use version 2.69
            # Note: autoconf2.69 package provides autoconf2.69, autoheader2.69, etc.
            # but not autom4te2.69, so we don't set AUTOM4TE
            export AUTOCONF=autoconf2.69
            export AUTOHEADER=autoheader2.69
            export AUTORECONF=autoreconf2.69
            export AUTOUPDATE=autoupdate2.69
            autoreconf_cmd="autoreconf2.69"
        fi
    fi
    
    # Special handling for binutils/gcc/gdb/newlib: they use autogen to generate Makefile.in from Makefile.def
    if [ "$lib_name" = "binutils" ] || [ "$lib_name" = "gcc" ] || [ "$lib_name" = "gdb" ] || [ "$lib_name" = "newlib" ]; then
        # First generate Makefile.in using autogen if Makefile.def exists
        if [ -f "Makefile.def" ] && which autogen > /dev/null 2>&1; then
            echo "Generating Makefile.in from Makefile.def using autogen"
            autogen Makefile.def || {
                error "Failed to generate Makefile.in with autogen in $lib_src_dir"
                popd > /dev/null
                return 1
            }
        fi
        
        # Run libtoolize and copy libtool m4 files for binutils
        # Binutils configure.ac uses m4_include([libtool.m4]) which requires these files
        # in the top-level directory before aclocal runs
        if [ "$lib_name" = "binutils" ]; then
            echo "Running libtoolize to generate libtool files"
            libtoolize -c -f || {
                error "Failed to run libtoolize in $lib_src_dir"
                popd > /dev/null
                return 1
            }
            # Copy libtool m4 files to top-level directory where configure.ac expects them
            local aclocal_dir=$(aclocal --print-ac-dir 2>/dev/null)
            if [ -n "$aclocal_dir" ] && [ -d "$aclocal_dir" ]; then
                echo "Copying libtool m4 files to top-level directory"
                for m4file in libtool.m4 ltoptions.m4 ltsugar.m4 ltversion.m4 lt~obsolete.m4; do
                    if [ -f "$aclocal_dir/$m4file" ]; then
                        cp "$aclocal_dir/$m4file" .
                    fi
                done
            fi
        fi
        
        # Copy auxiliary build files (install-sh, missing, etc.) since these projects
        # don't use automake at the top level and autoreconf won't install them
        local automake_dir=$(automake --print-libdir 2>/dev/null)
        if [ -n "$automake_dir" ] && [ -d "$automake_dir" ]; then
            echo "Installing auxiliary build files from automake"
            for file in install-sh missing config.guess config.sub depcomp compile test-driver ylwrap; do
                if [ -f "$automake_dir/$file" ] && [ ! -f "$file" ]; then
                    cp "$automake_dir/$file" "$file"
                    chmod +x "$file"
                fi
            done
        fi
    fi
    
    # Special handling for libiconv: it needs m4 and srcm4 directories in ACLOCAL_PATH
    if [ "$lib_name" = "libiconv" ]; then
        # Use env to set ACLOCAL_PATH only for this autoreconf call
        env ACLOCAL_PATH="m4:srcm4:${ACLOCAL_PATH:-}" $autoreconf_cmd -i -f || {
            error "Failed to regenerate autotools files in $lib_src_dir"
            popd > /dev/null
            return 1
        }
    else
        $autoreconf_cmd -i -f || {
            error "Failed to regenerate autotools files in $lib_src_dir"
            popd > /dev/null
            return 1
        }
    fi
    
    # Special handling for binutils/gcc/gdb/newlib: regenerate subdirectories that have configure.ac
    if [ "$lib_name" = "binutils" ] || [ "$lib_name" = "gcc" ] || [ "$lib_name" = "gdb" ] || [ "$lib_name" = "newlib" ]; then
        echo "Regenerating autotools files for subdirectories with configure.ac"
        # Find all subdirectories with configure.ac/configure.in (excluding gnulib which has special handling)
        # We need to process them in order from deepest to shallowest to handle nested subdirectories
        local subdirs=$(find . -name "configure.ac" -o -name "configure.in" | grep -v "^\./configure\." | grep -v gnulib | sed 's|/configure\.[ai][cn]$||' | sort -u)
        for subdir in $subdirs; do
            if [ -d "$subdir" ] && [ "$subdir" != "." ]; then
                echo "  Regenerating $subdir"
                pushd "$subdir" > /dev/null
                $autoreconf_cmd -i -f 2>/dev/null || {
                    # Some subdirectories might fail, that's okay - continue
                    true
                }
                popd > /dev/null
            fi
        done
    fi
    
    # Special handling for libcharset subdirectory in libiconv
    if [ "$lib_name" = "libiconv" ] && [ -d "libcharset" ]; then
        echo "Regenerating autotools files for libcharset subdirectory"
        pushd libcharset > /dev/null
        # Use env to set ACLOCAL_PATH only for this autoreconf call
        env ACLOCAL_PATH="m4:${ACLOCAL_PATH:-}" autoreconf -i -f || {
            error "Failed to regenerate autotools files in libcharset"
            popd > /dev/null
            popd > /dev/null
            return 1
        }
        popd > /dev/null
    fi
    
    popd > /dev/null
    echo "Successfully regenerated autotools files in $lib_src_dir"
    set -u
    return 0
}

# Run autoconf/automake linting with all warnings enabled
# Usage: lint_autotools <library_src_dir> [--strict]
# By default, linting reports issues but doesn't fail (informational mode)
# With --strict, linting failures will cause the function to return non-zero
lint_autotools() {
    set +u
    local strict_mode=0
    local lib_src_dir=""
    
    # Parse arguments
    for arg in "$@"; do
        if [ "$arg" = "--strict" ]; then
            strict_mode=1
        elif [ -z "$lib_src_dir" ]; then
            lib_src_dir="$arg"
        fi
    done
    
    if [ -z "$lib_src_dir" ] ; then
        warning "lint_autotools: Missing argument"
        return 1
    fi
    
    if [ ! -d "$lib_src_dir" ] ; then
        error "lint_autotools: Directory does not exist ($lib_src_dir)"
    fi
    
    local lib_name=$(basename "$lib_src_dir")
    echo "Running autotools linting for $lib_name in $lib_src_dir"
    if [ $strict_mode -eq 0 ]; then
        echo "  (informational mode - will not fail build)"
    fi
    
    pushd "$lib_src_dir" > /dev/null
    
    local lint_issues=0
    local autoconf_cmd="autoconf"
    local automake_cmd="automake"
    
    # Use autoconf2.69 for binutils/gcc/gdb/newlib if needed
    if [ "$lib_name" = "binutils" ] || [ "$lib_name" = "gcc" ] || [ "$lib_name" = "gdb" ] || [ "$lib_name" = "newlib" ]; then
        local autoconf_version=$(autoconf --version 2>/dev/null | head -n1 | sed -n 's/[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' || echo "")
        if [ "$autoconf_version" != "2.69" ] && which autoconf2.69 > /dev/null 2>&1; then
            autoconf_cmd="autoconf2.69"
            automake_cmd="automake"  # Use default automake
        fi
    fi
    
    # Run autoconf with all warnings enabled if configure.ac or configure.in exists
    if [ -f "configure.ac" ] || [ -f "configure.in" ]; then
        echo "  Running $autoconf_cmd --warnings=all..."
        $autoconf_cmd --warnings=all -o /dev/null 2>&1 | tee /tmp/autoconf-lint.log || true
        
        # Check if there were any warnings or errors in the output
        local issue_count=0
        if [ -f /tmp/autoconf-lint.log ] && [ -s /tmp/autoconf-lint.log ]; then
            if grep -qE "(warning|error|deprecated)" /tmp/autoconf-lint.log; then
                echo "  ⚠️  autoconf linting found issues in $lib_src_dir:"
                grep -E "(warning|error|deprecated)" /tmp/autoconf-lint.log | head -10
                issue_count=$(grep -cE "(warning|error|deprecated)" /tmp/autoconf-lint.log || echo 0)
                echo "  Total issues: $issue_count (see full output above)"
                lint_issues=$((lint_issues + 1))
            fi
        fi
        rm -f /tmp/autoconf-lint.log
    fi
    
    # Run automake with all warnings enabled if Makefile.am exists
    # Note: We skip actual file generation to avoid side effects, just check for warnings
    if [ -f "Makefile.am" ]; then
        echo "  Running $automake_cmd --warnings=all..."
        # Check if aclocal.m4 exists, if not we need to run aclocal first
        local need_cleanup=0
        local aclocal_existed=1
        if [ ! -f "aclocal.m4" ]; then
            echo "    Running aclocal to generate aclocal.m4 for linting..."
            aclocal 2>&1 | tee /tmp/aclocal-lint.log || true
            if [ -f "aclocal.m4" ]; then
                need_cleanup=1
                aclocal_existed=0
            else
                warning "aclocal failed, skipping automake linting in $lib_src_dir"
            fi
        fi
        
        # Run automake --warnings=all to check Makefile.am (only if aclocal.m4 exists)
        if [ -f "aclocal.m4" ]; then
            $automake_cmd --warnings=all --add-missing --copy 2>&1 | tee /tmp/automake-lint.log || true
            
            # Check if there were any warnings in the output
            local issue_count=0
            if [ -f /tmp/automake-lint.log ] && [ -s /tmp/automake-lint.log ]; then
                if grep -qE "(warning|error|deprecated)" /tmp/automake-lint.log; then
                    echo "  ⚠️  automake linting found issues in $lib_src_dir:"
                    grep -E "(warning|error|deprecated)" /tmp/automake-lint.log | head -10
                    issue_count=$(grep -cE "(warning|error|deprecated)" /tmp/automake-lint.log || echo 0)
                    echo "  Total issues: $issue_count (see full output above)"
                    lint_issues=$((lint_issues + 1))
                fi
            fi
        fi
        
        # Cleanup temporary files if we generated them
        if [ $need_cleanup -eq 1 ]; then
            rm -f aclocal.m4
        fi
        # Clean up any Makefile.in files that automake may have created during linting
        if [ $aclocal_existed -eq 0 ]; then
            # Only clean up if we created aclocal.m4 ourselves
            rm -f Makefile.in
        fi
        rm -f /tmp/automake-lint.log /tmp/aclocal-lint.log
    fi
    
    # Run shellcheck on shell scripts if available
    if which shellcheck > /dev/null 2>&1; then
        echo "  Running shellcheck on shell scripts..."
        local shell_scripts
        shell_scripts=$(find . -maxdepth 2 -type f \( -name "*.sh" -o -name "configure" \) 2>/dev/null || true)
        if [ -n "$shell_scripts" ]; then
            while IFS= read -r script; do
                # Skip configure scripts as they're auto-generated
                # Note: Using [[ ]] for regex matching (=~) which requires bash
                # This script is explicitly executed with bash (#!/bin/bash not present but sourced by bash scripts)
                if [[ "$script" =~ configure$ ]] && [[ -f "${script}.ac" || -f "${script}.in" ]]; then
                    continue
                fi
                if [ -f "$script" ] && file "$script" 2>/dev/null | grep -q "shell script"; then
                    echo "    Checking $script..."
                    if shellcheck -e SC1091,SC2148 "$script" 2>&1 | tee /tmp/shellcheck-lint.log | grep -qE "(warning|error)"; then
                        echo "  ⚠️  shellcheck found issues in $script (see above)"
                        lint_issues=$((lint_issues + 1))
                    fi
                fi
            done <<< "$shell_scripts"
        fi
        rm -f /tmp/shellcheck-lint.log
    fi
    
    popd > /dev/null
    
    # Report results
    if [ $lint_issues -gt 0 ]; then
        echo "⚠️  Linting found issues in $lib_src_dir ($lint_issues tool(s) reported problems)"
        if [ $strict_mode -eq 1 ]; then
            warning "Linting found issues in $lib_src_dir (strict mode enabled)"
            set -u
            return 1
        else
            echo "  (informational only - not failing build)"
        fi
    else
        echo "✓ Linting passed for $lib_src_dir"
    fi
    
    set -u
    return 0
}

# Check for drift between source files and autogenerated files
# This runs autoreconf and checks if git detects any changes
# Usage: check_autotools_drift <library_src_dir>
check_autotools_drift() {
    set +u
    if [ $# -ne 1 ] ; then
        warning "check_autotools_drift: Missing argument"
        return 1
    fi
    local lib_src_dir="$1"
    
    if [ ! -d "$lib_src_dir" ] ; then
        error "check_autotools_drift: Directory does not exist ($lib_src_dir)"
    fi
    
    local lib_name=$(basename "$lib_src_dir")
    echo "Checking autotools drift for $lib_name in $lib_src_dir"
    
    # Only check drift if configure.ac or configure.in exists
    if [ ! -f "$lib_src_dir/configure.ac" ] && [ ! -f "$lib_src_dir/configure.in" ]; then
        echo "No configure.ac or configure.in found, skipping drift check"
        set -u
        return 0
    fi
    
    # Save current state
    pushd "$lib_src_dir" > /dev/null
    
    # Create a temporary directory to store original files
    local temp_backup=$(mktemp -d)
    
    # Backup autogenerated files that should be tracked
    if [ -f "configure" ]; then
        cp configure "$temp_backup/" 2>/dev/null || true
    fi
    if [ -f "Makefile.in" ]; then
        cp Makefile.in "$temp_backup/" 2>/dev/null || true
    fi
    if [ -f "aclocal.m4" ]; then
        cp aclocal.m4 "$temp_backup/" 2>/dev/null || true
    fi
    
    # Run autoreconf to regenerate files
    echo "  Running autoreconf -fi to check for drift..."
    local autoreconf_cmd="autoreconf"
    if [ "$lib_name" = "binutils" ] || [ "$lib_name" = "gcc" ] || [ "$lib_name" = "gdb" ] || [ "$lib_name" = "newlib" ]; then
        local autoconf_version=$(autoconf --version 2>/dev/null | head -n1 | sed -n 's/[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' || echo "")
        if [ "$autoconf_version" != "2.69" ] && which autoconf2.69 > /dev/null 2>&1; then
            export AUTOCONF=autoconf2.69
            export AUTOHEADER=autoheader2.69
            export AUTOM4TE=autom4te2.69
            export AUTORECONF=autoreconf2.69
            export AUTOUPDATE=autoupdate2.69
            autoreconf_cmd="autoreconf2.69"
        fi
    fi
    
    # Run autoreconf
    $autoreconf_cmd -fi > /dev/null 2>&1 || {
        warning "autoreconf failed during drift check in $lib_src_dir"
        rm -rf "$temp_backup"
        popd > /dev/null
        set -u
        return 1
    }
    
    # Check if any tracked files changed
    local drift_detected=0
    if [ -f "$temp_backup/configure" ] && [ -f "configure" ]; then
        if ! diff -q "$temp_backup/configure" configure > /dev/null 2>&1; then
            warning "Drift detected: configure is out of sync in $lib_src_dir"
            drift_detected=1
        fi
    fi
    
    if [ -f "$temp_backup/Makefile.in" ] && [ -f "Makefile.in" ]; then
        if ! diff -q "$temp_backup/Makefile.in" Makefile.in > /dev/null 2>&1; then
            warning "Drift detected: Makefile.in is out of sync in $lib_src_dir"
            drift_detected=1
        fi
    fi
    
    # Restore original files to avoid modifying the working tree
    if [ -f "$temp_backup/configure" ]; then
        cp "$temp_backup/configure" configure
    fi
    if [ -f "$temp_backup/Makefile.in" ]; then
        cp "$temp_backup/Makefile.in" Makefile.in
    fi
    if [ -f "$temp_backup/aclocal.m4" ]; then
        cp "$temp_backup/aclocal.m4" aclocal.m4
    fi
    
    # Cleanup
    rm -rf "$temp_backup"
    popd > /dev/null
    
    if [ $drift_detected -eq 1 ]; then
        error "Autotools drift detected in $lib_src_dir - regenerate files with autoreconf -fi"
    fi
    
    echo "No drift detected in $lib_src_dir"
    set -u
    return 0
}

# Clean up unnecessary global shell variables
clean_env

ROOT=$(pwd)
SRCDIR=$ROOT/src

BUILDDIR_NATIVE=$ROOT/build-native
BUILDDIR_MINGW=$ROOT/build-mingw
INSTALLDIR_NATIVE=$ROOT/install-native
INSTALLDIR_NATIVE_DOC=$ROOT/install-native/share/doc/gcc-arm-none-eabi
INSTALLDIR_MINGW=$ROOT/install-mingw
INSTALLDIR_MINGW_DOC=$ROOT/install-mingw/share/doc/gcc-arm-none-eabi

PACKAGEDIR=$ROOT/pkg

GMP_VER=6.2.1
MPFR_VER=3.1.6
MPC_VER=1.0.3
ISL_VER=0.18
EXPAT_VER=2.2.6
LIBICONV_VER=1.15
ZLIB_VER=1.2.12
PYTHON_WIN_VER=2.7.13

BINUTILS=binutils
GCC=gcc
NEWLIB=newlib
NEWLIB_NANO=newlib
GDB=gdb
GMP=gmp
MPFR=mpfr
MPC=mpc
ISL=isl
EXPAT=expat
LIBICONV=libiconv
ZLIB=zlib-$ZLIB_VER
PYTHON_WIN=python-$PYTHON_WIN_VER.amd64

GMP_PACK=$GMP.tar.bz2
MPFR_PACK=$MPFR.tar.bz2
MPC_PACK=$MPC.tar.gz
ISL_PACK=$ISL.tar.xz
EXPAT_PACK=$EXPAT.tar.bz2
LIBICONV_PACK=$LIBICONV.tar.gz
ZLIB_PACK=$ZLIB.tar.gz
PYTHON_WIN_PACK=$PYTHON_WIN.msi

GMP_URL=https://gmplib.org/download/gmp/$GMP_PACK
MPFR_URL=http://www.mpfr.org/$MPFR/$MPFR_PACK
MPC_URL=ftp://ftp.gnu.org/gnu/mpc/$MPC_PACK
ISL_URL=http://isl.gforge.inria.fr/$ISL_PACK
EXPAT_URL=https://downloads.sourceforge.net/project/expat/expat/$EXPAT_VER/$EXPAT_PACK
LIBICONV_URL=https://ftp.gnu.org/pub/gnu/libiconv/$LIBICONV_PACK
ZLIB_URL=http://www.zlib.net/fossils/$ZLIB_PACK
PYTHON_WIN_URL=https://www.python.org/ftp/python/$PYTHON_WIN_VER/$PYTHON_WIN_PACK

TAR=tar
# Set variables according to real environment to make this script can run
# on Ubuntu and Mac OS X.
uname_string=$(uname | sed 'y/LINUXDARWIN/linuxdarwin/')
host_arch=$(uname -m | sed 'y/XI/xi/')
if [ "x$uname_string" == "xlinux" ] ; then
    BUILD="$host_arch"-linux-gnu
    HOST_NATIVE="$host_arch"-linux-gnu
    READLINK=readlink
    JOBS=$(grep ^processor /proc/cpuinfo|wc -l)
    GCC_CONFIG_OPTS_LCPP="--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"
    MD5="md5sum -b"
    PACKAGE_NAME_SUFFIX="${host_arch}-linux"
    WGET="wget -q"
elif [ "x$uname_string" == "xdarwin" ] ; then
    BUILD=x86_64-apple-darwin10
    HOST_NATIVE=x86_64-apple-darwin10
    READLINK=greadlink
    # Disable parallel build for mac as we will randomly run into "Permission denied" issue.
    #JOBS=$(sysctl -n hw.ncpu)
    JOBS=1
    GCC_CONFIG_OPTS_LCPP="--with-host-libstdcxx=-static-libgcc -Wl,-lstdc++ -lm"
    MD5="md5 -r"
    PACKAGE_NAME_SUFFIX=mac-$(sw_vers -productVersion)
    #Redefine wget command to curl as MacOS does not have wget by default
    WGET="curl -OLs"
    TAR=gtar
else
    error "Unsupported build system : $uname_string"
fi

SRC_PREREQS="GMP MPFR MPC ISL EXPAT LIBICONV ZLIB"
WIN_PREREQS="PYTHON_WIN"

PREREQS="$SRC_PREREQS"
if [ "x$BUILD" != "xx86_64-apple-darwin10" ]; then
    PREREQS="$SRC_PREREQS $WIN_PREREQS"
fi

SCRIPT=$(basename "$0")

RELEASEDATE=20230728
RELEASEVER=Rel1


# This is a build script, go on
# format of pattern match is:
# build-* or *_build
if [[ "${SCRIPT%%-*}" = "build" || "${SCRIPT#*_*}" = "build" ]]; then

    stack_level=0

    LICENSE_FILE=license.txt
    GCC_VER=$(cat "$SRCDIR/$GCC/gcc/BASE-VER")
    GCC_VER_DISPLAY=$(cut -d'.' -f1,2 "$SRCDIR/$GCC/gcc/BASE-VER")
    STM32_TOOLS_VER=$(git describe --tags 2>/dev/null || echo "$GCC_VER_DISPLAY-$RELEASEVER~$(git rev-parse --verify HEAD)")

    # sed -r doesn't exist in Darwin
    if [[ $(uname -s) == "Darwin" ]]
    then
        SEDOPTION='-E'
    else
        SEDOPTION='-r'
    fi
    HOST_MINGW=x86_64-w64-mingw32
    HOST_MINGW_TOOL=x86_64-w64-mingw32
    TARGET=arm-none-eabi
    ENV_CFLAGS=
    ENV_CPPFLAGS=
    ENV_LDFLAGS=
    BINUTILS_CONFIG_OPTS=
    GCC_CONFIG_OPTS=
    GDB_CONFIG_OPTS=
    NEWLIB_CONFIG_OPTS=


    PKGROOTNAME="GNU Tools for STM32"
    PKGVERSION="$PKGROOTNAME $STM32_TOOLS_VER"
    BUGURL="https://developer.arm.com/open-source/gnu-toolchain/gnu-rm"

    OBJ_SUFFIX_MINGW=$TARGET-$RELEASEDATE-$HOST_MINGW
    OBJ_SUFFIX_NATIVE=$TARGET-$RELEASEDATE-$HOST_NATIVE
    PACKAGE_NAME=gnu-tools-for-stm32-$STM32_TOOLS_VER
    PACKAGE_NAME_NATIVE=$PACKAGE_NAME-$PACKAGE_NAME_SUFFIX
    PACKAGE_NAME_MINGW=$PACKAGE_NAME-win32
    INSTALL_PACKAGE_NAME=$PACKAGE_NAME

fi # not a build script
