#!/usr/bin/env zsh
# ==============================================================================
# ZSH ENVIRONMENT MODULE
# Comprehensive environment variable management with XDG support.
# Handles XDG base directories, tool-specific paths, and editor configuration.
# ==============================================================================

# ----------------------------------------------------------
# MODULE CONFIGURATION
# ----------------------------------------------------------

# Idempotent guard - prevent multiple loads
(( ${+_Z_ENVIRONMENT_LOADED} )) && return 0
typeset -g _Z_ENVIRONMENT_LOADED=1

_log DEBUG "ZSH Environment Module loading"

# Module hooks
typeset -ga Z_PRE_ENV_INIT_HOOKS=()
typeset -ga Z_POST_ENV_INIT_HOOKS=()

# Configuration variables with defaults
# These can be overridden by exporting them in .zshenv before sourcing this module
: ${Z_ENVIRONMENT_ENABLED:=true}      # Enable/disable environment system (default: true)
: ${Z_ENVIRONMENT_XDG_STRICT:=true}   # Enforce XDG directories for all tools (default: true)
: ${Z_ENVIRONMENT_SSH_MINIMAL:=true}  # Use minimal environment in SSH sessions (default: true)
: ${Z_ENVIRONMENT_SSH_AGENT:=true}    # Auto-detect SSH agent socket (default: true)
: ${Z_LOCALE_OVERRIDE:=""}               # Override system locale (default: empty = use system)

# Editor preferences - can be overridden in .zshenv
: ${Z_GUI_EDITORS_ORDER:="surf cursor code"}
: ${Z_TERMINAL_EDITORS_ORDER:="nvim vim vi"}

# Exit early if module is disabled
[[ "$Z_ENVIRONMENT_ENABLED" != "true" ]] && return 0

# ----------------------------------------------------------
# DATA-DRIVEN ENVIRONMENT CONFIGURATION
# Tool data is populated by lib/registry/*.zsh files.
# Format: 'VAR' 'value|command'
# ----------------------------------------------------------

# Global associative arrays for environment definitions
typeset -gA ZSH_ENV_XDG_BASE
typeset -gA ZSH_ENV_CORE

# Ensure tool arrays exist (registry may have already populated them)
# NOTE: Fallback for standalone sourcing. Keep in sync with lib/registry/index.zsh.
(( ${+ZSH_ENV_TOOLS_ZSH} ))      || typeset -gA ZSH_ENV_TOOLS_ZSH
(( ${+ZSH_ENV_TOOLS_JS} ))       || typeset -gA ZSH_ENV_TOOLS_JS
(( ${+ZSH_ENV_TOOLS_GO} ))       || typeset -gA ZSH_ENV_TOOLS_GO
(( ${+ZSH_ENV_TOOLS_PYTHON} ))   || typeset -gA ZSH_ENV_TOOLS_PYTHON
(( ${+ZSH_ENV_TOOLS_DOCKER} ))   || typeset -gA ZSH_ENV_TOOLS_DOCKER
(( ${+ZSH_ENV_TOOLS_K8S} ))      || typeset -gA ZSH_ENV_TOOLS_K8S
(( ${+ZSH_ENV_TOOLS_JVM} ))      || typeset -gA ZSH_ENV_TOOLS_JVM
(( ${+ZSH_ENV_TOOLS_ANSIBLE} ))  || typeset -gA ZSH_ENV_TOOLS_ANSIBLE
(( ${+ZSH_ENV_TOOLS_CLOUD} ))    || typeset -gA ZSH_ENV_TOOLS_CLOUD
(( ${+ZSH_ENV_TOOLS_IAC} ))      || typeset -gA ZSH_ENV_TOOLS_IAC
(( ${+ZSH_ENV_TOOLS_DB} ))       || typeset -gA ZSH_ENV_TOOLS_DB
(( ${+ZSH_ENV_TOOLS_VIRT} ))     || typeset -gA ZSH_ENV_TOOLS_VIRT
(( ${+ZSH_ENV_TOOLS_SECURITY} )) || typeset -gA ZSH_ENV_TOOLS_SECURITY
(( ${+ZSH_ENV_TOOLS_BUILD} ))    || typeset -gA ZSH_ENV_TOOLS_BUILD
(( ${+ZSH_ENV_TOOLS_LANGS} ))    || typeset -gA ZSH_ENV_TOOLS_LANGS
(( ${+ZSH_ENV_TOOLS_RUBY} ))    || typeset -gA ZSH_ENV_TOOLS_RUBY
(( ${+ZSH_ENV_TOOLS_RUST} ))    || typeset -gA ZSH_ENV_TOOLS_RUST
(( ${+ZSH_ENV_TOOLS_GENERAL} ))  || typeset -gA ZSH_ENV_TOOLS_GENERAL
(( ${+Z_ENV_CONFIG_FILE_CHECKS} )) || typeset -gA Z_ENV_CONFIG_FILE_CHECKS

