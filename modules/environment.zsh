#!/usr/bin/env zsh
# ==============================================================================
# * ZSH ENVIRONMENT MODULE
# ? Comprehensive environment variable management with XDG support.
# ? Handles XDG base directories, tool-specific paths, and editor configuration.
# ==============================================================================

# ----------------------------------------------------------
# * MODULE CONFIGURATION
# ----------------------------------------------------------

# Idempotent guard - prevent multiple loads
(( ${+_ZSH_ENVIRONMENT_LOADED} )) && return 0
typeset -g _ZSH_ENVIRONMENT_LOADED=1

_log DEBUG "ZSH Environment Module loading"

# Module hooks
typeset -ga ZSH_PRE_ENV_INIT_HOOKS=()
typeset -ga ZSH_POST_ENV_INIT_HOOKS=()

# Configuration variables with defaults
# These can be overridden by exporting them in .zshenv before sourcing this module
: ${ZSH_ENVIRONMENT_ENABLED:=true}      # Enable/disable environment system (default: true)
: ${ZSH_ENVIRONMENT_XDG_STRICT:=true}   # Enforce XDG directories for all tools (default: true)
: ${ZSH_ENVIRONMENT_SSH_MINIMAL:=true}  # Use minimal environment in SSH sessions (default: true)
: ${ZSH_ENVIRONMENT_SSH_AGENT:=true}    # Auto-detect SSH agent socket (default: true)
: ${ZSH_LOCALE_OVERRIDE:=""}            # Override system locale (default: empty = use system)

# Editor preferences - can be overridden in .zshenv
: ${ZSH_GUI_EDITORS_ORDER:="surf cursor code"}
: ${ZSH_TERMINAL_EDITORS_ORDER:="nvim vim vi"}

# Exit early if module is disabled
[[ "$ZSH_ENVIRONMENT_ENABLED" != "true" ]] && return 0

# ----------------------------------------------------------
# * DATA-DRIVEN ENVIRONMENT CONFIGURATION
# ? Declarative definitions using format: 'VAR' 'value|command'
# ----------------------------------------------------------

# Global associative arrays for environment definitions
typeset -gA ZSH_ENV_XDG_BASE
typeset -gA ZSH_ENV_CORE

# Categorized tool environment variables
typeset -gA ZSH_ENV_TOOLS_JS       # JavaScript Ecosystem
typeset -gA ZSH_ENV_TOOLS_GO       # Go
typeset -gA ZSH_ENV_TOOLS_PYTHON   # Python
typeset -gA ZSH_ENV_TOOLS_DOCKER   # Docker
typeset -gA ZSH_ENV_TOOLS_K8S      # Kubernetes
typeset -gA ZSH_ENV_TOOLS_JVM      # JVM
typeset -gA ZSH_ENV_TOOLS_ANSIBLE   # Ansible
typeset -gA ZSH_ENV_TOOLS_CLOUD     # Cloud SDKs
typeset -gA ZSH_ENV_TOOLS_IAC       # Infrastructure as Code
typeset -gA ZSH_ENV_TOOLS_DB        # Databases
typeset -gA ZSH_ENV_TOOLS_VIRT      # Virtualization & Containers
typeset -gA ZSH_ENV_TOOLS_SECURITY  # Security
typeset -gA ZSH_ENV_TOOLS_BUILD     # Build Tools
typeset -gA ZSH_ENV_TOOLS_LANGS     # Misc Languages
typeset -gA ZSH_ENV_TOOLS_GENERAL  # General Tools
typeset -gA ZSH_ENV_TOOLS_ZSH       # ZSH

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
ZSH_ENV_XDG_BASE=(
    'XDG_CONFIG_HOME'   "$HOME/.config"
    'XDG_CACHE_HOME'    "$HOME/.cache"
    'XDG_DATA_HOME'     "$HOME/.local/share"
    'XDG_STATE_HOME'    "$HOME/.local/state"
    'XDG_RUNTIME_DIR'   "/tmp/runtime-$USER"
)

# Core Environment Variables - Always set
ZSH_ENV_CORE=(
    'GPG_TTY'       "$(tty)"
)

