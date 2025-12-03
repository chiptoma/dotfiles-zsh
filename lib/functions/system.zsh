#!/usr/bin/env zsh
# ==============================================================================
# * ZSH SYSTEM FUNCTIONS LIBRARY
# ? System utilities and productivity helpers.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_ZSH_FUNCTIONS_SYSTEM_LOADED} )) && return 0
typeset -g _ZSH_FUNCTIONS_SYSTEM_LOADED=1

# Configuration variables with defaults
: ${ZSH_FUNCTIONS_SYSTEM_ENABLED:=true}  # Enable/disable System functions (default: true)

# Exit early if System functions are disabled
[[ "$ZSH_FUNCTIONS_SYSTEM_ENABLED" != "true" ]] && return 0

# ----------------------------------------------------------
# * SYSTEM DETECTION FUNCTIONS
# ----------------------------------------------------------

# ----------------------------------------------------------
# * zsh_detect_homebrew
# ? Detects and initializes Homebrew on macOS (Intel/Apple Silicon) and Linux.
# ? Should be called from .zshenv for PATH setup.
#
# @return (int) : 0 if Homebrew found and initialized, 1 otherwise
#
# ? Notes:
# ? - Apple Silicon: /opt/homebrew/bin/brew
# ? - Intel Mac: /usr/local/bin/brew
# ? - Linux: /home/linuxbrew/.linuxbrew/bin/brew
# ----------------------------------------------------------
zsh_detect_homebrew() {
    local brew_path=""

    if [[ -f /opt/homebrew/bin/brew ]]; then
        brew_path="/opt/homebrew/bin/brew"
    elif [[ -f /usr/local/bin/brew ]]; then
        brew_path="/usr/local/bin/brew"
    elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        brew_path="/home/linuxbrew/.linuxbrew/bin/brew"
    fi

    if [[ -n "$brew_path" ]]; then
        local brew_env
        brew_env="$("$brew_path" shellenv 2>/dev/null)" || {
            _log WARN "Failed to get Homebrew environment from $brew_path"
            return 1
        }
        # ! Security: Parse brew shellenv output line-by-line, only accept known variables
        # ? Known safe variables from Homebrew: PATH, MANPATH, INFOPATH, HOMEBREW_*
        local line
        while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" == \#* ]] && continue
            # Only process 'export VAR=value' or 'export VAR="value"' patterns
            if [[ "$line" =~ ^export[[:space:]]+(PATH|MANPATH|INFOPATH|HOMEBREW_[A-Z_]+)= ]]; then
                eval "$line"
            fi
        done <<< "$brew_env"
        return 0
    fi

    return 1
}

# ----------------------------------------------------------
# * zsh_detect_ssh_agent
# ? Detects and configures SSH agent socket from various providers.
# ? Priority: 1Password > GPG Agent > GNOME Keyring > System default
# ? Should be called from .zshrc for interactive sessions.
#
# @return (int) : 0 always (graceful - never fails)
#
# ? Notes:
# ? - Skips detection if SSH_AUTH_SOCK already points to valid socket
# ? - Does not start agents, only detects existing ones
# ? - User can override by setting SSH_AUTH_SOCK in local.zsh
# ----------------------------------------------------------
zsh_detect_ssh_agent() {
    # Skip if already set to a valid socket
    [[ -S "${SSH_AUTH_SOCK:-}" ]] && return 0

    # 1Password SSH Agent (macOS)
    local op_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

    # GPG Agent SSH socket
    local gpg_sock="${XDG_RUNTIME_DIR:-/run/user/$UID}/gnupg/S.gpg-agent.ssh"

    # GNOME Keyring SSH socket
    local gnome_sock="${XDG_RUNTIME_DIR:-/run/user/$UID}/keyring/ssh"

    if [[ -S "$op_sock" ]]; then
        export SSH_AUTH_SOCK="$op_sock"
    elif [[ -S "$gpg_sock" ]]; then
        export SSH_AUTH_SOCK="$gpg_sock"
    elif [[ -S "$gnome_sock" ]]; then
        export SSH_AUTH_SOCK="$gnome_sock"
    fi

    return 0
}

# ----------------------------------------------------------
# * WEATHER INFORMATION
# ----------------------------------------------------------