# Master list of tool categories
typeset -ga ZSH_ENV_TOOL_CATEGORIES=(
    ZSH_ENV_TOOLS_ZSH
    ZSH_ENV_TOOLS_JS
    ZSH_ENV_TOOLS_GO
    ZSH_ENV_TOOLS_PYTHON
    ZSH_ENV_TOOLS_DOCKER
    ZSH_ENV_TOOLS_K8S
    ZSH_ENV_TOOLS_JVM
    ZSH_ENV_TOOLS_ANSIBLE
    ZSH_ENV_TOOLS_CLOUD
    ZSH_ENV_TOOLS_IAC
    ZSH_ENV_TOOLS_DB
    ZSH_ENV_TOOLS_VIRT
    ZSH_ENV_TOOLS_SECURITY
    ZSH_ENV_TOOLS_BUILD
    ZSH_ENV_TOOLS_LANGS
    ZSH_ENV_TOOLS_RUBY
    ZSH_ENV_TOOLS_RUST
    ZSH_ENV_TOOLS_GENERAL
)

# ZSH-specific directories (in addition to XDG)
: ${ZDOTDIR:="$HOME/.config/zsh"}
: ${ZSH_CONFIG_HOME:="$XDG_CONFIG_HOME/zsh"}
: ${ZSH_CACHE_HOME:="$XDG_CACHE_HOME/zsh"}
: ${ZSH_DATA_HOME:="$XDG_DATA_HOME/zsh"}
: ${ZSH_STATE_HOME:="$XDG_STATE_HOME/zsh"}

# Ensure ZSH directories exist (wrapped to prevent scope leak)
() {
    local dir
    for dir in "$ZSH_CONFIG_HOME" "$ZSH_CACHE_HOME" "$ZSH_DATA_HOME" "$ZSH_STATE_HOME"; do
        _ensure_dir "$dir"
    done
}

# XDG Base Directories - Defaults (set only if not already defined)
# NOTE: These duplicate .zshenv definitions intentionally.
# .zshenv sets them early (before utils/platform load); this table drives
# z_env_show display and ensures standalone sourcing of this module works.
ZSH_ENV_XDG_BASE=(
    'XDG_CONFIG_HOME'   "$HOME/.config"
    'XDG_CACHE_HOME'    "$HOME/.cache"
    'XDG_DATA_HOME'     "$HOME/.local/share"
    'XDG_STATE_HOME'    "$HOME/.local/state"
    'XDG_RUNTIME_DIR'   "/tmp/runtime-$USER"
)

# Core Environment Variables - Always set
# Use single quotes to defer $(tty) expansion until _env_setup_core() runs
ZSH_ENV_CORE=(
    'GPG_TTY'       '$(tty)'
)

export HOMEBREW_NO_ENV_HINTS=1

# Terminal configuration (non-SSH only)
typeset -gA ZSH_ENV_TERMINAL
ZSH_ENV_TERMINAL=(
    'LESS'                              "${LESS:--R -F -X -i -J -M -W -x4}"
    'LESSHISTFILE'                      '$XDG_STATE_HOME/less/history'
    'LESSKEY'                           '$XDG_CONFIG_HOME/less/keys'
    'LESS_TERMCAP_mb'                   $'\e[1;95m'     # begin bold - One Dark magenta
    'LESS_TERMCAP_md'                   $'\e[1;94m'     # begin blink - One Dark blue
    'LESS_TERMCAP_me'                   $'\e[0m'        # reset bold/blink
    'LESS_TERMCAP_so'                   $'\e[30;103m'   # begin reverse video - One Dark yellow bg
    'LESS_TERMCAP_se'                   $'\e[0m'        # reset reverse video
    'LESS_TERMCAP_us'                   $'\e[1;96m'     # begin underline - One Dark cyan
    'LESS_TERMCAP_ue'                   $'\e[0m'        # reset underline
)

