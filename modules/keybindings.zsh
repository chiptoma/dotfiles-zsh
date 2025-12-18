#!/usr/bin/env zsh
# ==============================================================================
# ZSH KEYBINDINGS MODULE
# Final keybinding configuration - loads LAST to override plugin defaults
# Must be sourced after all plugins (OMZ, fzf, etc.) to take effect
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_KEYBINDINGS_LOADED} )) && return 0
typeset -g _Z_KEYBINDINGS_LOADED=1

# Configuration variables with defaults
: ${Z_KEYBINDINGS_ENABLED:=true}    # Enable/disable keybindings (default: true)

_log DEBUG "ZSH Keybindings Module loading"

# Exit early if keybindings are disabled
if [[ "$Z_KEYBINDINGS_ENABLED" != "true" ]]; then
    _log INFO "ZSH Keybindings Module disabled, skipping"
    return 0
fi

# ----------------------------------------------------------
# ATUIN HISTORY SEARCH
# All atuin keybindings are centralized here
# environment.zsh loads widgets only (--disable-up-arrow)
# ----------------------------------------------------------

if _has_cmd atuin && (( $+widgets[atuin-up-search] )); then
    # Up arrow escape sequences vary by terminal mode:
    # ^[[A = raw/normal mode (what most terminals send)
    # ^[OA = application mode (cursor key mode)
    bindkey '^[[A' atuin-up-search
    bindkey '^[OA' atuin-up-search

    # Down arrow for atuin (if widget exists)
    if (( $+widgets[atuin-down-search] )); then
        bindkey '^[[B' atuin-down-search
        bindkey '^[OB' atuin-down-search
    fi

    # Ctrl+R for interactive history search
    if (( $+widgets[atuin-search] )); then
        bindkey '^R' atuin-search
    fi

    _log DEBUG "Atuin keybindings configured (up/down/ctrl-r)"
fi

# ----------------------------------------------------------
# NAVIGATION HELPERS
# Common navigation keybindings
# ----------------------------------------------------------

# Alt+Up/Down for directory history (if dirhistory plugin loaded)
if (( $+widgets[dirhistory_zle_dirhistory_up] )); then
    bindkey '^[^[[A' dirhistory_zle_dirhistory_up    # Alt+Up
    bindkey '^[^[[B' dirhistory_zle_dirhistory_down  # Alt+Down
    bindkey '^[[1;3A' dirhistory_zle_dirhistory_up   # Alt+Up (alternate)
    bindkey '^[[1;3B' dirhistory_zle_dirhistory_down # Alt+Down (alternate)
fi

# ----------------------------------------------------------
# EDITING HELPERS
# ----------------------------------------------------------

# Ctrl+Backspace to delete word (if not already bound)
bindkey '^H' backward-delete-word 2>/dev/null

# Ctrl+Delete to delete word forward
bindkey '^[[3;5~' delete-word 2>/dev/null

# Home/End keys
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line  # Linux console
bindkey '^[[4~' end-of-line        # Linux console

# ----------------------------------------------------------
_log DEBUG "ZSH Keybindings Module loaded successfully"
