#!/bin/sh
# ==============================================================================
# DOCKER TEST-IMAGE PREPARATION
# Installs the framework's base dependencies and creates a non-root test user
# on any supported distro family (apt/dnf/pacman/apk/zypper).
# ------------------------------------------------------------------------------
# NOTE: POSIX sh — Alpine base images have no bash until this script installs it.
# ==============================================================================

set -eu

PKGS="zsh git curl sudo bash ca-certificates"

if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    # shellcheck disable=SC2086 # word-splitting of PKGS is intentional
    apt-get install -y -qq $PKGS >/dev/null
    rm -rf /var/lib/apt/lists/*
elif command -v dnf >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    dnf install -y -q $PKGS shadow-utils util-linux
    dnf clean all -q
elif command -v pacman >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    pacman -Syu --noconfirm --quiet $PKGS
    pacman -Scc --noconfirm >/dev/null 2>&1 || true
elif command -v apk >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    apk add --no-cache -q $PKGS shadow
elif command -v zypper >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    zypper -n -q install $PKGS shadow
else
    echo "FAIL: no supported package manager found" >&2
    exit 1
fi

# Non-root test user with passwordless sudo (mirrors a real workstation setup)
if command -v useradd >/dev/null 2>&1; then
    useradd -m -s /bin/zsh testuser
else
    adduser -D -s /bin/zsh testuser
fi
mkdir -p /etc/sudoers.d
echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser
chmod 440 /etc/sudoers.d/testuser

echo "ok: prepared $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || uname -s)"
