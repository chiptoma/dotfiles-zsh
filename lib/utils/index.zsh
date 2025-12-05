#!/usr/bin/env zsh
# ==============================================================================
# * ZSH UTILS BARREL
# ? Entry point for all utility libraries.
# ? Load order: logging → core → platform
# ==============================================================================

# Idempotent guard
(( ${+_ZSH_UTILS_INDEX_LOADED} )) && return 0
typeset -g _ZSH_UTILS_INDEX_LOADED=1

# Get the directory of this script
local _utils_dir="${0:A:h}"

# ----------------------------------------------------------
# * 1. LOGGING
# ? Must load first - provides _log function for all modules
# ----------------------------------------------------------

[[ -r "${_utils_dir}/logging.zsh" ]] && source "${_utils_dir}/logging.zsh"

# ----------------------------------------------------------
# * 2. CORE UTILITIES
# ? Helper functions: _has_cmd, _ensure_dir, _cache_eval, etc.
# ? Hook system: ZSH_POST_INTERACTIVE_HOOKS
# ----------------------------------------------------------

[[ -r "${_utils_dir}/core.zsh" ]] && source "${_utils_dir}/core.zsh"

# ----------------------------------------------------------
# * 3. PLATFORM DETECTION
# ? Platform-specific functions: _is_macos, _is_linux, etc.
# ? Homebrew detection, SSH agent detection
# ----------------------------------------------------------

[[ -r "${_utils_dir}/platform/index.zsh" ]] && source "${_utils_dir}/platform/index.zsh"
