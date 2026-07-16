#!/usr/bin/env zsh
# ==============================================================================
# SHARED ZSH TEST HARNESS
# Common colors, counters, assertions, env setup, and summary for zsh suites.
# ------------------------------------------------------------------------------
# Context: sourced by unit-test.zsh, smoke-test.zsh, and help-sync-test.zsh.
# Scope: [PASS]/[FAIL]/[SKIP]/[WARN] per-check vocabulary, boxed summary via
#   print_summary, and a final machine-greppable "ok: <suite> — ..." /
#   "FAIL: <suite> — ..." line that Justfile/CI rely on.
# NOTE: assert_* helpers record pass/fail internally and always return 0 so
#   they are safe under `set -e`; use them as statements, not if-conditions.
# ==============================================================================

# Idempotent guard
(( ${+_Z_TEST_HARNESS_LOADED} )) && return 0
typeset -g _Z_TEST_HARNESS_LOADED=1

# ----------------------------------------------------------
# COLORS & COUNTERS
# ----------------------------------------------------------

# Colors (tty only; honors NO_COLOR and dumb terminals)
if [[ -t 1 && -z "${NO_COLOR:-}" && -n "${TERM:-}" && "${TERM:-}" != "dumb" ]]; then
    typeset -g RED=$'\033[0;31m'
    typeset -g GREEN=$'\033[0;32m'
    typeset -g YELLOW=$'\033[0;33m'
    typeset -g BLUE=$'\033[0;34m'
    typeset -g NC=$'\033[0m'
else
    typeset -g RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

typeset -g PASSED=0
typeset -g FAILED=0
typeset -g SKIPPED=0
typeset -g WARNINGS=0

# Suites parse --verbose before sourcing; default off otherwise
typeset -g VERBOSE="${VERBOSE:-false}"

# Test isolation temp dir (set by setup_test_env)
typeset -g TEST_TMP="${TEST_TMP:-}"

# ----------------------------------------------------------
# RESULT REPORTERS
# ----------------------------------------------------------

pass() {
    print -r -- "${GREEN}[PASS]${NC} $1"
    PASSED=$((PASSED + 1))
}

fail() {
    print -r -- "${RED}[FAIL]${NC} $1"
    [[ -n "${2:-}" ]] && print -r -- "       Expected: $2"
    [[ -n "${3:-}" ]] && print -r -- "       Got:      $3"
    FAILED=$((FAILED + 1))
}

skip() {
    print -r -- "${YELLOW}[SKIP]${NC} $1"
    SKIPPED=$((SKIPPED + 1))
}

warn() {
    print -r -- "${YELLOW}[WARN]${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

info() {
    [[ "$VERBOSE" == "true" ]] && print -r -- "${BLUE}[INFO]${NC} $1"
    return 0
}

section() {
    print
    print -r -- "${BLUE}━━━${NC} $1 ${BLUE}━━━${NC}"
}

# ----------------------------------------------------------
# ASSERTIONS
# Each records the result internally and takes a description.
# ----------------------------------------------------------

assert_eq() {
    local actual="$1" expected="$2" msg="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$msg"
    else
        fail "$msg" "$expected" "$actual"
    fi
}

assert_ne() {
    local actual="$1" unexpected="$2" msg="$3"
    if [[ "$actual" != "$unexpected" ]]; then
        pass "$msg"
    else
        fail "$msg" "not $unexpected" "$actual"
    fi
}

assert_true() {
    local msg="$1"
    shift
    if "$@"; then
        pass "$msg"
    else
        fail "$msg" "true" "false"
    fi
}

assert_false() {
    local msg="$1"
    shift
    if ! "$@"; then
        pass "$msg"
    else
        fail "$msg" "false" "true"
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" msg="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass "$msg"
    else
        fail "$msg" "contains '$needle'" "'$haystack'"
    fi
}

assert_file_exists() {
    local file="$1" msg="$2"
    if [[ -f "$file" ]]; then
        pass "$msg"
    else
        fail "$msg" "file exists: $file" "not found"
    fi
}

assert_dir_exists() {
    local dir="$1" msg="$2"
    if [[ -d "$dir" ]]; then
        pass "$msg"
    else
        fail "$msg" "directory exists: $dir" "not found"
    fi
}

assert_dir_not_exists() {
    local dir="$1" msg="$2"
    if [[ ! -d "$dir" ]]; then
        pass "$msg"
    else
        fail "$msg" "directory absent: $dir" "exists"
    fi
}

assert_file_contains() {
    local file="$1" pattern="$2" msg="$3"
    if grep -q "$pattern" "$file" 2>/dev/null; then
        pass "$msg"
    else
        fail "$msg" "pattern '$pattern' in $file" "not found"
    fi
}

assert_is_symlink() {
    local target="$1" msg="$2"
    if [[ -L "$target" ]]; then
        pass "$msg"
    else
        fail "$msg" "symlink: $target" "not a symlink"
    fi
}

# ----------------------------------------------------------
# TEST ENVIRONMENT
# ----------------------------------------------------------

setup_test_env() {
    TEST_TMP=$(mktemp -d)
}

teardown_test_env() {
    if [[ -n "${TEST_TMP:-}" && -d "${TEST_TMP:-}" ]]; then
        rm -rf "$TEST_TMP"
    fi
    TEST_TMP=""
    return 0
}

# Registered at source time: zsh EXIT traps set inside a function are
# function-scoped and would tear the temp dir down as soon as setup returns.
trap 'teardown_test_env' EXIT INT TERM

# ----------------------------------------------------------
# SKIP PREDICATES
# ----------------------------------------------------------

# Records a skip and returns 0 when <cmd> is missing; returns 1 when present.
# Usage: _skip_unless_cmd unzip "zip roundtrip" && return
_skip_unless_cmd() {
    command -v "$1" >/dev/null 2>&1 && return 1
    skip "${2:-$1 required} ($1 not installed)"
    return 0
}

_is_ci_or_container() {
    [[ -f /.dockerenv || "${CI:-}" == "true" || "${GITHUB_ACTIONS:-}" == "true" ]]
}

# Records a skip and returns 0 outside CI/container; returns 1 inside.
# Usage: _skip_unless_ci_or_container "installer run" && return
_skip_unless_ci_or_container() {
    _is_ci_or_container && return 1
    skip "${1:-requires CI or container environment}"
    return 0
}

# ----------------------------------------------------------
# SUMMARY
# ----------------------------------------------------------

# Prints the boxed summary and the machine-greppable final line.
# Usage: print_summary <suite-name>
# Returns: 0 when all checks passed, 1 when any failed.
print_summary() {
    local suite="$1"
    echo ""
    echo "================================================"
    echo "  Summary"
    echo "================================================"
    echo ""
    print -r -- "  ${GREEN}Passed:${NC}   $PASSED"
    print -r -- "  ${RED}Failed:${NC}   $FAILED"
    print -r -- "  ${YELLOW}Skipped:${NC}  $SKIPPED"
    print -r -- "  ${YELLOW}Warnings:${NC} $WARNINGS"
    echo ""
    if (( FAILED > 0 )); then
        print -r -- "FAIL: $suite — $FAILED of $((PASSED + FAILED)) checks failed"
        return 1
    fi
    print -r -- "ok: $suite — $PASSED passed, $SKIPPED skipped, $WARNINGS warnings"
    return 0
}