# ----------------------------------------------------------
# HELPER FUNCTIONS
# Internal utilities for environment configuration.
# ----------------------------------------------------------

# Find first available editor from list
_env_find_first_available_editor() {
    local editors="$1"
    local editor

    for editor in $=editors; do
        # Use hash table lookup (instant) instead of command -v (subprocess)
        if (( $+commands[$editor] )); then
            echo "$editor"
            return 0
        fi
    done
    return 1
}

# Check if we have actual GUI capability (not just macOS)
_env_has_gui() {
    # SSH session - no GUI
    if _is_ssh_session; then
        return 1
    fi

    # X11 display available
    if [[ -n "${DISPLAY:-}" ]]; then
        return 0
    fi

    # macOS with WindowServer running (not headless)
    if _is_macos; then
        # Check if we're in a GUI session (Aqua)
        if [[ "${TERM_PROGRAM:-}" == "Apple_Terminal" || "${TERM_PROGRAM:-}" == "iTerm.app" || \
              "${TERM_PROGRAM:-}" == "vscode" || "${TERM_PROGRAM:-}" == "Hyper" || \
              "${TERM_PROGRAM:-}" == "WarpTerminal" || "${TERM_PROGRAM:-}" == "Alacritty" || \
              -n "${__CFBundleIdentifier:-}" ]]; then
            return 0
        fi
        # If we're on macOS and not in SSH, assume GUI is available
        # (removed pgrep WindowServer fallback - spawns slow subprocess)
        return 0
    fi

    # Wayland
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        return 0
    fi

    return 1
}

# Configure editor environment
_env_configure_editors() {
    _log "DEBUG" "Configuring editor environment..."
    local editor_cmd sudo_editor_cmd
    local gui_editor=$(_env_find_first_available_editor "$Z_GUI_EDITORS_ORDER")
    local term_editor=$(_env_find_first_available_editor "$Z_TERMINAL_EDITORS_ORDER")

    # Determine primary editor based on environment
    if _env_has_gui && [[ -n "$gui_editor" ]]; then
        # GUI environment with GUI editor available
        editor_cmd="$gui_editor"
    elif [[ -n "$term_editor" ]]; then
        # Terminal editor fallback
        editor_cmd="$term_editor"
    else
        # Ultimate fallback
        editor_cmd="vi"
    fi

    # SUDO_EDITOR must ALWAYS be a terminal editor (for visudo, sudoedit, etc.)
    # GUI editors don't work properly with sudo
    if [[ -n "$term_editor" ]]; then
        sudo_editor_cmd="$term_editor"
    else
        sudo_editor_cmd="vi"
    fi

    # Set editor variables if not already set
    [[ -z "$EDITOR" ]] && export EDITOR="$editor_cmd"
    [[ -z "$VISUAL" ]] && export VISUAL="$editor_cmd"

    # TERMINAL_EDITOR: always the preferred terminal editor for in-terminal editing
    if [[ -z "$TERMINAL_EDITOR" ]]; then
        if [[ -n "$term_editor" ]]; then
            export TERMINAL_EDITOR="$term_editor"
        else
            export TERMINAL_EDITOR="vi"
        fi
    fi
    # GIT_EDITOR needs --wait for GUI editors to ensure git waits for the editor to close
    if [[ -z "$GIT_EDITOR" ]]; then
        case "$gui_editor" in
            code|cursor|surf|subl|atom|mate)
                export GIT_EDITOR="$gui_editor --wait"
                ;;
            *)
                export GIT_EDITOR="$editor_cmd"
                ;;
        esac
    fi

    # SUDO_EDITOR: use existing value if set, otherwise use our determined value
    if [[ -z "$SUDO_EDITOR" ]]; then
        export SUDO_EDITOR="$sudo_editor_cmd"
    fi

    # ALTERNATE_EDITOR: fallback for tools like emacsclient
    if [[ -z "$ALTERNATE_EDITOR" ]]; then
        if [[ -n "$term_editor" ]]; then
            export ALTERNATE_EDITOR="$term_editor"
        else
            export ALTERNATE_EDITOR="vi"
        fi
    fi

    _log "DEBUG" "Editors configured: EDITOR='$EDITOR', VISUAL='$VISUAL', GIT_EDITOR='$GIT_EDITOR', SUDO_EDITOR='$SUDO_EDITOR', TERMINAL_EDITOR='$TERMINAL_EDITOR', ALTERNATE_EDITOR='$ALTERNATE_EDITOR'"
}


