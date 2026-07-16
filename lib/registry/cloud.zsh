#!/usr/bin/env zsh
# ==============================================================================
# CLOUD SDKS REGISTRY
# AWS, GCP, Azure, OCI, IBM, DigitalOcean.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    'cloud_amplify'         '$HOME/.amplify/bin:append:not_minimal_mode'
    'cloud_gcp'             '$CLOUDSDK_INSTALL_DIR/bin:append:if_var_set:CLOUDSDK_INSTALL_DIR'
    'cloud_gcp_default'     '$HOME/google-cloud-sdk/bin:append:not_minimal_mode'
    'cloud_azure'           '$HOME/.azure/bin:append:not_minimal_mode'
    'cloud_oci'             '$HOME/.oci/bin:append:not_minimal_mode'
    'cloud_ibm'             '$HOME/.ibmcloud/bin:append:not_minimal_mode'
)

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

ZSH_ENV_TOOLS_CLOUD+=(
    'AWS_CONFIG_FILE'             '$XDG_CONFIG_HOME/aws/config|aws'
    'AWS_SHARED_CREDENTIALS_FILE' '$XDG_CONFIG_HOME/aws/credentials|aws'
    'AWS_CLI_HISTORY_FILE'        '$XDG_STATE_HOME/aws_history|aws'
    'BOTO_CONFIG'                 '$XDG_CONFIG_HOME/boto/config|boto'
    'CLOUDSDK_CONFIG'             '$XDG_CONFIG_HOME/gcloud|gcloud'
    'CLOUDSDK_ACTIVE_CONFIG_NAME' 'default|gcloud'
    'AZURE_CONFIG_DIR'            '$XDG_DATA_HOME/azure|az'
    'DIGITALOCEAN_CONFIG'         '$XDG_CONFIG_HOME/doctl/config.yaml|doctl'
    'OCI_CLI_CONFIG_FILE'         '$XDG_CONFIG_HOME/oci/config|oci'
    'IBMCLOUD_HOME'               '$XDG_CONFIG_HOME/ibmcloud|ibmcloud'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.aws'    '$XDG_CONFIG_HOME/aws|Set AWS_CONFIG_FILE dir|true|aws'
    '$HOME/.azure'  '$XDG_DATA_HOME/azure|Set AZURE_CONFIG_DIR|true|az'
)
