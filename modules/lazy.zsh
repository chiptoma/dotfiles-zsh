#!/usr/bin/env zsh
# ==============================================================================
# ZSH LAZY LOADING MODULE
# Defers expensive tool initialization until first use.
# Lazy loads: zoxide, nvm, pyenv, rbenv (command-based tools).
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_LAZY_LOADED} )) && return 0
typeset -g _Z_LAZY_LOADED=1

# Configuration variables with defaults
: ${Z_LAZY_ENABLED:=true}           # Enable/disable lazy loading (default: true)
: ${Z_LAZY_ZOXIDE:=true}            # Lazy load zoxide (default: true)
: ${Z_LAZY_NVM:=true}               # Lazy load nvm (default: true)
: ${Z_LAZY_PYENV:=true}             # Lazy load pyenv (default: true)
: ${Z_LAZY_RBENV:=true}             # Lazy load rbenv (default: true)

_log DEBUG "ZSH Lazy Loading Module loading"

# Exit early if module is disabled
if [[ "$Z_LAZY_ENABLED" != "true" ]]; then
    _log INFO "ZSH Lazy Loading Module disabled, skipping"
    return 0
fi

# ----------------------------------------------------------
# LAZY LOAD REGISTRY
# Tracks which tools have been lazily loaded
# ----------------------------------------------------------

typeset -gA _LAZY_LOADED_TOOLS

# ----------------------------------------------------------
# SECURITY VALIDATION
# Validates command names before use in eval to prevent injection.
# WARNING: All inputs to eval MUST pass through this validation.
# ----------------------------------------------------------

