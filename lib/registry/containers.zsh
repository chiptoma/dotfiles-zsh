#!/usr/bin/env zsh
# ==============================================================================
# CONTAINERS & KUBERNETES REGISTRY
# Docker, Podman, Vagrant, Minikube, Kubernetes tools.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    # Container runtimes
    'cont_docker'           '$HOME/.docker/bin:append:not_minimal_mode'
    'cont_podman'           '$HOME/.local/bin/podman:append:not_minimal_mode'
    'cont_colima'           '$HOME/.colima/bin:append:not_minimal_mode'
    'cont_rancher'          '$HOME/.rancher-desktop/bin:append:not_minimal_mode'

    # Kubernetes tools
    'k8s_krew'              '$KREW_ROOT/bin:append:if_var_set:KREW_ROOT'
    'k8s_krew_default'      '$HOME/.krew/bin:append:not_minimal_mode'
    'k8s_kubectx'           '$HOME/.kubectx:append:not_minimal_mode'
    'k8s_kube_bin'          '$HOME/.kube/bin:append:not_minimal_mode'
)

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

ZSH_ENV_TOOLS_DOCKER+=(
    'DOCKER_CONFIG' '$XDG_CONFIG_HOME/docker|docker'
)

ZSH_ENV_TOOLS_K8S+=(
    'KUBECONFIG'    '$XDG_CONFIG_HOME/kube/config|kubectl'
    'KREW_ROOT'     '$XDG_DATA_HOME/krew|kubectl-krew'
)

ZSH_ENV_TOOLS_VIRT+=(
    'VAGRANT_HOME'  '$XDG_DATA_HOME/vagrant|vagrant'
    'MINIKUBE_HOME' '$XDG_DATA_HOME/minikube|minikube'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.docker'     '$XDG_CONFIG_HOME/docker|Set DOCKER_CONFIG|true|docker'
    '$HOME/.kube'       '$XDG_CONFIG_HOME/kube|Set KUBECONFIG dir|true|kubectl'
    '$HOME/.krew'       '$XDG_DATA_HOME/krew|Set KREW_ROOT|true|kubectl-krew'
    '$HOME/.vagrant.d'  '$XDG_DATA_HOME/vagrant|Set VAGRANT_HOME|true|vagrant'
    '$HOME/.minikube'   '$XDG_DATA_HOME/minikube|Set MINIKUBE_HOME|true|minikube'
)
