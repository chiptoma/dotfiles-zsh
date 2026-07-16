#!/usr/bin/env zsh
# ==============================================================================
# ZSH USER UTILITIES
# Productivity helpers: calculator, weather, process management.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_FUNCTIONS_UTILITIES_LOADED} )) && return 0
typeset -g _Z_FUNCTIONS_UTILITIES_LOADED=1

# ----------------------------------------------------------
# WEATHER INFORMATION
# ----------------------------------------------------------

# Get weather information from wttr.in
# Usage: z_weather [location]
# Examples:
#   z_weather           # Current location (based on IP)
#   z_weather London    # Weather for London
#   z_weather "New York" # Weather for New York
z_weather() {
    local location="${1:-}"

    if ! _has_cmd curl; then
        _ui_error "curl command not found"
        _ui_dim "Install with: brew install curl"
        return 1
    fi

    # URL encode the location (spaces -> %20)
    local encoded_location="${location// /%20}"

    echo "Fetching weather data..."
    curl -s --connect-timeout 10 "wttr.in/${encoded_location}" || {
        echo ""
        _ui_error "Cannot fetch weather data"
        _ui_dim "Possible causes:"
        _ui_dim "  - No internet connection"
        _ui_dim "  - wttr.in service unavailable"
        _ui_dim "  - Invalid location name"
        return 1
    }
}

# ----------------------------------------------------------
# CALCULATOR
# ----------------------------------------------------------

# Safe calculator with input validation
# Usage: z_calc <expression>
# Examples:
#   z_calc "2 + 2"
#   z_calc "sqrt(16)"
#   z_calc "3.14 * 10^2"
z_calc() {
    if [[ -z "$1" ]]; then
        echo "Usage: calc <expression>"
        echo "Examples: calc '2 + 2', calc 'sqrt(16)', calc '3.14 * 10^2'"
        return 1
    fi

    # Join all arguments into single expression (allows: calc 2 * 2)
    local expression="$*"

    # Validate input - strict allowlist to prevent command injection
    # Step 1: Block dangerous patterns (Python injection attempts)
    if [[ "$expression" == *"__"* ]] || \
       [[ "$expression" == *"import"* ]] || \
       [[ "$expression" == *"eval"* ]] || \
       [[ "$expression" == *"exec"* ]] || \
       [[ "$expression" == *"open"* ]] || \
       [[ "$expression" == *"system"* ]]; then
        _ui_error "Expression contains blocked pattern"
        return 1
    fi

    # Step 2: Allow only safe characters
    if [[ "$expression" =~ [^0-9a-zA-Z+*/\(\).%^[:space:]-] ]]; then
        _ui_error "Invalid characters in expression"
        _ui_dim "Allowed: numbers, +, -, *, /, (, ), ., %, ^, scientific notation (e/E)"
        _ui_dim "Functions: sqrt, sin, cos, tan, log, exp, pow, abs, floor, ceil, pi, e"
        return 1
    fi

    # Step 3: Validate that letter sequences are only known math functions
    local safe_funcs="sqrt|sin|cos|tan|log|exp|pow|abs|floor|ceil|pi|e|asin|acos|atan"
    local alpha_only="${expression//[^a-zA-Z]/}"
    if [[ -n "$alpha_only" ]]; then
        # Extract all letter sequences and validate against safe function list
        local word
        local -a words=("${(@f)$(echo "$expression" | grep -oE '[a-zA-Z]+')}")
        for word in "${words[@]}"; do
            if [[ ! "$word" =~ ^($safe_funcs)$ ]]; then
                _ui_error "Unknown function '$word'"
                _ui_dim "Allowed functions: sqrt, sin, cos, tan, log, exp, pow, abs, floor, ceil, pi, e"
                return 1
            fi
        done
    fi

    if _has_cmd bc; then
        # Use bc with math library for advanced functions
        echo "$expression" | bc -l 2>/dev/null || {
            _ui_error "Invalid expression"
            return 1
        }
    elif _has_cmd python3; then
        # Fallback to Python for calculation
        python3 -c "from math import *; print($expression)" 2>/dev/null || {
            _ui_error "Invalid expression"
            return 1
        }
    elif _has_cmd python; then
        python -c "from math import *; print($expression)" 2>/dev/null || {
            _ui_error "Invalid expression"
            return 1
        }
    else
        # Pure-zsh fallback: zsh/mathfunc provides sqrt/sin/log/...;
        # translate bc's ^ to zsh's ** power operator
        zmodload zsh/mathfunc 2>/dev/null
        local zexpr="${expression//\^/**}"
        local result
        if result=$(print -r -- $(( zexpr )) 2>/dev/null); then
            print -r -- "$result"
        else
            _ui_error "Invalid expression"
            return 1
        fi
    fi
}

# ----------------------------------------------------------
# PROCESS MANAGEMENT
# ----------------------------------------------------------

# ------------------------------------------------------------------------------
# z_killapp (macOS)
# Gracefully quit an application using AppleScript, fallback to pkill.
#
# @param  $1  (string)  : Application name
# @return     (int)     : 0 on success, 1 on failure
# ------------------------------------------------------------------------------
z_killapp() {
    if ! _is_macos; then
        _ui_error "z_killapp is only available on macOS"
        return 1
    fi
    local app="${1:?Usage: killapp <app_name>}"
    app="${app//\"/}"
    app="${app//\'/}"
    osascript -e "tell application \"$app\" to quit" 2>/dev/null || \
        pkill -x "$app" 2>/dev/null || \
        { _ui_error "Could not quit $app"; return 1; }
}

# ------------------------------------------------------------------------------
# z_timeout
# Runs a command with a time limit, killing it if it exceeds the timeout.
#
# @param  $1  (string)  : Timeout duration (e.g., "5s", "2m", "1h", or seconds)
# @param  $@  (string)  : Command and arguments to execute
# @return     (int)     : Command exit code, 124 on timeout, 1 on error
#
# Notes:
# - Uses GNU timeout/gtimeout if available for efficiency.
# - Falls back to pure ZSH implementation using background jobs.
# - Supports suffixes: s (seconds), m (minutes), h (hours).
#
# Warning: Fallback implementation may not handle all edge cases.
# ------------------------------------------------------------------------------
z_timeout() {
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
        _ui_error "Invalid timeout duration '$duration'"
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
# z_pskill
# Kill process by name with confirmation.
#
# @param  $1  (string)  : Process name pattern to match.
# @return     (int)     : 0 on success, 1 on error or cancelled.
#
# Notes:
# - Uses pgrep to find matching processes.
# - Shows matched processes before confirmation.
# ------------------------------------------------------------------------------
z_pskill() {
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
# CLIPBOARD
# ----------------------------------------------------------

# Copy the absolute path of a file/dir (default: cwd) to the clipboard
# Usage: z_copypath [path]
z_copypath() {
    local target="${1:-.}"
    local abs="${target:A}"
    local clip_cmd
    clip_cmd="$(_get_clipboard_cmd)"
    print -rn -- "$abs" | eval "$clip_cmd" || return 1
    _ui_ok "Copied path: $abs"
}

# Copy a file's contents to the clipboard
# Usage: z_copyfile <file>
z_copyfile() {
    local file="$1"
    if [[ -z "$file" || ! -f "$file" ]]; then
        _ui_error "Usage: z_copyfile <file>"
        return 1
    fi
    local clip_cmd
    clip_cmd="$(_get_clipboard_cmd)"
    eval "$clip_cmd" < "$file" || return 1
    _ui_ok "Copied contents of ${file:t}"
}

_log DEBUG "ZSH User Utilities loaded"
