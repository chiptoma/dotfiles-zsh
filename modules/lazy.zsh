#!/usr/bin/env zsh
# ==============================================================================
# * ZSH LAZY LOADING MODULE
# ? Defers expensive tool initialization until first use.
# ? Significantly reduces shell startup time for tools like starship, atuin, zoxide.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_ZSH_LAZY_LOADED} )) && return 0
typeset -g _ZSH_LAZY_LOADED=1

# Configuration variables with defaults
: ${ZSH_LAZY_ENABLED:=true}           # Enable/disable lazy loading (default: true)
: ${ZSH_LAZY_STARSHIP:=true}          # Lazy load starship prompt (default: true)
: ${ZSH_LAZY_ATUIN:=true}             # Lazy load atuin history (default: true)
: ${ZSH_LAZY_ZOXIDE:=true}            # Lazy load zoxide (default: true)
: ${ZSH_LAZY_NVM:=true}               # Lazy load nvm (default: true)
: ${ZSH_LAZY_PYENV:=true}             # Lazy load pyenv (default: true)
: ${ZSH_LAZY_RBENV:=true}             # Lazy load rbenv (default: true)

_log DEBUG "ZSH Lazy Loading Module loading"

# Exit early if module is disabled
if [[ "$ZSH_LAZY_ENABLED" != "true" ]]; then
    _log INFO "ZSH Lazy Loading Module disabled, skipping"
    return 0
fi

# ----------------------------------------------------------
# * LAZY LOAD REGISTRY
# ? Tracks which tools have been lazily loaded
# ----------------------------------------------------------

typeset -gA _LAZY_LOADED_TOOLS

# ----------------------------------------------------------
# * CORE LAZY LOADING FUNCTION
# ? Creates a wrapper function that initializes on first call
# ----------------------------------------------------------

# Register a command for lazy loading
# Usage: lazy_load <command> <init_command> [aliases...]
# Parameters:
#   command:      The main command to wrap (e.g., "z")
#   init_command: The initialization command (e.g., "zoxide init zsh")
#   aliases:      Additional commands/aliases that should trigger init
#
# Example:
#   lazy_load "z" "zoxide init zsh" "zi" "zq"
lazy_load() {
    local cmd="$1"
    local init_cmd="$2"
    shift 2
    local -a aliases=("$@")

    # Skip if command doesn't exist
    if ! _has_cmd "${cmd%%[ ]*}"; then
        _log DEBUG "Lazy load skipped: ${cmd%%[ ]*} not found"
        return 0
    fi

    # Create the lazy wrapper for main command
    _lazy_create_wrapper "$cmd" "$init_cmd"

    # Create wrappers for aliases too
    local alias_cmd
    for alias_cmd in "${aliases[@]}"; do
        _lazy_create_wrapper "$alias_cmd" "$init_cmd"
    done

    _log DEBUG "Registered lazy load for: $cmd"
}