# Process XDG base directories
_env_setup_xdg_base() {
    _log "DEBUG" "Setting up XDG base directories..."

    local var value
    for var value in ${(kv)ZSH_ENV_XDG_BASE}; do
        # Respect existing values
        : ${(P)var::=$value}
        export $var
        _log "DEBUG" "$var=${(P)var}"
    done

    # Ensure XDG directories exist with correct permissions
    for dir in "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"; do
        _ensure_dir "$dir"
    done

    # XDG_RUNTIME_DIR needs special permissions (700)
    _ensure_dir "$XDG_RUNTIME_DIR" 700
}

# Process core environment variables
_env_setup_core() {
    _log "DEBUG" "Setting up core environment variables..."

    # Handle locale override (only if explicitly set)
    if [[ -n "$Z_LOCALE_OVERRIDE" ]]; then
        export LANG="$Z_LOCALE_OVERRIDE"
        export LC_ALL="$Z_LOCALE_OVERRIDE"
        _log "DEBUG" "Locale override: $Z_LOCALE_OVERRIDE"
    fi

    local var value expanded_value
    for var value in ${(kv)ZSH_ENV_CORE}; do
        # Expand command substitution at runtime (e.g., $(tty))
        expanded_value="${(e)value}"
        export "$var"="$expanded_value"
        _log "DEBUG" "$var=$expanded_value"
    done
}


# Process tool-specific environment variables
_env_setup_tools() {
    _log "DEBUG" "Setting up tool-specific environment variables..."

    if [[ "$Z_ENVIRONMENT_XDG_STRICT" != "true" ]]; then
        _log "INFO" "XDG strict mode disabled, skipping tool environment setup"
        return 0
    fi

    local category
    local var value_and_command
    local value command expanded_value

    # Process each tool category
    # Format: 'VAR_NAME' 'value|command' where | separates value from command
    # Using | instead of : allows values to contain colons (e.g., PATH-style vars)
    for category in ${ZSH_ENV_TOOL_CATEGORIES[@]}; do
        for var value_and_command in ${(kvP)category}; do
            value="${value_and_command%%|*}"
            command="${value_and_command#*|}"

            # Check if tool exists — clean up early-pass vars for missing tools
            if (( ! $+commands[$command] )); then
                [[ -n "${(P)var:-}" ]] && unset "$var"
                _log "DEBUG" "Skipping $var - command '$command' not in PATH"
                continue
            fi

            # Expand the value string using ZSH parameter expansion
            # Safer than eval but still expands $(...) command substitution
            # SECURITY: Values MUST come from registry files (lib/registry/*.zsh), NEVER user input
            # If value contains $(cmd), that command WILL execute
            expanded_value="${(e)value}"

            export "$var"="$expanded_value"
            _log "DEBUG" "Set $var=$expanded_value (for command: $command)"
        done
    done

    # Special handling for MAVEN_OPTS - append XDG settings, don't replace
    # User may have existing JVM options (heap size, GC settings, etc.)
    if (( $+commands[mvn] )); then
        local maven_xdg="-Dmaven.repo.local=$XDG_DATA_HOME/m2/repository"
        if [[ -n "${MAVEN_OPTS:-}" ]]; then
            # Only append if not already present
            if [[ "${MAVEN_OPTS:-}" != *"maven.repo.local"* ]]; then
                export MAVEN_OPTS="${MAVEN_OPTS:-} $maven_xdg"
                _log "DEBUG" "Appended XDG settings to existing MAVEN_OPTS"
            fi
        else
            export MAVEN_OPTS="$maven_xdg"
            _log "DEBUG" "Set MAVEN_OPTS=$maven_xdg"
        fi
    fi

    # Config files that cause errors when they don't exist
    # Data comes from Z_ENV_CONFIG_FILE_CHECKS (populated by registry files)
    # Format: 'VAR' 'path|command' — only set if file exists AND command installed
    local config_file config_var config_val_cmd config_path config_cmd
    for config_var config_val_cmd in ${(kv)Z_ENV_CONFIG_FILE_CHECKS}; do
        config_path="${config_val_cmd%%|*}"
        config_cmd="${config_val_cmd#*|}"
        config_file="${(e)config_path}"

        if (( $+commands[$config_cmd] )) && [[ -f "$config_file" ]]; then
            export "$config_var"="$config_file"
            _log "DEBUG" "Set $config_var=$config_file (config file exists)"
        else
            unset "$config_var"
            _log "DEBUG" "Skipping $config_var - file missing or command '$config_cmd' not found"
        fi
    done
}

