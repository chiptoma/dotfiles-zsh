#!/usr/bin/env zsh
# ==============================================================================
# * ZSH FUNCTIONS BARREL
# ? Auto-discovers and sources all function libraries in this directory.
# ? Provides single-import convenience for .zshenv and other entry points.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_ZSH_FUNCTIONS_INDEX_LOADED} )) && return 0
typeset -g _ZSH_FUNCTIONS_INDEX_LOADED=1

# ----------------------------------------------------------
# * AUTO-DISCOVERY LOADER
# ? Sources all .zsh files in this directory except index.zsh itself.
# ? Files are loaded in alphabetical order for predictable behavior.
# ----------------------------------------------------------

{
    local fn_dir="${ZSH_CONFIG_HOME}/lib/functions"
    local fn_file

    for fn_file in "${fn_dir}"/*.zsh(N); do
        [[ "${fn_file:t}" == "index.zsh" ]] && continue
        [[ -r "$fn_file" ]] && source "$fn_file"
    done
}

_log DEBUG "ZSH Functions Barrel loaded"