# Internal: Create a wrapper function
_lazy_create_wrapper() {
    local cmd="$1"
    local init_cmd="$2"
    local wrapper_name="_lazy_wrapper_${cmd//[^a-zA-Z0-9_]/_}"

    # Store the init command in a variable for this wrapper
    eval "_LAZY_INIT_CMD_${cmd//[^a-zA-Z0-9_]/_}=\"\$init_cmd\""

    # Create the wrapper function
    eval "
    $cmd() {
        # Prevent recursive calls
        if [[ -n \"\${_LAZY_LOADING_${cmd//[^a-zA-Z0-9_]/_}:-}\" ]]; then
            command $cmd \"\$@\"
            return \$?
        fi
        typeset -g _LAZY_LOADING_${cmd//[^a-zA-Z0-9_]/_}=1

        # Remove this wrapper
        unfunction $cmd 2>/dev/null

        # Run initialization
        _log DEBUG \"Lazy initializing: $cmd\"
        eval \"\${_LAZY_INIT_CMD_${cmd//[^a-zA-Z0-9_]/_}}\"

        # Mark as loaded
        _LAZY_LOADED_TOOLS[$cmd]=1

        # Clean up
        unset _LAZY_LOADING_${cmd//[^a-zA-Z0-9_]/_}
        unset _LAZY_INIT_CMD_${cmd//[^a-zA-Z0-9_]/_}

        # Call the now-initialized command
        $cmd \"\$@\"
    }
    "
}

# ----------------------------------------------------------
# * LAZY LOAD PRECMD HOOK
# ? Alternative: Initialize tools after first prompt
# ----------------------------------------------------------

# Initialize tools via precmd hook (runs once after first prompt)
# Usage: lazy_load_precmd <name> <init_command>
lazy_load_precmd() {
    local name="$1"
    local init_cmd="$2"

    # Store for later execution
    _LAZY_PRECMD_INITS+=("$name:$init_cmd")
}

# Precmd hook that runs deferred initializations
_lazy_precmd_hook() {
    # Only run once
    [[ -n "${_LAZY_PRECMD_DONE:-}" ]] && return 0
    typeset -g _LAZY_PRECMD_DONE=1

    local entry name init_cmd
    for entry in "${_LAZY_PRECMD_INITS[@]}"; do
        name="${entry%%:*}"
        init_cmd="${entry#*:}"
        _log DEBUG "Precmd lazy init: $name"
        eval "$init_cmd"
        _LAZY_LOADED_TOOLS[$name]=1
    done

    # Remove hook after first run
    add-zsh-hook -d precmd _lazy_precmd_hook
}

# Initialize precmd array
typeset -ga _LAZY_PRECMD_INITS

# ----------------------------------------------------------
# * STARSHIP LAZY LOADING
# ? Defers starship init until after first prompt
# ----------------------------------------------------------

_lazy_init_starship() {
    # Set starship config path (before any init)
    export STARSHIP_CONFIG="${ZSH_CONFIG_HOME}/starship.toml"

    if [[ "$ZSH_LAZY_STARSHIP" != "true" ]]; then
        # Immediate init
        if _has_cmd starship; then
            eval "$(starship init zsh)"
        fi
        return 0
    fi

    if _has_cmd starship; then
        # Use precmd for starship (needs to set up prompt)
        _lazy_starship_init() {
            [[ -n "${_STARSHIP_INITIALIZED:-}" ]] && return 0
            typeset -g _STARSHIP_INITIALIZED=1
            eval "$(starship init zsh)"
            _LAZY_LOADED_TOOLS[starship]=1
            _log DEBUG "Starship initialized (lazy)"
            # Remove hook
            add-zsh-hook -d precmd _lazy_starship_init
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _lazy_starship_init
        _log DEBUG "Starship lazy load registered"
    fi
}

# ----------------------------------------------------------
# * ATUIN LAZY LOADING
# ? Wraps atuin commands to defer initialization
# ----------------------------------------------------------

_lazy_init_atuin() {
    if [[ "$ZSH_LAZY_ATUIN" != "true" ]]; then
        # Immediate init
        if _has_cmd atuin; then
            eval "$(atuin init zsh)"
        fi
        return 0
    fi

    if _has_cmd atuin; then
        # Create wrapper that initializes on first use
        _atuin_lazy_init() {
            [[ -n "${_ATUIN_INITIALIZED:-}" ]] && return 1
            typeset -g _ATUIN_INITIALIZED=1
            eval "$(atuin init zsh)"
            _LAZY_LOADED_TOOLS[atuin]=1
            _log DEBUG "Atuin initialized (lazy)"
            return 0
        }

        # Wrap the atuin command
        atuin() {
            _atuin_lazy_init && atuin "$@" || command atuin "$@"
        }

        # Also trigger on Ctrl-R if atuin should handle it
        _atuin_search_lazy() {
            if _atuin_lazy_init; then
                # Re-bind and execute
                zle -N _atuin_search_widget
                zle _atuin_search_widget
            fi
        }
        zle -N _atuin_search_lazy
        # Bind Ctrl+R to atuin (will be overwritten by history.zsh if atuin not preferred)
        bindkey '^R' _atuin_search_lazy

        _log DEBUG "Atuin lazy load registered"
    fi
}

# ----------------------------------------------------------
# * ZOXIDE LAZY LOADING
# ? Wraps z/zi commands to defer initialization
# ----------------------------------------------------------

_lazy_init_zoxide() {
    if [[ "$ZSH_LAZY_ZOXIDE" != "true" ]]; then
        # Immediate init
        if _has_cmd zoxide; then
            eval "$(zoxide init zsh)"
        fi
        return 0
    fi

    # Skip if zoxide was already initialized (e.g., by OMZ zoxide plugin)
    if (( $+functions[__zoxide_z] )) || (( $+aliases[z] )); then
        _log DEBUG "Zoxide already initialized (likely by OMZ plugin), skipping lazy load"
        _LAZY_LOADED_TOOLS[zoxide]=1
        return 0
    fi

    if _has_cmd zoxide; then
        # Create lazy wrappers for z and zi
        # Use eval to define functions at runtime, avoiding parse-time alias conflicts
        eval '
        function z {
            unfunction z zi 2>/dev/null
            eval "$(zoxide init zsh)"
            _LAZY_LOADED_TOOLS[zoxide]=1
            _log DEBUG "Zoxide initialized (lazy)"
            z "$@"
        }

        function zi {
            unfunction z zi 2>/dev/null
            eval "$(zoxide init zsh)"
            _LAZY_LOADED_TOOLS[zoxide]=1
            _log DEBUG "Zoxide initialized (lazy)"
            zi "$@"
        }
        '

        _log DEBUG "Zoxide lazy load registered"
    fi
}

# ----------------------------------------------------------
# * NVM LAZY LOADING
# ? Defers NVM until node/npm/nvm is first called
# ----------------------------------------------------------

_lazy_init_nvm() {
    if [[ "$ZSH_LAZY_NVM" != "true" ]]; then
        return 0
    fi

    # Find NVM installation
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    [[ ! -d "$nvm_dir" ]] && return 0

    _nvm_lazy_load() {
        unfunction nvm node npm npx yarn pnpm 2>/dev/null
        export NVM_DIR="$nvm_dir"
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        _LAZY_LOADED_TOOLS[nvm]=1
        _log DEBUG "NVM initialized (lazy)"
    }

    # Create wrappers for all node-related commands
    local cmd
    for cmd in nvm node npm npx yarn pnpm; do
        eval "
        $cmd() {
            _nvm_lazy_load
            $cmd \"\$@\"
        }
        "
    done

    _log DEBUG "NVM lazy load registered"
}

# ----------------------------------------------------------
# * PYENV LAZY LOADING
# ? Defers pyenv until python/pyenv is first called
# ----------------------------------------------------------

_lazy_init_pyenv() {
    if [[ "$ZSH_LAZY_PYENV" != "true" ]]; then
        return 0
    fi

    # Find pyenv installation
    local pyenv_root="${PYENV_ROOT:-$HOME/.pyenv}"
    [[ ! -d "$pyenv_root" ]] && return 0

    _pyenv_lazy_load() {
        unfunction pyenv python python3 pip pip3 2>/dev/null
        export PYENV_ROOT="$pyenv_root"
        [[ -d "$PYENV_ROOT/bin" ]] && path=("$PYENV_ROOT/bin" $path)
        eval "$(pyenv init -)"
        _LAZY_LOADED_TOOLS[pyenv]=1
        _log DEBUG "Pyenv initialized (lazy)"
    }

    # Create wrappers
    local cmd
    for cmd in pyenv python python3 pip pip3; do
        eval "
        $cmd() {
            _pyenv_lazy_load
            $cmd \"\$@\"
        }
        "
    done

    _log DEBUG "Pyenv lazy load registered"
}

# ----------------------------------------------------------
# * RBENV LAZY LOADING
# ? Defers rbenv until ruby/rbenv is first called
# ----------------------------------------------------------

_lazy_init_rbenv() {
    if [[ "$ZSH_LAZY_RBENV" != "true" ]]; then
        return 0
    fi

    # Find rbenv installation
    local rbenv_root="${RBENV_ROOT:-$HOME/.rbenv}"
    [[ ! -d "$rbenv_root" ]] && _has_cmd rbenv || return 0

    _rbenv_lazy_load() {
        unfunction rbenv ruby gem bundle 2>/dev/null
        eval "$(rbenv init -)"
        _LAZY_LOADED_TOOLS[rbenv]=1
        _log DEBUG "Rbenv initialized (lazy)"
    }

    # Create wrappers
    local cmd
    for cmd in rbenv ruby gem bundle; do
        eval "
        $cmd() {
            _rbenv_lazy_load
            $cmd \"\$@\"
        }
        "
    done

    _log DEBUG "Rbenv lazy load registered"
}

# ----------------------------------------------------------
# * INTROSPECTION
# ? Show lazy loading status
# ----------------------------------------------------------

# Show which tools have been lazily loaded
zsh_lazy_status() {
    echo "Lazy Loading Status:"
    echo "===================="
    echo ""
    echo "Configuration:"
    echo "  ZSH_LAZY_ENABLED:   $ZSH_LAZY_ENABLED"
    echo "  ZSH_LAZY_STARSHIP:  $ZSH_LAZY_STARSHIP"
    echo "  ZSH_LAZY_ATUIN:     $ZSH_LAZY_ATUIN"
    echo "  ZSH_LAZY_ZOXIDE:    $ZSH_LAZY_ZOXIDE"
    echo "  ZSH_LAZY_NVM:       $ZSH_LAZY_NVM"
    echo "  ZSH_LAZY_PYENV:     $ZSH_LAZY_PYENV"
    echo "  ZSH_LAZY_RBENV:     $ZSH_LAZY_RBENV"
    echo ""
    echo "Initialized Tools:"
    if [[ ${#_LAZY_LOADED_TOOLS[@]} -eq 0 ]]; then
        echo "  (none yet - tools initialize on first use)"
    else
        local tool
        for tool in "${(k)_LAZY_LOADED_TOOLS[@]}"; do
            echo "  ✓ $tool"
        done
    fi
}

# ----------------------------------------------------------
# * AUTO-INITIALIZATION
# ? Register lazy loaders based on configuration.
# ? Tools initialize on first use, not at shell startup.
# ----------------------------------------------------------

_lazy_init_starship
_lazy_init_atuin
_lazy_init_zoxide
_lazy_init_nvm
_lazy_init_pyenv
_lazy_init_rbenv

# ----------------------------------------------------------
_log DEBUG "ZSH Lazy Loading Module loaded successfully"
