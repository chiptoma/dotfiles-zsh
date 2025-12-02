#!/usr/bin/env zsh
# ==============================================================================
# * ZSH FILE FUNCTIONS LIBRARY
# ? File management and information utilities.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_ZSH_FUNCTIONS_FILE_LOADED} )) && return 0
typeset -g _ZSH_FUNCTIONS_FILE_LOADED=1

# Configuration variables with defaults
: ${ZSH_FUNCTIONS_FILE_ENABLED:=true}  # Enable/disable File functions (default: true)

# Exit early if File functions are disabled
[[ "$ZSH_FUNCTIONS_FILE_ENABLED" != "true" ]] && return 0

# ----------------------------------------------------------
# * FILE INFORMATION
# ----------------------------------------------------------

# Show file/directory size in human-readable format
# Usage: zsh_sizeof <path>
zsh_sizeof() {
    if [[ -z "$1" ]]; then
        echo "Usage: sizeof <path>"
        return 1
    fi

    if [[ ! -e "$1" ]]; then
        echo "Error: '$1' does not exist" >&2
        return 1
    fi

    if _has_cmd dust; then
        dust -d 0 "$1"
    elif _is_macos || _is_bsd; then
        du -sh "$1"
    else
        du -sh --apparent-size "$1"
    fi
}

# ----------------------------------------------------------
# * FILE MANAGEMENT
# ----------------------------------------------------------

# Create a backup of a file
# Usage: zsh_backup <file>
zsh_backup() {
    if [[ -z "$1" ]]; then
        echo "Usage: backup <file>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "Error: '$1' is not a file" >&2
        return 1
    fi

    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp "$1" "${1}.${timestamp}.bak" && echo "Backed up to: ${1}.${timestamp}.bak"
}

# ----------------------------------------------------------
# * DEVELOPMENT HELPERS
# ----------------------------------------------------------

# Find and list all TODO/FIXME comments in current directory
# Usage: zsh_todos [pattern]
zsh_todos() {
    local pattern="${1:-TODO|FIXME|XXX|HACK}"

    if _has_cmd rg; then
        rg --no-heading --line-number "$pattern" .
    else
        grep -rn --color=auto -E "$pattern" .
    fi
}

# ----------------------------------------------------------
# * FILE MANAGER
# ----------------------------------------------------------

# Yazi file manager with cd-on-exit
# Changes directory to the last visited path when exiting yazi
# Usage: zsh_yazi [path]
zsh_yazi() {
    if ! _has_cmd yazi; then
        echo "Error: yazi command not found" >&2
        echo "Install with: brew install yazi" >&2
        return 1
    fi

    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || {
        echo "Error: Failed to create temp file" >&2
        return 1
    }

    # Ensure temp file cleanup on exit/interrupt
    trap 'rm -f "$tmp" 2>/dev/null' EXIT INT TERM

    yazi "$@" --cwd-file="$tmp"
    if [[ -f "$tmp" ]]; then
        local cwd
        cwd="$(cat "$tmp")"
        rm -f "$tmp"
        [[ -d "$cwd" && "$cwd" != "$PWD" ]] && cd "$cwd"
    fi

    # Reset trap
    trap - EXIT INT TERM
}

# ----------------------------------------------------------
# * DIRECTORY NAVIGATION
# ----------------------------------------------------------

# Go up N directories
# Usage: zsh_up [n]
# Examples:
#   zsh_up      # go up 1 directory
#   zsh_up 3    # go up 3 directories
zsh_up() {
    local count="${1:-1}"
    local -r max_depth="${ZSH_UP_MAX_DEPTH:-50}"  # Configurable safety limit

    # Validate input is a positive integer
    if [[ ! "$count" =~ ^[0-9]+$ ]] || [[ "$count" -eq 0 ]]; then
        echo "Usage: zsh_up [n] - go up n directories (default: 1, max: $max_depth)"
        return 1
    fi

    # Enforce maximum depth
    if (( count > max_depth )); then
        echo "Error: Maximum depth is $max_depth directories" >&2
        return 1
    fi

    local path=""
    for ((i = 0; i < count; i++)); do
        path="../$path"
    done

    cd "$path" || {
        echo "Error: Cannot go up $count directories" >&2
        return 1
    }
}

# Create directory and change into it
# Usage: zsh_mkcd <directory>
zsh_mkcd() {
    if [[ -z "$1" ]]; then
        echo "Usage: zsh_mkcd <directory>"
        return 1
    fi

    mkdir -p "$1" && cd "$1" || {
        echo "Error: Cannot create or enter directory '$1'" >&2
        return 1
    }
}

