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
# STARTUP PROFILER
# Opt-in (Z_PROFILE_STARTUP=true|zprof); no-op stubs otherwise.
# Loaded first so every later stage can be measured.
# ----------------------------------------------------------
[[ -r "${ZSH_CONFIG_HOME}/lib/core/profile.zsh" ]] && source "${ZSH_CONFIG_HOME}/lib/core/profile.zsh"

# ----------------------------------------------------------
# CORE LIBRARY
# Foundational infrastructure: logging, UI, helpers, platform.
# Load order: logging → ui → helpers → platform
# ----------------------------------------------------------
_z_prof_start 2>/dev/null || true
[[ -r "${ZSH_CONFIG_HOME}/lib/core/index.zsh" ]] && source "${ZSH_CONFIG_HOME}/lib/core/index.zsh"
typeset -f _log >/dev/null 2>&1 || _log() { print -ru2 -- "$@"; }
_z_prof_end "lib/core"

# ----------------------------------------------------------
# FUNCTIONS LIBRARY
# Auto-discovered function libraries via barrel import.
# All public functions use z_ prefix.
# ----------------------------------------------------------
_z_prof_start
[[ -r "${ZSH_CONFIG_HOME}/lib/functions/index.zsh" ]] && source "${ZSH_CONFIG_HOME}/lib/functions/index.zsh"
_z_prof_end "lib/functions"

# ----------------------------------------------------------
# TOOL REGISTRY
# Single source of truth for tool paths and environment data.
# Populates arrays consumed by 01_path.zsh and 02_environment.zsh.
# ----------------------------------------------------------
_z_prof_start
[[ -r "${ZSH_CONFIG_HOME}/lib/registry/index.zsh" ]] && source "${ZSH_CONFIG_HOME}/lib/registry/index.zsh"
_z_prof_end "lib/registry"

# ----------------------------------------------------------
# PATH MODULE
# Manages PATH with platform-specific optimizations.
# IMPORTANT: Loads BEFORE environment so $+commands[] works there.
# ----------------------------------------------------------
_z_prof_start
[[ -r "${ZSH_CONFIG_HOME}/modules/01_path.zsh" ]] && source "${ZSH_CONFIG_HOME}/modules/01_path.zsh"
_z_prof_end "01_path"

# ----------------------------------------------------------
# ENVIRONMENT MODULE
# Sets up environment variables, XDG directories, shell tools.
# PATH is now available - can use $+commands[] for tool detection.
# ----------------------------------------------------------
_z_prof_start
[[ -r "${ZSH_CONFIG_HOME}/modules/02_environment.zsh" ]] && source "${ZSH_CONFIG_HOME}/modules/02_environment.zsh"
_z_prof_end "02_environment"
