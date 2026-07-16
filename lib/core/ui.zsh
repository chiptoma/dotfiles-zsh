#!/usr/bin/env zsh
# ==============================================================================
# ZSH UI OUTPUT LIBRARY
# User-facing colorized output for interactive commands.
# Complements _log (developer debug) with visual UI output.
# ==============================================================================

# Idempotent guard
(( ${+_Z_UI_LOADED} )) && return 0
typeset -g _Z_UI_LOADED=1

# ----------------------------------------------------------
# COLOR CONSTANTS
# ANSI escape codes for consistent UI styling.
# ----------------------------------------------------------

typeset -g _UI_GREEN=$'\e[32m'
typeset -g _UI_YELLOW=$'\e[33m'
typeset -g _UI_RED=$'\e[31m'
typeset -g _UI_CYAN=$'\e[36m'
typeset -g _UI_WHITE=$'\e[1;37m'
typeset -g _UI_DIM=$'\e[90m'
typeset -g _UI_BOLD=$'\e[1m'
typeset -g _UI_RESET=$'\e[0m'

# ----------------------------------------------------------
# COLOR DETECTION
# Respects NO_COLOR spec and FORCE_COLOR override.
# ----------------------------------------------------------

_ui_is_no_color() {
    [[ -n "${NO_COLOR:-}" ]] || ! { [[ -t 1 ]] || [[ "${FORCE_COLOR:-}" == "1" ]]; }
}

if _ui_is_no_color; then
    _UI_GREEN='' _UI_YELLOW='' _UI_RED='' _UI_CYAN=''
    _UI_WHITE='' _UI_DIM='' _UI_BOLD='' _UI_RESET=''
fi

# ----------------------------------------------------------
# OUTPUT FUNCTIONS
# Structured output primitives for interactive commands.
# ----------------------------------------------------------

# Print a major header with decorative borders
# Usage: _ui_header "Title"
_ui_header() {
    echo ""
    echo "${_UI_CYAN}═══════════════════════════════════════════════════════════════${_UI_RESET}"
    echo "  ${_UI_WHITE}$1${_UI_RESET}"
    echo "${_UI_CYAN}═══════════════════════════════════════════════════════════════${_UI_RESET}"
    echo ""
}

# Print a section header
# Usage: _ui_section "Section Name"
_ui_section() {
    echo "${_UI_WHITE}$1:${_UI_RESET}"
}

# Print a footer bar
_ui_footer() {
    echo "${_UI_CYAN}═══════════════════════════════════════════════════════════════${_UI_RESET}"
}

# Print success message with green checkmark
# Usage: _ui_ok "Message"
_ui_ok() {
    echo "  ${_UI_GREEN}✓${_UI_RESET} $*"
}

# Print warning message with yellow indicator
# Usage: _ui_warn "Message"
_ui_warn() {
    echo "  ${_UI_YELLOW}~${_UI_RESET} $*"
}

# Print error message with red X
# Usage: _ui_error "Message"
_ui_error() {
    echo "  ${_UI_RED}✗${_UI_RESET} $*"
}

# Print dimmed secondary text
# Usage: _ui_dim "Message"
_ui_dim() {
    echo "  ${_UI_DIM}$*${_UI_RESET}"
}

# Print a key-value pair with aligned formatting
# Usage: _ui_kv "key" "description" [state] [note]
# state: ok (default), warn, error, dim
_ui_kv() {
    local key="$1"
    local desc="$2"
    local state="${3:-ok}"
    local note="${4:-}"
    local width=12

    local icon color
    case "$state" in
        ok)    icon="✓"; color="${_UI_GREEN}" ;;
        warn)  icon="~"; color="${_UI_YELLOW}" ;;
        error) icon="✗"; color="${_UI_RED}" ;;
        *)     icon=" "; color="${_UI_DIM}" ;;
    esac

    local pad=$((width - ${#key}))
    (( pad < 1 )) && pad=1
    local spacing="$(printf '%*s' $pad '')"

    local output="  ${color}${icon}${_UI_RESET} ${_UI_WHITE}${key}${_UI_RESET}${spacing}${desc}"
    [[ -n "$note" ]] && output+=" ${_UI_DIM}(${note})${_UI_RESET}"
    echo "$output"
}
