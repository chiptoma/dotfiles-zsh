#!/usr/bin/env zsh
# ==============================================================================
# TOOL CATALOG ACCESS
# Lazy parser for tools.dat — the single source of truth for the optional
# tool set shared by the installer and the runtime framework.
# ------------------------------------------------------------------------------
# NOTE: _z_tools_load is NOT called at shell startup; only interactive
#   helpers (z_health, z_status, z_check_tools, help) pay the parse cost.
# ==============================================================================

# Idempotent guard
(( ${+_Z_REGISTRY_TOOLS_LOADED} )) && return 0
typeset -g _Z_REGISTRY_TOOLS_LOADED=1

# name -> 'binary:desc:category:replaces:brew:apt' (split with ${(@s.:.)})
typeset -gA Z_TOOLS
# catalog order, preserved for display
typeset -ga Z_TOOL_NAMES

# Parses tools.dat into Z_TOOLS/Z_TOOL_NAMES. Pure zsh, zero subprocesses.
# Returns 0 when the catalog is loaded (now or previously), 1 when missing.
_z_tools_load() {
    (( ${#Z_TOOL_NAMES} )) && return 0

    local catalog="${ZSH_CONFIG_HOME:-${ZDOTDIR:-$HOME/.config/zsh}}/lib/registry/tools.dat"
    if [[ ! -r "$catalog" ]]; then
        _log WARN "Tool catalog not readable: $catalog"
        return 1
    fi

    local line name
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        name="${line%%:*}"
        Z_TOOLS[$name]="${line#*:}"
        Z_TOOL_NAMES+=("$name")
    done < "$catalog"

    _log DEBUG "Tool catalog loaded: ${#Z_TOOL_NAMES} tools"
    return 0
}

# Prints one field of a catalog entry.
# Usage: _z_tool_field <name> <binary|desc|category|replaces|brew|apt>
_z_tool_field() {
    local name="$1" field="$2"
    local -a fields=("${(@s.:.)Z_TOOLS[$name]}")
    case "$field" in
        binary)   print -r -- "${fields[1]:-}" ;;
        desc)     print -r -- "${fields[2]:-}" ;;
        category) print -r -- "${fields[3]:-}" ;;
        replaces) print -r -- "${fields[4]:-}" ;;
        brew)     print -r -- "${fields[5]:-}" ;;
        apt)      print -r -- "${fields[6]:-}" ;;
        *)        return 1 ;;
    esac
}

_log DEBUG "ZSH Registry Tools library loaded"