# ZSH
ZSH_ENV_TOOLS_ZSH=(
    # HISTFILE is set in history.zsh
    # ZSH_COMPDUMP is set in completion.zsh
    'ZSH_AUTOSUGGEST_HISTORY_FILE'  '$XDG_STATE_HOME/zsh/autosuggestions.history|zsh'
)

export HOMEBREW_NO_ENV_HINTS=1

# JavaScript Ecosystem
ZSH_ENV_TOOLS_JS=(
    'VOLTA_HOME'                '$XDG_DATA_HOME/volta|volta'
    'NPM_CONFIG_USERCONFIG'     '$XDG_CONFIG_HOME/npm/npmrc|npm'
    'NPM_CONFIG_CACHE'          '$XDG_CACHE_HOME/npm|npm'
    'NPM_CONFIG_INIT_MODULE'    '$XDG_CONFIG_HOME/npm/npm-init.js|npm'
    'YARN_CACHE_FOLDER'         '$XDG_CACHE_HOME/yarn|yarn'
    'YARN_CONFIG_FILE'          '$XDG_CONFIG_HOME/yarn/config|yarn'
    'YARN_ENABLE_GLOBAL_CACHE'  'false|yarn'
    'PNPM_HOME'                 '$XDG_DATA_HOME/pnpm|pnpm'
    'PNPM_STATE_DIR'            '$XDG_STATE_HOME/pnpm|pnpm'
    'PNPM_CACHE_DIR'            '$XDG_CACHE_HOME/pnpm|pnpm'
    'NODE_REPL_HISTORY'         '$XDG_STATE_HOME/node_repl_history|node'
    'NODE_ENV'                  'development|node'
    'TS_NODE_HISTORY'           '$XDG_STATE_HOME/ts_node_repl_history|ts-node'
    'NVM_DIR'                   '$XDG_DATA_HOME/nvm|nvm'
    'FNM_DIR'                   '$XDG_DATA_HOME/fnm|fnm'
    'N_PREFIX'                  '$XDG_DATA_HOME/n|n'
    'BUN_INSTALL'               '$XDG_DATA_HOME/bun|bun'
)

# Go
ZSH_ENV_TOOLS_GO=(
    'GOPATH'        '$XDG_DATA_HOME/go|go'
    'GOCACHE'       '$XDG_CACHE_HOME/go|go'
    'GOMODCACHE'    '$XDG_CACHE_HOME/go-mod|go'
)

# Python
ZSH_ENV_TOOLS_PYTHON=(
    'PYTHONSTARTUP'      '$XDG_CONFIG_HOME/python/python_startup.py|python'
    'PYTHON_HISTORY'     '$XDG_STATE_HOME/python_history|python'
    'PIP_CACHE_DIR'      '$XDG_CACHE_HOME/pip|pip'
    'PIPENV_CACHE_DIR'   '$XDG_CACHE_HOME/pipenv|pipenv'
    'POETRY_HOME'        '$XDG_DATA_HOME/poetry|poetry'
    'POETRY_CACHE_DIR'   '$XDG_CACHE_HOME/poetry|poetry'
    'PYENV_ROOT'         '$XDG_DATA_HOME/pyenv|pyenv'
    'WORKON_HOME'        '$XDG_DATA_HOME/virtualenvs|virtualenv'
    'VIRTUALENV_CONFIG_FILE' '$XDG_CONFIG_HOME/virtualenv/virtualenv.ini|virtualenv'
    'JUPYTER_RUNTIME_DIR' '$XDG_RUNTIME_DIR/jupyter|jupyter'
    'IPYTHONDIR'         '$XDG_CONFIG_HOME/ipython|ipython'
)

# Docker
ZSH_ENV_TOOLS_DOCKER=(
    'DOCKER_CONFIG' '$XDG_CONFIG_HOME/docker|docker'
)

# Kubernetes
ZSH_ENV_TOOLS_K8S=(
    'KUBECONFIG'    '$XDG_CONFIG_HOME/kube/config|kubectl'
)

