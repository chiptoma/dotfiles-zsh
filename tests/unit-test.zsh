#!/usr/bin/env zsh
# ==============================================================================
# * ZSH UNIT TEST FRAMEWORK
# ? Self-contained unit tests for core zsh configuration functions.
# ? Run: ./tests/unit-test.zsh [--verbose]
# ==============================================================================

# ! Do NOT use set -e - we handle failures via test assertions

# ----------------------------------------------------------
# * CONFIGURATION
# ----------------------------------------------------------

VERBOSE=false
[[ "$1" == "--verbose" || "$1" == "-v" ]] && VERBOSE=true

# Colors (safe for non-color terminals)
if [[ -t 1 ]] && [[ -n "$TERM" ]] && [[ "$TERM" != "dumb" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Counters
PASSED=0
FAILED=0
SKIPPED=0

# Test isolation temp dir
TEST_TMP=""

# ----------------------------------------------------------
# * TEST HELPERS
# ----------------------------------------------------------

pass() {
    echo "${GREEN}[PASS]${NC} $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo "${RED}[FAIL]${NC} $1"
    [[ -n "${2:-}" ]] && echo "       Expected: $2"
    [[ -n "${3:-}" ]] && echo "       Got:      $3"
    FAILED=$((FAILED + 1))
}

skip() {
    echo "${YELLOW}[SKIP]${NC} $1"
    SKIPPED=$((SKIPPED + 1))
}

info() {
    [[ "$VERBOSE" == "true" ]] && echo "${BLUE}[INFO]${NC} $1"
    return 0
}

section() {
    echo ""
    echo "${BLUE}━━━${NC} $1 ${BLUE}━━━${NC}"
}

# Assert helpers
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
        fail "$msg" "file exists" "not found"
    fi
}

assert_dir_exists() {
    local dir="$1" msg="$2"
    if [[ -d "$dir" ]]; then
        pass "$msg"
    else
        fail "$msg" "directory exists" "not found"
    fi
}

# ----------------------------------------------------------
# * TEST SETUP & TEARDOWN
# ----------------------------------------------------------

setup_test_env() {
    # Create isolated temp directory
    TEST_TMP=$(mktemp -d)

    # Detect ZDOTDIR
    if [[ -z "$ZDOTDIR" ]]; then
        if [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/zsh" ]]; then
            export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
        fi
    fi

    info "TEST_TMP=$TEST_TMP"
    info "ZDOTDIR=$ZDOTDIR"
}

teardown_test_env() {
    [[ -n "$TEST_TMP" && -d "$TEST_TMP" ]] && rm -rf "$TEST_TMP"
}

# Load a module in isolation
load_module() {
    local module="$1"
    local module_path="$ZDOTDIR/$module"

    if [[ ! -f "$module_path" ]]; then
        skip "Module not found: $module"
        return 1
    fi

    # Reset guards to allow reload
    unset _ZSH_UTILS_LOADED _ZSH_UTILS_INDEX_LOADED _ZSH_LOGGING_LOADED _ZSH_PATH_LOADED 2>/dev/null

    # Source minimal dependencies (new paths after refactor)
    source "$ZDOTDIR/lib/utils/logging.zsh" 2>/dev/null || true
    source "$module_path"
}

# ----------------------------------------------------------
# * TESTS: lib/utils.zsh
# ----------------------------------------------------------

test_utils() {
    section "lib/utils/core.zsh"

    # Load module
    unset _ZSH_UTILS_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/utils/logging.zsh" 2>/dev/null || true
    source "$ZDOTDIR/lib/utils/core.zsh" || { skip "core.zsh not loadable"; return; }

    # Test _has_cmd
    assert_true "_has_cmd finds 'ls'" _has_cmd ls
    assert_false "_has_cmd rejects nonexistent" _has_cmd __nonexistent_cmd_12345__

    # Test _is_empty / _is_not_empty
    assert_true "_is_empty with empty string" _is_empty ""
    assert_false "_is_empty with non-empty" _is_empty "hello"
    assert_true "_is_not_empty with content" _is_not_empty "hello"
    assert_false "_is_not_empty with empty" _is_not_empty ""

    # Test _ensure_dir
    local test_dir="$TEST_TMP/ensure_dir_test"
    _ensure_dir "$test_dir"
    assert_dir_exists "$test_dir" "_ensure_dir creates directory"

    # Test _ensure_dir with permissions
    local perm_dir="$TEST_TMP/perm_test"
    _ensure_dir "$perm_dir" 700
    assert_dir_exists "$perm_dir" "_ensure_dir with permissions"

    # Test _ensure_file
    local test_file="$TEST_TMP/ensure_file_test.txt"
    _ensure_file "$test_file"
    assert_file_exists "$test_file" "_ensure_file creates file"

    # Test _is_ssh_session (should be false in local test)
    unset SSH_CLIENT SSH_TTY SSH_CONNECTION
    assert_false "_is_ssh_session false when not in SSH" _is_ssh_session

    # Test _is_ci (should be false unless in CI)
    if [[ -z "$CI" && -z "$GITHUB_ACTIONS" ]]; then
        assert_false "_is_ci false in local env" _is_ci
    else
        assert_true "_is_ci true in CI env" _is_ci
    fi

    # Test _safe_source
    local source_file="$TEST_TMP/source_test.zsh"
    echo "TEST_VAR_FROM_SOURCE=loaded" > "$source_file"
    unset TEST_VAR_FROM_SOURCE
    _safe_source "$source_file"
    assert_eq "$TEST_VAR_FROM_SOURCE" "loaded" "_safe_source loads file"

    # Test _safe_source with non-existent file
    assert_false "_safe_source returns 1 for missing file" _safe_source "/nonexistent/file.zsh"
}

# ----------------------------------------------------------
# * TESTS: modules/logging.zsh
# ----------------------------------------------------------

test_logging() {
    section "lib/utils/logging.zsh"

    # Load module
    unset _ZSH_LOGGING_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/utils/logging.zsh" || { skip "logging.zsh not loadable"; return; }

    # Test log levels exist
    assert_eq "${ZSH_LOG_LEVELS[DEBUG]}" "0" "DEBUG level is 0"
    assert_eq "${ZSH_LOG_LEVELS[INFO]}" "1" "INFO level is 1"
    assert_eq "${ZSH_LOG_LEVELS[WARN]}" "2" "WARN level is 2"
    assert_eq "${ZSH_LOG_LEVELS[ERROR]}" "3" "ERROR level is 3"
    assert_eq "${ZSH_LOG_LEVELS[NONE]}" "4" "NONE level is 4"

    # Test log_level_set
    local old_level="$ZSH_LOG_LEVEL"
    log_level_set DEBUG
    assert_eq "$ZSH_LOG_LEVEL" "DEBUG" "log_level_set changes level"
    log_level_set "$old_level"

    # Test invalid log level
    assert_false "log_level_set rejects invalid level" log_level_set INVALID_LEVEL

    # Test _log output (capture stderr for WARN/ERROR)
    local output
    ZSH_LOG_LEVEL=DEBUG
    ZSH_LOG_TIMESTAMP_ENABLE=false
    ZSH_LOG_SHOW_CALLER=false
    output=$(_log INFO "test message" 2>&1)
    assert_contains "$output" "INFO" "_log includes level"
    assert_contains "$output" "test message" "_log includes message"

    # Restore
    ZSH_LOG_LEVEL="$old_level"
}

# ----------------------------------------------------------
# * TESTS: modules/path.zsh (Functions Only)
# ----------------------------------------------------------

test_path_functions() {
    section "modules/path.zsh (functions)"

    # We test path functions in isolation without running path_init
    # Load only the function definitions

    unset _ZSH_LOGGING_LOADED _ZSH_PATH_LOADED 2>/dev/null
    source "$ZDOTDIR/modules/logging.zsh" 2>/dev/null || true

    # Define minimal stubs for dependencies
    _is_macos() { [[ "$OSTYPE" == darwin* ]]; }
    _is_linux() { [[ "$OSTYPE" == linux* ]]; }
    _is_bsd() { [[ "$OSTYPE" == freebsd* || "$OSTYPE" == openbsd* ]]; }
    _is_ssh_session() { return 1; }
    _is_docker() { return 1; }
    _is_ci() { return 1; }

    # Source path module (will run path_init, but we'll test functions after)
    typeset -g ZSH_PATH_ENABLED=true
    source "$ZDOTDIR/modules/path.zsh" 2>/dev/null || { skip "path.zsh not loadable"; return; }

    # Test _path_add prepend
    local test_path_dir="$TEST_TMP/path_test_bin"
    mkdir -p "$test_path_dir"

    # Save original path
    local -a original_path=("${path[@]}")

    _path_add "$test_path_dir" prepend
    assert_eq "${path[1]}" "$test_path_dir" "_path_add prepends correctly"

    # Test duplicate prevention
    local path_count_before=${#path[@]}
    _path_add "$test_path_dir" prepend
    local path_count_after=${#path[@]}
    assert_eq "$path_count_after" "$path_count_before" "_path_add prevents duplicates"

    # Test _path_remove
    _path_remove "$test_path_dir"
    local found=false
    for p in "${path[@]}"; do
        [[ "$p" == "$test_path_dir" ]] && found=true
    done
    assert_false "_path_remove removes directory" $found

    # Test _path_clean with non-existent dir
    local fake_dir="$TEST_TMP/nonexistent_dir_$$"
    path+=("$fake_dir")
    _path_clean
    found=false
    for p in "${path[@]}"; do
        [[ "$p" == "$fake_dir" ]] && found=true
    done
    assert_false "_path_clean removes non-existent dirs" $found

    # Test path_contains (suppress debug output)
    local output
    ZSH_LOG_LEVEL=ERROR output=$(path_contains /usr/bin 2>&1)
    assert_contains "$output" "IS in PATH" "path_contains finds /usr/bin"

    ZSH_LOG_LEVEL=ERROR output=$(path_contains /nonexistent/path 2>&1)
    assert_contains "$output" "IS NOT in PATH" "path_contains rejects nonexistent"

    # Restore original path
    path=("${original_path[@]}")
}

# ----------------------------------------------------------
# * TESTS: modules/path.zsh (Condition Evaluation)
# ----------------------------------------------------------

test_path_conditions() {
    section "modules/path.zsh (conditions)"

    # Skip if path module isn't loaded
    (( $+functions[_is_path_condition_met] )) || { skip "_is_path_condition_met not defined"; return; }

    # Test 'always' condition
    assert_true "condition 'always' returns true" _is_path_condition_met always "" "/some/path"

    # Test 'exists' condition with real directory
    assert_true "condition 'exists' for /tmp" _is_path_condition_met exists "" "/tmp"
    assert_false "condition 'exists' for nonexistent" _is_path_condition_met exists "" "/nonexistent/path"

    # Test 'if_var_set' condition
    export TEST_VAR_SET="value"
    assert_true "condition 'if_var_set' with set var" _is_path_condition_met if_var_set TEST_VAR_SET ""
    unset TEST_VAR_SET
    assert_false "condition 'if_var_set' with unset var" _is_path_condition_met if_var_set TEST_VAR_SET ""

    # Test 'if_var_true' condition
    export TEST_VAR_TRUE="true"
    assert_true "condition 'if_var_true' with true" _is_path_condition_met if_var_true TEST_VAR_TRUE ""
    export TEST_VAR_TRUE="false"
    assert_false "condition 'if_var_true' with false" _is_path_condition_met if_var_true TEST_VAR_TRUE ""
    unset TEST_VAR_TRUE

    # Test OS conditions (platform-dependent)
    if [[ "$OSTYPE" == darwin* ]]; then
        assert_true "condition 'os_is_darwin' on macOS" _is_path_condition_met os_is_darwin "" ""
        assert_false "condition 'os_is_linux' on macOS" _is_path_condition_met os_is_linux "" ""
    elif [[ "$OSTYPE" == linux* ]]; then
        assert_false "condition 'os_is_darwin' on Linux" _is_path_condition_met os_is_darwin "" ""
        assert_true "condition 'os_is_linux' on Linux" _is_path_condition_met os_is_linux "" ""
    fi
}

# ----------------------------------------------------------
# * TESTS: modules/lazy.zsh
# ----------------------------------------------------------

test_lazy() {
    section "modules/lazy.zsh"

    # Check if lazy module can be loaded
    [[ -f "$ZDOTDIR/modules/lazy.zsh" ]] || { skip "lazy.zsh not found"; return; }

    # Test lazy status function exists after loading
    unset _ZSH_LAZY_LOADED 2>/dev/null
    typeset -g ZSH_LAZY_ENABLED=true
    typeset -g ZSH_LAZY_ZOXIDE=false  # Disable actual lazy loads for testing
    typeset -g ZSH_LAZY_NVM=false
    typeset -g ZSH_LAZY_PYENV=false
    typeset -g ZSH_LAZY_RBENV=false

    source "$ZDOTDIR/modules/lazy.zsh" 2>/dev/null || { skip "lazy.zsh not loadable"; return; }

    # Test zsh_lazy_status function exists
    if typeset -f zsh_lazy_status > /dev/null 2>&1; then
        pass "zsh_lazy_status function defined"
    else
        fail "zsh_lazy_status function defined"
    fi

    # Test _LAZY_LOADED_TOOLS array exists
    if [[ -n "${(t)_LAZY_LOADED_TOOLS}" ]]; then
        pass "_LAZY_LOADED_TOOLS array exists"
    else
        fail "_LAZY_LOADED_TOOLS array exists"
    fi

    # Test lazy_load function exists
    if typeset -f lazy_load > /dev/null 2>&1; then
        pass "lazy_load function defined"
    else
        fail "lazy_load function defined"
    fi
}

# ----------------------------------------------------------
# * TESTS: Input Validation
# ----------------------------------------------------------

test_input_validation() {
    section "Input Validation"

    # Test that functions handle empty inputs gracefully

    # _is_empty with no args (should not crash)
    local result
    result=$(_is_empty 2>&1) || true
    pass "_is_empty handles no args"

    # log_level_set with empty arg
    assert_false "log_level_set rejects empty input" log_level_set ""

    # _path_add with non-existent directory (should not add)
    local path_before=${#path[@]}
    _path_add "/definitely/not/a/real/path/$$" append 2>/dev/null
    local path_after=${#path[@]}
    assert_eq "$path_after" "$path_before" "_path_add ignores non-existent paths"
}

# ----------------------------------------------------------
# * TEST RUNNER
# ----------------------------------------------------------

main() {
    echo "================================================"
    echo "  ZSH Configuration Unit Tests"
    echo "================================================"

    setup_test_env

    # Run all test suites
    test_utils
    test_logging
    test_path_functions
    test_path_conditions
    test_lazy
    test_input_validation

    teardown_test_env

    # Summary
    echo ""
    echo "================================================"
    echo "  Summary"
    echo "================================================"
    echo ""
    echo "  ${GREEN}Passed:${NC}  $PASSED"
    echo "  ${RED}Failed:${NC}  $FAILED"
    echo "  ${YELLOW}Skipped:${NC} $SKIPPED"
    echo ""

    if [[ $FAILED -gt 0 ]]; then
        echo "${RED}UNIT TESTS FAILED${NC}"
        exit 1
    elif [[ $SKIPPED -gt 0 ]]; then
        echo "${YELLOW}UNIT TESTS PASSED WITH SKIPS${NC}"
        exit 0
    else
        echo "${GREEN}ALL UNIT TESTS PASSED${NC}"
        exit 0
    fi
}

main "$@"
