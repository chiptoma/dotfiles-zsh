#!/usr/bin/env zsh
# ==============================================================================
# ZSH PLATFORM UTILS BARREL
# Loads platform detection, then platform-specific utilities.
# ==============================================================================

# Idempotent guard
(( ${+_Z_PLATFORM_INDEX_LOADED} )) && return 0
typeset -g _Z_PLATFORM_INDEX_LOADED=1

# Load unified platform detection (all _is_* functions)
[[ -r "${0:A:h}/detect.zsh" ]] && source "${0:A:h}/detect.zsh"

# Load platform-specific utilities
if _is_macos; then
    [[ -r "${0:A:h}/macos.zsh" ]] && source "${0:A:h}/macos.zsh"
elif _is_linux; then
    [[ -r "${0:A:h}/linux.zsh" ]] && source "${0:A:h}/linux.zsh"
elif _is_bsd; then
    [[ -r "${0:A:h}/bsd.zsh" ]] && source "${0:A:h}/bsd.zsh"
fi
