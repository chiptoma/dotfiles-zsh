#!/usr/bin/env zsh
# ==============================================================================
# MISC LANGUAGES REGISTRY
# Haskell, Nim, .NET, Dart, Zig, Julia, R, PHP, Elm, Deno.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
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
)

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

ZSH_ENV_TOOLS_LANGS+=(
    'NUGET_PACKAGES'      '$XDG_CACHE_HOME/NuGet/packages|dotnet'
    'DOTNET_CLI_HOME'     '$XDG_DATA_HOME/dotnet|dotnet'
    'ELM_HOME'            '$XDG_CONFIG_HOME/elm|elm'
    'DENO_DIR'            '$XDG_CACHE_HOME/deno|deno'
    'JULIA_DEPOT_PATH'    '$XDG_DATA_HOME/julia:|julia'
    'JULIA_HISTORY'       '$XDG_STATE_HOME/julia_history|julia'
    'R_ENVIRON_USER'      '$XDG_CONFIG_HOME/R/Renviron|R'
    'R_PROFILE_USER'      '$XDG_CONFIG_HOME/R/Rprofile|R'
    'R_MAKEVARS_USER'     '$XDG_CONFIG_HOME/R/Makevars|R'
    'R_HISTFILE'          '$XDG_STATE_HOME/Rhistory|R'
    'GHCUP_USE_XDG_DIRS'  'true|ghcup'
    'STACK_ROOT'          '$XDG_DATA_HOME/stack|stack'
    'CABAL_CONFIG'        '$XDG_CONFIG_HOME/cabal/config|cabal'
    'CABAL_DIR'           '$XDG_DATA_HOME/cabal|cabal'
)

# PHP (General Tools category for display)
ZSH_ENV_TOOLS_GENERAL+=(
    'COMPOSER_HOME'       '$XDG_CONFIG_HOME/composer|composer'
    'COMPOSER_CACHE_DIR'  '$XDG_CACHE_HOME/composer|composer'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.dotnet'    '$XDG_DATA_HOME/dotnet|Set DOTNET_CLI_HOME|true|dotnet'
    '$HOME/.ghcup'     '$XDG_DATA_HOME/ghcup|Set GHCUP_USE_XDG_DIRS=true|true|ghcup'
    '$HOME/.cabal'     '$XDG_DATA_HOME/cabal|Set CABAL_DIR|true|cabal'
    '$HOME/.composer'  '$XDG_CONFIG_HOME/composer|Set COMPOSER_HOME|true|composer'
    '$HOME/.nimble'    '$XDG_DATA_HOME/nimble|Set NIMBLE_DIR|true|nimble'
)