# JVM
ZSH_ENV_TOOLS_JVM=(
    'GRADLE_USER_HOME'    '$XDG_DATA_HOME/gradle|gradle'
    'M2_HOME'             '$XDG_DATA_HOME/m2|mvn'
    '_JAVA_OPTIONS'       '-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java|java'
    'LEIN_HOME'           '$XDG_DATA_HOME/lein|lein'
    'BOOT_HOME'           '$XDG_DATA_HOME/boot|boot'
    'BOOT_LOCAL_REPO'     '$XDG_CACHE_HOME/boot|boot'
)

# Ansible
ZSH_ENV_TOOLS_ANSIBLE=(
    'ANSIBLE_CONFIG'    '$XDG_CONFIG_HOME/ansible/ansible.cfg|ansible'
    'ANSIBLE_HOME'      '$XDG_DATA_HOME/ansible|ansible'
)

# Cloud SDKs
ZSH_ENV_TOOLS_CLOUD=(
    'AWS_CONFIG_FILE'             '$XDG_CONFIG_HOME/aws/config|aws'
    'AWS_SHARED_CREDENTIALS_FILE' '$XDG_CONFIG_HOME/aws/credentials|aws'
    'AWS_CLI_HISTORY_FILE'        '$XDG_STATE_HOME/aws_history|aws'
    'BOTO_CONFIG'                 '$XDG_CONFIG_HOME/boto/config|boto'
    'CLOUDSDK_CONFIG'             '$XDG_CONFIG_HOME/gcloud|gcloud'
    'CLOUDSDK_ACTIVE_CONFIG_NAME' 'default|gcloud'
    'AZURE_CONFIG_DIR'            '$XDG_CONFIG_HOME/azure|az'
    'DIGITALOCEAN_CONFIG'         '$XDG_CONFIG_HOME/doctl/config.yaml|doctl'
    'OCI_CLI_CONFIG_FILE'         '$XDG_CONFIG_HOME/oci/config|oci'
    'IBMCLOUD_HOME'               '$XDG_CONFIG_HOME/ibmcloud|ibmcloud'
)

# Infrastructure as Code
ZSH_ENV_TOOLS_IAC=(
    'TF_DATA_DIR'         '$XDG_DATA_HOME/terraform|terraform'
    'TF_CLI_CONFIG_FILE'  '$XDG_CONFIG_HOME/terraform/terraformrc|terraform'
    'TERRAFORM_CONFIG'    '$XDG_CONFIG_HOME/terraform|terraform'
    'TERRAGRUNT_CONFIG'   '$XDG_CONFIG_HOME/terragrunt|terragrunt'
    'TERRAGRUNT_CACHE'    '$XDG_CACHE_HOME/terragrunt|terragrunt'
    'HELM_CONFIG_HOME'    '$XDG_CONFIG_HOME/helm|helm'
    'HELM_CACHE_HOME'     '$XDG_CACHE_HOME/helm|helm'
    'HELM_DATA_HOME'      '$XDG_DATA_HOME/helm|helm'
    'KUSTOMIZE_PLUGIN_HOME' '$XDG_DATA_HOME/kustomize/plugins|kustomize'
    'PULUMI_HOME'         '$XDG_DATA_HOME/pulumi|pulumi'
    'PULUMI_CONFIG_PASSPHRASE_FILE' '$XDG_CONFIG_HOME/pulumi/passphrase|pulumi'
)

# Databases
ZSH_ENV_TOOLS_DB=(
    'PSQL_HISTORY'        '$XDG_STATE_HOME/psql_history|psql'
    'PSQLRC'              '$XDG_CONFIG_HOME/pg/psqlrc|psql'
    'PGPASSFILE'          '$XDG_CONFIG_HOME/pg/pgpass|psql'
    'PGSERVICEFILE'       '$XDG_CONFIG_HOME/pg/pg_service.conf|psql'
    'MYSQL_HISTFILE'      '$XDG_STATE_HOME/mysql_history|mysql'
    'MYCLI_HISTFILE'      '$XDG_STATE_HOME/mycli_history|mycli'
    'REDISCLI_HISTFILE'   '$XDG_STATE_HOME/redis_history|redis-cli'
    'REDISCLI_RCFILE'     '$XDG_CONFIG_HOME/redis/redisclirc|redis-cli'
    'SQLITE_HISTORY'      '$XDG_STATE_HOME/sqlite_history|sqlite3'
    'MONGOSH_HOME'        '$XDG_CONFIG_HOME/mongosh|mongosh'
    'INFLUX_CLI_CONFIG'   '$XDG_CONFIG_HOME/influxdb/influx-cli.conf|influx'
)