# Get weather information from wttr.in
# Usage: zsh_weather [location]
# Examples:
#   zsh_weather           # Current location (based on IP)
#   zsh_weather London    # Weather for London
#   zsh_weather "New York" # Weather for New York
zsh_weather() {
    local location="${1:-}"

    if ! _has_cmd curl; then
        echo "Error: curl command not found" >&2
        echo "Install with: brew install curl" >&2
        return 1
    fi

    # URL encode the location (spaces -> %20)
    local encoded_location="${location// /%20}"

    echo "Fetching weather data..."
    curl -s --connect-timeout 10 "wttr.in/${encoded_location}" || {
        echo "" >&2
        echo "Error: Cannot fetch weather data" >&2
        echo "Possible causes:" >&2
        echo "  - No internet connection" >&2
        echo "  - wttr.in service unavailable" >&2
        echo "  - Invalid location name" >&2
        return 1
    }
}

# ----------------------------------------------------------
# * CALCULATOR
# ----------------------------------------------------------

# Safe calculator with input validation
# Usage: zsh_calc <expression>
# Examples:
#   zsh_calc "2 + 2"
#   zsh_calc "sqrt(16)"
#   zsh_calc "3.14 * 10^2"
zsh_calc() {
    if [[ -z "$1" ]]; then
        echo "Usage: calc <expression>"
        echo "Examples: calc '2 + 2', calc 'sqrt(16)', calc '3.14 * 10^2'"
        return 1
    fi

    # Join all arguments into single expression (allows: calc 2 * 2)
    local expression="$*"

    # Validate input - strict allowlist to prevent command injection
    # ? Step 1: Block dangerous patterns (Python injection attempts)
    if [[ "$expression" == *"__"* ]] || \
       [[ "$expression" == *"import"* ]] || \
       [[ "$expression" == *"eval"* ]] || \
       [[ "$expression" == *"exec"* ]] || \
       [[ "$expression" == *"open"* ]] || \
       [[ "$expression" == *"system"* ]]; then
        echo "Error: Expression contains blocked pattern" >&2
        return 1
    fi

    # ? Step 2: Allow only safe characters
    if [[ "$expression" =~ [^0-9a-zA-Z+*/\(\).%^[:space:]-] ]]; then
        echo "Error: Invalid characters in expression" >&2
        echo "Allowed: numbers, +, -, *, /, (, ), ., %, ^, scientific notation (e/E)" >&2
        echo "Functions: sqrt, sin, cos, tan, log, exp, pow, abs, floor, ceil, pi, e" >&2
        return 1
    fi

    # ? Step 3: Validate that letter sequences are only known math functions
    local safe_funcs="sqrt|sin|cos|tan|log|exp|pow|abs|floor|ceil|pi|e|asin|acos|atan"
    local alpha_only="${expression//[^a-zA-Z]/}"
    if [[ -n "$alpha_only" ]]; then
        # Check each word against safe function list
        local word
        for word in ${(s::)alpha_only}; do
            # Extract words (consecutive letters) - simplified check
            :
        done
        # More robust: extract all letter sequences and validate
        local -a words=("${(@f)$(echo "$expression" | grep -oE '[a-zA-Z]+')}")
        for word in "${words[@]}"; do
            if [[ ! "$word" =~ ^($safe_funcs)$ ]]; then
                echo "Error: Unknown function '$word'" >&2
                echo "Allowed functions: sqrt, sin, cos, tan, log, exp, pow, abs, floor, ceil, pi, e" >&2
                return 1
            fi
        done
    fi

    if _has_cmd bc; then
        # Use bc with math library for advanced functions
        echo "$expression" | bc -l 2>/dev/null || {
            echo "Error: Invalid expression" >&2
            return 1
        }
    elif _has_cmd python3; then
        # Fallback to Python for calculation
        python3 -c "from math import *; print($expression)" 2>/dev/null || {
            echo "Error: Invalid expression" >&2
            return 1
        }
    elif _has_cmd python; then
        python -c "from math import *; print($expression)" 2>/dev/null || {
            echo "Error: Invalid expression" >&2
            return 1
        }
    else
        echo "Error: No calculator available (install bc or python)" >&2
        return 1
    fi
}

# ----------------------------------------------------------
# * PROCESS MANAGEMENT
# ----------------------------------------------------------

