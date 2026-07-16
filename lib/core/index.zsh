#!/usr/bin/env zsh
# ==============================================================================
# ZSH CORE BARREL
# Entry point for all foundational infrastructure.
# Load order: logging → ui → helpers → platform
# ==============================================================================

# Idempotent guard
(( ${+_Z_CORE_INDEX_LOADED} )) && return 0
typeset -g _Z_CORE_INDEX_LOADED=1

# Get the directory of this script
local _core_dir="${0:A:h}"

# ----------------------------------------------------------
# 1. LOGGING
# Must load first - provides _log function for all modules
# ----------------------------------------------------------

[[ -r "${_core_dir}/logging.zsh" ]] && source "${_core_dir}/logging.zsh"

# ----------------------------------------------------------
# 2. UI OUTPUT
# Colorized output primitives (_ui_header, _ui_ok, etc.)
# ----------------------------------------------------------

[[ -r "${_core_dir}/ui.zsh" ]] && source "${_core_dir}/ui.zsh"

# ----------------------------------------------------------
# 3. HELPERS
# Infrastructure: _has_cmd, _ensure_dir, _cache_eval, etc.
# Hook system: Z_POST_INTERACTIVE_HOOKS
# ----------------------------------------------------------

[[ -r "${_core_dir}/helpers.zsh" ]] && source "${_core_dir}/helpers.zsh"

# ----------------------------------------------------------
# 4. PLATFORM DETECTION
# Platform-specific: _is_macos, _is_linux, Homebrew, etc.
# ----------------------------------------------------------

[[ -r "${_core_dir}/platform/index.zsh" ]] && source "${_core_dir}/platform/index.zsh"
