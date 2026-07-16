#!/usr/bin/env zsh
# ==============================================================================
# ZSH FRAMEWORK MANAGEMENT
# Version, updates, health check, status, benchmark, and diagnostics.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_FUNCTIONS_FRAMEWORK_LOADED} )) && return 0
typeset -g _Z_FUNCTIONS_FRAMEWORK_LOADED=1

# Ensure lazy tools map exists (z_lazy_status reads it)
(( ${+_LAZY_LOADED_TOOLS} )) || typeset -gA _LAZY_LOADED_TOOLS=()

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
        lock_mtime=$(_get_mtime "$lock_file")
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

# ----------------------------------------------------------
# VERSION
# ----------------------------------------------------------

# ------------------------------------------------------------------------------
# z_version
# Shows the current ZSH configuration version.
#
# @return     (int)     : 0 always
# ------------------------------------------------------------------------------
z_version() {
    local config_dir="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
    local version_file="$config_dir/version.txt"

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
# SSH AGENT
# ----------------------------------------------------------

# ------------------------------------------------------------------------------
# z_ssh_agent
# Shows the detected SSH agent provider, socket path, and liveness, and
# warns when the agent offers more keys than servers typically allow.
#
# NOTE: This is the on-demand liveness probe; boot-time detection in
#   lib/core/platform/detect.zsh only checks socket existence.
# ------------------------------------------------------------------------------
z_ssh_agent() {
    _ui_section "SSH Agent"

    local sock="${SSH_AUTH_SOCK:-}"
    if [[ -z "$sock" ]]; then
        _ui_warn "SSH_AUTH_SOCK is not set"
        _ui_dim "Auto-detection runs in .zshenv (toggle: Z_ENVIRONMENT_SSH_AGENT)"
        return 1
    fi

    local provider="system/other"
    case "$sock" in
        *2BUA8C4S2C.com.1password*|*/.1password/*) provider="1Password" ;;
        *gnupg*)                                   provider="GPG agent" ;;
        *keyring*)                                 provider="GNOME Keyring" ;;
        */launchd*|*com.apple*)                    provider="macOS launchd" ;;
    esac
    _ui_kv "Provider" "$provider" "dim"
    _ui_kv "Socket" "$sock" "dim"

    if [[ ! -S "$sock" ]]; then
        _ui_error "Socket does not exist — the agent is not running"
        _ui_dim "Start the agent app, then run _detect_ssh_agent (or open a new shell)"
        return 1
    fi

    # ssh-add -l: rc 0 = keys listed, 1 = alive but empty, 2 = unreachable
    local out rc key_count
    out=$(command ssh-add -l 2>/dev/null)
    rc=$?
    case $rc in
        0)
            key_count=$(print -r -- "$out" | grep -c .)
            _ui_kv "Status" "alive" "ok" "$key_count key(s) offered"
            if (( key_count > 5 )); then
                _ui_warn "Offering $key_count keys — default MaxAuthTries on servers is 6"
                _ui_dim "Pin hosts (IdentityFile + IdentitiesOnly) or order keys in"
                _ui_dim "1Password agent.toml; see docs/TROUBLESHOOTING.md (SSH section)"
            fi
            ;;
        1)
            _ui_kv "Status" "alive" "ok" "no keys loaded"
            ;;
        *)
            _ui_error "Socket exists but the agent is unreachable (stale socket)"
            _ui_dim "Restart the agent app, then run _detect_ssh_agent"
            return 1
            ;;
    esac
    return 0
}

# ----------------------------------------------------------
# ENVIRONMENT INFO
# ----------------------------------------------------------

# ------------------------------------------------------------------------------
# z_env_info
# Shows the resolved editor, pager, and viewer configuration with quick
# self-test hints. (Formerly the standalone bin/zsh-env-info script.)
# ------------------------------------------------------------------------------
z_env_info() {
    _ui_section "Editors"
    _ui_kv "EDITOR" "${EDITOR:-unset}" "dim"
    _ui_kv "VISUAL" "${VISUAL:-unset}" "dim"
    _ui_kv "SUDO_EDITOR" "${SUDO_EDITOR:-unset}" "dim"

    echo ""
    _ui_section "Pager"
    _ui_kv "LESS" "${LESS:-unset}" "dim"
    _ui_kv "MANPAGER" "${MANPAGER:-less}" "dim"

    if _has_cmd bat; then
        echo ""
        _ui_section "Bat"
        _ui_kv "Theme" "${BAT_THEME:-config default}" "dim"
        _ui_dim "List themes: bat --list-themes"
    fi

    echo ""
    _ui_section "Quick Tests"
    _ui_dim "\$EDITOR /tmp/test.txt        — editor opens"
    _ui_dim "man ls                       — colored man pages"
    _ui_dim "git log --oneline | less     — pager integration"
}