# ------------------------------------------------------------------------------
# * zsh_timeout
# ? Runs a command with a time limit, killing it if it exceeds the timeout.
#
# @param  $1  (string)  : Timeout duration (e.g., "5s", "2m", "1h", or seconds)
# @param  $@  (string)  : Command and arguments to execute
# @return     (int)     : Command exit code, 124 on timeout, 1 on error
#
# ? Notes:
# ? - Uses GNU timeout/gtimeout if available for efficiency.
# ? - Falls back to pure ZSH implementation using background jobs.
# ? - Supports suffixes: s (seconds), m (minutes), h (hours).
#
# ! Warning: Fallback implementation may not handle all edge cases.
# ------------------------------------------------------------------------------
zsh_timeout() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: timeout <duration> <command> [args...]"
        echo "Duration: number with optional suffix (s=seconds, m=minutes, h=hours)"
        echo "Examples:"
        echo "  timeout 5 ping google.com"
        echo "  timeout 30s curl example.com"
        echo "  timeout 2m long-running-script"
        return 1
    fi

    local duration="$1"
    shift

    # Parse duration to seconds
    local seconds
    case "$duration" in
        *h) seconds=$(( ${duration%h} * 3600 )) ;;
        *m) seconds=$(( ${duration%m} * 60 )) ;;
        *s) seconds="${duration%s}" ;;
        *)  seconds="$duration" ;;
    esac

    # Validate seconds is a positive number
    if ! [[ "$seconds" =~ ^[0-9]+$ ]] || [[ "$seconds" -le 0 ]]; then
        echo "Error: Invalid timeout duration '$duration'" >&2
        return 1
    fi

    # Use GNU timeout if available (most efficient)
    if _has_cmd timeout; then
        command timeout "${seconds}s" "$@"
        return $?
    elif _has_cmd gtimeout; then
        gtimeout "${seconds}s" "$@"
        return $?
    fi

    # Pure ZSH fallback using background job
    local pid exit_code

    # Run command in background
    "$@" &
    pid=$!

    # Wait with timeout using ZSH's read -t
    (
        sleep "$seconds"
        # Check if process still exists before sending signals
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null
            sleep 1
            kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null
        fi
    ) &
    local watchdog_pid=$!

    # Wait for command to complete
    wait "$pid" 2>/dev/null
    exit_code=$?

    # Clean up watchdog if command finished before timeout
    kill "$watchdog_pid" 2>/dev/null
    wait "$watchdog_pid" 2>/dev/null

    # Check if killed by timeout (128 + signal number)
    if [[ $exit_code -eq 143 ]] || [[ $exit_code -eq 137 ]]; then
        echo "Command timed out after ${seconds}s"
        return 124
    fi

    return $exit_code
}

# ------------------------------------------------------------------------------
# * zsh_pskill
# ? Kill process by name with confirmation.
#
# @param  $1  (string)  : Process name pattern to match.
# @return     (int)     : 0 on success, 1 on error or cancelled.
#
# ? Notes:
# ? - Uses pgrep to find matching processes.
# ? - Shows matched processes before confirmation.
# ------------------------------------------------------------------------------
zsh_pskill() {
    if [[ -z "$1" ]]; then
        echo "Usage: pskill <process_name>"
        return 1
    fi

    local pids
    if _is_macos || _is_bsd; then
        pids=$(pgrep -l "$1" 2>/dev/null)
    else
        pids=$(pgrep -a "$1" 2>/dev/null)
    fi

    if [[ -z "$pids" ]]; then
        echo "No processes found matching '$1'"
        return 1
    fi

    echo "Found processes:"
    echo "$pids"
    echo ""
    read -q "confirm?Kill these processes? [y/N] "
    echo ""

    if [[ "$confirm" == "y" ]]; then
        pkill "$1" && echo "Processes killed"
    else
        echo "Cancelled"
    fi
}

# ----------------------------------------------------------
# * UPDATE MANAGEMENT
# ? Configuration:
#     ZSH_UPDATE_CHECK_ENABLED  = true    (check for updates on launch)
#     ZSH_UPDATE_CHECK_INTERVAL = 86400   (seconds between checks, default 24h)
#     ZSH_UPDATE_AUTO_FETCH     = true    (fetch in background)
# ----------------------------------------------------------

# ------------------------------------------------------------------------------
# * zsh_update
# ? Updates the ZSH configuration to the latest version from git.
# ? Wrapper around install.sh --update for convenience.
#
# @return     (int)     : 0 on success, 1 on error
#
# ? Notes:
# ? - Stashes local changes if present
# ? - Shows changelog before applying
# ? - Prompts for confirmation
# ------------------------------------------------------------------------------
zsh_update() {
    local config_dir="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
    local install_script="$config_dir/install.sh"

    if [[ ! -f "$install_script" ]]; then
        echo "Error: install.sh not found at $install_script" >&2
        return 1
    fi

    bash "$install_script" --update
}

