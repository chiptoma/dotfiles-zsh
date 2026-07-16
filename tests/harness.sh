#!/usr/bin/env bash
# ==============================================================================
# SHARED BASH TEST HARNESS
# Bash-3.2-safe mirror of harness.zsh for the bash test suites.
# ------------------------------------------------------------------------------
# Context: sourced by installer-integration.sh, installer-unit.sh, and
#   structure-test.sh. Same names, vocabulary, and summary as harness.zsh.
# Scope: assert_* record pass/fail internally (safe under set -e); check_*
#   variants return 0/1 for use inside if-conditions.
# NOTE: no assoc arrays, no mapfile, no ((x++))-as-statement — macOS bash 3.2.
# ==============================================================================

# Idempotent guard
[ -n "${_SH_TEST_HARNESS_LOADED:-}" ] && return 0
_SH_TEST_HARNESS_LOADED=1

# ----------------------------------------------------------
# COLORS & COUNTERS
# ----------------------------------------------------------

# Colors (tty only; honors NO_COLOR and dumb terminals)
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ -n "${TERM:-}" ] && [ "${TERM:-}" != "dumb" ]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[0;33m'
    BLUE=$'\033[0;34m'
    NC=$'\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

PASSED=0
FAILED=0
SKIPPED=0
WARNINGS=0

# Suites parse --verbose before sourcing; default off otherwise
VERBOSE="${VERBOSE:-false}"

# Test isolation temp dir (set by setup_test_env)
TEST_TMP="${TEST_TMP:-}"

# ----------------------------------------------------------
# RESULT REPORTERS
# ----------------------------------------------------------

pass() {
    printf '%s\n' "${GREEN}[PASS]${NC} $1"
    PASSED=$((PASSED + 1))
}

fail() {
    printf '%s\n' "${RED}[FAIL]${NC} $1"
    [ -n "${2:-}" ] && printf '%s\n' "       Expected: $2"
    [ -n "${3:-}" ] && printf '%s\n' "       Got:      $3"
    FAILED=$((FAILED + 1))
}

skip() {
    printf '%s\n' "${YELLOW}[SKIP]${NC} $1"
    SKIPPED=$((SKIPPED + 1))
}

warn() {
    printf '%s\n' "${YELLOW}[WARN]${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

info() {
    [ "$VERBOSE" = "true" ] && printf '%s\n' "${BLUE}[INFO]${NC} $1"
    return 0
}

section() {
    printf '\n%s\n' "${BLUE}━━━${NC} $1 ${BLUE}━━━${NC}"
}

# ----------------------------------------------------------
# ASSERTIONS (record results; always return 0)
# ----------------------------------------------------------

assert_eq() {
    if [ "$1" = "$2" ]; then
        pass "$3"
    else
        fail "$3" "$2" "$1"
    fi
}

assert_ne() {
    if [ "$1" != "$2" ]; then
        pass "$3"
    else
        fail "$3" "not $2" "$1"
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
    if "$@"; then
        fail "$msg" "false" "true"
    else
        pass "$msg"
    fi
}

assert_contains() {
    case "$1" in
        *"$2"*) pass "$3" ;;
        *)      fail "$3" "contains '$2'" "'$1'" ;;
    esac
}

assert_file_exists() {
    if [ -f "$1" ]; then
        pass "$2"
    else
        fail "$2" "file exists: $1" "not found"
    fi
}

assert_dir_exists() {
    if [ -d "$1" ]; then
        pass "$2"
    else
        fail "$2" "directory exists: $1" "not found"
    fi
}

assert_dir_not_exists() {
    if [ ! -d "$1" ]; then
        pass "$2"
    else
        fail "$2" "directory absent: $1" "exists"
    fi
}

assert_file_contains() {
    if grep -q "$2" "$1" 2>/dev/null; then
        pass "$3"
    else
        fail "$3" "pattern '$2' in $1" "not found"
    fi
}

assert_is_symlink() {
    if [ -L "$1" ]; then
        pass "$2"
    else
        fail "$2" "symlink: $1" "not a symlink"
    fi
}

# ----------------------------------------------------------
# CHECK VARIANTS (return 0/1 for if-conditions; no recording)
# ----------------------------------------------------------

check_file_exists() {
    if [ -f "$1" ]; then
        return 0
    fi
    printf '%s\n' "       Expected file: $1"
    return 1
}

check_dir_exists() {
    if [ -d "$1" ]; then
        return 0
    fi
    printf '%s\n' "       Expected directory: $1"
    return 1
}

check_dir_not_exists() {
    if [ ! -d "$1" ]; then
        return 0
    fi
    printf '%s\n' "       Directory should not exist: $1"
    return 1
}

check_file_contains() {
    if grep -q "$2" "$1" 2>/dev/null; then
        return 0
    fi
    printf '%s\n' "       Pattern not found in $1: $2"
    return 1
}

check_is_symlink() {
    if [ -L "$1" ]; then
        return 0
    fi
    printf '%s\n' "       Expected symlink: $1"
    return 1
}

# ----------------------------------------------------------
# TEST ENVIRONMENT
# ----------------------------------------------------------

setup_test_env() {
    TEST_TMP=$(mktemp -d)
    trap 'teardown_test_env' EXIT INT TERM
}

teardown_test_env() {
    if [ -n "${TEST_TMP:-}" ] && [ -d "${TEST_TMP:-}" ]; then
        rm -rf "$TEST_TMP"
    fi
    TEST_TMP=""
    return 0
}

# ----------------------------------------------------------
# SKIP PREDICATES
# ----------------------------------------------------------

# Records a skip and returns 0 when <cmd> is missing; returns 1 when present.
# Usage: _skip_unless_cmd unzip "zip roundtrip" && return
_skip_unless_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        return 1
    fi
    skip "${2:-$1 required} ($1 not installed)"
    return 0
}

_is_ci_or_container() {
    [ -f /.dockerenv ] || [ "${CI:-}" = "true" ] || [ "${GITHUB_ACTIONS:-}" = "true" ]
}

# Records a skip and returns 0 outside CI/container; returns 1 inside.
# Usage: _skip_unless_ci_or_container "installer run" && return
_skip_unless_ci_or_container() {
    if _is_ci_or_container; then
        return 1
    fi
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
    printf '%s\n' "  ${GREEN}Passed:${NC}   $PASSED"
    printf '%s\n' "  ${RED}Failed:${NC}   $FAILED"
    printf '%s\n' "  ${YELLOW}Skipped:${NC}  $SKIPPED"
    printf '%s\n' "  ${YELLOW}Warnings:${NC} $WARNINGS"
    echo ""
    if [ "$FAILED" -gt 0 ]; then
        printf '%s\n' "FAIL: $suite — $FAILED of $((PASSED + FAILED)) checks failed"
        return 1
    fi
    printf '%s\n' "ok: $suite — $PASSED passed, $SKIPPED skipped, $WARNINGS warnings"
    return 0
}
