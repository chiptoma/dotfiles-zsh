#!/usr/bin/env zsh
# ==============================================================================
# ZSH PATH MODULE
# Intelligent PATH management with platform-specific optimizations.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_PATH_LOADED} )) && return 0
typeset -g _Z_PATH_LOADED=1

# Configuration variables with defaults
# These can be overridden by exporting them in .zshenv before sourcing this module
: ${Z_PATH_ENABLED:=true}         # Enable/disable path management (default: true)
: ${Z_PATH_HOMEBREW:=true}        # Detect and initialize Homebrew (default: true)
: ${Z_PATH_CLEAN:=true}           # Remove non-existent directories (default: true)
: ${Z_PATH_PROJECT_BIN:=false}    # Add project-local bin directories (default: false for security)
: ${Z_PATH_FORCE_MINIMAL:=false}  # Force minimal PATH setup (default: false)
: ${Z_PATH_SSH_MINIMAL:=true}     # Use minimal PATH in SSH sessions (default: true)

# Exit early if module is disabled
if [[ "$Z_PATH_ENABLED" != "true" ]]; then
    return 0
fi

# ----------------------------------------------------------
# DATA-DRIVEN PATH MANAGEMENT
# Path definitions are populated by lib/registry/*.zsh files.
# Format: name => "path_to_add:position:condition_tag[:condition_value]"
# ----------------------------------------------------------

# Ensure array exists (registry may have already populated it)
(( ${+Z_PATH_DEFINITIONS} )) || typeset -gA Z_PATH_DEFINITIONS

# ----------------------------------------------------------
# PATH CACHE
# O(1) lookup for duplicate detection instead of O(n) array scan
# ----------------------------------------------------------

typeset -gA _PATH_CACHE  # Associative array: path => 1

# Rebuild cache from current path array
_path_cache_rebuild() {
    _PATH_CACHE=()
    local entry
    for entry in "${path[@]}"; do
        _PATH_CACHE[$entry]=1
    done
}

# ----------------------------------------------------------
# HELPER FUNCTIONS
# ----------------------------------------------------------

# _path_add - Add a directory to PATH with position control
# Usage: _path_add <directory> <position>
# Parameters:
#   directory: Path to add
#   position: "prepend" or "append" (default: "append")
# Note: Directory must exist and will not be added if already in PATH
_path_add() {
    local dir="$1"
    local position="${2:-append}"

    # Expand environment variables like $HOME
    local expanded_dir="${(e)dir}"

    _log "DEBUG" "Attempting to add to PATH: $expanded_dir (Position: $position)"

    # Check if directory exists
    if [[ -d "$expanded_dir" ]]; then
        # O(1) cache lookup instead of O(n) array scan
        if (( ${+_PATH_CACHE[$expanded_dir]} )); then
            _log "DEBUG" "Directory '$expanded_dir' already in PATH (cache hit). Skipping."
            return 0
        fi

        if [[ "$position" == "prepend" ]]; then
            # Remove existing instances and prepend
            path=("$expanded_dir" "${(@)path:#$expanded_dir}")
        else
            # Remove existing instances and append
            path=("${(@)path:#$expanded_dir}" "$expanded_dir")
        fi

        # Update cache
        _PATH_CACHE[$expanded_dir]=1
        _log "INFO" "Added to PATH: $expanded_dir (Position: $position)"
    else
        _log "DEBUG" "Directory '$expanded_dir' (from '$dir') does not exist. Skipping."
    fi
}

# _path_remove - Remove a directory from PATH
# Usage: _path_remove <directory>
# Parameters:
#   directory: Path to remove
_path_remove() {
    local dir="$1"

    # Use Zsh array subtraction
    path=("${(@)path:#$dir}")
    # Update cache
    unset "_PATH_CACHE[$dir]"
    _log "DEBUG" "Processed removal request for: $dir"
}

