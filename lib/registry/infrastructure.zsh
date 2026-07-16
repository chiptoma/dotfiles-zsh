#!/usr/bin/env zsh
# ==============================================================================
# INFRASTRUCTURE REGISTRY
# Terraform, Pulumi, Helm, Ansible, and version managers.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    'infra_pulumi'          '$HOME/.pulumi/bin:append:not_minimal_mode'
    'infra_terraform'       '$HOME/.terraform.d/bin:append:not_minimal_mode'

    # tfenv version manager
    'dev_tfenv'             '$TFENV_ROOT/bin:append:if_var_set:TFENV_ROOT'
    'dev_tfenv_default'     '$HOME/.tfenv/bin:append:not_minimal_mode'
)

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

ZSH_ENV_TOOLS_ANSIBLE+=(
    'ANSIBLE_CONFIG'    '$XDG_CONFIG_HOME/ansible/ansible.cfg|ansible'
    'ANSIBLE_HOME'      '$XDG_DATA_HOME/ansible|ansible'
)

ZSH_ENV_TOOLS_IAC+=(
    'TF_CLI_CONFIG_FILE'  '$XDG_CONFIG_HOME/terraform/terraformrc|terraform'
    'TERRAGRUNT_CONFIG'   '$XDG_CONFIG_HOME/terragrunt|terragrunt'
    'TERRAGRUNT_CACHE'    '$XDG_CACHE_HOME/terragrunt|terragrunt'
    'HELM_CONFIG_HOME'    '$XDG_CONFIG_HOME/helm|helm'
    'HELM_CACHE_HOME'     '$XDG_CACHE_HOME/helm|helm'
    'HELM_DATA_HOME'      '$XDG_DATA_HOME/helm|helm'
    'KUSTOMIZE_PLUGIN_HOME' '$XDG_DATA_HOME/kustomize/plugins|kustomize'
    'PULUMI_HOME'         '$XDG_DATA_HOME/pulumi|pulumi'
    'PULUMI_CONFIG_PASSPHRASE_FILE' '$XDG_CONFIG_HOME/pulumi/passphrase|pulumi'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.ansible'      '$XDG_DATA_HOME/ansible|Set ANSIBLE_HOME|true|ansible'
    '$HOME/.pulumi'       '$XDG_DATA_HOME/pulumi|Set PULUMI_HOME|true|pulumi'
    '$HOME/.terraform.d'  '$XDG_CONFIG_HOME/terraform|Set TF_CLI_CONFIG_FILE dir|true|terraform'
    '$HOME/.helm'         '$XDG_CONFIG_HOME/helm|Set HELM_CONFIG_HOME|true|helm'
)