# Virtualization & Containers
ZSH_ENV_TOOLS_VIRT=(
    'VAGRANT_HOME'  '$XDG_DATA_HOME/vagrant|vagrant'
    'MINIKUBE_HOME' '$XDG_DATA_HOME/minikube|minikube'
)

# Security
ZSH_ENV_TOOLS_SECURITY=(
    'GNUPGHOME'           '$XDG_DATA_HOME/gnupg|gpg'
    'PASSWORD_STORE_DIR'  '$XDG_DATA_HOME/pass|pass'
    'GOPASS_CONFIG'       '$XDG_CONFIG_HOME/gopass/config.yml|gopass'
    'GOPASS_HOMEDIR'      '$XDG_DATA_HOME/gopass|gopass'
)

# Build Tools
ZSH_ENV_TOOLS_BUILD=(
    'CCACHE_DIR'         '$XDG_CACHE_HOME/ccache|ccache'
    'CCACHE_CONFIGPATH'  '$XDG_CONFIG_HOME/ccache/config|ccache'
    'CMAKE_CONFIG_DIR'   '$XDG_CONFIG_HOME/cmake|cmake'
    'CMAKE_CACHE_DIR'    '$XDG_CACHE_HOME/cmake|cmake'
    'PKG_CONFIG_PATH'    '$XDG_DATA_HOME/pkgconfig:$XDG_DATA_HOME/lib/pkgconfig|pkg-config'
)

# Misc Languages
ZSH_ENV_TOOLS_LANGS=(
    'NUGET_PACKAGES'      '$XDG_CACHE_HOME/nuget/packages|dotnet'
    'DOTNET_CLI_HOME'     '$XDG_DATA_HOME/dotnet|dotnet'
    'ELM_HOME'            '$XDG_DATA_HOME/elm|elm'
    'DENO_DIR'            '$XDG_CACHE_HOME/deno|deno'
    'JULIA_DEPOT_PATH'    '$XDG_DATA_HOME/julia|julia'
    'JULIA_HISTORY'       '$XDG_STATE_HOME/julia_history|julia'
    'R_ENVIRON_USER'      '$XDG_CONFIG_HOME/R/Renviron|R'
    'R_PROFILE_USER'      '$XDG_CONFIG_HOME/R/Rprofile|R'
    'R_MAKEVARS_USER'     '$XDG_CONFIG_HOME/R/Makevars|R'
    'R_HISTFILE'          '$XDG_STATE_HOME/Rhistory|R'
    'GHCUP_USE_XDG_DIRS'  'true|ghcup'
    'STACK_ROOT'          '$XDG_DATA_HOME/stack|stack'
    'CABAL_CONFIG'        '$XDG_CONFIG_HOME/cabal/config|cabal'
    'CABAL_DIR'           '$XDG_DATA_HOME/cabal|cabal'
)