# Setup terminal configuration
_env_setup_terminal() {
    _log "DEBUG" "Setting up terminal environment..."
    if _is_ssh_session && [[ "$Z_ENVIRONMENT_SSH_MINIMAL" == "true" ]]; then
        _log "INFO" "Minimal SSH session, skipping terminal environment setup"
        return 0
    fi

    local var value expanded_value
    for var value in ${(kv)ZSH_ENV_TERMINAL}; do
        # Expand the value string using ZSH parameter expansion
        # Safer than eval - prevents shell injection
        expanded_value="${(e)value}"

        export "$var"="$expanded_value"
        _log "DEBUG" "Set $var=\"$expanded_value\""
    done

    # Create required directories
    _ensure_dir "$XDG_STATE_HOME/less"
    _ensure_dir "$XDG_CONFIG_HOME/less"

    # Bat configuration if available
    if _has_cmd bat; then
        export BAT_THEME="${BAT_THEME:-OneHalfDark}"
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"
        export MANROFFOPT="-c"
        _log "DEBUG" "Configured bat as MANPAGER"
    fi
}

# ----------------------------------------------------------
# MAIN INITIALIZATION
# Entry point that orchestrates all environment setup.
# ----------------------------------------------------------

_environment_init() {
    # Execute pre-init hooks
    local hook
    for hook in ${Z_PRE_ENV_INIT_HOOKS[@]}; do
        if (( $+functions[$hook] )); then
            _log "DEBUG" "Running pre-init hook: $hook"
            $hook
        fi
    done

    _log "INFO" "Initializing ZSH Environment Module..."

    # Detect SSH session
    if [[ "$Z_ENVIRONMENT_SSH_MINIMAL" == "true" ]] && _is_ssh_session; then
        Z_ENVIRONMENT_IS_SSH=true
        _log "INFO" "SSH session detected, using minimal environment"
    else
        Z_ENVIRONMENT_IS_SSH=false
    fi

    # Setup XDG base directories
    _env_setup_xdg_base

    # Setup core environment
    _env_setup_core

    # Setup tool-specific environment
    _env_setup_tools

    # Setup terminal configuration (non-SSH only)
    if [[ "$Z_ENVIRONMENT_IS_SSH" != "true" ]]; then
        _env_setup_terminal
    fi

    # ----------------------------------------------------------
    # SSH AGENT DETECTION
    # Auto-detect SSH agent socket from 1Password, GPG, GNOME Keyring, etc.
    # Set Z_ENVIRONMENT_SSH_AGENT=false to disable and manage manually.
    # ----------------------------------------------------------

    if [[ "$Z_ENVIRONMENT_SSH_AGENT" == "true" ]]; then
        if typeset -f _detect_ssh_agent >/dev/null 2>&1; then
            _detect_ssh_agent
            _log "DEBUG" "SSH agent detection completed"
        else
            _log "DEBUG" "_detect_ssh_agent not available, skipping"
        fi
    fi

    # Configure editors (PATH is now available for editor detection)
    _env_configure_editors

    _log "INFO" "ZSH Environment Module initialized successfully"

    # Execute post-init hooks
    for hook in ${Z_POST_ENV_INIT_HOOKS[@]}; do
        if (( $+functions[$hook] )); then
            _log "DEBUG" "Running post-init hook: $hook"
            $hook
        fi
    done
}

# ----------------------------------------------------------
# PUBLIC FUNCTIONS
# User-facing commands for environment management.
# ----------------------------------------------------------