# _path_clean - Remove non-existent directories from PATH
# Usage: _path_clean
# Note: Checks each PATH entry and removes those that don't exist
_path_clean() {
    # Quick check: if path count equals unique count and all exist, skip cleanup
    local needs_clean=false
    local element
    for element in "${path[@]}"; do
        if [[ ! -d "$element" ]]; then
            needs_clean=true
            break
        fi
    done
    if [[ "$needs_clean" == "false" ]]; then
        _log "DEBUG" "PATH is clean, no non-existent entries found"
        return 0
    fi

    _log "INFO" "Cleaning non-existent paths..."

    local -a existing_paths
    local -a removed_paths

    # Iterate through path array and keep only existing directories
    for element in "${path[@]}"; do
        if [[ -d "$element" ]]; then
            existing_paths+=("$element")
        else
            removed_paths+=("$element")
            _log "DEBUG" "Removed non-existent path: $element"
        fi
    done

    # Check if cleaning would result in empty PATH
    if [[ ${#existing_paths[@]} -eq 0 ]]; then
        _log "WARN" "_path_clean would result in empty PATH. Keeping original."
        return 1
    fi

    # Assign cleaned array back to path
    path=("${existing_paths[@]}")

    # Rebuild cache after cleaning
    _path_cache_rebuild

    _log "INFO" "PATH cleaned. ${#removed_paths[@]} non-existent entries removed."
}

# _is_path_condition_met - Evaluate condition for path addition
# Usage: _is_path_condition_met <condition_tag> <condition_value> <path_to_check>
# Returns: 0 if condition is met, 1 otherwise
_is_path_condition_met() {
    local condition_tag="$1"
    local condition_value="$2"
    local path_to_check="$3"

    case "$condition_tag" in
        always)
            return 0
            ;;
        exists)
            # Expand variables first
            local expanded_path="${(e)path_to_check}"
            [[ -d "$expanded_path" ]] && return 0
            ;;
        os_is_darwin)
            _is_macos && return 0
            ;;
        os_is_linux)
            _is_linux && return 0
            ;;
        os_is_bsd)
            _is_bsd && return 0
            ;;
        not_minimal_mode)
            [[ "$Z_PATH_IS_MINIMAL" != "true" ]] && return 0
            ;;
        if_command_exists)
            command -v "$condition_value" &>/dev/null && return 0
            ;;
        if_var_set)
            [[ -n "${(P)condition_value:-}" ]] && return 0
            ;;
        if_var_true)
            [[ "${(P)condition_value:-}" == "true" ]] && return 0
            ;;
        *)
            ;;
    esac

    return 1
}

# _process_path_definitions - Process the data-driven path definitions
# Usage: _process_path_definitions
# Note: Iterates through Z_PATH_DEFINITIONS and adds paths based on conditions
_process_path_definitions() {
    local name value
    local path_to_add position condition_tag condition_value
    local -a fields

    for name value in ${(kv)Z_PATH_DEFINITIONS}; do
        # Split the value by colons
        fields=("${(@s/:/)value}")

        path_to_add="${fields[1]}"
        position="${fields[2]:-append}"
        condition_tag="${fields[3]:-always}"
        condition_value="${fields[4]:-}"

        _log "DEBUG" "Processing path definition: $name -> $value"

        # Evaluate condition then delegate to _path_add (which checks -d)
        if _is_path_condition_met "$condition_tag" "$condition_value" "$path_to_add"; then
            _path_add "$path_to_add" "$position"
        else
            _log "DEBUG" "Condition for '$name' not met. Skipping '$path_to_add'."
        fi
    done
}


# _add_project_paths - Add project-local bin directories to PATH
# Usage: _add_project_paths
# Note: Called on directory change when Z_PATH_PROJECT_BIN is true
_add_project_paths() {
    _log "DEBUG" "Adding project-specific paths for: $(pwd -P)"

    # Convert relative paths to absolute paths and add them
    local abs_path

    # List of project-local directories to check
    local -a project_dirs=("./bin" "./node_modules/.bin" "./.venv/bin" "./vendor/bin")

    # First, remove any previously added project paths (using stored absolute paths)
    if [[ -n "$_LAST_PROJECT_PATHS" ]]; then
        for abs_path in ${(s/:/)_LAST_PROJECT_PATHS}; do
            _log "DEBUG" "Removing previously added project path: $abs_path"
            _path_remove "$abs_path"
        done
    fi

    # Clear the stored paths
    _LAST_PROJECT_PATHS=""

    # Add new project paths as absolute paths
    local added_count=0
    local dir
    for dir in "${project_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            abs_path="$(cd "$dir" 2>/dev/null && pwd -P)"
            if [[ -n "$abs_path" ]]; then
                _log "DEBUG" "Adding project path: $abs_path (from $dir)"
                _path_add "$abs_path" "prepend"
                added_count=$((added_count + 1))
                # Store the absolute path for later removal
                if [[ -n "$_LAST_PROJECT_PATHS" ]]; then
                    _LAST_PROJECT_PATHS="$_LAST_PROJECT_PATHS:$abs_path"
                else
                    _LAST_PROJECT_PATHS="$abs_path"
                fi
            fi
        fi
    done

    if [[ $added_count -eq 0 ]]; then
        _log "DEBUG" "No project-specific paths found or added."
    fi
}