# ----------------------------------------------------------
# * ARCHIVE EXTRACTION
# ----------------------------------------------------------

# Check archive for path traversal attempts (../ or absolute paths)
# Usage: _check_archive_safety <file>
# Returns: 0 if safe, 1 if dangerous paths detected
_check_archive_safety() {
    local file="$1"
    local -a dangerous_entries=()

    case "$file" in
        *.tar*|*.tgz|*.tbz2|*.txz)
            if _has_cmd tar; then
                dangerous_entries=("${(@f)$(tar -tf "$file" 2>/dev/null | grep -E '(^/|\.\./)')}")
            fi
            ;;
        *.zip|*.jar|*.war|*.ear)
            if _has_cmd unzip; then
                dangerous_entries=("${(@f)$(unzip -l "$file" 2>/dev/null | awk '{print $4}' | grep -E '(^/|\.\./)')}")
            fi
            ;;
    esac

    # Filter empty entries
    dangerous_entries=("${(@)dangerous_entries:#}")

    if [[ ${#dangerous_entries[@]} -gt 0 ]]; then
        echo "! Security warning: Archive contains potentially dangerous paths:" >&2
        printf '  %s\n' "${dangerous_entries[@]}" >&2
        return 1
    fi

    return 0
}

# Universal archive extractor
# Usage: zsh_extract <file> [destination]
# Supports: tar, gz, bz2, xz, zip, rar, 7z, Z, deb, rpm, zst
zsh_extract() {
    if [[ -z "$1" ]]; then
        echo "Usage: zsh_extract <file> [destination]"
        return 1
    fi

    local file="$1"
    local dest="${2:-.}"

    if [[ ! -f "$file" ]]; then
        echo "Error: '$file' is not a valid file" >&2
        return 1
    fi

    # Create destination directory if specified and doesn't exist
    if [[ "$dest" != "." && ! -d "$dest" ]]; then
        mkdir -p "$dest" || {
            echo "Error: Cannot create destination directory '$dest'" >&2
            return 1
        }
    fi

    # Security check: detect path traversal attempts
    if ! _check_archive_safety "$file"; then
        echo "Error: Extraction aborted for security reasons" >&2
        echo "Use dedicated tools with --strip-components or similar options if intentional" >&2
        return 1
    fi

    case "$file" in
        *.tar.bz2|*.tbz2)
            _require_cmd tar && tar xvjf "$file" -C "$dest"
            ;;
        *.tar.gz|*.tgz)
            _require_cmd tar && tar xvzf "$file" -C "$dest"
            ;;
        *.tar.xz|*.txz)
            _require_cmd tar && tar xvJf "$file" -C "$dest"
            ;;
        *.tar.zst)
            _require_cmd tar && tar --zstd -xvf "$file" -C "$dest"
            ;;
        *.tar)
            _require_cmd tar && tar xvf "$file" -C "$dest"
            ;;
        *.bz2)
            _require_cmd bunzip2 && bunzip2 -k "$file"
            ;;
        *.gz)
            _require_cmd gunzip && gunzip -k "$file"
            ;;
        *.xz)
            _require_cmd unxz && unxz -k "$file"
            ;;
        *.zip|*.jar|*.war|*.ear)
            _require_cmd unzip && unzip "$file" -d "$dest"
            ;;
        *.rar)
            if _has_cmd unrar; then
                unrar x "$file" "$dest"
            elif _has_cmd 7z; then
                7z x "$file" -o"$dest"
            else
                echo "Error: unrar or 7z required for .rar files" >&2
                return 1
            fi
            ;;
        *.7z)
            _require_cmd 7z && 7z x "$file" -o"$dest"
            ;;
        *.Z)
            _require_cmd uncompress && uncompress "$file"
            ;;
        *.deb)
            _require_cmd ar && ar x "$file"
            ;;
        *.rpm)
            if _has_cmd rpm2cpio && _has_cmd cpio; then
                rpm2cpio "$file" | cpio -idmv
            else
                echo "Error: rpm2cpio and cpio required for .rpm files" >&2
                return 1
            fi
            ;;
        *.zst)
            _require_cmd unzstd && unzstd "$file"
            ;;
        *)
            echo "Error: Unknown archive format for '$file'" >&2
            echo "Supported: tar, gz, bz2, xz, zst, zip, rar, 7z, Z, deb, rpm"
            return 1
            ;;
    esac
}

_log DEBUG "ZSH File Functions Library loaded"
