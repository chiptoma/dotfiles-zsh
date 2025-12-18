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
# ----------------------------------------------------------

# Global associative array for path definitions
# Format: name => "path_to_add:position:condition_tag[:condition_value]"
typeset -gA Z_PATH_DEFINITIONS


# Initialize path definitions with system and user paths
Z_PATH_DEFINITIONS=(
    # Core system paths
    'sys_usr_bin'           '/usr/bin:prepend:always'
    'sys_bin'               '/bin:prepend:always'
    'sys_usr_sbin'          '/usr/sbin:prepend:always'
    'sys_sbin'              '/sbin:prepend:always'
    'sys_usr_local_bin'     '/usr/local/bin:prepend:if_command_exists:/usr/local/bin/brew'
    'sys_usr_local_sbin'    '/usr/local/sbin:prepend:if_command_exists:/usr/local/bin/brew'

    # Core user paths
    'user_xdg_bin'          '$HOME/.local/bin:prepend:exists'
    'user_home_bin'         '$HOME/bin:prepend:exists'
    'user_dot_bin'          '$HOME/.bin:prepend:exists'
    'user_scripts'          '$HOME/scripts:prepend:exists'

    # Node.js / JavaScript
    'js_volta'              '$VOLTA_HOME/bin:prepend:if_var_set:VOLTA_HOME'
    'js_volta_default'      '$HOME/.local/share/volta/bin:prepend:exists'
    'js_nvm'                '$NVM_DIR/versions/node/*/bin:append:if_var_set:NVM_DIR'
    'js_nvm_default'        '$HOME/.nvm/versions/node/*/bin:append:exists'
    'js_npm_prefix'         '$NPM_CONFIG_PREFIX/bin:append:if_var_set:NPM_CONFIG_PREFIX'
    'js_npm_global'         '$HOME/.npm-global/bin:append:exists'
    'js_yarn_folder'        '$YARN_GLOBAL_FOLDER/node_modules/.bin:append:if_var_set:YARN_GLOBAL_FOLDER'
    'js_yarn_default'       '$HOME/.yarn/bin:append:exists'
    'js_pnpm'               '$PNPM_HOME:append:if_var_set:PNPM_HOME'
    'js_pnpm_default'       '$HOME/.pnpm:append:exists'
    'js_bun'                '$BUN_INSTALL/bin:append:if_var_set:BUN_INSTALL'
    'js_bun_default'        '$HOME/.bun/bin:append:exists'
    'js_deno'               '$DENO_INSTALL/bin:append:if_var_set:DENO_INSTALL'
    'js_deno_default'       '$HOME/.deno/bin:append:exists'

    # Python
    'py_pyenv_root'         '$PYENV_ROOT/bin:append:if_var_set:PYENV_ROOT'
    'py_pyenv_shims'        '$PYENV_ROOT/shims:append:if_var_set:PYENV_ROOT'
    'py_pyenv_default'      '$HOME/.pyenv/bin:append:exists'
    'py_pyenv_shims_def'    '$HOME/.pyenv/shims:append:exists'
    'py_poetry'             '$POETRY_HOME/bin:append:if_var_set:POETRY_HOME'
    'py_poetry_default'     '$HOME/.poetry/bin:append:exists'
    'py_rye'                '$RYE_HOME/shims:append:if_var_set:RYE_HOME'
    'py_rye_default'        '$HOME/.rye/shims:append:exists'
    'py_pipx'               '$PIPX_HOME/venvs/*/bin:append:if_var_set:PIPX_HOME'
    'py_pipx_default'       '$HOME/.pipx/venvs/*/bin:append:exists'

    # Ruby
    'rb_rbenv_root'         '$RBENV_ROOT/bin:append:if_var_set:RBENV_ROOT'
    'rb_rbenv_shims'        '$RBENV_ROOT/shims:append:if_var_set:RBENV_ROOT'
    'rb_rbenv_default'      '$HOME/.rbenv/bin:append:exists'
    'rb_rbenv_shims_def'    '$HOME/.rbenv/shims:append:exists'
    'rb_rvm'                '$rvm_path/bin:append:if_var_set:rvm_path'
    'rb_rvm_default'        '$HOME/.rvm/bin:append:exists'
    'rb_gem'                '$HOME/.gem/ruby/*/bin:append:exists'

    # Go
    'go_path'               '$GOPATH/bin:append:if_var_set:GOPATH'
    'go_default'            '$HOME/go/bin:append:exists'
    'go_local_share'        '$HOME/.local/share/go/bin:append:exists'

    # Rust
    'rust_cargo'            '$CARGO_HOME/bin:append:if_var_set:CARGO_HOME'
    'rust_cargo_default'    '$HOME/.cargo/bin:append:exists'

    # Java/JVM
    'java_home'             '$JAVA_HOME/bin:append:if_var_set:JAVA_HOME'
    'java_sdkman_cand'      '$SDKMAN_DIR/candidates/*/current/bin:append:if_var_set:SDKMAN_DIR'
    'java_sdkman_def'       '$HOME/.sdkman/candidates/*/current/bin:append:exists'
    'java_jbang'            '$JBANG_DIR/bin:append:if_var_set:JBANG_DIR'
    'java_jbang_default'    '$HOME/.jbang/bin:append:exists'

    # PHP
    'php_composer'          '$COMPOSER_HOME/vendor/bin:append:if_var_set:COMPOSER_HOME'
    'php_composer_def1'     '$HOME/.composer/vendor/bin:append:exists'
    'php_composer_def2'     '$HOME/.config/composer/vendor/bin:append:exists'
    'php_phpenv_root'       '$PHPENV_ROOT/bin:append:if_var_set:PHPENV_ROOT'
    'php_phpenv_shims'      '$PHPENV_ROOT/shims:append:if_var_set:PHPENV_ROOT'
    'php_phpenv_default'    '$HOME/.phpenv/bin:append:exists'
    'php_phpenv_shims_def'  '$HOME/.phpenv/shims:append:exists'

    # Other languages
    'lang_julia'            '$HOME/.juliaup/bin:append:exists'
    'lang_haskell_xdg'      '$XDG_BIN_HOME:append:if_var_true:GHCUP_USE_XDG_DIRS'
    'lang_haskell_ghcup'    '$HOME/.ghcup/bin:append:exists'
    'lang_haskell_cabal'    '$CABAL_DIR/bin:append:if_var_set:CABAL_DIR'
    'lang_haskell_cabal_def' '$HOME/.cabal/bin:append:exists'
    'lang_nim'              '$HOME/.nimble/bin:append:exists'
    'lang_dotnet'           '$HOME/.dotnet/tools:append:exists'
    'lang_dart_cache'       '$PUB_CACHE/bin:append:if_var_set:PUB_CACHE'
    'lang_dart_default'     '$HOME/.pub-cache/bin:append:exists'
    'lang_zig'              '$HOME/.zig:append:exists'
    'lang_zig_alt'          '$HOME/.local/bin/zig:append:exists'

    # CLI Tools
    'tool_atuin'            '$HOME/.atuin/bin:prepend:exists'

    # Homebrew (uses HOMEBREW_PREFIX set by platform lib)
    'brew_bin'              '$HOMEBREW_PREFIX/bin:prepend:if_var_set:HOMEBREW_PREFIX'
    'brew_sbin'             '$HOMEBREW_PREFIX/sbin:prepend:if_var_set:HOMEBREW_PREFIX'
    'brew_gnu_coreutils'    '$HOMEBREW_GNU_COREUTILS:prepend:if_var_set:HOMEBREW_GNU_COREUTILS'
)

