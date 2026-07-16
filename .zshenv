# ==============================================================================
# ZSH ENVIRONMENT CONFIGURATION
# Entry point for all zsh sessions (interactive and non-interactive).
# Sets XDG directories, loads core utilities, and initializes essential paths.
# ==============================================================================

# ----------------------------------------------------------
# XDG BASE DIRECTORIES
# Set only if not already defined by the system.
# ----------------------------------------------------------

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ----------------------------------------------------------
# IDEMPOTENT GUARD
# Prevents double-loading and ensures array uniqueness.
# ----------------------------------------------------------

(( ${+_Z_ZSHENV_LOADED} )) && return 0
typeset -g _Z_ZSHENV_LOADED=1
typeset -gU path fpath

# ----------------------------------------------------------
# ZSH DIRECTORIES
# Define ZDOTDIR and XDG-aligned ZSH paths.
# ----------------------------------------------------------

export ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME}/zsh}"
export ZSH_CONFIG_HOME="$ZDOTDIR"
export ZSH_DATA_HOME="$XDG_DATA_HOME/zsh"
export ZSH_CACHE_HOME="$XDG_CACHE_HOME/zsh"
export ZSH_STATE_HOME="$XDG_STATE_HOME/zsh"

if ! mkdir -p "$ZSH_CONFIG_HOME" "$ZSH_CACHE_HOME" "$ZSH_STATE_HOME" "$ZSH_DATA_HOME" "${ZSH_CACHE_HOME}/completion" 2>/dev/null; then
    # Fall back to /tmp if home directories are not writable (read-only containers, etc.)
    print -ru2 -- "[WARN] Cannot create ZSH directories under $HOME — using /tmp fallback"
    export ZSH_CACHE_HOME="/tmp/zsh-cache-${UID}"
    export ZSH_STATE_HOME="/tmp/zsh-state-${UID}"
    mkdir -p "$ZSH_CACHE_HOME" "$ZSH_STATE_HOME" "${ZSH_CACHE_HOME}/completion" 2>/dev/null
fi

# ----------------------------------------------------------
# CORE LIBRARY
# Foundational infrastructure: logging, UI, helpers, platform.
# Load order: logging → ui → helpers → platform
# ----------------------------------------------------------
[[ -r "${ZSH_CONFIG_HOME}/lib/core/index.zsh" ]] && source "${ZSH_CONFIG_HOME}/lib/core/index.zsh"
typeset -f _log >/dev/null 2>&1 || _log() { print -ru2 -- "$@"; }

# ----------------------------------------------------------
# FUNCTIONS LIBRARY
# Auto-discovered function libraries via barrel import.
# All public functions use z_ prefix.
# ----------------------------------------------------------
[[ -r "${ZSH_CONFIG_HOME}/lib/functions/index.zsh" ]] && source "${ZSH_CONFIG_HOME}/lib/functions/index.zsh"

# ----------------------------------------------------------
# TOOL REGISTRY
# Single source of truth for tool paths and environment data.
# Populates arrays consumed by 01_path.zsh and 02_environment.zsh.
# ----------------------------------------------------------
[[ -r "${ZSH_CONFIG_HOME}/lib/registry/index.zsh" ]] && source "${ZSH_CONFIG_HOME}/lib/registry/index.zsh"

# ----------------------------------------------------------
# PATH MODULE
# Manages PATH with platform-specific optimizations.
# IMPORTANT: Loads BEFORE environment so $+commands[] works there.
# ----------------------------------------------------------
[[ -r "${ZSH_CONFIG_HOME}/modules/01_path.zsh" ]] && source "${ZSH_CONFIG_HOME}/modules/01_path.zsh"

# ----------------------------------------------------------
# ENVIRONMENT MODULE
# Sets up environment variables, XDG directories, shell tools.
# PATH is now available - can use $+commands[] for tool detection.
# ----------------------------------------------------------
[[ -r "${ZSH_CONFIG_HOME}/modules/02_environment.zsh" ]] && source "${ZSH_CONFIG_HOME}/modules/02_environment.zsh"
