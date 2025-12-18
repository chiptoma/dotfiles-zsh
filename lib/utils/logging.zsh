#!/usr/bin/env zsh
# ==============================================================================
# ZSH LOGGING MODULE
# Centralized logging facility for Zsh scripts with level-based filtering.
# Provides timestamp, caller info, PID, and shell context output options.
# ==============================================================================

# ----------------------------------------------------------
# MODULE GUARD
# ----------------------------------------------------------

# Idempotent guard - prevent multiple loads
(( ${+_Z_LOGGING_LOADED} )) && return 0
typeset -g _Z_LOGGING_LOADED=1

# ----------------------------------------------------------
# LOG LEVEL DEFINITIONS
# Numeric values for level comparison (lower = more verbose)
# ----------------------------------------------------------

typeset -gA Z_LOG_LEVELS=(
    DEBUG  0
    INFO   1
    WARN   2
    ERROR  3
    NONE   4
)

# ----------------------------------------------------------
# CONFIGURATION
# Default values can be overridden in .zshenv before sourcing
# ----------------------------------------------------------

# Internal config (not exported - only used by shell config)
typeset -g Z_LOG_LEVEL="${Z_LOG_LEVEL:-WARN}"
typeset -g Z_LOG_TIMESTAMP_FORMAT="${Z_LOG_TIMESTAMP_FORMAT:-+%Y-%m-%d %H:%M:%S}"
typeset -g Z_LOG_SHOW_CALLER="${Z_LOG_SHOW_CALLER:-true}"
typeset -g Z_LOG_TIMESTAMP_ENABLE="${Z_LOG_TIMESTAMP_ENABLE:-true}"
typeset -g Z_LOG_COLOR="${Z_LOG_COLOR:-auto}"           # auto|true|false
typeset -g Z_LOG_SHOW_PID="${Z_LOG_SHOW_PID:-false}"
typeset -g Z_LOG_SHOW_SHELL="${Z_LOG_SHOW_SHELL:-false}"

# ----------------------------------------------------------
# DATETIME MODULE
# Load zsh/datetime for efficient timestamps if available
# ----------------------------------------------------------

if ! zmodload -e zsh/datetime 2>/dev/null; then
    zmodload zsh/datetime 2>/dev/null || true
fi

# ----------------------------------------------------------
# INTERNAL FUNCTIONS
# Private utilities for log message assembly
# ----------------------------------------------------------

# Build a timestamp using zsh/datetime if available
# Defined once at load time to avoid per-call conditional
if zmodload -e zsh/datetime 2>/dev/null; then
    _log_get_timestamp() {
        [[ "$Z_LOG_TIMESTAMP_ENABLE" != "true" ]] && return 0
        local ts
        strftime -s ts "$Z_LOG_TIMESTAMP_FORMAT" $EPOCHSECONDS
        print -r -- "$ts"
    }
else
    _log_get_timestamp() {
        [[ "$Z_LOG_TIMESTAMP_ENABLE" != "true" ]] && return 0
        print -r -- "$(date "$Z_LOG_TIMESTAMP_FORMAT")"
    }
fi

# Determine caller file:function:line robustly
_log_get_caller() {
    local file="unknown_script" line="-1" func="${funcstack[3]:-main}"
    if [[ -n ${funcfiletrace[2]} ]]; then
        local ft="${funcfiletrace[2]}"   # file:line
        file="${ft%%:*}"
        line="${ft#*:}"
    fi
    print -r -- "${file:t}:${func}:${line}"
}

# ----------------------------------------------------------
# CORE LOG FUNCTION
# Main logging entry point with level filtering and formatting
# ----------------------------------------------------------

