#!/usr/bin/env zsh
# ==============================================================================
# ZSH COMPILATION MODULE
# Automatically compiles ZSH scripts to bytecode (.zwc) for faster loading.
# Supports incremental compilation, directory archives, and stale file cleanup.
# ==============================================================================

# ----------------------------------------------------------
# MODULE CONFIGURATION
# ----------------------------------------------------------

# Idempotent guard - prevent multiple loads
(( ${+_Z_COMPILATION_LOADED} )) && return 0
typeset -g _Z_COMPILATION_LOADED=1

# Configuration variables with defaults
: ${Z_COMPILATION_ENABLED:=true}           # Enable/disable compilation (default: true)
: ${Z_COMPILATION_CLEANUP_ON_START:=true}   # Run stale cleanup on shell start (default: true)

_log DEBUG "ZSH Compilation Module loading"

# Exit early if module is disabled
if [[ "$Z_COMPILATION_ENABLED" != "true" ]]; then
    _log INFO "ZSH Compilation Module disabled, skipping..."
    return 0
fi

# ----------------------------------------------------------
# HELPER FUNCTIONS
# Core compilation and cleanup utilities
# ----------------------------------------------------------

# ------------------------------------------------------------------------------
# _zcompile_if_needed
# Compiles a single ZSH file if source is newer than its .zwc bytecode.
#
# @param  $1  (string)  : Path to the source file to compile.
# @return     (int)     : 0 on success or skip, 1 on failure.
#
# Notes:
# - Skips if source doesn't exist.
# - Skips if .zwc exists and is newer than source.
# - Creates .zwc in same directory as source (ZSH requirement).
# ------------------------------------------------------------------------------
_zcompile_if_needed() {
    local src="$1"
    local compiled="${src}.zwc"

    # Skip if source doesn't exist
    [[ ! -f "$src" ]] && return 0

    # Skip if compiled file exists and is newer than source
    [[ -f "$compiled" && "$compiled" -nt "$src" ]] && return 0

    # Attempt compilation with error handling
    if zcompile "$src" 2>/dev/null; then
        _log DEBUG "Compiled: ${src#$HOME/}"
        return 0
    else
        _log ERROR "Failed to compile: ${src#$HOME/}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# _compile_function_dir
# Compiles all functions in a directory into a single .zwc archive.
#
# @param  $1  (string)  : Path to the function directory.
# @return     (int)     : 0 on success or skip, 1 on failure.
#
# Notes:
# - Creates one .zwc file for the entire directory (more efficient).
# - Only recompiles if any function is newer than the archive.
# - Skips empty or non-writable directories.
#
# Warning: Directory must contain regular files only.
# ------------------------------------------------------------------------------
_compile_function_dir() {
    local dir="$1"
    local zwc="${dir}.zwc"

    # Validate directory exists (zwc is created next to dir, zcompile handles write errors)
    [[ ! -d "$dir" ]] && return 0

    # Check if directory has any regular files (pure zsh, no subshell)
    local files=("$dir"/*(.N))
    (( ${#files} == 0 )) && return 0

    # Determine if recompilation is needed
    local needs_compile=false
    if [[ ! -f "$zwc" ]]; then
        needs_compile=true
    else
        local func
        for func in "${files[@]}"; do
            if [[ "$func" -nt "$zwc" ]]; then
                needs_compile=true
                break
            fi
        done
    fi

    # Compile if needed
    if [[ "$needs_compile" == "true" ]]; then
        if zcompile "$zwc" "${files[@]}" 2>/dev/null; then
            _log DEBUG "Compiled directory: ${dir#$HOME/}"
            return 0
        else
            _log ERROR "Failed to compile directory: ${dir#$HOME/}"
            return 1
        fi
    fi

    return 0
}

# ------------------------------------------------------------------------------
# z_cleanup_zwc
# Removes stale or all compiled .zwc files.
#
# @param  $1  (string)  : Mode - "stale" (default) or "all".
# @return     (int)     : 0 on success.
#
# Notes:
# - "stale" mode: Removes .zwc files where source no longer exists.
# - "all" mode: Removes ALL .zwc files (nuclear option).
#
# Warning: "all" mode is destructive - removes all compiled bytecode.
# ------------------------------------------------------------------------------
z_cleanup_zwc() {
    local mode="${1:-stale}"
    local zwc_file source_file
    local count=0

    # Glob patterns for .zwc files (no duplicates: **/* includes root)
    local -a zwc_patterns=(
        "${ZSH_CONFIG_HOME}"/**/*.zwc(.N)
        "${ZDOTDIR:-$HOME}"/.*.zwc(.N)
        "${HOME}"/.*.zwc(.N)
    )

    if [[ "$mode" == "all" ]]; then
        _log INFO "Removing all compiled (.zwc) files..."

        for zwc_file in ${zwc_patterns[@]}; do
            [[ -f "$zwc_file" ]] || continue
            rm -f "$zwc_file"
            ((count++))
            _log DEBUG "Removed: ${zwc_file#$HOME/}"
        done

        _log INFO "Removed $count compiled files"
    else
        # Remove only stale .zwc files (where source no longer exists)
        for zwc_file in ${zwc_patterns[@]}; do
            source_file="${zwc_file%.zwc}"
            # Check both file and directory (for function dir .zwc)
            if [[ ! -f "$source_file" && ! -d "$source_file" ]]; then
                rm -f "$zwc_file"
                ((count++))
                _log DEBUG "Removed stale: ${zwc_file#$HOME/}"
            fi
        done

        if (( count > 0 )); then
            _log INFO "Cleaned $count stale compiled files"
        else
            _log DEBUG "No stale compiled files found"
        fi
    fi

    return 0
}

# ----------------------------------------------------------
# COMPILE CORE ZSH FILES
# Main dotfiles: .zshrc, .zshenv, .zprofile, .zlogin, .zlogout, .p10k.zsh
# ----------------------------------------------------------

_log DEBUG "Compiling core ZSH files..."

_zcompile_if_needed "${ZDOTDIR:-$HOME}/.zshrc"
_zcompile_if_needed "${ZDOTDIR:-$HOME}/.zshenv"
_zcompile_if_needed "${ZDOTDIR:-$HOME}/.zprofile"
_zcompile_if_needed "${ZDOTDIR:-$HOME}/.zlogin"
_zcompile_if_needed "${ZDOTDIR:-$HOME}/.zlogout"
_zcompile_if_needed "${HOME}/.p10k.zsh"

# ----------------------------------------------------------
# COMPILE CONFIGURATION MODULES
# All .zsh files in modules/, lib/, and config root
# ----------------------------------------------------------

_log DEBUG "Compiling configuration modules..."

# Compile modules directory
() {
    local file
    for file in "${ZSH_CONFIG_HOME}/modules"/*.zsh(.N); do
        _zcompile_if_needed "$file"
    done
}

# Compile lib directory (utils, etc.)
() {
    local file
    for file in "${ZSH_CONFIG_HOME}/lib"/*.zsh(.N); do
        _zcompile_if_needed "$file"
    done
}

# ----------------------------------------------------------
# COMPILE FUNCTION DIRECTORIES
# Creates single .zwc archive per function directory
# ----------------------------------------------------------

_log DEBUG "Compiling function directories..."

# Compile lib/functions (primary function location)
[[ -d "${ZSH_CONFIG_HOME}/lib/functions" ]] && \
    _compile_function_dir "${ZSH_CONFIG_HOME}/lib/functions"

# Compile other function directories if they exist
[[ -d "${ZSH_CONFIG_HOME}/functions" ]] && \
    _compile_function_dir "${ZSH_CONFIG_HOME}/functions"

# ----------------------------------------------------------
# CLEANUP STALE FILES
# Remove orphaned .zwc files (configurable)
# ----------------------------------------------------------

if [[ "$Z_COMPILATION_CLEANUP_ON_START" == "true" ]]; then
    _log DEBUG "Cleaning up stale .zwc files..."
    z_cleanup_zwc
fi

# ----------------------------------------------------------
# DEBUG REPORT
# List all compiled files when debug mode enabled
# ----------------------------------------------------------

if [[ "$Z_COMPILATION_DEBUG" == "true" ]]; then
    # Wrap in anonymous function to scope local variables
    () {
        typeset -A seen_files
        local -a zwc_files=()
        local zwc_file source_file

        # Collect all .zwc files with deduplication
        for zwc_file in "${ZSH_CONFIG_HOME}"/**/*.zwc(.N) \
                        "${ZDOTDIR:-$HOME}"/.*.zwc(.N) \
                        "${HOME}"/.*.zwc(.N); do
            source_file="${zwc_file%.zwc}"
            if [[ -z "${seen_files[$zwc_file]}" ]] && \
               [[ -f "$source_file" || -d "$source_file" ]]; then
                seen_files[$zwc_file]=1
                zwc_files+=("$zwc_file")
            fi
        done

        # Sort natively (no subshell) and display
        if (( ${#zwc_files} > 0 )); then
            _log INFO ""
            _log INFO "Compiled files list:"
            for zwc_file in ${(o)zwc_files}; do
                _log INFO "  -> ${zwc_file#$HOME/}"
            done
            _log INFO "  -> Total: ${#zwc_files} compiled files"
        else
            _log INFO "No compiled files found"
        fi
        _log INFO ""
    }
fi

# ----------------------------------------------------------
# ALIASES
# User-facing commands for compilation management
# ----------------------------------------------------------

alias compclean='z_cleanup_zwc'          # Remove stale .zwc files
alias compclean-all='z_cleanup_zwc all'  # Remove ALL .zwc files

# ----------------------------------------------------------
_log DEBUG "ZSH Compilation Module loaded successfully"