# General Tools
ZSH_ENV_TOOLS_GENERAL=(
    'CARGO_HOME'          '$XDG_DATA_HOME/cargo|cargo'
    'RUSTUP_HOME'         '$XDG_DATA_HOME/rustup|rustup'
    'GEM_HOME'            '$XDG_DATA_HOME/gem|gem'
    'GEM_SPEC_CACHE'      '$XDG_CACHE_HOME/gem|gem'
    'BUNDLE_USER_CONFIG'  '$XDG_CONFIG_HOME/bundle|bundle'
    'BUNDLE_USER_CACHE'   '$XDG_CACHE_HOME/bundle|bundle'
    'BUNDLE_USER_PLUGIN'  '$XDG_DATA_HOME/bundle|bundle'
    'JUPYTER_CONFIG_DIR'  '$XDG_CONFIG_HOME/jupyter|jupyter'
    # INPUTRC and WGETRC are handled separately in _env_setup_tools()
    'CURL_HOME'           '$XDG_CONFIG_HOME/curl|curl'
    'COMPOSER_HOME'       '$XDG_CONFIG_HOME/composer|composer'
    'COMPOSER_CACHE_DIR'  '$XDG_CACHE_HOME/composer|composer'
    'HTOPRC'              '$XDG_CONFIG_HOME/htop/htoprc|htop'
    'TMUX_TMPDIR'         '$XDG_RUNTIME_DIR/tmux|tmux'
    'SCREENRC'            '$XDG_CONFIG_HOME/screen/screenrc|screen'
    'PARALLEL_HOME'       '$XDG_CONFIG_HOME/parallel|parallel'
    # ? Config files that must exist are handled separately in _env_setup_tools()
    # ? RIPGREP_CONFIG_PATH, BAT_CONFIG_PATH, WGETRC, INPUTRC
    # ? FZF_DEFAULT_OPTS_FILE causes errors if file doesn't exist
    # ? Better to set FZF_DEFAULT_OPTS directly in shell config
)

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
# * HELPER FUNCTIONS
# ? Internal utilities for environment configuration.
# ----------------------------------------------------------

