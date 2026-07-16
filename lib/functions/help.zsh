#!/usr/bin/env zsh
# ==============================================================================
# ZSH HELP SYSTEM
# Data-driven, tiered help: overview, interactive browser, per-command detail.
# Registry maps user-facing aliases to descriptions and categories.
# ==============================================================================

# Idempotent guard
(( ${+_Z_FUNCTIONS_HELP_LOADED} )) && return 0
typeset -g _Z_FUNCTIONS_HELP_LOADED=1

# ----------------------------------------------------------
# HELP REGISTRY
# Format: _HELP_REGISTRY[alias]="group|description|function|platform|tool_dep"
# group: builtin, tool, discovery
# platform: all, macos, linux
# tool_dep: external tool name (empty for builtin/discovery)
# ----------------------------------------------------------

# Single statement: zsh -n can only parse [key]=val literals when the
# assoc declaration is on the same command.
typeset -gA _HELP_REGISTRY=(
    # ── Framework Utilities (no special external tool) ──
    [calc]="builtin|Safe calculator|z_calc|all|"
    [weather]="builtin|Weather forecast from wttr.in|z_weather|all|"
    [timeout]="builtin|Run command with time limit|z_timeout|all|"
    [pskill]="builtin|Kill process by name|z_pskill|all|"
    [extract]="builtin|Universal archive extractor|z_extract|all|"
    [sizeof]="builtin|Show file/directory size|z_sizeof|all|"
    [backup]="builtin|Create timestamped backup|z_backup|all|"
    [dotbackup]="builtin|Snapshot all managed dotfiles + tool configs|z_dotfiles_backup|all|"
    [dotrestore]="builtin|Restore dotfiles from a backup|z_dotfiles_restore|all|"
    [todos]="builtin|Find TODO/FIXME/HACK comments|z_todos|all|"
    [up]="builtin|Navigate up N directories|z_up|all|"
    [mkcd]="builtin|Create directory and cd into it|z_mkcd|all|"
    [ports]="builtin|Show listening ports|z_show_ports|all|"
    [portcheck]="builtin|Check if a port is in use|z_portcheck|all|"
    [ip]="builtin|Show public IP address|z_publicip|all|"
    [localip]="builtin|Show local IP address|z_localip|all|"
    [waitport]="builtin|Wait for remote port to open|z_waitport|all|"

    # ── Tool Commands (require specific external tools) ──
    [y]="tool|Yazi file manager (cd on exit)|z_yazi|all|yazi"
    [activate]="tool|Activate nearest virtualenv|z_activate_venv|all|python"
    [gcleanup]="tool|Delete merged branches safely|z_git_cleanup|all|git"
    [gitsize]="tool|Show git repository size|z_gitsize|all|git"
    [dstop]="tool|Stop all running containers|z_docker_cleanup|all|docker"
    [drmi]="tool|Remove dangling images|z_docker_cleanup|all|docker"
    [drmv]="tool|Remove dangling volumes|z_docker_cleanup|all|docker"
    [killapp]="tool|Quit macOS app gracefully|z_killapp|macos|osascript"
    [speedtest]="tool|Run internet speed test|z_speedtest|all|speedtest-cli"
    [wifi-name]="tool|Current WiFi network name|z_wifi_name|macos|macOS"
    [wifi-pass]="tool|WiFi password from Keychain|z_wifi_password|macos|macOS"
    [als]="tool|Interactive alias browser|z_alias_browser|all|fzf"

    # ── XDG Guardian ──
    [xdg-check]="builtin|XDG compliance scan and stray file report|z_xdg_check|all|"
    [xdg-fix]="builtin|Interactive XDG migration tool|z_xdg_fix|all|"
    [xdg-status]="builtin|One-line XDG compliance status|z_xdg_status|all|"

    # ── Discovery (framework introspection) ──
    [help]="discovery|This help system|z_help|all|"
    [zstatus]="discovery|Module and tool status|z_status|all|"
    [zhealth]="discovery|Diagnostic health check|z_health|all|"
    [lazy]="discovery|Lazy loading status|z_lazy_status|all|"
    [zbench]="discovery|Benchmark shell startup time|z_benchmark|all|"
    [zupdate]="discovery|Update to latest version|z_update|all|"
    [zversion]="discovery|Show framework version|z_version|all|"
    [check-tools]="discovery|Check recommended CLI tools|z_check_tools|all|"
    [compclean]="discovery|Remove stale compiled .zwc files|z_cleanup_zwc|all|"

    # ── PATH Management ──
    [zpath]="discovery|Show all PATH entries|z_path_show|all|"
    [zpathwhich]="discovery|Find which PATH provides a command|z_path_which|all|"
    [zpathdebug]="discovery|PATH debug information|z_path_debug|all|"
    [zpathinvalid]="discovery|Check for non-existent PATH entries|z_path_invalid|all|"
    [zpathcontains]="discovery|Check if directory is in PATH|z_path_contains|all|"
    [zpathreload]="discovery|Reload path module|z_path_reload|all|"
    [zpathclean]="discovery|Clean non-existent PATH entries|_path_clean|all|"

    # ── Environment Management ──
    [zenv]="discovery|Show environment settings|z_env_show|all|"
    [zenvstatus]="discovery|Environment detection status|z_env_status|all|"
    [zenvreload]="discovery|Reload environment module|z_env_reload|all|"

    # ── History Management ──
    [h]="builtin|Interactive history search|z_history_search|all|"
    [zhistsearch]="builtin|Interactive history search (fzf)|z_history_search|all|fzf"
    [zhistbackup]="builtin|Backup history file|z_history_backup|all|"
    [zhistclean]="builtin|Clean history file|z_history_clean|all|"
    [zhiststats]="builtin|History statistics|z_history_stats|all|"
)

