#!/usr/bin/env zsh
# ==============================================================================
# CLI TOOLS REGISTRY
# Modern CLI replacements and productivity tools.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    'tool_atuin'            '$HOME/.atuin/bin:prepend:exists'
)

# ----------------------------------------------------------
# CONFIG FILE CHECKS
# Only set if file exists (tools error on missing config files)
# ----------------------------------------------------------

Z_ENV_CONFIG_FILE_CHECKS+=(
    'RIPGREP_CONFIG_PATH'  '$XDG_CONFIG_HOME/ripgrep/config|rg'
    'BAT_CONFIG_PATH'      '$XDG_CONFIG_HOME/bat/config|bat'
)
