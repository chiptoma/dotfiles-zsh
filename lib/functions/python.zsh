#!/usr/bin/env zsh
# ==============================================================================
# * ZSH PYTHON FUNCTIONS LIBRARY
# ? Python development and virtual environment utilities.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_ZSH_FUNCTIONS_PYTHON_LOADED} )) && return 0
typeset -g _ZSH_FUNCTIONS_PYTHON_LOADED=1

# Configuration variables with defaults
: ${ZSH_FUNCTIONS_PYTHON_ENABLED:=true}  # Enable/disable Python functions (default: true)

# Exit early if Python functions are disabled
[[ "$ZSH_FUNCTIONS_PYTHON_ENABLED" != "true" ]] && return 0

# ----------------------------------------------------------
# * VIRTUAL ENVIRONMENT MANAGEMENT
# ----------------------------------------------------------

# Activate Python virtual environment from common locations
# Usage: zsh_activate_venv
# Description: Searches for virtual environments in common locations:
#              venv, .venv, env, .env (in that order)
zsh_activate_venv() {
    # Try common virtual environment locations in order of preference
    local venv_locations=(
        "venv/bin/activate"
        ".venv/bin/activate"
        "env/bin/activate"
        ".env/bin/activate"
    )

    local venv_path
    for venv_path in "${venv_locations[@]}"; do
        if [[ -f "$venv_path" ]]; then
            echo "Activating virtual environment: $venv_path"
            source "$venv_path"
            echo "✓ Virtual environment activated"
            return 0
        fi
    done

    # No virtual environment found
    echo "Error: No virtual environment found in common locations" >&2
    echo "" >&2
    echo "Searched for:" >&2
    echo "  - venv/bin/activate" >&2
    echo "  - .venv/bin/activate" >&2
    echo "  - env/bin/activate" >&2
    echo "  - .env/bin/activate" >&2
    echo "" >&2
    echo "Create a virtual environment with:" >&2
    echo "  python3 -m venv venv" >&2
    echo "" >&2
    echo "Or use one of the alternative names:" >&2
    echo "  python3 -m venv .venv" >&2
    return 1
}

_log DEBUG "ZSH Python Functions Library loaded"
