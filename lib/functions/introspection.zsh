#!/usr/bin/env zsh
# ==============================================================================
# ZSH INTROSPECTION FUNCTIONS LIBRARY
# Interactive alias browser and shell introspection utilities
# Parses inline comments from aliases.zsh for descriptions
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_FUNCTIONS_INTROSPECTION_LOADED} )) && return 0
typeset -g _Z_FUNCTIONS_INTROSPECTION_LOADED=1

# Configuration variables with defaults
: ${Z_FUNCTIONS_INTROSPECTION_ENABLED:=true}

# Exit early if disabled
[[ "$Z_FUNCTIONS_INTROSPECTION_ENABLED" != "true" ]] && return 0

# Path to aliases file (parsed for descriptions)
typeset -g _ALS_SOURCE_FILE="${ZSH_CONFIG_HOME}/modules/aliases.zsh"

# ----------------------------------------------------------
# DESCRIPTION CACHE
# Built by parsing inline comments from aliases.zsh
# ----------------------------------------------------------

typeset -gA _ALIAS_DESC_CACHE
_ALIAS_DESC_CACHE=()

# Build description cache from source file
# Parses lines matching: alias NAME='...'  # Description
_als_build_cache() {
    _ALIAS_DESC_CACHE=()
    [[ ! -f "$_ALS_SOURCE_FILE" ]] && return 1

    local line name desc
    while IFS= read -r line; do
        # Match: alias NAME='...'  # Description
        # or:    alias NAME="..."  # Description
        if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+([^=]+)=.*#[[:space:]]*(.+)$ ]]; then
            name="${match[1]}"
            desc="${match[2]}"
            # Clean up name (remove quotes, flags like -g -s)
            name="${name##* }"  # Get last word (alias name)
            name="${name//\'/}"
            name="${name//\"/}"
            [[ -n "$name" && -n "$desc" ]] && _ALIAS_DESC_CACHE[$name]="$desc"
        fi
    done < "$_ALS_SOURCE_FILE"
}

# Initialize cache on load
_als_build_cache

# Get description for an alias (from cache or empty)
_als_get_desc() {
    local name="$1"
    echo "${_ALIAS_DESC_CACHE[$name]:-}"
}

# ----------------------------------------------------------
# CATEGORY DEFINITIONS
# Patterns to group aliases by category
# ----------------------------------------------------------

typeset -gA _ALIAS_CATEGORIES
_ALIAS_CATEGORIES=(
    [1-NAV]="Navigation|^\.+='|^-=|^home=|^d[lskcev]=|^prj=|^mkcd=|^up=|^[dpo]=|^z[zb]="
    [2-FILES]="Files|^md=|^rd=|^cl[rs]?=|^c=|^sizeof=|^backup=|^todos=|^l[tlsa]|^cat[pn]?=|^find=|^f=|^fde="
    [3-GIT]="Git|^g[a-z]|^lg="
    [4-DOCKER]="Docker|^d[cpinvs]|^dc=|^lzd="
    [5-DEV]="Development|^py=|^pip=|^venv=|^activate=|^[ny][iargstbd]=|^pn[iarsgstb]|^ans[pigdvc]?="
    [6-SYSTEM]="System|^ps[gk]|^ka=|^ports=|^ip=|^local|^speed|^port|^wait|^p8=|^cpu=|^mem=|^flush|^lock|^afk|^trash=|^band|^netmon"
    [7-TOOLS]="Modern Tools|^du[h]?=|^df[a]?=|^top=|^htop=|^ping=|^trace|^http[s]?=|^rg[ifcl]=|^ps[tcm]=|^diff|^bench"
    [8-PROD]="Productivity|^zsh[re]|^gitconfig=|^e[t]?=|^reload=|^src=|^now[dt]?=|^week=|^calc=|^weather=|^[yY]="
    [9-GLOBAL]="Global Pipes|^[GLHTSUFC]=|^NE=|^NUL=|^ERR=|^JQ[CR]?="
)

# ----------------------------------------------------------
# HELPER FUNCTIONS
# ----------------------------------------------------------