# Show all managed environment variables
z_env_show() {
    # This function is monolithic to avoid bugs from passing arrays between functions.

    # --- Color Setup ---
    local color_key color_value color_header color_reset
    if [[ -t 1 ]]; then
        color_key=$'\e[1;32m'    # Green
        color_value=$'\e[0m'     # Reset
        color_header=$'\e[1;34m' # Blue
        color_reset=$'\e[0m'
    fi

    # --- Data Collection & Padding Calculation ---
    typeset -A all_vars
    local -a managed_var_names
    local max_len=0

    # Helper to add a variable to the display list
    _add_to_display() {
        local category="$1" var="$2"
        if (( ${+parameters[$var]} )); then
            all_vars[$category:$var]="${(P)var}"
            managed_var_names+=("$var")
            if (( ${#var} > max_len )); then
                max_len=${#var}
            fi
        fi
    }

    # 1. XDG Base Directories
    for var in ${(k)ZSH_ENV_XDG_BASE}; do _add_to_display "01_XDG" "$var"; done

    # 2. ZSH Base Directories and Variables
    for var in 'ZDOTDIR' 'ZSH_CACHE_HOME' 'ZSH_CONFIG_HOME' 'ZSH_DATA_HOME' 'ZSH_STATE_HOME'; do
        _add_to_display "02_ZSH_Base" "$var"
    done

    # 3. ZSH Tool Variables (from ZSH_ENV_TOOLS_ZSH)
    for var val in ${(kv)ZSH_ENV_TOOLS_ZSH}; do
        _add_to_display "03_ZSH_Variables" "$var"
    done

    # 4. Core Environment
    for var in ${(k)ZSH_ENV_CORE}; do _add_to_display "04_Core" "$var"; done

    # 5. Editor Variables
    for var in 'EDITOR' 'VISUAL' 'GIT_EDITOR' 'SUDO_EDITOR' 'TERMINAL_EDITOR' 'ALTERNATE_EDITOR'; do _add_to_display "05_Editor" "$var"; done

    # 6. Terminal Environment
    for var in ${(k)ZSH_ENV_TERMINAL}; do _add_to_display "06_Terminal" "$var"; done

    # 7. Tool Categories (excluding ZSH which we handled above)
    local category_name
    for category in ${ZSH_ENV_TOOL_CATEGORIES[@]}; do
        if [[ "$category" != "ZSH_ENV_TOOLS_ZSH" ]]; then
            category_name="${category#ZSH_ENV_TOOLS_}"
            for var val in ${(kvP)category}; do
                _add_to_display "07_Tool_${category_name}" "$var"
            done
        fi
    done

    # 8. Collect "other" variables, grouped by prefix
    typeset -A other_vars_by_prefix
    for var in ${(k)parameters[(R)export]}; do
        if [[ ${managed_var_names[(Ie)$var]} -eq 0 ]]; then
            local prefix=${var%%_*}
            # Skip single-character variables and special shell variables
            if [[ ${#prefix} -gt 1 && "$var" != "_" && "$var" != "PS"* && "$var" != "PROMPT"* ]]; then
                other_vars_by_prefix[${prefix}]+="$var "
                all_vars[08_Other_${prefix}:$var]="${(P)var}"
                if (( ${#var} > max_len )); then
                    max_len=${#var}
                fi
            fi
        fi
    done

    # --- Printing ---
    local last_category=""
    # Sort by the prefixed key
    for key in ${(ko)all_vars}; do
        local category="${key%%:*}"
        local var="${key#*:}"
        local val="${all_vars[$key]}"

        if [[ "$category" != "$last_category" ]]; then
            local header_name="${category#[0-9][0-9]_}"
            if [[ "$header_name" == "XDG" ]]; then
                header_name="XDG Base Directories"
            elif [[ "$header_name" == "ZSH" ]]; then
                header_name="ZSH Base Directories"
            elif [[ "$header_name" == "ZSH Variables" ]]; then
                header_name="ZSH Variables"
            elif [[ "$header_name" == "Core" ]]; then
                header_name="Core Environment"
            elif [[ "$header_name" == "Editor" ]]; then
                header_name="Editor Variables"
            elif [[ "$header_name" == "Terminal" ]]; then
                header_name="Terminal Environment"
            elif [[ "$header_name" == Tool_* ]]; then
                local tool_name="${header_name#Tool_}"
                case "$tool_name" in
                    JS) header_name="JavaScript Ecosystem" ;;
                    GO) header_name="Go Environment" ;;
                    PYTHON) header_name="Python Environment" ;;
                    DOCKER) header_name="Docker Environment" ;;
                    K8S) header_name="Kubernetes Environment" ;;
                    JVM) header_name="JVM Environment" ;;
                    ANSIBLE) header_name="Ansible Environment" ;;
                    CLOUD) header_name="Cloud SDKs" ;;
                    IAC) header_name="Infrastructure as Code" ;;
                    DB) header_name="Database Tools" ;;
                    VIRT) header_name="Virtualization & Containers" ;;
                    SECURITY) header_name="Security Tools" ;;
                    BUILD) header_name="Build Tools" ;;
                    LANGS) header_name="Misc Languages" ;;
                    RUBY) header_name="Ruby Environment" ;;
                    RUST) header_name="Rust Environment" ;;
                    GENERAL) header_name="General Tools" ;;
                    *) header_name="${tool_name} Environment" ;;
                esac
            elif [[ "$header_name" == Other_* ]]; then
                local prefix="${header_name#Other_}"
                # Count variables with this prefix
                local count=$(echo ${other_vars_by_prefix[$prefix]} | wc -w | tr -d ' ')
                header_name="Other Variables - ${prefix} (${count} variables)"
            fi

            if [[ -n "$last_category" ]]; then echo ""; fi
            echo "${color_header}--- ${header_name} ---${color_reset}"
            last_category="$category"
        fi

        local padding=$(( max_len - ${#var} ))
        printf "%s%s%*s = %s%s%s\n" "$color_key" "$var" "$padding" "" "$color_value" "$val" "$color_reset"
    done

    # Print summary
    echo ""
    echo "${color_header}--- Summary ---${color_reset}"
    echo "Total managed variables: ${#managed_var_names[@]}"
    echo "Total exported variables: $(export | wc -l | tr -d ' ')"
}

# Check installation status of configured tools
# Derives tool list from registry data (ZSH_ENV_TOOL_CATEGORIES)
z_env_status() {
    echo "=== Tool Installation Status ==="
    echo ""

    local -A seen_commands
    local category var value_and_command command

    for category in ${ZSH_ENV_TOOL_CATEGORIES[@]}; do
        for var value_and_command in ${(kvP)category}; do
            command="${value_and_command#*|}"
            # Skip duplicates (many vars share the same command)
            (( ${+seen_commands[$command]} )) && continue
            seen_commands[$command]=1

            if _has_cmd "$command"; then
                echo "  ✓ $command"
            else
                echo "  ✗ $command"
            fi
        done
    done
}

# Reload the environment module
z_env_reload() {
    echo "Reloading environment module..."
    local script_path="$(_resolve_module_path modules/02_environment.zsh)"

    if [[ -f "$script_path" ]]; then
        unset _Z_ENVIRONMENT_LOADED
        source "$script_path"
        _ui_ok "Environment module reloaded"
    else
        echo "✗ Could not find environment.zsh at: $script_path" >&2
        return 1
    fi
}

# ----------------------------------------------------------
# SHELL TOOL INITIALIZATION
# Tools that hook into the shell (direnv, atuin).
# Keybindings are handled by keybindings.zsh module.
# ----------------------------------------------------------

# direnv - Environment switcher (interactive only, uses precmd hook)
if _is_interactive && _has_cmd direnv; then
    _cache_eval "direnv-hook" "direnv hook zsh" "direnv"
    _log "DEBUG" "direnv hook initialized"
fi

# atuin - Better shell history (interactive only, registers ZLE widgets)
if _is_interactive && _has_cmd atuin; then
    _cache_eval "atuin-init" "atuin init zsh --disable-up-arrow" "atuin"
    _log "DEBUG" "atuin widgets loaded (keybindings in keybindings.zsh)"
fi

# ----------------------------------------------------------
# STARSHIP PROMPT (DEFERRED)
# Must run in .zshrc AFTER /etc/zshrc which overwrites PROMPT.
# Registered as POST_INTERACTIVE hook, executed by .zshrc.
# ----------------------------------------------------------

_env_init_starship() {
    if _has_cmd starship; then
        # Starship config at ~/.config/starship.toml (standard location)
        # Copied from tools/starship.toml during installation
        _cache_eval "starship-init" "starship init zsh" "starship"
        _log "DEBUG" "starship prompt initialized"
    fi
}

# Register starship for deferred execution (after /etc/zshrc)
Z_POST_INTERACTIVE_HOOKS+=('_env_init_starship')

# ----------------------------------------------------------
# MODULE INITIALIZATION
# ----------------------------------------------------------

_environment_init

_log DEBUG "ZSH Environment Module loaded successfully"