# Additional non-minimal mode paths (will be added conditionally)
Z_PATH_DEFINITIONS+=(
    # macOS specific paths
    # Homebrew paths are handled via HOMEBREW_PREFIX (see brew_bin, brew_sbin above)
    'mac_ports_bin'         '/opt/local/bin:prepend:os_is_darwin'
    'mac_ports_sbin'        '/opt/local/sbin:prepend:os_is_darwin'
    'mac_cryptexes'         '/System/Cryptexes/App/usr/bin:append:os_is_darwin'
    'mac_apple'             '/Library/Apple/usr/bin:append:os_is_darwin'
    'mac_mono'              '/Library/Frameworks/Mono.framework/Versions/Current/bin:append:os_is_darwin'
    'mac_xcode'             '/Applications/Xcode.app/Contents/Developer/usr/bin:append:os_is_darwin'
    'mac_cmdline_tools'     '/Library/Developer/CommandLineTools/usr/bin:append:os_is_darwin'

    # Linux specific paths
    'linux_snap'            '/snap/bin:append:os_is_linux'
    'linux_flatpak_sys'     '/var/lib/flatpak/exports/bin:append:os_is_linux'
    'linux_flatpak_user'    '$HOME/.local/share/flatpak/exports/bin:append:os_is_linux'
    'linux_appimage'        '$HOME/Applications:append:os_is_linux'
    'linux_appimage_alt'    '$HOME/.local/bin/appimages:append:os_is_linux'
    'linux_nix_profile'     '$NIX_USER_PROFILE_DIR/profile/bin:append:if_var_set:NIX_USER_PROFILE_DIR'
    'linux_nix_default'     '$HOME/.nix-profile/bin:append:os_is_linux'
    'linux_nix_system'      '/nix/var/nix/profiles/default/bin:append:os_is_linux'
    'linux_brew'            '/home/linuxbrew/.linuxbrew/bin:append:os_is_linux'
    'linux_brew_user'       '$HOME/.linuxbrew/bin:append:os_is_linux'
    'linux_games'           '/usr/games:append:os_is_linux'
    'linux_ccache'          '/usr/lib/ccache:append:os_is_linux'

    # Development tools (non-minimal)
    'dev_asdf'              '$ASDF_DIR/bin:append:if_var_set:ASDF_DIR'
    'dev_asdf_default'      '$HOME/.asdf/bin:append:not_minimal_mode'
    'dev_asdf_shims'        '$ASDF_DATA_DIR/shims:append:if_var_set:ASDF_DATA_DIR'
    'dev_asdf_shims_def'    '$HOME/.asdf/shims:append:not_minimal_mode'
    'dev_sdkman'            '$SDKMAN_DIR/bin:append:if_var_set:SDKMAN_DIR'
    'dev_sdkman_default'    '$HOME/.sdkman/bin:append:not_minimal_mode'
    'dev_jenv'              '$JENV_ROOT/bin:append:if_var_set:JENV_ROOT'
    'dev_jenv_default'      '$HOME/.jenv/bin:append:not_minimal_mode'
    'dev_tfenv'             '$TFENV_ROOT/bin:append:if_var_set:TFENV_ROOT'
    'dev_tfenv_default'     '$HOME/.tfenv/bin:append:not_minimal_mode'

    # Container tools (non-minimal)
    'cont_docker'           '$HOME/.docker/bin:append:not_minimal_mode'
    'cont_podman'           '$HOME/.local/bin/podman:append:not_minimal_mode'
    'cont_colima'           '$HOME/.colima/bin:append:not_minimal_mode'
    'cont_rancher'          '$HOME/.rancher-desktop/bin:append:not_minimal_mode'

    # Cloud CLIs (non-minimal)
    'cloud_amplify'         '$HOME/.amplify/bin:append:not_minimal_mode'
    'cloud_gcp'             '$CLOUDSDK_INSTALL_DIR/bin:append:if_var_set:CLOUDSDK_INSTALL_DIR'
    'cloud_gcp_default'     '$HOME/google-cloud-sdk/bin:append:not_minimal_mode'
    'cloud_azure'           '$HOME/.azure/bin:append:not_minimal_mode'
    'cloud_oci'             '$HOME/.oci/bin:append:not_minimal_mode'
    'cloud_ibm'             '$HOME/.ibmcloud/bin:append:not_minimal_mode'

    # Kubernetes tools (non-minimal)
    'k8s_krew'              '$KREW_ROOT/bin:append:if_var_set:KREW_ROOT'
    'k8s_krew_default'      '$HOME/.krew/bin:append:not_minimal_mode'
    'k8s_kubectx'           '$HOME/.kubectx:append:not_minimal_mode'
    'k8s_kube_bin'          '$HOME/.kube/bin:append:not_minimal_mode'

    # Infrastructure tools (non-minimal)
    'infra_pulumi'          '$HOME/.pulumi/bin:append:not_minimal_mode'
    'infra_terraform'       '$HOME/.terraform.d/bin:append:not_minimal_mode'

    # macOS IDE/Editor CLI tools
    'ide_vscode'            '/Applications/Visual Studio Code.app/Contents/Resources/app/bin:append:os_is_darwin'
    'ide_vscode_insiders'   '/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin:append:os_is_darwin'
    'ide_vscodium'          '/Applications/VSCodium.app/Contents/Resources/app/bin:append:os_is_darwin'
    'ide_cursor'            '/Applications/Cursor.app/Contents/Resources/app/bin:append:os_is_darwin'
    'ide_windsurf'          '$HOME/.codeium/windsurf/bin:append:os_is_darwin'
    'ide_sublime'           '/Applications/Sublime Text.app/Contents/SharedSupport/bin:append:os_is_darwin'
    'ide_bbedit'            '/Applications/BBEdit.app/Contents/Helpers:append:os_is_darwin'
    'ide_tower'             '/Applications/Tower.app/Contents/MacOS:append:os_is_darwin'
    'ide_sourcetree'        '/Applications/Sourcetree.app/Contents/Resources:append:os_is_darwin'
    'ide_github_desktop'    '/Applications/GitHub Desktop.app/Contents/Resources/app/bin:append:os_is_darwin'

    # Cross-platform development tools
    'dev_jetbrains'         '$HOME/.local/share/JetBrains/Toolbox/scripts:append:not_minimal_mode'
    'dev_vscode_remote'     '$HOME/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin:append:not_minimal_mode'

    # BSD specific paths
    'bsd_pkg_bin'           '/usr/pkg/bin:append:os_is_bsd'
    'bsd_pkg_sbin'          '/usr/pkg/sbin:append:os_is_bsd'
)

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
            [[ -n "${(P)condition_value}" ]] && return 0
            ;;
        if_var_true)
            [[ "${(P)condition_value}" == "true" ]] && return 0
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

        # Evaluate condition
        if _is_path_condition_met "$condition_tag" "$condition_value" "$path_to_add"; then
            # Special handling for 'exists' and 'if_command_exists' conditions
            if [[ "$condition_tag" == "exists" ]]; then
                local expanded_path="${(e)path_to_add}"
                if [[ ! -d "$expanded_path" ]]; then
                    _log "DEBUG" "Path '$path_to_add' from definition '$name' does not exist (required by condition). Skipping."
                    continue
                fi
            elif [[ "$condition_tag" == "if_command_exists" ]]; then
                local expanded_path="${(e)path_to_add}"
                if [[ ! -d "$expanded_path" ]]; then
                    _log "DEBUG" "Path '$path_to_add' from definition '$name' does not exist (required by condition). Skipping."
                    continue
                fi
            fi
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

