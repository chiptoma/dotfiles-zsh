#!/usr/bin/env zsh
# ==============================================================================
# HELP SYNC TEST
# Fails when docs/COMMANDS.md drifts from the help registry, or when
# z_* functions and registry entries drift from each other.
# ------------------------------------------------------------------------------
# Scope: L0 lint layer; run via `just lint` and CI. Read-only.
# ==============================================================================

emulate -L zsh

REPO_ROOT="${0:A:h:h}"
FAILURES=0
CHECKS=0

pass() { print -r -- "ok: $1"; (( CHECKS += 1 )); }
fail() { print -r -- "FAIL: $1"; (( FAILURES += 1, CHECKS += 1 )); }

# Load just enough framework for the registry + functions; the history
# module defines the z_history_* functions the registry references
export ZDOTDIR="$REPO_ROOT" ZSH_CONFIG_HOME="$REPO_ROOT" Z_LOG_LEVEL=NONE
source "$REPO_ROOT/lib/core/index.zsh" 2>/dev/null
source "$REPO_ROOT/lib/functions/index.zsh" 2>/dev/null
source "$REPO_ROOT/modules/05_history.zsh" 2>/dev/null

# ----------------------------------------------------------
# 1. docs/COMMANDS.md matches the generator output
# Generated in a clean subshell — identical to `just docs-commands`
# ----------------------------------------------------------
generated="$(cd "$REPO_ROOT" && ZDOTDIR="$REPO_ROOT" ZSH_CONFIG_HOME="$REPO_ROOT" Z_LOG_LEVEL=NONE zsh -c '
    source lib/core/index.zsh 2>/dev/null
    source lib/functions/index.zsh 2>/dev/null
    z_help --export-md
' 2>/dev/null)"
committed_file="$REPO_ROOT/docs/COMMANDS.md"

if [[ ! -f "$committed_file" ]]; then
    fail "docs/COMMANDS.md missing — run: just docs-commands"
elif [[ "$generated" == "$(<$committed_file)" ]]; then
    pass "docs/COMMANDS.md is in sync with the help registry"
else
    fail "docs/COMMANDS.md drifted — run: just docs-commands"
fi

# ----------------------------------------------------------
# 2. Every registry func resolves to a real function
# ----------------------------------------------------------
bad_funcs=0
for _alias in ${(k)_HELP_REGISTRY}; do
    _fn="${${(@s:|:)_HELP_REGISTRY[$_alias]}[3]}"
    if ! (( ${+functions[$_fn]} )); then
        fail "registry entry '$_alias' points at undefined function: $_fn"
        (( bad_funcs += 1 ))
    fi
done
(( bad_funcs == 0 )) && pass "all ${#_HELP_REGISTRY} registry entries resolve to real functions"

# ----------------------------------------------------------
# 3. Every public z_* function has a registry entry
#    (module-internal reload/show helpers are registered or exempt)
# ----------------------------------------------------------
typeset -A registered_fns
for _alias in ${(k)_HELP_REGISTRY}; do
    registered_fns[${${(@s:|:)_HELP_REGISTRY[$_alias]}[3]}]=1
done

# Exemptions: subcommand-style helpers surfaced through a registered parent
typeset -a exempt=(
    z_help                      # the help system itself
    z_path_show z_path_which z_path_debug z_path_invalid z_path_contains z_path_reload
    z_env_show z_env_status z_env_reload
    z_history_backup z_history_clean z_history_stats z_history_search
    z_xdg_fix z_xdg_status
    z_lazy_status z_cleanup_zwc
    z_wifi_name z_wifi_password
)

missing=0
for _fn in ${(k)functions}; do
    [[ "$_fn" == z_* ]] || continue
    (( ${+registered_fns[$_fn]} )) && continue
    (( ${exempt[(Ie)$_fn]} )) && continue
    fail "public function has no help entry: $_fn"
    (( missing += 1 ))
done
(( missing == 0 )) && pass "every public z_* function is registered (or exempt)"

# ----------------------------------------------------------
# SUMMARY
# ----------------------------------------------------------
print -r -- "---"
if (( FAILURES > 0 )); then
    print -r -- "FAIL: help sync — $FAILURES of $CHECKS checks failed"
    exit 1
fi
print -r -- "ok: help sync — all $CHECKS checks passed"