# ------------------------------------------------------------------------------
# * _zsh_check_updates
# ? Checks for available updates (called on shell startup).
# ? Uses caching to avoid network calls on every launch.
#
# @return     (int)     : 0 always (non-blocking)
#
# ? Notes:
# ? - Runs git fetch in background to not slow down shell startup
# ? - Caches check result to avoid frequent network calls
# ? - Shows notification only if updates are available
# ------------------------------------------------------------------------------
_zsh_check_updates() {
    # Skip if disabled
    [[ "${ZSH_UPDATE_CHECK_ENABLED:-true}" != "true" ]] && return 0

    local config_dir="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
    local cache_dir="${ZSH_CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}"
    local cache_file="$cache_dir/update_check"
    local interval="${ZSH_UPDATE_CHECK_INTERVAL:-86400}"  # Default: 24 hours

    # Resolve symlink to actual git directory
    local git_dir="$config_dir"
    if [[ -L "$config_dir" ]]; then
        git_dir="$(readlink "$config_dir")"
    fi

    # Skip if not a git repo
    [[ ! -d "$git_dir/.git" ]] && return 0

    # Check cache - skip if checked recently
    if [[ -f "$cache_file" ]]; then
        local last_check
        last_check=$(cat "$cache_file" 2>/dev/null | head -1)
        local now
        now=$(date +%s)
        if [[ -n "$last_check" ]] && (( now - last_check < interval )); then
            # Show cached notification if updates were found
            local cached_status
            cached_status=$(sed -n '2p' "$cache_file" 2>/dev/null)
            if [[ "$cached_status" == "updates_available" ]]; then
                print -P "%F{yellow}⚡ ZSH config updates available. Run %F{cyan}zsh_update%F{yellow} to update.%f"
            fi
            return 0
        fi
    fi

    # Fetch updates in background (non-blocking)
    if [[ "${ZSH_UPDATE_AUTO_FETCH:-true}" == "true" ]]; then
        (
            cd "$git_dir" 2>/dev/null || exit 0
            git fetch --quiet 2>/dev/null

            # Check if behind upstream
            local branch upstream local_rev remote_rev
            branch=$(git branch --show-current 2>/dev/null)
            upstream="origin/$branch"
            local_rev=$(git rev-parse HEAD 2>/dev/null)
            remote_rev=$(git rev-parse "$upstream" 2>/dev/null)

            # Update cache (use >| to override noclobber)
            mkdir -p "$cache_dir"
            if [[ -n "$remote_rev" && "$local_rev" != "$remote_rev" ]]; then
                # Check if we're behind (not just diverged)
                if git merge-base --is-ancestor HEAD "$upstream" 2>/dev/null; then
                    echo "$(date +%s)\nupdates_available" >| "$cache_file"
                else
                    echo "$(date +%s)\nup_to_date" >| "$cache_file"
                fi
            else
                echo "$(date +%s)\nup_to_date" >| "$cache_file"
            fi
        ) &!
    fi
}

# ------------------------------------------------------------------------------
# * zsh_version
# ? Shows the current ZSH configuration version.
#
# @return     (int)     : 0 always
# ------------------------------------------------------------------------------
zsh_version() {
    local config_dir="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
    local version_file="$config_dir/VERSION"

    if [[ -f "$version_file" ]]; then
        echo "ZSH Configuration v$(cat "$version_file")"
    else
        echo "ZSH Configuration (version unknown)"
    fi

    # Show git info if available
    if [[ -d "$config_dir/.git" ]] || [[ -L "$config_dir" && -d "$(readlink "$config_dir")/.git" ]]; then
        local git_dir="$config_dir"
        [[ -L "$config_dir" ]] && git_dir="$(readlink "$config_dir")"
        local commit_hash
        commit_hash=$(git -C "$git_dir" rev-parse --short HEAD 2>/dev/null)
        local branch
        branch=$(git -C "$git_dir" branch --show-current 2>/dev/null)
        if [[ -n "$commit_hash" ]]; then
            echo "  Git: $branch @ $commit_hash"
        fi
    fi
}

_log DEBUG "ZSH System Functions Library loaded"
