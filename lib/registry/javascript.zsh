#!/usr/bin/env zsh
# ==============================================================================
# JAVASCRIPT ECOSYSTEM REGISTRY
# Node.js runtimes, version managers, and package managers.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    'js_volta'              '$VOLTA_HOME/bin:prepend:if_var_set:VOLTA_HOME'
    'js_volta_default'      '$HOME/.local/share/volta/bin:prepend:exists'
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
)

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

ZSH_ENV_TOOLS_JS+=(
    'VOLTA_HOME'                '$XDG_DATA_HOME/volta|volta'
    'NPM_CONFIG_USERCONFIG'     '$XDG_CONFIG_HOME/npm/npmrc|npm'
    'NPM_CONFIG_CACHE'          '$XDG_CACHE_HOME/npm|npm'
    'NPM_CONFIG_INIT_MODULE'    '$XDG_CONFIG_HOME/npm/config/npm-init.js|npm'
    'YARN_CACHE_FOLDER'         '$XDG_CACHE_HOME/yarn|yarn'
    'YARN_CONFIG_FILE'          '$XDG_CONFIG_HOME/yarn/config|yarn'
    'YARN_ENABLE_GLOBAL_CACHE'  'false|yarn'
    'PNPM_HOME'                 '$XDG_DATA_HOME/pnpm|pnpm'
    'PNPM_STATE_DIR'            '$XDG_STATE_HOME/pnpm|pnpm'
    'PNPM_CACHE_DIR'            '$XDG_CACHE_HOME/pnpm|pnpm'
    'NODE_REPL_HISTORY'         '$XDG_STATE_HOME/node_repl_history|node'
    'NODE_ENV'                  'development|node'
    'TS_NODE_HISTORY'           '$XDG_STATE_HOME/ts_node_repl_history|ts-node'
    'NVM_DIR'                   '$XDG_DATA_HOME/nvm|nvm'
    'FNM_DIR'                   '$XDG_DATA_HOME/fnm|fnm'
    'N_PREFIX'                  '$XDG_DATA_HOME/n|n'
    'BUN_INSTALL'               '$XDG_DATA_HOME/bun|bun'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.volta'              '$XDG_DATA_HOME/volta|Set VOLTA_HOME|true|volta'
    '$HOME/.npm'                '$XDG_CACHE_HOME/npm|Set NPM_CONFIG_CACHE|true|npm'
    '$HOME/.npmrc'              '$XDG_CONFIG_HOME/npm/npmrc|Set NPM_CONFIG_USERCONFIG|true|npm'
    '$HOME/.nvm'                '$XDG_DATA_HOME/nvm|Set NVM_DIR|true|nvm'
    '$HOME/.bun'                '$XDG_DATA_HOME/bun|Set BUN_INSTALL|true|bun'
    '$HOME/.deno'               '$XDG_CACHE_HOME/deno|Set DENO_DIR|true|deno'
    '$HOME/.yarn'               '$XDG_CONFIG_HOME/yarn|Set YARN_CONFIG_FILE dir|true|yarn'
    '$HOME/.pnpm'               '$XDG_DATA_HOME/pnpm|Set PNPM_HOME|true|pnpm'
    '$HOME/.node_repl_history'  '$XDG_STATE_HOME/node_repl_history|Set NODE_REPL_HISTORY|true|node'
)
