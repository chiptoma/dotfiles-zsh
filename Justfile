# ==============================================================================
# ZSH DOTFILES — TASK RUNNER
# Single entry point for every dev, test, and maintenance task in this repo.
# ------------------------------------------------------------------------------
# Layers: L0 lint → L1 unit → L2 smoke → L3 install (container) → L4 docker
#   matrix → L5 CI. `just test` covers L0–L2 and is safe on any machine;
#   L3 mutates $HOME and refuses to run outside a container without FORCE=1.
# NOTE: recipes print evidence lines (ok:/warn:/FAIL:) and exit non-zero on FAIL.
# ==============================================================================

set shell := ["bash", "-euo", "pipefail", "-c"]

repo := justfile_directory()

# Default: list available recipes
default:
    @just --list --unsorted

# ----------------------------------------------------------
# L0 — LINT & STATIC CHECKS
# ----------------------------------------------------------

# Syntax-check every shell file and verify repo structure
lint:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{repo}}"
    fails=0
    bash -n install.sh && echo "ok: bash -n install.sh" || { echo "FAIL: bash -n install.sh"; fails=$((fails+1)); }
    for f in tests/*.sh tests/docker/*.sh; do
        bash -n "$f" && echo "ok: bash -n $f" || { echo "FAIL: bash -n $f"; fails=$((fails+1)); }
    done
    while IFS= read -r f; do
        zsh -n "$f" && echo "ok: zsh -n $f" || { echo "FAIL: zsh -n $f"; fails=$((fails+1)); }
    done < <(find . -name '*.zsh' -not -path './.git/*' | sort; printf '%s\n' ./.zshenv ./.zshrc ./.zprofile)
    if command -v shellcheck >/dev/null 2>&1; then
        # -S error mirrors CI (test-quality.yml); warnings are tracked, not gating
        shellcheck -S error install.sh tests/*.sh tests/docker/*.sh && echo "ok: shellcheck (severity: error)" || { echo "FAIL: shellcheck"; fails=$((fails+1)); }
    else
        echo "warn: shellcheck not installed — skipped (brew install shellcheck)"
    fi
    bash tests/structure-test.sh || fails=$((fails+1))
    zsh tests/help-sync-test.zsh || fails=$((fails+1))
    [[ $fails -eq 0 ]] && echo "ok: lint — clean" || { echo "FAIL: lint — $fails group(s) failed"; exit 1; }

# ----------------------------------------------------------
# L1/L2 — UNIT & SMOKE (safe on any machine)
# ----------------------------------------------------------

# Run the unit test suite (~30 suites)
test-unit:
    cd "{{repo}}" && ZDOTDIR="{{repo}}" zsh tests/unit-test.zsh

# Run the smoke test suite (structure + shell boots)
test-smoke:
    cd "{{repo}}" && ZDOTDIR="{{repo}}" zsh tests/smoke-test.zsh

# L0 + L1 + L2 — the default local gate
test: lint test-unit test-smoke
    @echo "ok: test — lint + unit + smoke all green"

# ----------------------------------------------------------
# L3 — INSTALLER INTEGRATION (destructive; container-guarded)
# ----------------------------------------------------------

# Run installer integration tests (mutates $HOME — use test-docker instead)
test-install:
    cd "{{repo}}" && bash tests/installer-integration.sh

# ----------------------------------------------------------
# L4 — DOCKER DISTRO MATRIX (local)
# ----------------------------------------------------------

# Build a distro test image and run install + unit + smoke inside it
test-docker distro='ubuntu':
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{repo}}"
    case "{{distro}}" in
        ubuntu) image="ubuntu:24.04";      platform="" ;;
        debian) image="debian:stable";     platform="" ;;
        fedora) image="fedora:latest";     platform="" ;;
        rocky)  image="rockylinux:9";      platform="" ;;
        arch)   image="archlinux:latest";  platform="linux/amd64" ;;
        alpine) image="alpine:latest";     platform="" ;;
        *) echo "FAIL: unknown distro '{{distro}}' (ubuntu|debian|fedora|rocky|arch|alpine)"; exit 2 ;;
    esac
    # ${var:+...} form: empty-array expansion breaks under bash 3.2 set -u
    platform_flag=""; [[ -n "$platform" ]] && platform_flag="--platform=$platform"
    echo "── building zshdot-test-{{distro}} ($image) ──"
    docker build ${platform_flag:+"$platform_flag"} -q \
        -f tests/docker/Dockerfile --build-arg BASE_IMAGE="$image" \
        -t "zshdot-test-{{distro}}" tests/docker
    echo "── running L3 integration + L1 unit + L2 smoke in {{distro}} ──"
    docker run --rm ${platform_flag:+"$platform_flag"} -v "{{repo}}:/repo:ro" "zshdot-test-{{distro}}" \
        bash -c 'cp -r /repo "$HOME/repo" && cd "$HOME/repo" \
            && bash tests/installer-integration.sh \
            && ZDOTDIR="$HOME/repo" zsh tests/unit-test.zsh \
            && ZDOTDIR="$HOME/repo" zsh tests/smoke-test.zsh'
    echo "ok: test-docker {{distro}} — all suites green"

# Run the full local distro matrix (arch runs emulated; failures downgraded to warn)
test-docker-all:
    #!/usr/bin/env bash
    # No assoc arrays: macOS ships bash 3.2
    set -uo pipefail
    summary=""
    fails=0
    for d in ubuntu debian fedora rocky arch alpine; do
        if just test-docker "$d"; then
            summary="$summary  $d: ok\n"
        else
            case "$d" in
                arch|alpine)
                    echo "warn: $d failed (known-flaky tier: emulation/musl)"
                    summary="$summary  $d: warn (non-gating)\n"
                    ;;
                *)
                    summary="$summary  $d: FAIL\n"
                    fails=$((fails+1))
                    ;;
            esac
        fi
    done
    echo "── distro matrix summary ──"
    printf "%b" "$summary"
    [[ $fails -eq 0 ]] && echo "ok: test-docker-all — required distros green" \
                       || { echo "FAIL: test-docker-all — $fails required distro(s) failed"; exit 1; }

# Everything runnable locally: L0–L4
test-all: test test-docker-all
    @echo "ok: test-all — local layers L0-L4 green"

# ----------------------------------------------------------
# UTILITIES
# ----------------------------------------------------------

# Show what the installer would do, without changing anything
install-dry:
    cd "{{repo}}" && bash install.sh --dry-run --yes

# Benchmark interactive shell startup (hyperfine preferred)
bench:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{repo}}"
    if command -v hyperfine >/dev/null 2>&1; then
        hyperfine --warmup 3 --runs 10 "zsh -ic exit"
    else
        echo "warn: hyperfine not installed — falling back to a 10-run loop"
        for i in $(seq 1 10); do /usr/bin/time -p zsh -ic exit 2>&1 | awk '/^real/ {print $2 "s"}'; done
    fi

# Regenerate docs/COMMANDS.md from the help registry
docs-commands:
    #!/usr/bin/env zsh
    cd "{{repo}}"
    ZDOTDIR="{{repo}}" ZSH_CONFIG_HOME="{{repo}}" Z_LOG_LEVEL=NONE zsh -c '
        source lib/core/index.zsh 2>/dev/null
        source lib/functions/index.zsh 2>/dev/null
        z_help --export-md
    ' > docs/COMMANDS.md
    echo "ok: docs/COMMANDS.md regenerated ($(wc -l < docs/COMMANDS.md | tr -d ' ') lines)"