# ----------------------------------------------------------
# STARTUP PROFILE
# ----------------------------------------------------------

# ------------------------------------------------------------------------------
# z_profile
# Prints the per-stage startup timing table recorded by lib/core/profile.zsh.
#
# NOTE: Requires the shell to have started with Z_PROFILE_STARTUP=true.
# ------------------------------------------------------------------------------
z_profile() {
    if [[ "${Z_PROFILE_STARTUP:-}" != "true" ]]; then
        _ui_warn "Startup profiling is off for this shell"
        _ui_dim "Per-stage:      Z_PROFILE_STARTUP=true zsh -ic z_profile"
        _ui_dim "Function-level: Z_PROFILE_STARTUP=zprof zsh -ic exit"
        return 1
    fi

    _ui_section "Startup Profile"
    local label
    local -F sum=0 ms=0
    for label in "${_Z_PROFILE_ORDER[@]}"; do
        sum=$(( sum + _Z_PROFILE_MS[$label] ))
    done
    for label in "${_Z_PROFILE_ORDER[@]}"; do
        ms=$(( _Z_PROFILE_MS[$label] ))
        local -i pct=0
        (( sum > 0 )) && pct=$(( ms * 100.0 / sum ))
        _ui_kv "$label" "$(printf '%7.1f ms' $ms)" "dim" "${pct}%"
    done
    _ui_kv "measured total" "$(printf '%7.1f ms' $sum)" "ok"
    _ui_dim "Excludes zsh binary startup + .zshlocal; benchmark with 'just bench'"
}

# ----------------------------------------------------------
# BENCHMARK
# ----------------------------------------------------------

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

    # hyperfine gives warmup, statistics, and outlier detection for free
    if _has_cmd hyperfine; then
        hyperfine --warmup 3 --runs "$runs" 'zsh -ic exit'
        return $?
    fi

    echo "Benchmarking ZSH startup time ($runs iterations)..."
    echo ""

    local elapsed_ms
    for ((i=1; i<=runs; i++)); do
        # Measure startup time using /usr/bin/time for accuracy
        elapsed_ms=$( { /usr/bin/time -p zsh -ic 'exit'; } 2>&1 | awk '/^real/ {printf "%.0f", $2 * 1000}' )

        if [[ -z "$elapsed_ms" ]]; then
            _ui_error "Could not parse /usr/bin/time output — aborting"
            return 1
        fi

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
        _ui_ok "Excellent (<100ms)"
    elif ((avg < 200)); then
        _ui_ok "Good (<200ms)"
    elif ((avg < 500)); then
        _ui_warn "Acceptable (<500ms)"
    else
        _ui_error "Slow (>500ms) - consider profiling with 'zprof'"
    fi
}

# ----------------------------------------------------------
# HEALTH CHECK
# Comprehensive health check for ZSH configuration.
# ----------------------------------------------------------