_log() {
    local raw_level="$1"
    local level_name="${1:u}"; shift
    local message="$*"

    # Validate level
    if [[ ! -v "Z_LOG_LEVELS[$level_name]" ]]; then
        level_name="ERROR"
        message="Invalid log level: ${raw_level} (defaulting to ERROR) ${message}"
    fi

    # Filter by level
    local message_level=${Z_LOG_LEVELS[$level_name]}
    local global_level=${Z_LOG_LEVELS[${Z_LOG_LEVEL:u}]}
    if (( message_level < global_level )); then
        return 0
    fi

    # Color decision
    # Respects Z_LOG_COLOR setting, NO_COLOR env var, and FORCE_COLOR
    local use_color=false
    case "$Z_LOG_COLOR" in
        true)  use_color=true ;;
        false) use_color=false ;;
        auto)
            if [[ "$FORCE_COLOR" == "1" ]]; then
                use_color=true
            elif [[ -n "$NO_COLOR" ]]; then
                use_color=false
            elif [[ -t 1 ]] || [[ -t 2 ]]; then
                use_color=true
            fi
            ;;
    esac

    local c_reset=$'\e[0m'
    local c_level=""
    if $use_color; then
        case "$level_name" in
            DEBUG) c_level=$'\e[90m' ;;  # bright black / grey
            INFO)  c_level=$'\e[32m' ;;  # green
            WARN)  c_level=$'\e[33m' ;;  # yellow
            ERROR) c_level=$'\e[31m' ;;  # red
            *)     c_level=$''       ;;
        esac
    fi

    # Assemble message
    local out=""
    if [[ "$Z_LOG_TIMESTAMP_ENABLE" == "true" ]]; then
        local ts="$(_log_get_timestamp)"
        [[ -n $ts ]] && out+="[$ts] "
    fi
    if $use_color; then
        out+="[${c_level}${level_name}${c_reset}]"
    else
        out+="[${level_name}]"
    fi
    if [[ "$Z_LOG_SHOW_CALLER" == "true" ]]; then
        local ci="$(_log_get_caller)"
        out+=" [${ci}]"
    fi
    if [[ "$Z_LOG_SHOW_PID" == "true" ]]; then
        out+=" [pid:$$]"
    fi
    if [[ "$Z_LOG_SHOW_SHELL" == "true" ]]; then
        local shctx=""
        [[ -o interactive ]] && shctx+="i" || shctx+="-"
        [[ -o login ]]       && shctx+="l" || shctx+="-"
        out+=" [sh:${shctx}]"
    fi
    out+=": ${message}"

    # Route to stream
    if [[ "$level_name" == "ERROR" || "$level_name" == "WARN" ]]; then
        print -r -- "$out" >&2
    else
        print -r -- "$out"
    fi
}

# ----------------------------------------------------------
# PUBLIC FUNCTIONS
# User-facing log level management
# ----------------------------------------------------------

# Change log level at runtime
z_log_level_set() {
    # Handle empty input gracefully
    if [[ -z "$1" ]]; then
        _log WARN "z_log_level_set: No level specified"
        return 1
    fi

    local lvl="${1:u}"
    if [[ -v "Z_LOG_LEVELS[$lvl]" ]]; then
        Z_LOG_LEVEL="$lvl"
    else
        _log WARN "Unknown log level: $1"
        return 1
    fi
}

# Temporarily run a command with a different log level
z_with_log_level() {
    # Error if no arguments provided
    if (( $# == 0 )); then
        _log ERROR "z_with_log_level: No level or command provided"
        return 1
    fi

    local lvl="${1:u}"; shift

    # Error if no command provided after level
    if (( $# == 0 )); then
        _log ERROR "z_with_log_level: No command provided (usage: z_with_log_level LEVEL command...)"
        return 1
    fi

    local old="$Z_LOG_LEVEL"
    z_log_level_set "$lvl" || return 1
    "$@"
    local rc=$?
    Z_LOG_LEVEL="$old"
    return $rc
}

# ----------------------------------------------------------
# UI OUTPUT FUNCTIONS
# User-facing colorized output for interactive commands.
# Complements _log (developer debug) with visual UI output.
#
# _log DEBUG "Module loaded"     → Developer debugging
# _ui_header "Health Check"      → User-facing UI
# ----------------------------------------------------------

# Export color variables for use by other modules
# Uses $'\e[...]' syntax for proper ANSI escape handling
typeset -g _UI_GREEN=$'\e[32m'
typeset -g _UI_YELLOW=$'\e[33m'
typeset -g _UI_RED=$'\e[31m'
typeset -g _UI_CYAN=$'\e[36m'
typeset -g _UI_WHITE=$'\e[1;37m'
typeset -g _UI_DIM=$'\e[90m'
typeset -g _UI_BOLD=$'\e[1m'
typeset -g _UI_RESET=$'\e[0m'

# Check if UI colors should be disabled
_ui_is_no_color() {
    [[ -n "$NO_COLOR" ]] || ! { [[ -t 1 ]] || [[ "$FORCE_COLOR" == "1" ]]; }
}

# Disable colors if not supported
if _ui_is_no_color; then
    _UI_GREEN='' _UI_YELLOW='' _UI_RED='' _UI_CYAN=''
    _UI_WHITE='' _UI_DIM='' _UI_BOLD='' _UI_RESET=''
fi

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

# ----------------------------------------------------------
_log DEBUG "ZSH Logging Module loaded"