# Check if we're in an SSH session (uses utils library)
_env_is_ssh_session() {
    _is_ssh_session
}

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
    if _is_not_empty "$DISPLAY"; then
        return 0
    fi

    # macOS with WindowServer running (not headless)
    if _is_macos; then
        # Check if we're in a GUI session (Aqua)
        if [[ "$TERM_PROGRAM" == "Apple_Terminal" || "$TERM_PROGRAM" == "iTerm.app" || \
              "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "Hyper" || \
              "$TERM_PROGRAM" == "WarpTerminal" || "$TERM_PROGRAM" == "Alacritty" || \
              -n "$__CFBundleIdentifier" ]]; then
            return 0
        fi
        # ? If we're on macOS and not in SSH, assume GUI is available
        # ? (removed pgrep WindowServer fallback - spawns slow subprocess)
        return 0
    fi

    # Wayland
    if _is_not_empty "$WAYLAND_DISPLAY"; then
        return 0
    fi

    return 1
}

# Configure editor environment
_env_configure_editors() {
    _log "DEBUG" "Configuring editor environment..."
    local editor_cmd sudo_editor_cmd
    local gui_editor=$(_env_find_first_available_editor "$ZSH_GUI_EDITORS_ORDER")
    local term_editor=$(_env_find_first_available_editor "$ZSH_TERMINAL_EDITORS_ORDER")

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
    if [[ -n "$ZSH_LOCALE_OVERRIDE" ]]; then
        export LANG="$ZSH_LOCALE_OVERRIDE"
        export LC_ALL="$ZSH_LOCALE_OVERRIDE"
        _log "DEBUG" "Locale override: $ZSH_LOCALE_OVERRIDE"
    fi

    local var value
    for var value in ${(kv)ZSH_ENV_CORE}; do
        export "$var"="$value"
        _log "DEBUG" "$var=${(P)var}"
    done
}


# Process tool-specific environment variables
_env_setup_tools() {
    _log "DEBUG" "Setting up tool-specific environment variables..."

    if [[ "$ZSH_ENVIRONMENT_XDG_STRICT" != "true" ]]; then
        _log "INFO" "XDG strict mode disabled, skipping tool environment setup"
        return 0
    fi

    local category
    local var value_and_command
    local value command expanded_value

    # Process each tool category
    # ? Format: 'VAR_NAME' 'value|command' where | separates value from command
    # ? Using | instead of : allows values to contain colons (e.g., PATH-style vars)
    for category in ${ZSH_ENV_TOOL_CATEGORIES[@]}; do
        for var value_and_command in ${(kvP)category}; do
            value="${value_and_command%%|*}"
            command="${value_and_command#*|}"

            # Check if tool exists BEFORE setting env var (PATH is now available)
            if (( ! $+commands[$command] )); then
                _log "DEBUG" "Skipping $var - command '$command' not in PATH"
                continue
            fi

            # Expand the value string using ZSH parameter expansion
            # ? Safer than eval but still expands $(...) command substitution
            # ! SECURITY: Values MUST come from hardcoded arrays, NEVER user input
            # ! If value contains $(cmd), that command WILL execute
            expanded_value="${(e)value}"

            export "$var"="$expanded_value"
            _log "DEBUG" "Set $var=$expanded_value (for command: $command)"
        done
    done

    # Special handling for HISTFILE - only set for bash
    if [[ -n "$BASH_VERSION" ]] && [[ "$ZSH_ENVIRONMENT_XDG_STRICT" == "true" ]]; then
        export HISTFILE="$XDG_STATE_HOME/bash/history"
    fi

    # ! Special handling for MAVEN_OPTS - append XDG settings, don't replace
    # ? User may have existing JVM options (heap size, GC settings, etc.)
    if (( $+commands[mvn] )); then
        local maven_xdg="-Dmaven.repo.local=$XDG_DATA_HOME/m2/repository"
        if [[ -n "$MAVEN_OPTS" ]]; then
            # Only append if not already present
            if [[ "$MAVEN_OPTS" != *"maven.repo.local"* ]]; then
                export MAVEN_OPTS="$MAVEN_OPTS $maven_xdg"
                _log "DEBUG" "Appended XDG settings to existing MAVEN_OPTS"
            fi
        else
            export MAVEN_OPTS="$maven_xdg"
            _log "DEBUG" "Set MAVEN_OPTS=$maven_xdg"
        fi
    fi

    # Special handling for config files that cause errors when they don't exist
    # These will be checked and only set if the files actually exist
    local config_file
    local config_files_to_check=(
        "RIPGREP_CONFIG_PATH:$XDG_CONFIG_HOME/ripgrep/config"
        "BAT_CONFIG_PATH:$XDG_CONFIG_HOME/bat/config"
        "WGETRC:$XDG_CONFIG_HOME/wgetrc"
        "INPUTRC:$XDG_CONFIG_HOME/readline/inputrc"
    )

    for entry in "${config_files_to_check[@]}"; do
        local var="${entry%%:*}"
        config_file="${entry#*:}"
        config_file="${(e)config_file}"  # Expand variables (safer than eval)

        if [[ -f "$config_file" ]]; then
            export "$var"="$config_file"
            _log "DEBUG" "Set $var=$config_file (config file exists)"
        else
            unset "$var"  # Unset if it was set earlier
            _log "DEBUG" "Skipping $var - config file does not exist at $config_file"
        fi
    done
}

# Setup terminal configuration
_env_setup_terminal() {
    _log "DEBUG" "Setting up terminal environment..."
    if _env_is_ssh_session && [[ "$ZSH_ENVIRONMENT_SSH_MINIMAL" == "true" ]]; then
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
# * MAIN INITIALIZATION
# ? Entry point that orchestrates all environment setup.
# ----------------------------------------------------------

_environment_init() {
    # Execute pre-init hooks
    local hook
    for hook in ${ZSH_PRE_ENV_INIT_HOOKS[@]}; do
        if (( $+functions[$hook] )); then
            _log "DEBUG" "Running pre-init hook: $hook"
            $hook
        fi
    done

    _log "INFO" "Initializing ZSH Environment Module..."

    # Detect SSH session
    if [[ "$ZSH_ENVIRONMENT_SSH_MINIMAL" == "true" ]] && _env_is_ssh_session; then
        ZSH_ENVIRONMENT_IS_SSH=true
        _log "INFO" "SSH session detected, using minimal environment"
    else
        ZSH_ENVIRONMENT_IS_SSH=false
    fi

    # Setup XDG base directories
    _env_setup_xdg_base

    # Setup core environment
    _env_setup_core

    # Setup tool-specific environment
    _env_setup_tools

    # Setup terminal configuration (non-SSH only)
    if [[ "$ZSH_ENVIRONMENT_IS_SSH" != "true" ]]; then
        _env_setup_terminal
    fi

    # ----------------------------------------------------------
    # * SSH AGENT DETECTION
    # ? Auto-detect SSH agent socket from 1Password, GPG, GNOME Keyring, etc.
    # ? Set ZSH_ENVIRONMENT_SSH_AGENT=false to disable and manage manually.
    # ----------------------------------------------------------

    if [[ "$ZSH_ENVIRONMENT_SSH_AGENT" == "true" ]]; then
        if typeset -f zsh_detect_ssh_agent >/dev/null 2>&1; then
            zsh_detect_ssh_agent
            _log "DEBUG" "SSH agent detection completed"
        else
            _log "DEBUG" "zsh_detect_ssh_agent not available, skipping"
        fi
    fi

    # Configure editors (PATH is now available for editor detection)
    _env_configure_editors

    _log "INFO" "ZSH Environment Module initialized successfully"

    # Execute post-init hooks
    for hook in ${ZSH_POST_ENV_INIT_HOOKS[@]}; do
        if (( $+functions[$hook] )); then
            _log "DEBUG" "Running post-init hook: $hook"
            $hook
        fi
    done
}

# ----------------------------------------------------------
# * PUBLIC FUNCTIONS
# ? User-facing commands for environment management.
# ----------------------------------------------------------

# Show all managed environment variables
env_show() {
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
env_status() {
    echo "=== Tool Installation Status ==="
    echo ""

    # Check major tools
    local -a tools=(
        "docker:Docker"
        "kubectl:Kubernetes"
        "node:Node.js"
        "npm:NPM"
        "yarn:Yarn"
        "pnpm:PNPM"
        "volta:Volta"
        "python:Python"
        "pip:Pip"
        "pyenv:Pyenv"
        "ruby:Ruby"
        "gem:Gem"
        "go:Go"
        "cargo:Rust/Cargo"
        "java:Java"
        "composer:PHP Composer"
    )

    local cmd name
    for tool in "${tools[@]}"; do
        cmd="${tool%%:*}"
        name="${tool#*:}"

        if _has_cmd "$cmd"; then
            echo "✓ $name is installed"
        else
            echo "✗ $name is not installed"
        fi
    done
}

# Reload the environment module
env_reload() {
    echo "Reloading environment module..."

    # Try to determine the script path
    local script_path
    if [[ -n "$ZDOTDIR" ]]; then
        script_path="$ZDOTDIR/modules/environment.zsh"
    else
        script_path="${HOME}/.config/zsh/modules/environment.zsh"
    fi

    if [[ -f "$script_path" ]]; then
        source "$script_path"
        echo "✓ Environment module reloaded"
    else
        echo "✗ Could not find environment.zsh at: $script_path" >&2
        return 1
    fi
}

# ----------------------------------------------------------
# * SHELL TOOL INITIALIZATION
# ? Tools that hook into the shell (direnv, atuin).
# ? Keybindings are handled by keybindings.zsh module.
# ----------------------------------------------------------

# direnv - Environment switcher (init directly, no PROMPT involvement)
if _has_cmd direnv; then
    _cache_eval "direnv-hook" "direnv hook zsh" "direnv"
    _log "DEBUG" "direnv hook initialized"
fi

# atuin - Better shell history (widgets only, keybindings in keybindings.zsh)
if _has_cmd atuin; then
    _cache_eval "atuin-init" "atuin init zsh --disable-up-arrow" "atuin"
    _log "DEBUG" "atuin widgets loaded (keybindings in keybindings.zsh)"
fi

# ----------------------------------------------------------
# * STARSHIP PROMPT (DEFERRED)
# ? Must run in .zshrc AFTER /etc/zshrc which overwrites PROMPT.
# ? Registered as POST_INTERACTIVE hook, executed by .zshrc.
# ----------------------------------------------------------

_env_init_starship() {
    if _has_cmd starship; then
        export STARSHIP_CONFIG="${ZSH_CONFIG_HOME}/starship.toml"
        eval "$(starship init zsh)"
        _log "DEBUG" "starship prompt initialized"
    fi
}

# Register starship for deferred execution (after /etc/zshrc)
ZSH_POST_INTERACTIVE_HOOKS+=('_env_init_starship')

# ----------------------------------------------------------
# * ALIASES
# ----------------------------------------------------------

alias envshow="env_show"
alias envstatus="env_status"
alias envreload="env_reload"

# ----------------------------------------------------------
# * MODULE INITIALIZATION
# ----------------------------------------------------------

_environment_init

_log DEBUG "ZSH Environment Module loaded successfully"
