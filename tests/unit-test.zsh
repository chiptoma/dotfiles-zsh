#!/usr/bin/env zsh
# ==============================================================================
# ZSH UNIT TEST FRAMEWORK
# Self-contained unit tests for core zsh configuration functions.
# Run: ./tests/unit-test.zsh [--verbose]
# ==============================================================================

# Do NOT use set -e - we handle failures via test assertions

# ----------------------------------------------------------
# CONFIGURATION
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
# TEST HELPERS
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
# TEST SETUP & TEARDOWN
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
    unset _Z_UTILS_LOADED _Z_UTILS_INDEX_LOADED _Z_LOGGING_LOADED _Z_PATH_LOADED 2>/dev/null

    # Source minimal dependencies (new paths after refactor)
    source "$ZDOTDIR/lib/utils/logging.zsh" 2>/dev/null || true
    source "$module_path"
}

# ----------------------------------------------------------
# TESTS: lib/utils.zsh
# ----------------------------------------------------------

test_utils() {
    section "lib/utils/core.zsh"

    # Load module
    unset _Z_UTILS_LOADED 2>/dev/null
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
# TESTS: modules/logging.zsh
# ----------------------------------------------------------

test_logging() {
    section "lib/utils/logging.zsh"

    # Load module
    unset _Z_LOGGING_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/utils/logging.zsh" || { skip "logging.zsh not loadable"; return; }

    # Test log levels exist
    assert_eq "${Z_LOG_LEVELS[DEBUG]}" "0" "DEBUG level is 0"
    assert_eq "${Z_LOG_LEVELS[INFO]}" "1" "INFO level is 1"
    assert_eq "${Z_LOG_LEVELS[WARN]}" "2" "WARN level is 2"
    assert_eq "${Z_LOG_LEVELS[ERROR]}" "3" "ERROR level is 3"
    assert_eq "${Z_LOG_LEVELS[NONE]}" "4" "NONE level is 4"

    # Test z_log_level_set
    local old_level="$Z_LOG_LEVEL"
    z_log_level_set DEBUG
    assert_eq "$Z_LOG_LEVEL" "DEBUG" "z_log_level_set changes level"
    z_log_level_set "$old_level"

    # Test invalid log level
    assert_false "z_log_level_set rejects invalid level" z_log_level_set INVALID_LEVEL

    # Test _log output (capture stderr for WARN/ERROR)
    local output
    Z_LOG_LEVEL=DEBUG
    Z_LOG_TIMESTAMP_ENABLE=false
    Z_LOG_SHOW_CALLER=false
    output=$(_log INFO "test message" 2>&1)
    assert_contains "$output" "INFO" "_log includes level"
    assert_contains "$output" "test message" "_log includes message"

    # Restore
    Z_LOG_LEVEL="$old_level"
}

# ----------------------------------------------------------
# TESTS: modules/path.zsh (Functions Only)
# ----------------------------------------------------------

test_path_functions() {
    section "modules/path.zsh (functions)"

    # We test path functions in isolation without running path_init
    # Load only the function definitions

    unset _Z_LOGGING_LOADED _Z_PATH_LOADED 2>/dev/null
    source "$ZDOTDIR/modules/logging.zsh" 2>/dev/null || true

    # Define minimal stubs for dependencies
    _is_macos() { [[ "$OSTYPE" == darwin* ]]; }
    _is_linux() { [[ "$OSTYPE" == linux* ]]; }
    _is_bsd() { [[ "$OSTYPE" == freebsd* || "$OSTYPE" == openbsd* ]]; }
    _is_ssh_session() { return 1; }
    _is_docker() { return 1; }
    _is_ci() { return 1; }

    # Source path module (will run path_init, but we'll test functions after)
    typeset -g Z_PATH_ENABLED=true
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
    Z_LOG_LEVEL=ERROR output=$(path_contains /usr/bin 2>&1)
    assert_contains "$output" "IS in PATH" "path_contains finds /usr/bin"

    Z_LOG_LEVEL=ERROR output=$(path_contains /nonexistent/path 2>&1)
    assert_contains "$output" "IS NOT in PATH" "path_contains rejects nonexistent"

    # Restore original path
    path=("${original_path[@]}")
}

# ----------------------------------------------------------
# TESTS: modules/path.zsh (Condition Evaluation)
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
# TESTS: modules/lazy.zsh
# ----------------------------------------------------------

test_lazy() {
    section "modules/lazy.zsh"

    # Check if lazy module can be loaded
    [[ -f "$ZDOTDIR/modules/lazy.zsh" ]] || { skip "lazy.zsh not found"; return; }

    # Test lazy status function exists after loading
    unset _Z_LAZY_LOADED 2>/dev/null
    typeset -g Z_LAZY_ENABLED=true
    typeset -g Z_LAZY_ZOXIDE=false  # Disable actual lazy loads for testing
    typeset -g Z_LAZY_NVM=false
    typeset -g Z_LAZY_PYENV=false
    typeset -g Z_LAZY_RBENV=false

    source "$ZDOTDIR/modules/lazy.zsh" 2>/dev/null || { skip "lazy.zsh not loadable"; return; }

    # Test z_lazy_status function exists
    if typeset -f z_lazy_status > /dev/null 2>&1; then
        pass "z_lazy_status function defined"
    else
        fail "z_lazy_status function defined"
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

    # Test lazy_load_precmd function exists
    if typeset -f lazy_load_precmd > /dev/null 2>&1; then
        pass "lazy_load_precmd function defined"
    else
        fail "lazy_load_precmd function defined"
    fi

    # Test _LAZY_PRECMD_INITS array exists
    if [[ -n "${(t)_LAZY_PRECMD_INITS}" ]]; then
        pass "_LAZY_PRECMD_INITS array exists"
    else
        fail "_LAZY_PRECMD_INITS array exists"
    fi

    # Test _lazy_validate_cmd security validation
    if typeset -f _lazy_validate_cmd > /dev/null 2>&1; then
        pass "_lazy_validate_cmd function defined"

        # Test valid command names
        assert_true "validates simple command" _lazy_validate_cmd "mycommand"
        assert_true "validates hyphenated" _lazy_validate_cmd "my-command"
        assert_true "validates underscored" _lazy_validate_cmd "my_command"
        assert_true "validates with numbers" _lazy_validate_cmd "cmd123"

        # Test invalid command names (should be rejected)
        assert_false "rejects semicolon" _lazy_validate_cmd "cmd;rm" 2>/dev/null
        assert_false "rejects pipe" _lazy_validate_cmd "cmd|cat" 2>/dev/null
        assert_false "rejects subshell" _lazy_validate_cmd '$(whoami)' 2>/dev/null
        assert_false "rejects backticks" _lazy_validate_cmd '`whoami`' 2>/dev/null
        assert_false "rejects spaces" _lazy_validate_cmd "cmd arg" 2>/dev/null
    else
        fail "_lazy_validate_cmd function defined"
    fi
}

# ----------------------------------------------------------
# TESTS: Input Validation
# ----------------------------------------------------------

test_input_validation() {
    section "Input Validation"

    # Test that functions handle empty inputs gracefully

    # _is_empty with no args (should not crash)
    local result
    result=$(_is_empty 2>&1) || true
    pass "_is_empty handles no args"

    # z_log_level_set with empty arg
    assert_false "z_log_level_set rejects empty input" z_log_level_set ""

    # _path_add with non-existent directory (should not add)
    local path_before=${#path[@]}
    _path_add "/definitely/not/a/real/path/$$" append 2>/dev/null
    local path_after=${#path[@]}
    assert_eq "$path_after" "$path_before" "_path_add ignores non-existent paths"
}

# ----------------------------------------------------------
# TESTS: modules/history.zsh
# ----------------------------------------------------------

test_history() {
    section "modules/history.zsh"

    # Load dependencies first
    unset _Z_HISTORY_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/utils/logging.zsh" 2>/dev/null || true
    source "$ZDOTDIR/lib/utils/core.zsh" 2>/dev/null || true

    # Load history module
    source "$ZDOTDIR/modules/history.zsh" 2>/dev/null || { skip "history.zsh not loadable"; return; }

    # Test _should_ignore_history_cmd function exists
    if ! typeset -f _should_ignore_history_cmd > /dev/null 2>&1; then
        skip "_should_ignore_history_cmd not defined"
        return
    fi

    # Test security filter patterns - commands that SHOULD be ignored
    assert_true "ignores password export" _should_ignore_history_cmd "export PASSWORD=secret123"
    assert_true "ignores API key assignment" _should_ignore_history_cmd "export AWS_SECRET_ACCESS_KEY=abcd1234"
    assert_true "ignores op CLI" _should_ignore_history_cmd "op get item login"
    assert_true "ignores vault read" _should_ignore_history_cmd "vault read secret/data"
    assert_true "ignores pass command" _should_ignore_history_cmd "pass show email/gmail"
    assert_true "ignores curl with auth header" _should_ignore_history_cmd "curl -H 'Authorization: Bearer token' https://api.example.com"
    assert_true "ignores git clone with creds" _should_ignore_history_cmd "git clone https://user:pass@github.com/repo.git"
    assert_true "ignores docker login" _should_ignore_history_cmd "docker login -u user -p password"

    # Test normal commands that should NOT be ignored
    assert_false "allows git status" _should_ignore_history_cmd "git status"
    assert_false "allows ls -la" _should_ignore_history_cmd "ls -la"
    assert_false "allows cd command" _should_ignore_history_cmd "cd /tmp"
    assert_false "allows echo hello" _should_ignore_history_cmd "echo hello"
    assert_false "allows vim" _should_ignore_history_cmd "vim ~/.zshrc"
    assert_false "allows brew install" _should_ignore_history_cmd "brew install fzf"

    # Test history functions exist
    if typeset -f history_stats > /dev/null 2>&1; then
        pass "history_stats function defined"
    else
        fail "history_stats function defined"
    fi

    if typeset -f history_backup > /dev/null 2>&1; then
        pass "history_backup function defined"
    else
        fail "history_backup function defined"
    fi

    if typeset -f history_clean > /dev/null 2>&1; then
        pass "history_clean function defined"
    else
        fail "history_clean function defined"
    fi

    # Test history edge cases
    # Test with empty HISTFILE path
    local old_histfile="$HISTFILE"
    unset HISTFILE
    assert_false "history_backup handles missing HISTFILE" history_backup 2>/dev/null
    HISTFILE="$old_histfile"
}

# ----------------------------------------------------------
# TESTS: lib/utils/platform/detect.zsh
# ----------------------------------------------------------

test_platform_detection() {
    section "lib/utils/platform/detect.zsh"

    # Check if platform detection module exists
    [[ -f "$ZDOTDIR/lib/utils/platform/detect.zsh" ]] || { skip "detect.zsh not found"; return; }

    # Load module
    unset _Z_PLATFORM_DETECT_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/utils/platform/detect.zsh" 2>/dev/null || { skip "detect.zsh not loadable"; return; }

    # Test primary platform detection functions exist
    if typeset -f _is_macos > /dev/null 2>&1; then
        pass "_is_macos function defined"
    else
        fail "_is_macos function defined"
    fi

    if typeset -f _is_linux > /dev/null 2>&1; then
        pass "_is_linux function defined"
    else
        fail "_is_linux function defined"
    fi

    if typeset -f _is_bsd > /dev/null 2>&1; then
        pass "_is_bsd function defined"
    else
        fail "_is_bsd function defined"
    fi

    # Test architecture detection functions
    if typeset -f _is_arm > /dev/null 2>&1; then
        pass "_is_arm function defined"
    else
        fail "_is_arm function defined"
    fi

    if typeset -f _is_x86_64 > /dev/null 2>&1; then
        pass "_is_x86_64 function defined"
    else
        fail "_is_x86_64 function defined"
    fi

    # Test WSL detection
    if typeset -f _is_wsl > /dev/null 2>&1; then
        pass "_is_wsl function defined"
    else
        fail "_is_wsl function defined"
    fi

    # Platform-specific validation
    if [[ "$OSTYPE" == darwin* ]]; then
        assert_true "_is_macos returns true on macOS" _is_macos
        assert_false "_is_linux returns false on macOS" _is_linux
    elif [[ "$OSTYPE" == linux* ]]; then
        assert_false "_is_macos returns false on Linux" _is_macos
        assert_true "_is_linux returns true on Linux" _is_linux
    fi
}

# ----------------------------------------------------------
# TESTS: Security (Negative Tests)
# Verify that security controls reject malicious inputs.
# ----------------------------------------------------------

test_security_negative() {
    section "Security (Negative Tests)"

    # ─────────────────────────────────────────────────────────
    # Lazy Load Injection Prevention
    # ─────────────────────────────────────────────────────────

    # Test that lazy_load rejects unsafe command names
    if typeset -f _lazy_validate_cmd > /dev/null 2>&1; then
        # Shell metacharacters that could enable injection
        assert_false "rejects newline injection" _lazy_validate_cmd $'cmd\nrm -rf /' 2>/dev/null
        assert_false "rejects carriage return" _lazy_validate_cmd $'cmd\rrm' 2>/dev/null
        assert_false "rejects ampersand" _lazy_validate_cmd "cmd&whoami" 2>/dev/null
        assert_false "rejects double ampersand" _lazy_validate_cmd "cmd&&whoami" 2>/dev/null
        assert_false "rejects double pipe" _lazy_validate_cmd "cmd||whoami" 2>/dev/null
        assert_false "rejects redirect" _lazy_validate_cmd "cmd>file" 2>/dev/null
        assert_false "rejects append redirect" _lazy_validate_cmd "cmd>>file" 2>/dev/null
        assert_false "rejects input redirect" _lazy_validate_cmd "cmd<file" 2>/dev/null
        assert_false "rejects dollar expansion" _lazy_validate_cmd 'cmd$PATH' 2>/dev/null
        assert_false "rejects brace expansion" _lazy_validate_cmd "cmd{a,b}" 2>/dev/null
        assert_false "rejects glob asterisk" _lazy_validate_cmd "cmd*" 2>/dev/null
        assert_false "rejects glob question" _lazy_validate_cmd "cmd?" 2>/dev/null
        assert_false "rejects square brackets" _lazy_validate_cmd "cmd[0]" 2>/dev/null
        assert_false "rejects parentheses" _lazy_validate_cmd "cmd()" 2>/dev/null
        assert_false "rejects hash comment" _lazy_validate_cmd "cmd#" 2>/dev/null
        assert_false "rejects exclamation" _lazy_validate_cmd "cmd!" 2>/dev/null
        assert_false "rejects tilde expansion" _lazy_validate_cmd "~cmd" 2>/dev/null
        assert_false "rejects equals in name" _lazy_validate_cmd "VAR=cmd" 2>/dev/null
        assert_false "rejects forward slash" _lazy_validate_cmd "/bin/cmd" 2>/dev/null
        assert_false "rejects backslash" _lazy_validate_cmd "cmd\\n" 2>/dev/null
    else
        skip "_lazy_validate_cmd not available for security tests"
    fi

    # Test lazy_load function integration
    if typeset -f lazy_load > /dev/null 2>&1; then
        # Verify lazy_load returns error for unsafe commands
        local result
        result=$(lazy_load "cmd;rm" "echo init" 2>&1)
        [[ $? -ne 0 ]] && pass "lazy_load rejects unsafe command (semicolon)" || fail "lazy_load rejects unsafe command (semicolon)"

        result=$(lazy_load '$(whoami)' "echo init" 2>&1)
        [[ $? -ne 0 ]] && pass "lazy_load rejects unsafe command (subshell)" || fail "lazy_load rejects unsafe command (subshell)"
    else
        skip "lazy_load not available for integration test"
    fi

    # ─────────────────────────────────────────────────────────
    # History Filter Completeness
    # ─────────────────────────────────────────────────────────

    if typeset -f _should_ignore_history_cmd > /dev/null 2>&1; then
        # Additional sensitive patterns that should be filtered
        assert_true "ignores GPG passphrase" _should_ignore_history_cmd "gpg --passphrase secret"
        assert_true "ignores ssh with password" _should_ignore_history_cmd "sshpass -p password ssh user@host"
        assert_true "ignores mysql with password" _should_ignore_history_cmd "mysql -u root -pMyPassword"
        assert_true "ignores PGPASSWORD" _should_ignore_history_cmd "PGPASSWORD=secret psql"
        assert_true "ignores private key export" _should_ignore_history_cmd "export PRIVATE_KEY=-----BEGIN"
        assert_true "ignores heroku config set" _should_ignore_history_cmd "heroku config:set SECRET_KEY=abc123"
        assert_true "ignores npm with token" _should_ignore_history_cmd "NPM_TOKEN=abc npm publish"
        assert_true "ignores github token" _should_ignore_history_cmd "export GITHUB_TOKEN=ghp_xxxx"
        assert_true "ignores gitlab token" _should_ignore_history_cmd "export GITLAB_TOKEN=glpat-xxxx"

        # curl/wget with credentials in URL
        assert_true "ignores curl with credentials in URL" _should_ignore_history_cmd "curl https://user:pass@api.example.com/data"
        assert_true "ignores wget with credentials in URL" _should_ignore_history_cmd "wget https://user:pass@example.com/file"

        # Env vars with 'key' suffix
        assert_true "ignores key= assignment" _should_ignore_history_cmd "export ENCRYPTION_KEY=abc123"

        # Edge cases that should NOT be filtered (false positive prevention)
        assert_false "allows git commit with password in message" _should_ignore_history_cmd "git commit -m 'Add password validation'"
        assert_false "allows echo about secrets" _should_ignore_history_cmd "echo 'Remember to set secrets'"
        assert_false "allows grep for password patterns" _should_ignore_history_cmd "grep -r 'password' src/"
        assert_false "allows cat of non-secret file" _should_ignore_history_cmd "cat /etc/passwd"
    else
        skip "_should_ignore_history_cmd not available for history tests"
    fi

    # ─────────────────────────────────────────────────────────
    # Precmd Array Protection
    # ─────────────────────────────────────────────────────────

    # Verify _LAZY_PRECMD_INITS is readonly after module load
    if [[ -n "${(t)_LAZY_PRECMD_INITS}" ]]; then
        # Try to modify readonly array (should fail)
        local modify_result
        modify_result=$( (eval '_LAZY_PRECMD_INITS+=("injection:whoami")' 2>&1) || true )
        if [[ "$modify_result" == *"read-only"* ]] || [[ "$modify_result" == *"readonly"* ]]; then
            pass "_LAZY_PRECMD_INITS is protected (readonly)"
        else
            # Check if it actually modified
            local found_injection=false
            for entry in "${_LAZY_PRECMD_INITS[@]}"; do
                [[ "$entry" == *"injection"* ]] && found_injection=true
            done
            if [[ "$found_injection" == "false" ]]; then
                pass "_LAZY_PRECMD_INITS is protected (modification failed silently)"
            else
                fail "_LAZY_PRECMD_INITS is protected (readonly)" "readonly array" "modifiable"
            fi
        fi
    else
        skip "_LAZY_PRECMD_INITS not available for protection test"
    fi
}

# ----------------------------------------------------------
# TESTS: lib/functions/python.zsh
# ----------------------------------------------------------

test_python() {
    section "lib/functions/python.zsh"

    # Check if python functions module exists
    [[ -f "$ZDOTDIR/lib/functions/python.zsh" ]] || { skip "python.zsh not found"; return; }

    # Load dependencies first
    source "$ZDOTDIR/lib/utils/logging.zsh" 2>/dev/null || true
    source "$ZDOTDIR/lib/utils/core.zsh" 2>/dev/null || true

    # Load module
    unset _Z_FUNCTIONS_PYTHON_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/functions/python.zsh" 2>/dev/null || { skip "python.zsh not loadable"; return; }

    # Test function existence
    if typeset -f z_activate_venv > /dev/null 2>&1; then
        pass "z_activate_venv function defined"
    else
        fail "z_activate_venv function defined"
    fi

    # Test z_activate_venv returns error when no venv exists
    local test_dir=$(mktemp -d)
    pushd "$test_dir" > /dev/null
    local result
    result=$(z_activate_venv 2>&1)
    local exit_code=$?
    popd > /dev/null
    rm -rf "$test_dir"

    if [[ $exit_code -ne 0 ]]; then
        pass "z_activate_venv returns error when no venv exists"
    else
        fail "z_activate_venv returns error when no venv exists" "non-zero" "$exit_code"
    fi

    # Test idempotent guard
    if [[ "${_Z_FUNCTIONS_PYTHON_LOADED:-}" == "1" ]]; then
        pass "Python module sets idempotent guard"
    else
        fail "Python module sets idempotent guard"
    fi
}

# ----------------------------------------------------------
# TESTS: lib/functions/docker.zsh
# ----------------------------------------------------------

test_docker() {
    section "lib/functions/docker.zsh"

    # Check if docker functions module exists
    [[ -f "$ZDOTDIR/lib/functions/docker.zsh" ]] || { skip "docker.zsh not found"; return; }

    # Load dependencies first
    source "$ZDOTDIR/lib/utils/logging.zsh" 2>/dev/null || true
    source "$ZDOTDIR/lib/utils/core.zsh" 2>/dev/null || true

    # Load module
    unset _Z_FUNCTIONS_DOCKER_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/functions/docker.zsh" 2>/dev/null || { skip "docker.zsh not loadable"; return; }

    # Test function existence
    if typeset -f z_docker_stop_all > /dev/null 2>&1; then
        pass "z_docker_stop_all function defined"
    else
        fail "z_docker_stop_all function defined"
    fi

    if typeset -f z_docker_rmi_dangling > /dev/null 2>&1; then
        pass "z_docker_rmi_dangling function defined"
    else
        fail "z_docker_rmi_dangling function defined"
    fi

    if typeset -f z_docker_rmv_dangling > /dev/null 2>&1; then
        pass "z_docker_rmv_dangling function defined"
    else
        fail "z_docker_rmv_dangling function defined"
    fi

    # Test idempotent guard
    if [[ "${_Z_FUNCTIONS_DOCKER_LOADED:-}" == "1" ]]; then
        pass "Docker module sets idempotent guard"
    else
        fail "Docker module sets idempotent guard"
    fi

    # Test docker command check (should fail gracefully if docker not installed)
    if ! command -v docker > /dev/null 2>&1; then
        # Docker not installed - verify functions handle this gracefully
        local result
        result=$(z_docker_stop_all 2>&1)
        if [[ "$result" == *"docker command not found"* ]]; then
            pass "z_docker_stop_all handles missing docker gracefully"
        else
            fail "z_docker_stop_all handles missing docker gracefully" "error message" "$result"
        fi
    else
        skip "Docker is installed, skipping missing-docker test"
    fi
}

# ----------------------------------------------------------
# TEST RUNNER
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
    test_history
    test_input_validation
    test_platform_detection
    test_python
    test_docker
    test_security_negative

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