# Validate command name for safe use in eval
# Usage: _lazy_validate_cmd <cmd_name>
# Returns: 0 if safe, 1 if contains unsafe characters
# Only allows alphanumeric, underscore, and hyphen
_lazy_validate_cmd() {
    local cmd="$1"
    # Allow only safe characters: a-z, A-Z, 0-9, underscore, hyphen
    if [[ "$cmd" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 0
    fi
    _log ERROR "lazy_load: Unsafe characters in command name: $cmd"
    return 1
}

# ----------------------------------------------------------
# CORE LAZY LOADING FUNCTION
# Creates a wrapper function that initializes on first call
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

    # SECURITY: Validate command name before use in eval
    if ! _lazy_validate_cmd "$cmd"; then
        _log ERROR "lazy_load: Rejecting unsafe command name: $cmd"
        return 1
    fi

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
        # SECURITY: Validate each alias
        if ! _lazy_validate_cmd "$alias_cmd"; then
            _log WARN "lazy_load: Skipping unsafe alias: $alias_cmd"
            continue
        fi
        _lazy_create_wrapper "$alias_cmd" "$init_cmd"
    done

    _log DEBUG "Registered lazy load for: $cmd"
}

# Internal: Create a wrapper function
# SECURITY: cmd must be validated before calling this function
_lazy_create_wrapper() {
    local cmd="$1"
    local init_cmd="$2"

    # Defense-in-depth: Re-validate even though caller should validate
    if ! _lazy_validate_cmd "$cmd"; then
        _log ERROR "_lazy_create_wrapper: Unsafe command rejected: $cmd"
        return 1
    fi

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
# LAZY LOAD PRECMD HOOK
# Alternative: Initialize tools after first prompt
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
# SECURITY MODEL:
# - _LAZY_PRECMD_INITS is populated ONLY at module load time by internal callers
# - The array is marked readonly after initialization completes (see end of module)
# - This prevents external code from injecting malicious commands via the array
# - init_cmd values come from hardcoded strings in this module, not user input
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
# ZOXIDE LAZY LOADING
# Wraps z/zi commands to defer initialization
# ----------------------------------------------------------

_lazy_init_zoxide() {
    if [[ "$Z_LAZY_ZOXIDE" != "true" ]]; then
        # Immediate init with caching
        if _has_cmd zoxide; then
            _cache_eval "zoxide" "zoxide init zsh" "zoxide"
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
            _cache_eval "zoxide" "zoxide init zsh" "zoxide"
            _LAZY_LOADED_TOOLS[zoxide]=1
            _log DEBUG "Zoxide initialized (lazy, cached)"
            z "$@"
        }

        function zi {
            unfunction z zi 2>/dev/null
            _cache_eval "zoxide" "zoxide init zsh" "zoxide"
            _LAZY_LOADED_TOOLS[zoxide]=1
            _log DEBUG "Zoxide initialized (lazy, cached)"
            zi "$@"
        }
        '

        _log DEBUG "Zoxide lazy load registered"
    fi
}

# ----------------------------------------------------------
# NVM LAZY LOADING
# Defers NVM until node/npm/nvm is first called
# ----------------------------------------------------------

_lazy_init_nvm() {
    if [[ "$Z_LAZY_NVM" != "true" ]]; then
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
# PYENV LAZY LOADING
# Defers pyenv until python/pyenv is first called
# ----------------------------------------------------------

_lazy_init_pyenv() {
    if [[ "$Z_LAZY_PYENV" != "true" ]]; then
        return 0
    fi

    # Find pyenv installation
    local pyenv_root="${PYENV_ROOT:-$HOME/.pyenv}"
    [[ ! -d "$pyenv_root" ]] && return 0

    _pyenv_lazy_load() {
        unfunction pyenv python python3 pip pip3 2>/dev/null
        export PYENV_ROOT="$pyenv_root"
        [[ -d "$PYENV_ROOT/bin" ]] && path=("$PYENV_ROOT/bin" $path)
        _cache_eval "pyenv" "pyenv init -" "pyenv"
        _LAZY_LOADED_TOOLS[pyenv]=1
        _log DEBUG "Pyenv initialized (lazy, cached)"
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
# RBENV LAZY LOADING
# Defers rbenv until ruby/rbenv is first called
# ----------------------------------------------------------

_lazy_init_rbenv() {
    if [[ "$Z_LAZY_RBENV" != "true" ]]; then
        return 0
    fi

    # Find rbenv installation
    local rbenv_root="${RBENV_ROOT:-$HOME/.rbenv}"
    [[ ! -d "$rbenv_root" ]] && _has_cmd rbenv || return 0

    _rbenv_lazy_load() {
        unfunction rbenv ruby gem bundle 2>/dev/null
        _cache_eval "rbenv" "rbenv init -" "rbenv"
        _LAZY_LOADED_TOOLS[rbenv]=1
        _log DEBUG "Rbenv initialized (lazy, cached)"
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
# INTROSPECTION
# Show lazy loading status
# ----------------------------------------------------------

# Show which tools have been lazily loaded
z_lazy_status() {
    echo "Lazy Loading Status:"
    echo "===================="
    echo ""
    echo "Configuration:"
    echo "  Z_LAZY_ENABLED:   $Z_LAZY_ENABLED"
    echo "  Z_LAZY_ZOXIDE:    $Z_LAZY_ZOXIDE"
    echo "  Z_LAZY_NVM:       $Z_LAZY_NVM"
    echo "  Z_LAZY_PYENV:     $Z_LAZY_PYENV"
    echo "  Z_LAZY_RBENV:     $Z_LAZY_RBENV"
    echo ""
    echo "Lazy Loaded Tools:"
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
# AUTO-INITIALIZATION
# Register lazy loaders for command-based tools.
# ----------------------------------------------------------

_lazy_init_zoxide
_lazy_init_nvm
_lazy_init_pyenv
_lazy_init_rbenv

# ----------------------------------------------------------
# SECURITY: Lock precmd init array after registration phase
# This prevents external code from injecting commands via the array
# ----------------------------------------------------------
typeset -gr _LAZY_PRECMD_INITS

_log DEBUG "ZSH Lazy Loading Module loaded successfully"