# Run health check on ZSH configuration
# Usage: z_health
# Checks: ZDOTDIR, config files, plugins, tools, PATH, SSH agent, startup time
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
    # 4. Plugins
    # ----------------------------------------------------------
    echo ""
    _ui_section "Plugins"
    local plugins_dir="${Z_PLUGINS_DIR:-${ZSH_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/zsh}/plugins}"
    local legacy_plugins_dir="${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-zsh/custom/plugins"
    local expected_plugins=("zsh-autosuggestions" "zsh-syntax-highlighting" "fzf-tab")
    for plugin in "${expected_plugins[@]}"; do
        if [[ -d "$plugins_dir/$plugin" || -d "$legacy_plugins_dir/$plugin" ]]; then
            _ui_ok "Plugin: $plugin"
        else
            _ui_warn "Plugin missing: $plugin"
            ((warnings++))
        fi
    done

    # ----------------------------------------------------------
    # 5. Installed Tools
    # ----------------------------------------------------------
    echo ""
    _ui_section "CLI Tools"
    _z_tools_load 2>/dev/null
    local tool_count=0
    local ver name binary
    for name in "${Z_TOOL_NAMES[@]}"; do
        binary="${Z_TOOLS[$name]%%:*}"
        if command -v "$binary" &>/dev/null; then
            ver=$("$binary" --version 2>/dev/null | head -1 | cut -d' ' -f2 | cut -d'-' -f1)
            _ui_kv "$name" "" "ok" "${ver:-}"
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
    # 6b. SSH Agent
    # ----------------------------------------------------------
    echo ""
    _ui_section "SSH Agent"
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
        _ui_warn "SSH_AUTH_SOCK not set"
        ((warnings++))
    elif [[ ! -S "$SSH_AUTH_SOCK" ]]; then
        _ui_error "Socket missing: $SSH_AUTH_SOCK"
        ((issues++))
    else
        command ssh-add -l >/dev/null 2>&1
        case $? in
            0|1) _ui_ok "Agent alive ($SSH_AUTH_SOCK)" ;;
            *)
                _ui_warn "Stale socket — agent unreachable (run z_ssh_agent)"
                ((warnings++))
                ;;
        esac
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
    _z_tools_load 2>/dev/null
    # Debian ships some binaries under alternate names
    local -A alt_bins=(bat batcat fd fdfind)
    local name binary desc category alt
    for name in "${Z_TOOL_NAMES[@]}"; do
        local -a fields=("${(@s.:.)Z_TOOLS[$name]}")
        binary="${fields[1]}" desc="${fields[2]}" category="${fields[3]}"
        [[ "$category" == "extra" ]] && continue
        alt="${alt_bins[$binary]:-}"

        if _has_cmd "$binary"; then
            _ui_kv "$name" "$desc" "ok"
        elif [[ -n "$alt" ]] && _has_cmd "$alt"; then
            _ui_kv "$name" "$desc" "ok" "as $alt"
        else
            _ui_kv "$name" "$desc" "error" "not installed"
        fi
    done

    # ----------------------------------------------------------
    # Integrations
    # ----------------------------------------------------------
    echo ""
    _ui_section "Integrations"

    local -a integrations=(
        "zoxide:Smart cd"
        "atuin:History sync"
        "starship:Prompt"
    )

    for entry in "${integrations[@]}"; do
        local cmd="${entry%%:*}"
        local desc="${entry#*:}"

        if ! _has_cmd "$cmd"; then
            _ui_kv "$cmd" "$desc" "error" "not installed"
            continue
        fi

        # Detect integration via runtime artifacts (functions, widgets, env vars)
        local is_active=false
        case "$cmd" in
            zoxide)
                (( ${+_LAZY_LOADED_TOOLS[zoxide]} )) && is_active=true
                (( $+functions[__zoxide_z] )) && is_active=true
                # Lazy wrapper function means integration is configured
                (( $+functions[z] )) && is_active=true
                ;;
            atuin)
                (( $+widgets[atuin-up-search] )) && is_active=true
                (( $+widgets[atuin-search] )) && is_active=true
                ;;
            starship)
                (( $+functions[starship_precmd] )) && is_active=true
                [[ "${STARSHIP_SHELL:-}" == "zsh" ]] && is_active=true
                ;;
        esac

        if [[ "$is_active" == "true" ]]; then
            _ui_kv "$cmd" "$desc" "ok" "active"
        else
            _ui_kv "$cmd" "$desc" "warn" "installed, not integrated"
        fi
    done

    # ----------------------------------------------------------
    # Summary
    # ----------------------------------------------------------
    echo ""
    _ui_footer
    echo "  Config:  ${_UI_WHITE}${ZDOTDIR:-~/.config/zsh}${_UI_RESET}"
    echo "  Local:   ${_UI_WHITE}${ZDOTDIR:-~/.config/zsh}/.zshlocal${_UI_RESET}"
    echo ""
    echo "  Run ${_UI_GREEN}zhealth${_UI_RESET} for detailed diagnostics."
    echo ""
}

# ----------------------------------------------------------
# CHECK TOOLS
# Wrapper for shared _check_tools function
# ----------------------------------------------------------

z_check_tools() {
    _check_tools
}

# ----------------------------------------------------------
# LAZY LOADING STATUS
# Shows which tools have been lazily loaded.
# ----------------------------------------------------------

z_lazy_status() {
    _ui_header "Lazy Loading Status"

    _ui_section "Configuration"
    _ui_kv "Z_LAZY_ENABLED" "${Z_LAZY_ENABLED:-true}" "dim"
    _ui_kv "Z_LAZY_ZOXIDE" "${Z_LAZY_ZOXIDE:-true}" "dim"
    _ui_kv "Z_LAZY_NVM" "${Z_LAZY_NVM:-true}" "dim"
    _ui_kv "Z_LAZY_PYENV" "${Z_LAZY_PYENV:-true}" "dim"
    _ui_kv "Z_LAZY_RBENV" "${Z_LAZY_RBENV:-true}" "dim"

    echo ""
    _ui_section "Loaded Tools"
    if [[ ${#_LAZY_LOADED_TOOLS[@]} -eq 0 ]]; then
        _ui_dim "  (none yet - tools initialize on first use)"
    else
        local tool
        for tool in "${(k)_LAZY_LOADED_TOOLS[@]}"; do
            _ui_ok "$tool"
        done
    fi
}

# ----------------------------------------------------------
# COMPILED FILE CLEANUP
# Removes stale or all compiled .zwc files.
# ----------------------------------------------------------

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

_log DEBUG "ZSH Framework Management loaded"
