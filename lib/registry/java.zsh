#!/usr/bin/env zsh
# ==============================================================================
# JAVA/JVM ECOSYSTEM REGISTRY
# Java runtimes, build tools, and version managers.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    'java_home'             '$JAVA_HOME/bin:append:if_var_set:JAVA_HOME'
    'java_jbang'            '$JBANG_DIR/bin:append:if_var_set:JBANG_DIR'
    'java_jbang_default'    '$HOME/.jbang/bin:append:exists'

    # Version managers
    'dev_sdkman'            '$SDKMAN_DIR/bin:append:if_var_set:SDKMAN_DIR'
    'dev_sdkman_default'    '$HOME/.sdkman/bin:append:not_minimal_mode'
    'dev_jenv'              '$JENV_ROOT/bin:append:if_var_set:JENV_ROOT'
    'dev_jenv_default'      '$HOME/.jenv/bin:append:not_minimal_mode'
)

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

Z_ENV_TOOLS_JVM+=(
    'GRADLE_USER_HOME'    '$XDG_DATA_HOME/gradle|gradle'
    '_JAVA_OPTIONS'       '-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java|java'
    'LEIN_HOME'           '$XDG_DATA_HOME/lein|lein'
    'BOOT_HOME'           '$XDG_DATA_HOME/boot|boot'
    'BOOT_LOCAL_REPO'     '$XDG_CACHE_HOME/boot|boot'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.gradle'  '$XDG_DATA_HOME/gradle|Set GRADLE_USER_HOME|true|gradle'
    '$HOME/.sdkman'  '$XDG_DATA_HOME/sdkman|Set SDKMAN_DIR|true|sdk'
    '$HOME/.jenv'    '$XDG_DATA_HOME/jenv|Set JENV_ROOT|true|jenv'
    '$HOME/.lein'    '$XDG_DATA_HOME/lein|Set LEIN_HOME|true|lein'
)
