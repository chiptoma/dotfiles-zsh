#!/usr/bin/env zsh
# ==============================================================================
# CORE SYSTEM REGISTRY
# System paths, Homebrew, platform paths, and ZSH configuration.
# ==============================================================================

# ----------------------------------------------------------
# SYSTEM PATHS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
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

    # Homebrew (uses HOMEBREW_PREFIX set by platform lib)
    'brew_bin'              '$HOMEBREW_PREFIX/bin:prepend:if_var_set:HOMEBREW_PREFIX'
    'brew_sbin'             '$HOMEBREW_PREFIX/sbin:prepend:if_var_set:HOMEBREW_PREFIX'
    'brew_gnu_coreutils'    '$HOMEBREW_GNU_COREUTILS:prepend:if_var_set:HOMEBREW_GNU_COREUTILS'
)

# ----------------------------------------------------------
# PLATFORM PATHS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    # macOS specific
    'mac_ports_bin'         '/opt/local/bin:prepend:os_is_darwin'
    'mac_ports_sbin'        '/opt/local/sbin:prepend:os_is_darwin'
    'mac_cryptexes'         '/System/Cryptexes/App/usr/bin:append:os_is_darwin'
    'mac_apple'             '/Library/Apple/usr/bin:append:os_is_darwin'
    'mac_mono'              '/Library/Frameworks/Mono.framework/Versions/Current/bin:append:os_is_darwin'
    'mac_xcode'             '/Applications/Xcode.app/Contents/Developer/usr/bin:append:os_is_darwin'
    'mac_cmdline_tools'     '/Library/Developer/CommandLineTools/usr/bin:append:os_is_darwin'

    # Linux specific
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

    # BSD specific
    'bsd_pkg_bin'           '/usr/pkg/bin:append:os_is_bsd'
    'bsd_pkg_sbin'          '/usr/pkg/sbin:append:os_is_bsd'
)

# ----------------------------------------------------------
# VERSION MANAGERS (cross-language)
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    'dev_asdf'              '$ASDF_DIR/bin:append:if_var_set:ASDF_DIR'
    'dev_asdf_default'      '$HOME/.asdf/bin:append:not_minimal_mode'
    'dev_asdf_shims'        '$ASDF_DATA_DIR/shims:append:if_var_set:ASDF_DATA_DIR'
    'dev_asdf_shims_def'    '$HOME/.asdf/shims:append:not_minimal_mode'
)

# ----------------------------------------------------------
# ZSH ENVIRONMENT
# ----------------------------------------------------------

ZSH_ENV_TOOLS_ZSH+=(
    'ZSH_AUTOSUGGEST_HISTORY_FILE'  '$XDG_STATE_HOME/zsh/autosuggestions.history|zsh'
)
