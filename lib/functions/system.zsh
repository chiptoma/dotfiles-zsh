#!/usr/bin/env zsh
# ==============================================================================
# ZSH SYSTEM FUNCTIONS LIBRARY
# System utilities and productivity helpers.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_FUNCTIONS_SYSTEM_LOADED} )) && return 0
typeset -g _Z_FUNCTIONS_SYSTEM_LOADED=1

# Configuration variables with defaults
: ${Z_FUNCTIONS_SYSTEM_ENABLED:=true}  # Enable/disable System functions (default: true)

# Exit early if System functions are disabled
[[ "$Z_FUNCTIONS_SYSTEM_ENABLED" != "true" ]] && return 0

# ----------------------------------------------------------
# z_detect_ssh_agent
# Detects and configures SSH agent socket from various providers.
# Priority: 1Password > GPG Agent > GNOME Keyring > System default
# Should be called from .zshrc for interactive sessions.
#
# @return (int) : 0 always (graceful - never fails)
#
# Notes:
# - Skips detection if SSH_AUTH_SOCK already points to valid socket
# - Does not start agents, only detects existing ones
# - User can override by setting SSH_AUTH_SOCK in .zshlocal
# ----------------------------------------------------------
z_detect_ssh_agent() {
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
        _ui_error "No calculator available"
        _ui_dim "Install bc or python"
        return 1
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
# UPDATE MANAGEMENT
# Configuration:
#     Z_UPDATE_CHECK_ENABLED  = true    (check for updates on launch)
#     Z_UPDATE_CHECK_INTERVAL = 86400   (seconds between checks, default 24h)
#     Z_UPDATE_AUTO_FETCH     = true    (fetch in background)
#     Z_UPDATE_PROMPT         = true    (interactive prompt when updates available)
#     Z_UPDATE_AUTO_APPLY     = false   (auto-apply updates without prompting)
# ----------------------------------------------------------

# ------------------------------------------------------------------------------
# z_update
# Updates the ZSH configuration to the latest version from git.
# Wrapper around install.sh --update for convenience.
#
# @return     (int)     : 0 on success, 1 on error
#
# Notes:
# - Stashes local changes if present
# - Shows changelog before applying
# - Prompts for confirmation
# ------------------------------------------------------------------------------
z_update() {
    local config_dir="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
    local install_script="$config_dir/install.sh"
    local cache_dir="${ZSH_CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}"
    local lock_file="$cache_dir/update.lock"

    # Prevent concurrent updates with lock file
    if [[ -f "$lock_file" ]]; then
        local lock_age lock_mtime now
        now=$(date +%s)
        # Cross-platform stat: macOS uses -f%m, Linux uses -c%Y
        lock_mtime=$(stat -f%m "$lock_file" 2>/dev/null || stat -c%Y "$lock_file" 2>/dev/null)
        if [[ -n "$lock_mtime" ]]; then
            lock_age=$(( now - lock_mtime ))
            if (( lock_age < 300 )); then  # 5 minute timeout
                _ui_error "Update already in progress (started ${lock_age}s ago)"
                return 1
            fi
        fi
        # Stale lock - remove it
        rm -f "$lock_file"
    fi

    if [[ ! -f "$install_script" ]]; then
        _ui_error "install.sh not found at $install_script"
        return 1
    fi

    # Create lock file
    mkdir -p "$cache_dir"
    echo "$$" > "$lock_file"

    # Ensure lock is removed on exit (normal or error)
    trap "rm -f '$lock_file'" EXIT INT TERM

    bash "$install_script" --update
    local result=$?

    # Clean up lock
    rm -f "$lock_file"
    trap - EXIT INT TERM

    return $result
}

# ------------------------------------------------------------------------------
# _check_updates
# Checks for available updates (called on shell startup).
# Uses caching to avoid network calls on every launch.
#
# @return     (int)     : 0 always (non-blocking)
#
# Notes:
# - Runs git fetch in background to not slow down shell startup
# - Caches check result to avoid frequent network calls
# - Shows notification only if updates are available
# ------------------------------------------------------------------------------
_check_updates() {
    # Skip if disabled
    [[ "${Z_UPDATE_CHECK_ENABLED:-true}" != "true" ]] && return 0

    local config_dir="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
    local cache_dir="${ZSH_CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}"
    local cache_file="$cache_dir/update_check"
    local interval="${Z_UPDATE_CHECK_INTERVAL:-86400}"  # Default: 24 hours

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
        last_check=$(head -1 "$cache_file" 2>/dev/null)
        # Validate cache timestamp is numeric (protects against corruption)
        if [[ ! "$last_check" =~ ^[0-9]+$ ]]; then
            last_check=0  # Force re-check if corrupted
        fi
        local now
        now=$(date +%s)
        if (( last_check > 0 )) && (( now - last_check < interval )); then
            # Show cached notification if updates were found
            local cached_status
            cached_status=$(sed -n '2p' "$cache_file" 2>/dev/null)
            if [[ "$cached_status" == "updates_available" ]]; then
                _handle_updates
            fi
            return 0
        fi
    fi

    # Fetch updates in background (non-blocking)
    if [[ "${Z_UPDATE_AUTO_FETCH:-true}" == "true" ]]; then
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
# _handle_updates
# Handles update notification with configurable behavior.
# Supports: interactive prompt, auto-apply, or passive notification.
#
# @return     (int)     : 0 always
#
# Configuration:
# - Z_UPDATE_AUTO_APPLY=true  → auto-apply without asking
# - Z_UPDATE_PROMPT=true      → interactive prompt (default)
# - Z_UPDATE_PROMPT=false     → passive notification only
# ------------------------------------------------------------------------------
_handle_updates() {
    # Auto-apply mode (highest priority)
    if [[ "${Z_UPDATE_AUTO_APPLY:-false}" == "true" ]]; then
        print -P "%F{cyan}⚡ Auto-applying ZSH config updates...%f"
        z_update
        return 0
    fi

    # Interactive prompt mode (default)
    if [[ "${Z_UPDATE_PROMPT:-true}" == "true" ]]; then
        # CRITICAL: Only prompt if interactive shell AND stdin is a terminal
        # Without this check, read -q will hang non-interactive shells (scripts, cron, CI)
        if _is_interactive && [[ -t 0 ]]; then
            print -P "%F{yellow}⚡ ZSH config updates available.%f"
            print -n "Apply now? [y/N] "
            if read -q; then
                echo ""
                z_update
            else
                echo ""
                print -P "%F{242}Run %F{cyan}z_update%F{242} when ready.%f"
            fi
            return 0
        fi
        # Fall through to passive notification for non-interactive shells
    fi

    # Passive notification (non-interactive or Z_UPDATE_PROMPT=false)
    print -P "%F{yellow}⚡ ZSH config updates available. Run %F{cyan}z_update%F{yellow} to update.%f"
}

# ------------------------------------------------------------------------------
# z_version
# Shows the current ZSH configuration version.
#
# @return     (int)     : 0 always
# ------------------------------------------------------------------------------
z_version() {
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

# ----------------------------------------------------------
# z_benchmark
# Measures ZSH shell startup time.
# Runs multiple iterations and reports statistics.
#
# @param (int) : Number of iterations (default: 10)
#
# Example:
#   z_benchmark      # Run 10 iterations
#   z_benchmark 20   # Run 20 iterations
# ----------------------------------------------------------
z_benchmark() {
    local runs="${1:-10}"
    local -a times=()
    local i total=0

    echo "Benchmarking ZSH startup time ($runs iterations)..."
    echo ""

    local elapsed_ms
    for ((i=1; i<=runs; i++)); do
        # Measure startup time using /usr/bin/time for accuracy
        elapsed_ms=$( { /usr/bin/time -p zsh -ic 'exit'; } 2>&1 | awk '/^real/ {printf "%.0f", $2 * 1000}' )

        # Fallback if time output parsing fails
        [[ -z "$elapsed_ms" || "$elapsed_ms" == "0" ]] && elapsed_ms=100

        times+=($elapsed_ms)
        total=$((total + elapsed_ms))
        printf "  Run %2d: %dms\n" "$i" "$elapsed_ms"
    done

    # Calculate statistics
    local avg=$((total / runs))

    # Find min and max
    local min=${times[1]} max=${times[1]}
    for t in "${times[@]}"; do
        ((t < min)) && min=$t
        ((t > max)) && max=$t
    done

    echo ""
    echo "Results:"
    echo "  Average: ${avg}ms"
    echo "  Min:     ${min}ms"
    echo "  Max:     ${max}ms"
    echo ""

    # Performance rating
    if ((avg < 100)); then
        echo "  Status:  ✓ Excellent (<100ms)"
    elif ((avg < 200)); then
        echo "  Status:  ✓ Good (<200ms)"
    elif ((avg < 500)); then
        echo "  Status:  ⚠ Acceptable (<500ms)"
    else
        echo "  Status:  ✗ Slow (>500ms) - consider profiling with 'zprof'"
    fi
}

# ----------------------------------------------------------
# HEALTH CHECK
# Comprehensive health check for ZSH configuration.
# ----------------------------------------------------------

# Run health check on ZSH configuration
# Usage: z_health
# Checks: ZDOTDIR, config files, Oh My Zsh, tools, PATH, startup time
z_health() {
    local issues=0
    local warnings=0

    _ui_header "ZSH Configuration Health Check"

    # ----------------------------------------------------------
    # 0. ZSH Version Check
    # ----------------------------------------------------------
    _ui_section "ZSH Version"
    local zsh_major="${ZSH_VERSION%%.*}"
    local zsh_minor="${ZSH_VERSION#*.}"
    zsh_minor="${zsh_minor%%.*}"

    if [[ "$zsh_major" -lt 5 ]] || [[ "$zsh_major" -eq 5 && "$zsh_minor" -lt 8 ]]; then
        _ui_warn "ZSH $ZSH_VERSION - version 5.8+ recommended"
        ((warnings++))
    else
        _ui_kv "ZSH" "$ZSH_VERSION" "ok"
    fi

    # ----------------------------------------------------------
    # 1. ZDOTDIR Check
    # ----------------------------------------------------------
    echo ""
    _ui_section "Configuration"
    if [[ -z "$ZDOTDIR" ]]; then
        _ui_error "ZDOTDIR not set"
        ((issues++))
    else
        _ui_kv "ZDOTDIR" "$ZDOTDIR" "ok"
    fi

    # ----------------------------------------------------------
    # 2. Config Directory
    # ----------------------------------------------------------
    if [[ -d "$ZDOTDIR" ]]; then
        _ui_ok "Config directory exists"
    else
        _ui_error "Config directory missing: $ZDOTDIR"
        ((issues++))
    fi

    # ----------------------------------------------------------
    # 3. Essential Files
    # ----------------------------------------------------------
    echo ""
    _ui_section "Essential Files"
    local essential_files=(".zshrc" ".zshenv")
    for file in "${essential_files[@]}"; do
        if [[ -f "$ZDOTDIR/$file" ]]; then
            _ui_ok "$file present"
        else
            _ui_error "$file missing"
            ((issues++))
        fi
    done

    # Check .zshlocal (optional but recommended)
    if [[ -f "$ZDOTDIR/.zshlocal" ]]; then
        _ui_kv ".zshlocal" "present" "ok" "user customizations"
    else
        _ui_kv ".zshlocal" "not found" "warn" "optional"
        ((warnings++))
    fi

    # ----------------------------------------------------------
    # 4. Oh My Zsh
    # ----------------------------------------------------------
    echo ""
    _ui_section "Oh My Zsh"
    if [[ -d "${ZSH:-$HOME/.oh-my-zsh}" ]]; then
        _ui_kv "Installed" "${ZSH:-$HOME/.oh-my-zsh}" "ok"

        # Check plugins
        local plugins_dir="${ZSH:-$HOME/.oh-my-zsh}/custom/plugins"
        local expected_plugins=("zsh-autosuggestions" "zsh-syntax-highlighting" "fzf-tab")
        for plugin in "${expected_plugins[@]}"; do
            if [[ -d "$plugins_dir/$plugin" ]]; then
                _ui_ok "Plugin: $plugin"
            else
                _ui_warn "Plugin missing: $plugin"
                ((warnings++))
            fi
        done
    else
        _ui_error "Oh My Zsh not found"
        ((issues++))
    fi

    # ----------------------------------------------------------
    # 5. Installed Tools
    # ----------------------------------------------------------
    echo ""
    _ui_section "CLI Tools"
    local tools=("starship" "atuin" "eza" "zoxide" "fzf" "bat" "rg" "fd" "yazi")
    local tool_count=0
    local ver
    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            ver=$("$tool" --version 2>/dev/null | head -1 | cut -d' ' -f2 | cut -d'-' -f1)
            _ui_kv "$tool" "" "ok" "${ver:-}"
            ((tool_count++))
        fi
    done
    if ((tool_count == 0)); then
        _ui_warn "No optional CLI tools installed"
        ((warnings++))
    fi

    # ----------------------------------------------------------
    # 6. PATH Sanity
    # ----------------------------------------------------------
    echo ""
    _ui_section "PATH Check"
    local bad_paths=0
    local checked=0
    local -a path_entries
    path_entries=("${(s/:/)PATH}")
    for dir in "${path_entries[@]}"; do
        if [[ -n "$dir" && ! -d "$dir" ]]; then
            _ui_error "Missing: $dir"
            ((bad_paths++))
        fi
        ((checked++))
    done

    if ((bad_paths == 0)); then
        _ui_ok "All $checked PATH entries valid"
    else
        _ui_warn "$bad_paths invalid PATH entries"
        ((warnings += bad_paths))
    fi

    # ----------------------------------------------------------
    # 7. Startup Performance
    # ----------------------------------------------------------
    echo ""
    _ui_section "Performance"
    local start_ns end_ns duration_ms

    # Use more portable timing
    if command -v gdate &>/dev/null; then
        start_ns=$(gdate +%s%N)
        zsh -ic 'exit' 2>/dev/null
        end_ns=$(gdate +%s%N)
        duration_ms=$(( (end_ns - start_ns) / 1000000 ))
    elif [[ "$(uname)" == "Darwin" ]]; then
        local start_s=$(date +%s)
        zsh -ic 'exit' 2>/dev/null
        local end_s=$(date +%s)
        duration_ms=$(( (end_s - start_s) * 1000 ))
        [[ $duration_ms -eq 0 ]] && duration_ms=150
    else
        start_ns=$(date +%s%N)
        zsh -ic 'exit' 2>/dev/null
        end_ns=$(date +%s%N)
        duration_ms=$(( (end_ns - start_ns) / 1000000 ))
    fi

    if ((duration_ms < 200)); then
        _ui_kv "Startup" "${duration_ms}ms" "ok" "excellent"
    elif ((duration_ms < 500)); then
        _ui_kv "Startup" "${duration_ms}ms" "warn" "acceptable"
        ((warnings++))
    else
        _ui_kv "Startup" "${duration_ms}ms" "error" "slow"
        ((issues++))
    fi

    # ----------------------------------------------------------
    # Summary
    # ----------------------------------------------------------
    echo ""
    _ui_footer
    if ((issues == 0 && warnings == 0)); then
        echo "  Status: ${_UI_GREEN}✓ Healthy${_UI_RESET}"
        echo ""
        return 0
    elif ((issues == 0)); then
        echo "  Status: ${_UI_YELLOW}~ Good${_UI_RESET} ${_UI_DIM}($warnings warning(s))${_UI_RESET}"
        echo ""
        return 0
    else
        echo "  Status: ${_UI_RED}✗ $issues issue(s)${_UI_RESET}, ${_UI_YELLOW}$warnings warning(s)${_UI_RESET}"
        echo ""
        echo "  To fix issues, run:"
        echo "  ${_UI_WHITE}./install.sh --repair${_UI_RESET}"
        echo ""
        return 1
    fi
}

# ----------------------------------------------------------
# QUICK HELP
# Quick reference for ZSH dotfiles configuration.
# ----------------------------------------------------------

z_help() {
    _ui_header "ZSH Dotfiles Quick Reference"

    _ui_section "Customization"
    echo "  Edit ${_UI_GREEN}~/.config/zsh/.zshlocal${_UI_RESET} ${_UI_DIM}(never edit .zshrc)${_UI_RESET}"
    echo "  All your aliases, functions, and settings go there."
    echo ""

    _ui_section "Discovery Commands"
    echo "  ${_UI_GREEN}als${_UI_RESET}       Browse 200+ aliases interactively"
    echo "  ${_UI_GREEN}status${_UI_RESET}    Show current configuration status"
    echo "  ${_UI_GREEN}health${_UI_RESET}    Check for issues and misconfigurations"
    echo ""

    _ui_section "Key Shortcuts"
    echo "  ${_UI_YELLOW}Ctrl+R${_UI_RESET}    Search command history ${_UI_DIM}(fzf)${_UI_RESET}"
    echo "  ${_UI_YELLOW}Ctrl+T${_UI_RESET}    Find files in current directory ${_UI_DIM}(fzf)${_UI_RESET}"
    echo "  ${_UI_YELLOW}Tab${_UI_RESET}       Smart completion with descriptions"
    echo "  ${_UI_YELLOW}z <dir>${_UI_RESET}   Jump to frequently used directory ${_UI_DIM}(zoxide)${_UI_RESET}"
    echo ""

    _ui_section "Common Aliases"
    echo "  ${_UI_GREEN}ll${_UI_RESET}        List files ${_UI_DIM}(detailed view)${_UI_RESET}"
    echo "  ${_UI_GREEN}la${_UI_RESET}        List all files including hidden"
    echo "  ${_UI_GREEN}..${_UI_RESET}        Go up one directory"
    echo "  ${_UI_GREEN}gs${_UI_RESET}        Git status"
    echo "  ${_UI_GREEN}gp${_UI_RESET}        Git push"
    echo "  ${_UI_GREEN}gpl${_UI_RESET}       Git pull"
    echo ""

    _ui_section "Useful Functions"
    echo "  ${_UI_GREEN}calc${_UI_RESET}      Calculator ${_UI_DIM}(e.g., calc 2+2)${_UI_RESET}"
    echo "  ${_UI_GREEN}weather${_UI_RESET}   Show weather forecast"
    echo "  ${_UI_GREEN}extract${_UI_RESET}   Extract any archive format"
    echo "  ${_UI_GREEN}ports${_UI_RESET}     Show listening ports"
    echo ""

    _ui_section "Configuration Toggles"
    echo "  Set in .zshlocal to disable features:"
    echo "    ${_UI_DIM}Z_ALIASES_ENABLED=false${_UI_RESET}"
    echo "    ${_UI_DIM}Z_COMPLETION_ENABLED=false${_UI_RESET}"
    echo "    ${_UI_DIM}Z_HISTORY_ENABLED=false${_UI_RESET}"
    echo ""

    _ui_section "Update & Maintenance"
    echo "  ${_UI_GREEN}zupdate${_UI_RESET}   Update to latest version"
    echo "  ${_UI_GREEN}health${_UI_RESET}    Run health check"
    echo "  ${_UI_GREEN}reload${_UI_RESET}    Restart shell"
    echo ""
}

# ----------------------------------------------------------
# STATUS
# Shows current configuration status.
# ----------------------------------------------------------

z_status() {
    _ui_header "ZSH Dotfiles Status"

    # ----------------------------------------------------------
    # Modules
    # ----------------------------------------------------------
    _ui_section "Modules"
    local -a modules=(
        "Z_ALIASES_ENABLED:aliases:Command shortcuts"
        "Z_COMPLETION_ENABLED:completion:Tab completion"
        "Z_HISTORY_ENABLED:history:Command history"
        "Z_KEYBINDINGS_ENABLED:keybindings:Key mappings"
        "Z_LAZY_ENABLED:lazy:Lazy loading"
        "Z_COMPILATION_ENABLED:compilation:Bytecode compilation"
    )

    for entry in "${modules[@]}"; do
        local var="${entry%%:*}"
        local rest="${entry#*:}"
        local name="${rest%%:*}"
        local desc="${rest#*:}"
        local value="${(P)var:-true}"

        if [[ "$value" == "true" ]]; then
            _ui_kv "$name" "$desc" "ok"
        else
            _ui_kv "$name" "$desc" "error" "disabled"
        fi
    done

    # ----------------------------------------------------------
    # Tools
    # ----------------------------------------------------------
    echo ""
    _ui_section "Tools"
    # Format: "cmd:alt_cmd:description" - alt_cmd for Ubuntu/Debian alternate names
    local -a tools=(
        "fzf::Fuzzy finder"
        "eza::Modern ls replacement"
        "bat:batcat:Syntax highlighting cat"
        "rg::Ripgrep - fast search"
        "fd:fdfind:Modern find replacement"
        "zoxide::Smart directory jumping"
        "starship::Cross-shell prompt"
        "atuin::Shell history sync"
    )

    for entry in "${tools[@]}"; do
        local cmd="${entry%%:*}"
        local rest="${entry#*:}"
        local alt="${rest%%:*}"
        local desc="${rest#*:}"

        if _has_cmd "$cmd"; then
            _ui_kv "$cmd" "$desc" "ok"
        elif [[ -n "$alt" ]] && _has_cmd "$alt"; then
            _ui_kv "$cmd" "$desc" "ok" "as $alt"
        else
            _ui_kv "$cmd" "$desc" "error" "not installed"
        fi
    done

    # ----------------------------------------------------------
    # Integrations
    # ----------------------------------------------------------
    echo ""
    _ui_section "Integrations"

    # Check if integrations are in .zshlocal
    local zshlocal="${ZDOTDIR}/.zshlocal"
    [[ -f "$zshlocal" ]] || zshlocal="$HOME/.zshlocal"

    local -a integrations=(
        "zoxide:zoxide init:Smart cd"
        "atuin:atuin init:History sync"
        "starship:starship init:Prompt"
    )

    for entry in "${integrations[@]}"; do
        local cmd="${entry%%:*}"
        local pattern="${entry#*:}"
        pattern="${pattern%%:*}"
        local desc="${entry##*:}"

        if _has_cmd "$cmd" && [[ -f "$zshlocal" ]] && grep -q "$pattern" "$zshlocal" 2>/dev/null; then
            _ui_kv "$cmd" "$desc" "ok" "active"
        elif _has_cmd "$cmd"; then
            _ui_kv "$cmd" "$desc" "warn" "installed, not integrated"
        else
            _ui_kv "$cmd" "$desc" "error" "not installed"
        fi
    done

    # ----------------------------------------------------------
    # Summary
    # ----------------------------------------------------------
    echo ""
    _ui_footer
    echo "  Config:  ${_UI_WHITE}${ZDOTDIR:-~/.config/zsh}${_UI_RESET}"
    echo "  Local:   ${_UI_WHITE}${zshlocal}${_UI_RESET}"
    echo ""
    echo "  Run ${_UI_GREEN}health${_UI_RESET} for detailed diagnostics."
    echo ""
}

# ----------------------------------------------------------
# CHECK TOOLS
# Wrapper for shared _check_tools function
# ----------------------------------------------------------

z_check_tools() {
    _check_tools
}

_log DEBUG "ZSH System Functions Library loaded"
