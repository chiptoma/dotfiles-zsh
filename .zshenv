# ==============================================================================
# ZSH ENVIRONMENT CONFIGURATION
# Entry point for all zsh sessions (interactive and non-interactive).
# Sets XDG directories, loads core utilities, and initializes essential paths.
# ==============================================================================

# ----------------------------------------------------------
# XDG BASE DIRECTORIES
# Set only if not already defined by the system.
# ----------------------------------------------------------

: ${XDG_CONFIG_HOME:="$HOME/.config"}
: ${XDG_CACHE_HOME:="$HOME/.cache"}
: ${XDG_DATA_HOME:="$HOME/.local/share"}
: ${XDG_STATE_HOME:="$HOME/.local/state"}

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

mkdir -p "$ZSH_CONFIG_HOME" "$ZSH_CACHE_HOME" "$ZSH_STATE_HOME" "$ZSH_DATA_HOME" "${ZSH_CACHE_HOME}/completion"

# ----------------------------------------------------------
# UTILS LIBRARY
# Consolidated utilities: logging, core helpers, platform detection.
# Load order: logging → core → platform
# ----------------------------------------------------------
[[ -r "${ZSH_CONFIG_HOME}/lib/utils/index.zsh" ]] && source "${ZSH_CONFIG_HOME}/lib/utils/index.zsh"
typeset -f _log >/dev/null 2>&1 || _log() { print -ru2 -- "$@"; }

# ----------------------------------------------------------
# FUNCTIONS LIBRARY
# Auto-discovered function libraries via barrel import.
# All functions are namespaced with zsh_ prefix.
# ----------------------------------------------------------
[[ -r "${ZSH_CONFIG_HOME}/lib/functions/index.zsh" ]] && source "${ZSH_CONFIG_HOME}/lib/functions/index.zsh"

# ----------------------------------------------------------
# PATH MODULE
# Manages PATH with platform-specific optimizations.
# IMPORTANT: Loads BEFORE environment so $+commands[] works there.
# ----------------------------------------------------------
[[ -r "${ZSH_CONFIG_HOME}/modules/path.zsh" ]] && source "${ZSH_CONFIG_HOME}/modules/path.zsh"

# ----------------------------------------------------------
# ENVIRONMENT MODULE
# Sets up environment variables, XDG directories, shell tools.
# PATH is now available - can use $+commands[] for tool detection.
# ----------------------------------------------------------
[[ -r "${ZSH_CONFIG_HOME}/modules/environment.zsh" ]] && source "${ZSH_CONFIG_HOME}/modules/environment.zsh"
