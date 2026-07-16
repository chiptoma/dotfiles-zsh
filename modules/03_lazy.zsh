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
    [[ ! -d "$rbenv_root" ]] && ! _has_cmd rbenv && return 0

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
# AUTO-INITIALIZATION
# Register lazy loaders for command-based tools.
# ----------------------------------------------------------

_lazy_init_zoxide
_lazy_init_nvm
_lazy_init_pyenv
_lazy_init_rbenv

_log DEBUG "ZSH Lazy Loading Module loaded successfully"