# Generate all aliases list with category headers
# Uses TAB delimiter: HEADER_OR_EMPTY \t ALIAS \t COMMAND
# fzf searches only fields 2,3 (alias/command), so headers never match
_als_all_list() {
    local cat_key cat_data cat_name cat_pattern

    # Performance: Cache alias output once instead of calling per category
    local all_aliases="$(alias)"

    for cat_key in ${(ok)_ALIAS_CATEGORIES}; do
        cat_data="${_ALIAS_CATEGORIES[$cat_key]}"
        cat_name="${cat_data%%|*}"
        cat_pattern="${cat_data#*|}"

        # Check if category has any matches before printing header
        local matches=$(echo "$all_aliases" | grep -E "$cat_pattern" 2>/dev/null)
        [[ -z "$matches" ]] && continue

        # Category header: field1=header_text, field2=empty, field3=empty (full width)
        printf "\033[1;35m━━━ %-14s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\t\t\n" "$cat_name"

        echo "$matches" | sort | while IFS='=' read -r name cmd; do
            # Remove surrounding quotes from command
            cmd="${cmd#\'}"
            cmd="${cmd%\'}"
            cmd="${cmd#\"}"
            cmd="${cmd%\"}"

            # Truncate command if too long
            local max_cmd=55
            if (( ${#cmd} > max_cmd )); then
                cmd="${cmd:0:$((max_cmd-3))}..."
            fi

            # Alias line: field1=empty, field2=alias (left-aligned), field3=command
            printf "\t%-14s\t│ %s\n" "$name" "$cmd"
        done
    done
}

# ----------------------------------------------------------
# PUBLIC FUNCTIONS
# ----------------------------------------------------------

# Interactive alias browser with fzf TUI
z_alias_browser() {
    if ! _has_cmd fzf; then
        _ui_error "fzf is required"
        _ui_dim "Install: brew install fzf"
        return 1
    fi

    # Rebuild cache to catch any changes
    _als_build_cache

    # Export descriptions and full commands for preview
    local desc_file cmd_file
    local temp_dir="${XDG_RUNTIME_DIR:-/tmp}"

    # Create temp files with error handling
    desc_file=$(mktemp "$temp_dir/als-desc.XXXXXX" 2>/dev/null) || {
        _ui_error "Failed to create temp file in $temp_dir"
        return 1
    }
    cmd_file=$(mktemp "$temp_dir/als-cmd.XXXXXX" 2>/dev/null) || {
        rm -f "$desc_file" 2>/dev/null
        _ui_error "Failed to create temp file in $temp_dir"
        return 1
    }

    # Ensure cleanup on exit, interrupt, or error
    trap "rm -f '$desc_file' '$cmd_file' 2>/dev/null" EXIT INT TERM

    for key in ${(k)_ALIAS_DESC_CACHE}; do
        echo "$key=${_ALIAS_DESC_CACHE[$key]}" >> "$desc_file"
    done

    # Store full commands (not truncated)
    alias | while IFS='=' read -r name cmd; do
        cmd="${cmd#\'}"
        cmd="${cmd%\'}"
        echo "$name=$cmd" >> "$cmd_file"
    done

    local selected

    # Use platform-specific clipboard command (defined in lib/utils/platform/*.zsh)
    local clip_cmd
    clip_cmd="$(_get_clipboard_cmd)"

    selected=$(_als_all_list | fzf \
        --ansi \
        --height=100% \
        --layout=reverse \
        --border=rounded \
        --prompt="🔍 Search aliases: " \
        --header=$'\n' \
        --info=inline \
        --color="fg:#abb2bf,bg:-1,hl:#98c379,fg+:#abb2bf,bg+:#2c323c,hl+:#98c379,info:#e5c07b,prompt:#c678dd,pointer:#61afef,marker:#e5c07b,spinner:#e5c07b,header:#e06c75" \
        --delimiter=$'\t' \
        --nth=2,3 \
        --preview="
            line={}
            # Header lines start with ━, alias lines start with tab
            if [[ \"\$line\" == \"━\"* ]]; then
                echo '📁 Category header'
                echo ''
                echo 'Navigate to an alias below'
            else
                # Extract alias name (field 2, trim whitespace)
                name=\$(echo \"\$line\" | cut -f2 | awk '{\$1=\$1};1')
                [[ -z \"\$name\" ]] && exit
                cmd=\$(grep \"^\$name=\" \"$cmd_file\" 2>/dev/null | head -1 | cut -d= -f2-)
                desc=\$(grep \"^\$name=\" \"$desc_file\" 2>/dev/null | head -1 | cut -d= -f2-)
                echo '📋 Alias details:'
                echo ''
                echo -e \"\\033[1;33mAlias:\\033[0m \$name\"
                echo ''
                echo -e \"\\033[1;34mCommand:\\033[0m \$cmd\"
                echo ''
                if [[ -n \"\$desc\" ]]; then
                    echo -e \"\\033[1;32mDescription:\\033[0m \$desc\"
                fi
            fi
        " \
        --preview-window="down:7:wrap" \
        --border-label="┤ ⏎ execute · ^Y copy · ESC close · ^/ preview ├" \
        --border-label-pos="bottom" \
        --margin=1 \
        --padding=1 \
        --pointer="▶" \
        --marker="✓" \
        --bind="ctrl-y:execute-silent(echo {} | cut -f2 | awk '{\$1=\$1};1' | $clip_cmd)+abort" \
        --bind="ctrl-/:toggle-preview" \
        --bind="enter:accept" \
    )

    rm -f "$desc_file" "$cmd_file"

    # Skip if header selected (starts with ━) or empty
    if [[ -n "$selected" && "$selected" != "━"* ]]; then
        local alias_name
        # Extract alias from field 2
        alias_name=$(echo "$selected" | cut -f2 | awk '{$1=$1};1')
        if [[ -n "$alias_name" ]]; then
            print -z "$alias_name"
        fi
    fi
}

_log DEBUG "ZSH Introspection Functions Library loaded"
