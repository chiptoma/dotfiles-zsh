#!/usr/bin/env zsh
# ==============================================================================
# * ZSH UTILS LIBRARY
# ? Common utility functions used by all modules.
# ? All functions use _ prefix (internal helpers).
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_ZSH_UTILS_LOADED} )) && return 0
typeset -g _ZSH_UTILS_LOADED=1

# ----------------------------------------------------------
# * COMMAND CHECKS
# ----------------------------------------------------------

# Check if a command exists
# Usage: _has_cmd <command>
# Returns: 0 if command exists, 1 otherwise
_has_cmd() {
    (( $+commands[$1] ))
}

# Require a command to exist, log error if not found
# Usage: _require_cmd <command>
# Returns: 0 if command exists, 1 with error message otherwise
_require_cmd() {
    if ! _has_cmd "$1"; then
        _log ERROR "Required command not found: $1"
        return 1
    fi
    return 0
}

# ----------------------------------------------------------
# * ENVIRONMENT DETECTION
# ? Non-platform-specific environment checks
# ----------------------------------------------------------

# Check if in an SSH session
_is_ssh_session() {
    [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]]
}

# Check if running inside a Docker container
_is_docker() {
    [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null
}

# Check if running in CI/CD environment
_is_ci() {
    [[ -n "$CI" || -n "$GITHUB_ACTIONS" || -n "$GITLAB_CI" || -n "$JENKINS_URL" || -n "$TRAVIS" ]]
}

# Check if shell is interactive
_is_interactive() {
    [[ -o interactive ]]
}

# Check if shell is a login shell
_is_login_shell() {
    [[ -o login ]]
}

# ----------------------------------------------------------
# * FILE SYSTEM HELPERS
# ----------------------------------------------------------

# Ensure a directory exists, create if not
# Usage: _ensure_dir <directory> [permissions]
# Parameters:
#   directory: Path to directory
#   permissions: Optional chmod permissions (e.g., 700)
# Returns: 0 on success, 1 on failure
_ensure_dir() {
    local dir="$1"
    local perms="${2:-}"

    if [[ ! -d "$dir" ]]; then
        if ! mkdir -p "$dir" 2>/dev/null; then
            _log ERROR "Failed to create directory: $dir"
            return 1
        fi
        _log DEBUG "Created directory: $dir"

        if [[ -n "$perms" ]]; then
            chmod "$perms" "$dir" 2>/dev/null
            _log DEBUG "Set permissions $perms on: $dir"
        fi
    fi
    return 0
}

# Ensure a file exists, create if not
# Usage: _ensure_file <file> [permissions]
# Parameters:
#   file: Path to file
#   permissions: Optional chmod permissions (e.g., 600)
_ensure_file() {
    local file="$1"
    local perms="${2:-}"

    if [[ ! -f "$file" ]]; then
        if ! touch "$file" 2>/dev/null; then
            _log ERROR "Failed to create file: $file"
            return 1
        fi
        _log DEBUG "Created file: $file"

        if [[ -n "$perms" ]]; then
            chmod "$perms" "$file" 2>/dev/null
            _log DEBUG "Set permissions $perms on: $file"
        fi
    fi
    return 0
}

# ----------------------------------------------------------
# * STRING UTILITIES
# ----------------------------------------------------------

# Check if a string is empty
_is_empty() {
    [[ -z "$1" ]]
}

# Check if a string is not empty
_is_not_empty() {
    [[ -n "$1" ]]
}

# ----------------------------------------------------------
# * CACHING HELPERS
# ----------------------------------------------------------

# Cache and source the output of a command
# Usage: _cache_eval <name> <command> [binary]
# Parameters:
#   name: Cache file name (without path)
#   command: Command to run and cache output
#   binary: Binary to check for updates (defaults to name)
# Example: _cache_eval "direnv" "direnv hook zsh" "direnv"
#
# ! SECURITY WARNING - READ BEFORE MODIFYING:
# ! This function uses eval to execute the command string.
# ! Only call with TRUSTED, HARDCODED command strings.
# ! NEVER pass user input or external data as the command parameter.
# ! Current trusted callers: direnv, atuin, helm completion
_cache_eval() {
    local name="$1"
    local cmd="$2"
    local binary="${3:-$1}"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    local cache_file="${cache_dir}/${name}.zsh"

    # Ensure cache directory exists
    _ensure_dir "$cache_dir"

    # Regenerate cache if:
    # 1. Cache file doesn't exist, OR
    # 2. Binary is newer than cache file
    if [[ ! -f "$cache_file" ]] || \
       { _has_cmd "$binary" && [[ "$(command -v "$binary")" -nt "$cache_file" ]]; }; then
        _log DEBUG "Regenerating cache for $name"
        eval "$cmd" > "$cache_file" 2>/dev/null
        chmod 600 "$cache_file" 2>/dev/null
    fi

    # Source the cache file if it exists and is not empty
    if [[ -s "$cache_file" ]]; then
        source "$cache_file"
        _log DEBUG "Sourced cache: $cache_file"
    fi
}

# ----------------------------------------------------------
# * SAFE SOURCING
# ----------------------------------------------------------

# Configuration for file ownership verification (disabled by default)
: ${ZSH_VERIFY_FILE_OWNERSHIP:=false}

# Safely source a file with optional ownership verification
# Usage: _safe_source <file>
# Returns: 0 on success, 1 if file not readable or ownership check fails
_safe_source() {
    local file="$1"
    [[ -r "$file" ]] || return 1

    if [[ "$ZSH_VERIFY_FILE_OWNERSHIP" == "true" ]]; then
        local owner
        # Platform-appropriate stat (detect via $OSTYPE since platform libs load after utils)
        if [[ "$OSTYPE" == darwin* ]] || [[ "$OSTYPE" == freebsd* ]] || [[ "$OSTYPE" == openbsd* ]]; then
            owner=$(stat -f %u "$file" 2>/dev/null)
        else
            owner=$(stat -c %u "$file" 2>/dev/null)
        fi
        if [[ -n "$owner" && "$owner" != "0" && "$owner" != "$UID" ]]; then
            _log WARN "Skipping $file: untrusted ownership (owner: $owner)"
            return 1
        fi
    fi

    source "$file"
}

# ----------------------------------------------------------
# * DEPENDENCY CHECKS
# ----------------------------------------------------------

# Check if Oh-My-Zsh is installed
# Usage: _require_omz
# Returns: 0 if installed, 1 with error message if not
_require_omz() {
    [[ -d "$ZSH" ]] && return 0

    print -P "%F{red}Error:%f Oh My Zsh not found at ${ZSH:-\$ZSH not set}"
    print -P "Install: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    return 1
}

# ----------------------------------------------------------
# * LOGGING INTEGRATION
# ----------------------------------------------------------

# Ensure _log function exists (fallback if logging module not loaded)
if ! typeset -f _log >/dev/null 2>&1; then
    _log() {
        # Minimal fallback - only show WARN and ERROR
        local level="$1"
        shift
        if [[ "$level" == "WARN" || "$level" == "ERROR" ]]; then
            print -ru2 -- "[$level] $*"
        fi
    }
fi

_log DEBUG "ZSH Utils Library loaded"