# path_show - Display all PATH entries with line numbers
# Usage: path_show
path_show() {
    echo "=== Current PATH ==="
    local count=${#path[@]}
    local width=${#count}
    echo "$PATH" | tr ':' '\n' | awk -v w=$width '{printf "%*d %s\n", w, NR, $0}'
}

# path_which - Find which PATH entry provides a command
# Usage: path_which <command>
# Parameters:
#   command: Name of the command to locate
path_which() {
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

# path_debug - Display detailed PATH debugging information
# Usage: path_debug
path_debug() {
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

# path_invalid - Check for non-existent PATH entries
# Usage: path_invalid
path_invalid() {
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

# path_contains - Check if a directory is in PATH
# Usage: path_contains <directory>
# Parameters:
#   directory: Directory to check for in PATH
# Returns: 0 if found, 1 if not found
path_contains() {
    local dir_to_check="$1"

    if [[ -z "$dir_to_check" ]]; then
        echo "Usage: path_contains <directory>"
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

# path_reload - Reload the path.zsh module
# Usage: path_reload
path_reload() {
    echo "Reloading path.zsh module..."

    # Try to determine the script path
    local script_path

    # Method 1: If ZDOTDIR is set, use it
    if [[ -n "$ZDOTDIR" ]]; then
        script_path="$ZDOTDIR/modules/path.zsh"
    # Method 2: Fallback to common location
    else
        script_path="${HOME}/.config/zsh/modules/path.zsh"
    fi

    if [[ -f "$script_path" ]]; then
        source "$script_path"
        echo "path.zsh module reloaded."
    else
        echo "ERROR: Could not find path.zsh at: $script_path" >&2
        return 1
    fi
}

# ----------------------------------------------------------
# ALIASES
# ----------------------------------------------------------

alias path="path_show"
alias pathshow="path_show"
alias pathwhich="path_which"
alias pathdebug="path_debug"
alias pathclean="_path_clean && echo '✓ PATH cleaned'"
alias pathinvalid="path_invalid"
alias pathcontains="path_contains"
alias pathreload="path_reload"

_log DEBUG "ZSH PATH Module loaded successfully"