# ----------------------------------------------------------
# INITIALIZATION FUNCTION
# ----------------------------------------------------------

path_init() {
    _log "INFO" "Initializing Zsh PATH management..."

    # ----------------------------------------------------------
    # HOMEBREW DETECTION
    # Must run before other path operations to set up HOMEBREW_PREFIX
    # ----------------------------------------------------------

    if [[ "$Z_PATH_HOMEBREW" == "true" ]]; then
        if typeset -f _detect_homebrew >/dev/null 2>&1; then
            _detect_homebrew
            _log "DEBUG" "Homebrew detection completed"
        else
            _log "DEBUG" "_detect_homebrew not available, skipping"
        fi
    fi

    # ----------------------------------------------------------
    # PATH SAFETY CHECK
    # ----------------------------------------------------------

    # Ensure PATH is never empty
    if [[ -z "$PATH" ]]; then
        PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
        _log "WARN" "PATH was empty, initialized with system defaults."
    fi

    # Initialize PATH cache from existing entries
    _path_cache_rebuild

    # ----------------------------------------------------------
    # MINIMAL MODE DETECTION
    # ----------------------------------------------------------

    # Detect if we should use minimal PATH setup (e.g. SSH sessions, Docker, CI/CD, etc.)
    Z_PATH_IS_MINIMAL=false

    # Check if we're in an SSH session
    if _is_ssh_session; then
        ZSH_IN_SSH=true
    else
        ZSH_IN_SSH=false
    fi

    # Determine if we should setup a minimal PATH
    if [[ "$Z_PATH_FORCE_MINIMAL" == "true" ]]; then
        # Case 1: Explicitly requested minimal mode
        Z_PATH_IS_MINIMAL=true
    elif [[ "$ZSH_IN_SSH" == "true" && "$Z_PATH_SSH_MINIMAL" != "false" ]]; then
        # Case 2: In SSH session and not explicitly disabled
        Z_PATH_IS_MINIMAL=true
    elif _is_docker; then
        # Case 3: Running in Docker container
        Z_PATH_IS_MINIMAL=true
    elif _is_ci; then
        # Case 4: Running in CI/CD environment
        Z_PATH_IS_MINIMAL=true
    fi

    # Set up path array as global unique array
    typeset -Uga path

    # ----------------------------------------------------------
    # PATH SETUP
    # ----------------------------------------------------------

    # Process all path definitions
    _process_path_definitions

    # If minimal mode, stop here
    if [[ "$Z_PATH_IS_MINIMAL" == "true" ]]; then
        export PATH
        _log "INFO" "PATH initialization complete (minimal mode)."
        return 0
    fi

    # ----------------------------------------------------------
    # LOCAL PROJECT BINARIES
    # ----------------------------------------------------------

    if [[ "$Z_PATH_PROJECT_BIN" == "true" ]]; then
        # Hook into ZSH directory changes
        autoload -U add-zsh-hook
        add-zsh-hook chpwd _add_project_paths

        # Run once for current directory
        _add_project_paths
    fi

    # ----------------------------------------------------------
    # FINAL PATH EXPORT
    # ----------------------------------------------------------

    export PATH
    _log "INFO" "PATH initialization complete."
}

# Call the initialization function
path_init

# ----------------------------------------------------------
# DEFERRED PATH CLEANUP
# Register _path_clean to run after .zshrc loads (via hook system).
# This ensures all PATH modifications from plugins/scripts are applied first.
# ----------------------------------------------------------

if [[ "$Z_PATH_CLEAN" == "true" ]]; then
    Z_POST_INTERACTIVE_HOOKS+=('_path_clean')
    _log "DEBUG" "Registered _path_clean for deferred execution"
fi

# ----------------------------------------------------------
# PUBLIC FUNCTIONS
# ----------------------------------------------------------