# Group display order
typeset -ga _HELP_CATEGORIES=(
    "builtin:Framework Utilities"
    "tool:Tool Commands"
    "discovery:Discovery"
)

# ----------------------------------------------------------
# PLATFORM FILTER
# ----------------------------------------------------------

_help_is_platform_match() {
    case "$1" in
        all)   return 0 ;;
        macos) _is_macos ;;
        linux) _is_linux ;;
        *)     return 0 ;;
    esac
}

# ----------------------------------------------------------
# REGISTRY FIELD PARSER
# Extracts fields from a registry entry into caller's locals.
# Sets: group, desc, func, platform, tool_dep
# ----------------------------------------------------------

_help_parse_entry() {
    local _entry="$1"
    group="${_entry%%|*}"
    local _rest="${_entry#*|}"
    desc="${_rest%%|*}"
    _rest="${_rest#*|}"
    func="${_rest%%|*}"
    _rest="${_rest#*|}"
    platform="${_rest%%|*}"
    tool_dep="${_rest#*|}"
}

# ----------------------------------------------------------
# STATIC OVERVIEW
# Default mode: grouped command list + framework state
# ----------------------------------------------------------

_help_static() {
    _ui_header "ZSH Dotfiles Help"

    local cat_key cat_label entry cmd
    local group desc func platform tool_dep

    for cat_entry in "${_HELP_CATEGORIES[@]}"; do
        cat_key="${cat_entry%%:*}"
        cat_label="${cat_entry#*:}"

        # Collect matching commands for this group
        local -a cmds=()
        for cmd in ${(ko)_HELP_REGISTRY}; do
            entry="${_HELP_REGISTRY[$cmd]}"
            group="${entry%%|*}"
            [[ "$group" != "$cat_key" ]] && continue

            _help_parse_entry "$entry"
            _help_is_platform_match "$platform" || continue

            cmds+=("$cmd")
        done

        [[ ${#cmds} -eq 0 ]] && continue

        _ui_section "$cat_label"
        for cmd in "${cmds[@]}"; do
            entry="${_HELP_REGISTRY[$cmd]}"
            _help_parse_entry "$entry"

            # Append [tool_dep] tag for tool commands
            local display_desc="$desc"
            if [[ -n "$tool_dep" ]]; then
                display_desc="${desc} ${_UI_DIM}[${tool_dep}]${_UI_RESET}"
            fi

            _ui_kv "$cmd" "$display_desc" "ok"
        done
        echo ""
    done

    # Framework state
    _help_show_state

    # Key shortcuts
    _ui_section "Key Shortcuts"
    echo "  ${_UI_YELLOW}Ctrl+R${_UI_RESET}    Search command history"
    echo "  ${_UI_YELLOW}Ctrl+T${_UI_RESET}    Find files in current directory"
    echo "  ${_UI_YELLOW}Tab${_UI_RESET}       Smart completion with descriptions"
    echo "  ${_UI_YELLOW}z <dir>${_UI_RESET}   Jump to directory ${_UI_DIM}(zoxide)${_UI_RESET}"
    echo ""

    # Footer
    _ui_footer
    echo "  Edit ${_UI_GREEN}~/.config/zsh/.zshlocal${_UI_RESET} for customization."
    echo "  Run ${_UI_GREEN}help -i${_UI_RESET} for interactive browser, ${_UI_GREEN}help <cmd>${_UI_RESET} for details."
    echo ""
}

# ----------------------------------------------------------
# FRAMEWORK STATE
# Compact summary of modules, tools, lazy loading
# ----------------------------------------------------------

_help_show_state() {
    _ui_section "Framework"

    # Modules
    local -a enabled_modules=()
    local -a module_checks=(
        "Z_ALIASES_ENABLED:aliases"
        "Z_COMPLETION_ENABLED:completion"
        "Z_HISTORY_ENABLED:history"
        "Z_KEYBINDINGS_ENABLED:keybindings"
        "Z_LAZY_ENABLED:lazy"
    )
    for entry in "${module_checks[@]}"; do
        local var="${entry%%:*}"
        local name="${entry#*:}"
        [[ "${(P)var:-true}" == "true" ]] && enabled_modules+=("$name")
    done
    _ui_kv "Modules" "${(j: :)enabled_modules}" "dim"

    # Tools (catalog-driven; extras are opt-in and excluded from the ratio)
    _z_tools_load 2>/dev/null
    local -i installed=0 total=0
    local -a installed_names=()
    local t binary category
    for t in "${Z_TOOL_NAMES[@]}"; do
        local -a _tf=("${(@s.:.)Z_TOOLS[$t]}")
        binary="${_tf[1]}" category="${_tf[3]}"
        [[ "$category" == "extra" ]] && continue
        ((total++))
        if _has_cmd "$binary"; then
            ((installed++))
            installed_names+=("$t")
        fi
    done
    local tool_state="ok"
    (( installed < total )) && tool_state="warn"
    _ui_kv "Tools" "${installed}/${total} installed" "$tool_state" "${(j: :)installed_names}"

    # Lazy loading
    local -a lazy_tools=(
        "Z_LAZY_ZOXIDE:zoxide"
        "Z_LAZY_NVM:nvm"
        "Z_LAZY_PYENV:pyenv"
        "Z_LAZY_RBENV:rbenv"
    )
    local -a loaded=() pending=()
    for entry in "${lazy_tools[@]}"; do
        local var="${entry%%:*}"
        local name="${entry#*:}"
        [[ "${(P)var:-true}" != "true" ]] && continue
        if (( ${+_LAZY_LOADED_TOOLS[$name]} )); then
            loaded+=("$name")
        else
            pending+=("$name")
        fi
    done
    local lazy_desc=""
    [[ ${#loaded} -gt 0 ]] && lazy_desc="${(j:, :)loaded} loaded"
    if [[ ${#pending} -gt 0 ]]; then
        [[ -n "$lazy_desc" ]] && lazy_desc+=", "
        lazy_desc+="${(j:, :)pending} pending"
    fi
    [[ -z "$lazy_desc" ]] && lazy_desc="none configured"
    _ui_kv "Lazy" "$lazy_desc" "dim"

    echo ""
}

# ----------------------------------------------------------
# COMMAND DETAIL
# Show details for a single command
# ----------------------------------------------------------

_help_detail() {
    local cmd="$1"
    local entry="${_HELP_REGISTRY[$cmd]}"

    # Try looking up by z_ function name if not found as alias
    if [[ -z "$entry" ]]; then
        local k v fn_name
        for k in ${(k)_HELP_REGISTRY}; do
            v="${_HELP_REGISTRY[$k]}"
            fn_name="${${v#*|}#*|}"
            fn_name="${fn_name%%|*}"
            if [[ "$fn_name" == "$cmd" ]]; then
                cmd="$k"
                entry="$v"
                break
            fi
        done
    fi

    if [[ -z "$entry" ]]; then
        _ui_error "Unknown command: $cmd"
        echo "  Run ${_UI_GREEN}help${_UI_RESET} to see all available commands."
        return 1
    fi

    local group desc func platform tool_dep
    _help_parse_entry "$entry"

    # Resolve group label
    local group_label="$group"
    local cat_entry
    for cat_entry in "${_HELP_CATEGORIES[@]}"; do
        if [[ "${cat_entry%%:*}" == "$group" ]]; then
            group_label="${cat_entry#*:}"
            break
        fi
    done

    # Get alias expansion
    local expansion=""
    expansion="$(alias "$cmd" 2>/dev/null)"
    if [[ -n "$expansion" ]]; then
        expansion="${expansion#*=}"
        expansion="${expansion#\'}"
        expansion="${expansion%\'}"
    fi

    echo ""
    echo "  ${_UI_WHITE}Command:${_UI_RESET}     ${_UI_GREEN}${cmd}${_UI_RESET}"
    echo "  ${_UI_WHITE}Function:${_UI_RESET}    ${_UI_DIM}${func}${_UI_RESET}"
    echo "  ${_UI_WHITE}Category:${_UI_RESET}    ${group_label}"
    [[ -n "$tool_dep" ]] && \
    echo "  ${_UI_WHITE}Requires:${_UI_RESET}    ${_UI_YELLOW}${tool_dep}${_UI_RESET}"
    echo "  ${_UI_WHITE}Description:${_UI_RESET} ${desc}"
    [[ -n "$expansion" ]] && \
    echo "  ${_UI_WHITE}Expands to:${_UI_RESET}  ${_UI_DIM}${expansion}${_UI_RESET}"
    [[ "$platform" != "all" ]] && \
    echo "  ${_UI_WHITE}Platform:${_UI_RESET}    ${platform}"
    echo ""
}

# ----------------------------------------------------------
# INTERACTIVE BROWSER
# fzf-powered searchable help with preview
# ----------------------------------------------------------

_help_interactive() {
    if ! _has_cmd fzf; then
        _ui_warn "fzf is required for interactive mode"
        _ui_dim "Install: brew install fzf"
        _ui_dim "Falling back to static help..."
        echo ""
        _help_static
        return
    fi

    # Build line list from registry
    local -a lines=()
    local cmd entry group desc func platform tool_dep

    for cat_entry in "${_HELP_CATEGORIES[@]}"; do
        local cat_key="${cat_entry%%:*}"
        local cat_label="${cat_entry#*:}"

        for cmd in ${(ko)_HELP_REGISTRY}; do
            entry="${_HELP_REGISTRY[$cmd]}"
            _help_parse_entry "$entry"
            [[ "$group" != "$cat_key" ]] && continue
            _help_is_platform_match "$platform" || continue

            # Show [tool_name] for tools, [group] for others
            local tag="$cat_label"
            [[ -n "$tool_dep" ]] && tag="$tool_dep"

            lines+=("$(printf "%-14s  %-42s  [%s]" "$cmd" "$desc" "$tag")")
        done
    done

    local clip_cmd
    clip_cmd="$(_get_clipboard_cmd)"

    local selected
    selected=$(printf '%s\n' "${lines[@]}" | fzf \
        --ansi \
        --height=80% \
        --layout=reverse \
        --border=rounded \
        --prompt="Search commands: " \
        --header="ZSH Framework Help" \
        --info=inline \
        --color="fg:#abb2bf,bg:-1,hl:#98c379,fg+:#abb2bf,bg+:#2c323c,hl+:#98c379,info:#e5c07b,prompt:#c678dd,pointer:#61afef,marker:#e5c07b,spinner:#e5c07b,header:#e06c75" \
        --preview="
            cmd=\$(echo {} | awk '{print \$1}')
            entry=\"\${_HELP_REGISTRY[\$cmd]:-}\"
            if [[ -n \"\$entry\" ]]; then
                IFS='|' read -r grp desc func plat tdep <<< \"\$entry\"
                expansion=\$(alias \"\$cmd\" 2>/dev/null | cut -d= -f2- | sed \"s/^'//;s/'$//\")
                echo ''
                echo -e \"\\033[1;37mCommand:\\033[0m     \\033[32m\$cmd\\033[0m\"
                echo -e \"\\033[1;37mFunction:\\033[0m    \\033[90m\$func\\033[0m\"
                echo -e \"\\033[1;37mCategory:\\033[0m    \$grp\"
                [[ -n \"\$tdep\" ]] && echo -e \"\\033[1;37mRequires:\\033[0m    \\033[33m\$tdep\\033[0m\"
                echo -e \"\\033[1;37mDescription:\\033[0m \$desc\"
                [[ -n \"\$expansion\" ]] && echo -e \"\\033[1;37mExpands to:\\033[0m  \\033[90m\$expansion\\033[0m\"
                [[ \"\$plat\" != 'all' ]] && echo -e \"\\033[1;37mPlatform:\\033[0m    \$plat\"
            fi
        " \
        --preview-window="right:45%:wrap" \
        --border-label="| enter: execute  ^Y: copy  ^/: preview  esc: close |" \
        --border-label-pos="bottom" \
        --pointer=">" \
        --marker="*" \
        --bind="ctrl-y:execute-silent(echo {} | awk '{print \$1}' | $clip_cmd)+abort" \
        --bind="ctrl-/:toggle-preview" \
        --bind="enter:accept" \
    )

    if [[ -n "$selected" ]]; then
        local alias_name
        alias_name="$(echo "$selected" | awk '{print $1}')"
        if [[ -n "$alias_name" ]]; then
            print -z "$alias_name"
        fi
    fi
}

# ----------------------------------------------------------
# PUBLIC ROUTER
# ----------------------------------------------------------

z_help() {
    case "${1:-}" in
        "")                _help_static ;;
        -i|--interactive)  _help_interactive ;;
        -h|--help)         _help_static ;;
        *)                 _help_detail "$1" ;;
    esac
}

_log DEBUG "ZSH Help System loaded"