# z_path_show - Display all PATH entries with line numbers
# Usage: z_path_show
z_path_show() {
    echo "=== Current PATH ==="
    local count=${#path[@]}
    local width=${#count}
    echo "$PATH" | tr ':' '\n' | awk -v w=$width '{printf "%*d %s\n", w, NR, $0}'
}

# z_path_which - Find which PATH entry provides a command
# Usage: z_path_which <command>
# Parameters:
#   command: Name of the command to locate
z_path_which() {
    local cmd="$1"
    local full_path=$(command -v "$cmd" 2>/dev/null)

    if [[ -n "$full_path" ]]; then
        echo "Command '$cmd' found at: $full_path"
        local dir=$(dirname "$full_path")
        echo "From PATH entry: $dir"
    else
        echo "Command '$cmd' not found in PATH"
    fi
}

# z_path_debug - Display detailed PATH debugging information
# Usage: z_path_debug
z_path_debug() {
    echo "=== PATH Debug Information ==="
    echo "Total entries: ${#path[@]}"
    # Unique count requires dedup; use associative array for O(n)
    local -A seen; local -i unique=0
    for p in "${path[@]}"; do (( ${+seen[$p]} )) || { seen[$p]=1; ((unique++)); }; done
    echo "Unique entries: $unique"
    # Non-existent count
    local -i invalid=0
    for p in "${path[@]}"; do [[ ! -d "$p" ]] && ((invalid++)); done
    echo "Non-existent: $invalid"
    echo ""
    echo "First 5 entries:"
    echo "$PATH" | tr ':' '\n' | head -5 | awk '{printf "%d %s\n", NR, $0}'
    echo ""
    echo "Last 5 entries:"
    echo "$PATH" | tr ':' '\n' | tail -5 | awk '{printf "%d %s\n", NR, $0}'
}

# z_path_invalid - Check for non-existent PATH entries
# Usage: z_path_invalid
z_path_invalid() {
    echo "Checking for invalid PATH entries..."

    local entry
    local found_invalid=false

    for entry in "${path[@]}"; do
        if [[ ! -d "$entry" ]]; then
            echo "WARNING: Invalid PATH entry: $entry" >&2
            found_invalid=true
        fi
    done

    if [[ "$found_invalid" == "false" ]]; then
        echo "PATH is clean, no invalid entries found."
    fi
}

# z_path_contains - Check if a directory is in PATH
# Usage: z_path_contains <directory>
# Parameters:
#   directory: Directory to check for in PATH
# Returns: 0 if found, 1 if not found
z_path_contains() {
    local dir_to_check="$1"

    if [[ -z "$dir_to_check" ]]; then
        echo "Usage: z_path_contains <directory>"
        return 2
    fi

    _log "DEBUG" "Checking if PATH contains: $dir_to_check"

    # Resolve to absolute path
    local abs_dir
    if [[ -d "$dir_to_check" ]]; then
        abs_dir="$(cd "$dir_to_check" 2>/dev/null && pwd -P)"
        if [[ -z "$abs_dir" ]]; then
            # If cd failed, use original path
            abs_dir="$dir_to_check"
            _log "DEBUG" "Failed to canonicalize '$dir_to_check', using original path"
        fi
    else
        abs_dir="$dir_to_check"
    fi

    local entry
    for entry in "${path[@]}"; do
        # Resolve PATH entry to absolute path
        local abs_entry
        if [[ -d "$entry" ]]; then
            abs_entry="$(cd "$entry" 2>/dev/null && pwd -P)"
            if [[ -z "$abs_entry" ]]; then
                # If cd failed, use original entry
                abs_entry="$entry"
                _log "DEBUG" "Failed to canonicalize PATH entry '$entry', using original path"
            fi
        else
            abs_entry="$entry"
        fi

        if [[ "$abs_dir" == "$abs_entry" ]]; then
            echo "Directory '$abs_dir' IS in PATH."
            return 0
        fi
    done

    echo "Directory '$abs_dir' IS NOT in PATH."
    return 1
}

# z_path_reload - Reload the PATH module
# Usage: z_path_reload
z_path_reload() {
    local module="modules/01_path.zsh"
    echo "Reloading ${module:t} module..."
    local script_path="$(_resolve_module_path "$module")"

    if [[ -f "$script_path" ]]; then
        unset _Z_PATH_LOADED
        source "$script_path"
        _ui_ok "${module:t} module reloaded"
    else
        echo "✗ Could not find ${module:t} at: $script_path" >&2
        return 1
    fi
}

_log DEBUG "ZSH PATH Module loaded successfully"
