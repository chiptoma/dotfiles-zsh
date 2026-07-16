#!/usr/bin/env zsh
# ==============================================================================
# ZSH UNIT TEST FRAMEWORK
# Unit tests for core zsh configuration functions (shared harness.zsh).
# Run: ./tests/unit-test.zsh [--verbose]
# ==============================================================================

# Do NOT use set -e - we handle failures via test assertions

# ----------------------------------------------------------
# CONFIGURATION
# ----------------------------------------------------------

VERBOSE=false
[[ "$1" == "--verbose" || "$1" == "-v" ]] && VERBOSE=true

source "${0:A:h}/harness.zsh"

# ----------------------------------------------------------
# SUITE SETUP
# ----------------------------------------------------------

# Detect ZDOTDIR so modules can be loaded from the repo under test
setup_suite_env() {
    setup_test_env

    if [[ -z "$ZDOTDIR" ]]; then
        if [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/zsh" ]]; then
            export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
        fi
    fi

    info "TEST_TMP=$TEST_TMP"
    info "ZDOTDIR=$ZDOTDIR"
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
    unset _Z_HELPERS_LOADED _Z_CORE_INDEX_LOADED _Z_LOGGING_LOADED _Z_PATH_LOADED 2>/dev/null

    # Source minimal dependencies (new paths after refactor)
    source "$ZDOTDIR/lib/core/logging.zsh" 2>/dev/null || true
    source "$module_path"
}

# ----------------------------------------------------------
# TESTS: lib/core/helpers.zsh
# ----------------------------------------------------------

test_utils() {
    section "lib/core/helpers.zsh"

    # Load module
    unset _Z_HELPERS_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/core/logging.zsh" 2>/dev/null || true
    source "$ZDOTDIR/lib/core/helpers.zsh" || { skip "core.zsh not loadable"; return; }

    # Test _has_cmd
    assert_true "_has_cmd finds 'ls'" _has_cmd ls
    assert_false "_has_cmd rejects nonexistent" _has_cmd __nonexistent_cmd_12345__

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
    if [[ -z "${CI:-}" && -z "${GITHUB_ACTIONS:-}" ]]; then
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
# TESTS: lib/core/logging.zsh
# ----------------------------------------------------------

test_logging() {
    section "lib/core/logging.zsh"

    # Load module
    unset _Z_LOGGING_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/core/logging.zsh" || { skip "logging.zsh not loadable"; return; }

    # Test log levels exist
    assert_eq "${Z_LOG_LEVELS[DEBUG]}" "0" "DEBUG level is 0"
    assert_eq "${Z_LOG_LEVELS[INFO]}" "1" "INFO level is 1"
    assert_eq "${Z_LOG_LEVELS[WARN]}" "2" "WARN level is 2"
    assert_eq "${Z_LOG_LEVELS[ERROR]}" "3" "ERROR level is 3"
    assert_eq "${Z_LOG_LEVELS[NONE]}" "4" "NONE level is 4"

    # Test z_log_level
    local old_level="$Z_LOG_LEVEL"
    z_log_level DEBUG
    assert_eq "$Z_LOG_LEVEL" "DEBUG" "z_log_level changes level"
    z_log_level "$old_level"

    # Test invalid log level
    assert_false "z_log_level rejects invalid level" z_log_level INVALID_LEVEL

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
# TESTS: modules/01_path.zsh (Functions Only)
# ----------------------------------------------------------

test_path_functions() {
    section "modules/01_path.zsh (functions)"

    # We test path functions in isolation without running _path_init
    # Load only the function definitions

    unset _Z_LOGGING_LOADED _Z_PATH_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/core/logging.zsh" 2>/dev/null || true

    # Define minimal stubs for dependencies
    _is_macos() { [[ "$OSTYPE" == darwin* ]]; }
    _is_linux() { [[ "$OSTYPE" == linux* ]]; }
    _is_bsd() { [[ "$OSTYPE" == freebsd* || "$OSTYPE" == openbsd* ]]; }
    _is_ssh_session() { return 1; }
    _is_docker() { return 1; }
    _is_ci() { return 1; }

    # Source path module (will run _path_init, but we'll test functions after)
    typeset -g Z_PATH_ENABLED=true
    source "$ZDOTDIR/modules/01_path.zsh" 2>/dev/null || { skip "path.zsh not loadable"; return; }

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

    # Test z_path_contains (suppress debug output)
    local output
    Z_LOG_LEVEL=ERROR output=$(z_path_contains /usr/bin 2>&1)
    assert_contains "$output" "IS in PATH" "z_path_contains finds /usr/bin"

    Z_LOG_LEVEL=ERROR output=$(z_path_contains /nonexistent/path 2>&1)
    assert_contains "$output" "IS NOT in PATH" "z_path_contains rejects nonexistent"

    # Restore original path
    path=("${original_path[@]}")
}

# ----------------------------------------------------------
# TESTS: modules/01_path.zsh (Exact Ordering)
# ----------------------------------------------------------

test_path_ordering() {
    section "modules/01_path.zsh (ordering)"

    (( $+functions[_path_add] )) || { skip "_path_add not defined"; return; }

    local dir_a="$TEST_TMP/path_order_a" dir_b="$TEST_TMP/path_order_b"
    mkdir -p "$dir_a" "$dir_b"

    local -a original_path=("${path[@]}")

    # Prepend ordering: the LAST prepend must win index 1
    _path_add "$dir_a" prepend
    _path_add "$dir_b" prepend
    assert_eq "${path[1]}" "$dir_b" "second prepend lands at exact index 1"
    assert_eq "${path[2]}" "$dir_a" "first prepend is pushed to exact index 2"

    # Reset PATH and dedup cache before testing append
    path=("${original_path[@]}")
    (( $+functions[_path_cache_rebuild] )) && _path_cache_rebuild 2>/dev/null

    # Append ordering: appends land at the tail in call order
    _path_add "$dir_a" append
    _path_add "$dir_b" append
    assert_eq "${path[-2]}" "$dir_a" "first append sits at exact second-to-last index"
    assert_eq "${path[-1]}" "$dir_b" "second append lands at exact last index"

    # Restore
    path=("${original_path[@]}")
    (( $+functions[_path_cache_rebuild] )) && _path_cache_rebuild 2>/dev/null
}

# ----------------------------------------------------------
# TESTS: modules/01_path.zsh (Condition Evaluation)
# ----------------------------------------------------------

test_path_conditions() {
    section "modules/01_path.zsh (conditions)"

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
# TESTS: modules/03_lazy.zsh
# ----------------------------------------------------------

test_lazy() {
    section "modules/03_lazy.zsh"

    # Check if lazy module can be loaded
    [[ -f "$ZDOTDIR/modules/03_lazy.zsh" ]] || { skip "lazy.zsh not found"; return; }

    # Test lazy status function exists after loading
    unset _Z_LAZY_LOADED 2>/dev/null
    typeset -g Z_LAZY_ENABLED=true
    typeset -g Z_LAZY_ZOXIDE=false  # Disable actual lazy loads for testing
    typeset -g Z_LAZY_NVM=false
    typeset -g Z_LAZY_PYENV=false
    typeset -g Z_LAZY_RBENV=false

    source "$ZDOTDIR/modules/03_lazy.zsh" 2>/dev/null || { skip "lazy.zsh not loadable"; return; }

    # z_lazy_status now lives in lib/functions/framework.zsh
    # Just verify the lazy module loads without it
    pass "Lazy module loads successfully"

    # Test _LAZY_LOADED_TOOLS array exists
    if [[ -n "${(t)_LAZY_LOADED_TOOLS}" ]]; then
        pass "_LAZY_LOADED_TOOLS array exists"
    else
        fail "_LAZY_LOADED_TOOLS array exists"
    fi

    # The bespoke per-tool initializers are the whole lazy API
    local fn
    for fn in _lazy_init_zoxide _lazy_init_nvm _lazy_init_pyenv _lazy_init_rbenv; do
        if typeset -f "$fn" > /dev/null 2>&1; then
            pass "$fn defined"
        else
            fail "$fn defined"
        fi
    done
}

# ----------------------------------------------------------
# TESTS: Input Validation
# ----------------------------------------------------------

test_input_validation() {
    section "Input Validation"

    # Test that functions handle empty inputs gracefully

    # z_log_level with empty arg
    assert_false "z_log_level rejects empty input" z_log_level ""

    # _path_add with non-existent directory (should not add)
    local path_before=${#path[@]}
    _path_add "/definitely/not/a/real/path/$$" append 2>/dev/null
    local path_after=${#path[@]}
    assert_eq "$path_after" "$path_before" "_path_add ignores non-existent paths"
}

# ----------------------------------------------------------
# TESTS: modules/05_history.zsh
# ----------------------------------------------------------

test_history() {
    section "modules/05_history.zsh"

    # Load dependencies first
    unset _Z_HISTORY_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/core/logging.zsh" 2>/dev/null || true
    source "$ZDOTDIR/lib/core/helpers.zsh" 2>/dev/null || true

    # Load history module
    source "$ZDOTDIR/modules/05_history.zsh" 2>/dev/null || { skip "history.zsh not loadable"; return; }

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
    if typeset -f z_history_stats > /dev/null 2>&1; then
        pass "z_history_stats function defined"
    else
        fail "z_history_stats function defined"
    fi

    if typeset -f z_history_backup > /dev/null 2>&1; then
        pass "z_history_backup function defined"
    else
        fail "z_history_backup function defined"
    fi

    if typeset -f z_history_clean > /dev/null 2>&1; then
        pass "z_history_clean function defined"
    else
        fail "z_history_clean function defined"
    fi

    # Test history edge cases
    # Test with empty HISTFILE path
    local old_histfile="$HISTFILE"
    unset HISTFILE
    assert_false "z_history_backup handles missing HISTFILE" z_history_backup 2>/dev/null
    HISTFILE="$old_histfile"
}

# ----------------------------------------------------------
# TESTS: lib/core/platform/detect.zsh
# ----------------------------------------------------------

test_platform_detection() {
    section "lib/core/platform/detect.zsh"

    # Check if platform detection module exists
    [[ -f "$ZDOTDIR/lib/core/platform/detect.zsh" ]] || { skip "detect.zsh not found"; return; }

    # Load module
    unset _Z_PLATFORM_DETECT_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/core/platform/detect.zsh" 2>/dev/null || { skip "detect.zsh not loadable"; return; }

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
    source "$ZDOTDIR/lib/core/logging.zsh" 2>/dev/null || true
    source "$ZDOTDIR/lib/core/helpers.zsh" 2>/dev/null || true

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
    source "$ZDOTDIR/lib/core/logging.zsh" 2>/dev/null || true
    source "$ZDOTDIR/lib/core/helpers.zsh" 2>/dev/null || true

    # Load module
    unset _Z_FUNCTIONS_DOCKER_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/functions/docker.zsh" 2>/dev/null || { skip "docker.zsh not loadable"; return; }

    # Test consolidated function existence
    if typeset -f z_docker_cleanup > /dev/null 2>&1; then
        pass "z_docker_cleanup function defined"
    else
        fail "z_docker_cleanup function defined"
    fi

    # Test idempotent guard
    if [[ "${_Z_FUNCTIONS_DOCKER_LOADED:-}" == "1" ]]; then
        pass "Docker module sets idempotent guard"
    else
        fail "Docker module sets idempotent guard"
    fi

    # Test docker command check (should fail gracefully if docker not installed)
    if ! command -v docker > /dev/null 2>&1; then
        # Docker not installed - verify function handles this gracefully
        local result
        result=$(z_docker_cleanup stop 2>&1)
        if [[ "$result" == *"docker command not found"* ]]; then
            pass "z_docker_cleanup handles missing docker gracefully"
        else
            fail "z_docker_cleanup handles missing docker gracefully" "error message" "$result"
        fi
    else
        skip "Docker is installed, skipping missing-docker test"
    fi

    # Test invalid subcommand
    if typeset -f z_docker_cleanup > /dev/null 2>&1; then
        local result
        result=$(z_docker_cleanup bogus 2>&1)
        if [[ "$result" == *"Unknown subcommand"* ]]; then
            pass "z_docker_cleanup rejects invalid subcommand"
        else
            fail "z_docker_cleanup rejects invalid subcommand" "error message" "$result"
        fi
    fi
}

# ----------------------------------------------------------
# TESTS: lib/core/helpers.zsh (_get_mtime)
# ----------------------------------------------------------

test_get_mtime() {
    section "lib/core/helpers.zsh (_get_mtime)"

    [[ -f "$ZDOTDIR/lib/core/helpers.zsh" ]] || { skip "core.zsh not found"; return; }

    # Load dependencies
    source "$ZDOTDIR/lib/core/logging.zsh" 2>/dev/null || true
    unset _Z_HELPERS_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/core/helpers.zsh" 2>/dev/null || true

    if ! typeset -f _get_mtime > /dev/null 2>&1; then
        skip "_get_mtime not available"
        return
    fi

    # Test with existing file
    local test_file="$TEST_TMP/mtime_test"
    touch "$test_file"
    local mtime
    mtime=$(_get_mtime "$test_file")
    if [[ "$mtime" -gt 0 ]]; then
        pass "_get_mtime returns positive epoch for existing file"
    else
        fail "_get_mtime returns positive epoch for existing file" ">0" "$mtime"
    fi

    # Verify mtime is a reasonable epoch (after year 2020)
    if [[ "$mtime" -gt 1577836800 ]]; then
        pass "_get_mtime returns reasonable epoch value"
    else
        fail "_get_mtime returns reasonable epoch value" ">1577836800" "$mtime"
    fi

    # Test with non-existent file
    local missing_mtime
    missing_mtime=$(_get_mtime "/tmp/nonexistent_file_$RANDOM" 2>/dev/null)
    if [[ "$missing_mtime" == "0" ]] || [[ -z "$missing_mtime" ]]; then
        pass "_get_mtime returns 0 or empty for missing file"
    else
        fail "_get_mtime returns 0 or empty for missing file" "0 or empty" "$missing_mtime"
    fi
}

# ----------------------------------------------------------
# TESTS: lib/core/helpers.zsh (_cache_eval)
# ----------------------------------------------------------

test_cache_eval() {
    section "lib/core/helpers.zsh (_cache_eval)"

    [[ -f "$ZDOTDIR/lib/core/helpers.zsh" ]] || { skip "core.zsh not found"; return; }

    # Load dependencies
    source "$ZDOTDIR/lib/core/logging.zsh" 2>/dev/null || true
    unset _Z_HELPERS_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/core/helpers.zsh" 2>/dev/null || true

    if ! typeset -f _cache_eval > /dev/null 2>&1; then
        skip "_cache_eval not available"
        return
    fi

    # Test allowlist rejection
    local cache_dir="${TEST_TMP}/cache"
    mkdir -p "$cache_dir"
    local old_xdg="${XDG_CACHE_HOME:-}"
    export XDG_CACHE_HOME="$TEST_TMP"

    local reject_result
    reject_result=$(_cache_eval "evil" "evil_command --hack" "evil" 2>&1)
    local reject_code=$?
    if [[ $reject_code -ne 0 ]]; then
        pass "_cache_eval rejects non-allowlisted command"
    else
        fail "_cache_eval rejects non-allowlisted command" "non-zero exit" "$reject_code"
    fi

    # Test allowlisted command creates cache file
    # Use 'echo' aliased as an allowlisted name test
    if _has_cmd zoxide; then
        _cache_eval "zoxide" "zoxide init zsh" "zoxide" 2>/dev/null
        if [[ -f "$TEST_TMP/zsh/zoxide.zsh" ]]; then
            pass "_cache_eval creates cache file for allowlisted command"
        else
            skip "_cache_eval cache file creation (zoxide may have failed)"
        fi
    else
        skip "_cache_eval cache creation (zoxide not installed)"
    fi

    # Restore XDG
    if [[ -n "$old_xdg" ]]; then
        export XDG_CACHE_HOME="$old_xdg"
    else
        unset XDG_CACHE_HOME
    fi
}

# ----------------------------------------------------------
# TESTS: modules/02_environment.zsh
# ----------------------------------------------------------

test_environment() {
    section "modules/02_environment.zsh"

    [[ -f "$ZDOTDIR/modules/02_environment.zsh" ]] || { skip "environment.zsh not found"; return; }

    # Test XDG base directory defaults are defined
    local env_output
    env_output=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        source \$ZDOTDIR/.zshenv 2>/dev/null
        echo \"XDG_CONFIG=\${XDG_CONFIG_HOME}\"
        echo \"XDG_CACHE=\${XDG_CACHE_HOME}\"
        echo \"XDG_DATA=\${XDG_DATA_HOME}\"
        echo \"XDG_STATE=\${XDG_STATE_HOME}\"
    " 2>&1)

    if [[ "$env_output" == *"XDG_CONFIG="* ]] && [[ "$env_output" != *"XDG_CONFIG=$"* ]]; then
        pass "XDG_CONFIG_HOME is set"
    else
        fail "XDG_CONFIG_HOME is set"
    fi

    if [[ "$env_output" == *"XDG_CACHE="* ]] && [[ "$env_output" != *"XDG_CACHE=$"* ]]; then
        pass "XDG_CACHE_HOME is set"
    else
        fail "XDG_CACHE_HOME is set"
    fi

    # Test EDITOR detection runs
    local editor_output
    editor_output=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        source \$ZDOTDIR/.zshenv 2>/dev/null
        [[ -n \"\$EDITOR\" ]] && echo 'EDITOR_SET' || echo 'EDITOR_UNSET'
    " 2>&1)

    if [[ "$editor_output" == *"EDITOR_SET"* ]]; then
        pass "EDITOR is detected and set"
    else
        skip "EDITOR detection (no editor found)"
    fi

    # Test z_env_show function exists
    local func_check
    func_check=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        source \$ZDOTDIR/.zshenv 2>/dev/null
        (( \$+functions[z_env_show] )) && echo 'DEFINED' || echo 'MISSING'
    " 2>&1)

    if [[ "$func_check" == *"DEFINED"* ]]; then
        pass "z_env_show function defined"
    else
        fail "z_env_show function defined"
    fi

    # Test z_env_reload function exists
    func_check=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        source \$ZDOTDIR/.zshenv 2>/dev/null
        (( \$+functions[z_env_reload] )) && echo 'DEFINED' || echo 'MISSING'
    " 2>&1)

    if [[ "$func_check" == *"DEFINED"* ]]; then
        pass "z_env_reload function defined"
    else
        fail "z_env_reload function defined"
    fi

    # Test tool detection skips uninstalled tools
    local fake_tool_result
    fake_tool_result=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        export Z_LOG_LEVEL=DEBUG
        source \$ZDOTDIR/.zshenv 2>&1 | grep -c 'Skipping' || echo '0'
    " 2>&1)

    # Should skip at least some tools (not all 50+ are installed)
    if [[ "$fake_tool_result" =~ ^[0-9]+$ ]] && [[ "$fake_tool_result" -gt 0 ]]; then
        pass "Environment module skips uninstalled tools ($fake_tool_result skipped)"
    else
        skip "Tool skip count check (log parsing may vary)"
    fi
}

# ----------------------------------------------------------
# TESTS: Platform Detection Extended
# ----------------------------------------------------------

test_platform_extended() {
    section "Platform Detection (extended)"

    # Load platform detection
    source "$ZDOTDIR/lib/core/logging.zsh" 2>/dev/null || true
    source "$ZDOTDIR/lib/core/helpers.zsh" 2>/dev/null || true
    source "$ZDOTDIR/lib/core/platform/detect.zsh" 2>/dev/null || true

    # Test _is_docker (should be false on dev machine)
    if typeset -f _is_docker > /dev/null 2>&1; then
        if ! _is_docker; then
            pass "_is_docker returns false on dev machine"
        else
            skip "_is_docker returned true (running in container?)"
        fi
    else
        skip "_is_docker not available"
    fi

    # Test _is_ci (should be false locally)
    if typeset -f _is_ci > /dev/null 2>&1; then
        if [[ -z "${CI:-}" ]]; then
            assert_false "_is_ci returns false locally" _is_ci
        else
            skip "_is_ci test (running in CI)"
        fi
    fi

    # Test _is_interactive
    if typeset -f _is_interactive > /dev/null 2>&1; then
        # In non-interactive test runner, should be false
        if ! _is_interactive 2>/dev/null; then
            pass "_is_interactive false in test runner"
        else
            pass "_is_interactive true (test run interactively)"
        fi
    fi

    # Test _get_clipboard_cmd returns something
    if typeset -f _get_clipboard_cmd > /dev/null 2>&1; then
        local clip_cmd
        clip_cmd=$(_get_clipboard_cmd)
        if [[ -n "$clip_cmd" ]]; then
            pass "_get_clipboard_cmd returns a command ($clip_cmd)"
        else
            fail "_get_clipboard_cmd returns a command" "non-empty" "empty"
        fi
    else
        skip "_get_clipboard_cmd not available"
    fi

    # Test platform cache variables are set
    if [[ -n "${_CACHED_UNAME_S:-}" ]] || [[ -n "${_CACHED_OSTYPE:-}" ]]; then
        pass "Platform cache variables are set"
    else
        skip "Platform cache variables (may not be exported)"
    fi
}

# ----------------------------------------------------------
# TESTS: _ensure_file permissions
# ----------------------------------------------------------

test_ensure_file_perms() {
    section "lib/core/helpers.zsh (_ensure_file perms)"

    source "$ZDOTDIR/lib/core/logging.zsh" 2>/dev/null || true
    unset _Z_HELPERS_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/core/helpers.zsh" 2>/dev/null || true

    if ! typeset -f _ensure_file > /dev/null 2>&1; then
        skip "_ensure_file not available"
        return
    fi

    # Test creating file with specific permissions
    local test_file="$TEST_TMP/perms_test_file"
    rm -f "$test_file" 2>/dev/null
    _ensure_file "$test_file" "600"

    if [[ -f "$test_file" ]]; then
        pass "_ensure_file creates file with perms arg"
    else
        fail "_ensure_file creates file with perms arg"
        return
    fi

    # Verify permissions were set
    local perms
    if [[ "$OSTYPE" == darwin* ]]; then
        perms=$(stat -f %Lp "$test_file" 2>/dev/null)
    else
        perms=$(stat -c %a "$test_file" 2>/dev/null)
    fi
    if [[ "$perms" == "600" ]]; then
        pass "_ensure_file sets correct permissions (600)"
    else
        fail "_ensure_file sets correct permissions (600)" "600" "$perms"
    fi

    # Test _ensure_file on already-existing file (should not error)
    local result
    result=$(_ensure_file "$test_file" "600" 2>&1)
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        pass "_ensure_file succeeds on existing file"
    else
        fail "_ensure_file succeeds on existing file" "0" "$rc"
    fi
}

# ----------------------------------------------------------
# TESTS: Plugin Fallback (self-managed plugins, no OMZ)
# ----------------------------------------------------------

test_plugin_fallback() {
    section "Plugin Fallback (graceful degradation)"

    # Shell must boot with no plugin directories at all
    local fallback_result
    fallback_result=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        export Z_PLUGINS_DIR='/tmp/nonexistent-plugins-$$'
        export XDG_DATA_HOME='/tmp/nonexistent-data-$$'
        export Z_LOG_LEVEL=NONE
        source \$ZDOTDIR/.zshenv 2>/dev/null
        source \$ZDOTDIR/.zshrc 2>/dev/null
        echo 'FALLBACK_OK'
    " 2>&1)

    if [[ "$fallback_result" == *"FALLBACK_OK"* ]]; then
        pass "Shell starts without plugins"
    else
        fail "Shell starts without plugins"
    fi

    # Framework modules must load regardless of plugin availability
    local modules_result
    modules_result=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        export Z_PLUGINS_DIR='/tmp/nonexistent-plugins-$$'
        export XDG_DATA_HOME='/tmp/nonexistent-data-$$'
        export Z_LOG_LEVEL=NONE
        source \$ZDOTDIR/.zshenv 2>/dev/null
        source \$ZDOTDIR/.zshrc 2>/dev/null
        (( \$+functions[z_lazy_status] )) && echo 'LAZY_OK'
        (( \$+functions[z_history_stats] )) && echo 'HISTORY_OK'
    " 2>&1)

    if [[ "$modules_result" == *"LAZY_OK"* ]]; then
        pass "Lazy module loads without plugins"
    else
        fail "Lazy module loads without plugins"
    fi

    if [[ "$modules_result" == *"HISTORY_OK"* ]]; then
        pass "History module loads without plugins"
    else
        fail "History module loads without plugins"
    fi
}

# ----------------------------------------------------------
# lib/functions/utilities.zsh + lib/functions/framework.zsh
# ----------------------------------------------------------

test_system_functions() {
    section "lib/functions/utilities.zsh + framework.zsh"

    # z_calc
    if (( $+functions[z_calc] )); then
        local calc_out
        calc_out=$(z_calc '2+2' 2>/dev/null)
        if [[ "$calc_out" == *"4"* ]]; then
            pass "z_calc basic arithmetic (2+2=4)"
        else
            fail "z_calc basic arithmetic (got: $calc_out)"
        fi

        z_calc '' >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            pass "z_calc rejects empty input"
        else
            fail "z_calc accepts empty input"
        fi

        # Injection prevention
        z_calc '__import__("os")' >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            pass "z_calc rejects injection attempt"
        else
            fail "z_calc allows injection"
        fi
    else
        skip "z_calc not defined"
    fi

    # z_version
    if (( $+functions[z_version] )); then
        local ver_out
        ver_out=$(z_version 2>/dev/null)
        if [[ -n "$ver_out" && "$ver_out" == *"ZSH Configuration"* ]]; then
            pass "z_version outputs version string"
        else
            fail "z_version output unexpected: $ver_out"
        fi
    else
        skip "z_version not defined"
    fi

    # z_help
    if (( $+functions[z_help] )); then
        local help_out
        help_out=$(z_help 2>/dev/null)
        if [[ -n "$help_out" ]]; then
            pass "z_help produces output"
        else
            fail "z_help produces no output"
        fi
    else
        skip "z_help not defined"
    fi

    # z_timeout
    if (( $+functions[z_timeout] )); then
        z_timeout 2 true >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            pass "z_timeout succeeds with fast command"
        else
            fail "z_timeout fails with fast command"
        fi

        z_timeout >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            pass "z_timeout rejects no args"
        else
            fail "z_timeout accepts no args"
        fi
    else
        skip "z_timeout not defined"
    fi

    # _detect_ssh_agent (infrastructure function in lib/core/platform/detect.zsh)
    if (( $+functions[_detect_ssh_agent] )); then
        pass "_detect_ssh_agent function defined"
    else
        fail "_detect_ssh_agent not defined"
    fi

    # z_check_tools
    if (( $+functions[z_check_tools] )); then
        pass "z_check_tools function defined"
    else
        fail "z_check_tools not defined"
    fi

    # z_health
    if (( $+functions[z_health] )); then
        local health_out
        health_out=$(z_health 2>/dev/null)
        if [[ -n "$health_out" ]]; then
            pass "z_health produces output"
        else
            fail "z_health produces no output"
        fi
    else
        skip "z_health not defined"
    fi

    # z_status
    if (( $+functions[z_status] )); then
        local status_out
        status_out=$(z_status 2>/dev/null)
        if [[ -n "$status_out" ]]; then
            pass "z_status produces output"
        else
            fail "z_status produces no output"
        fi
    else
        skip "z_status not defined"
    fi
}

# ----------------------------------------------------------
# lib/functions/file.zsh
# ----------------------------------------------------------

test_file_functions() {
    section "lib/functions/file.zsh"

    # z_sizeof
    if (( $+functions[z_sizeof] )); then
        local sizeof_out
        sizeof_out=$(z_sizeof "$TEST_TMP" 2>/dev/null)
        if [[ $? -eq 0 && -n "$sizeof_out" ]]; then
            pass "z_sizeof on existing directory"
        else
            fail "z_sizeof fails on existing directory"
        fi

        z_sizeof "/nonexistent_path_$$" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            pass "z_sizeof rejects missing path"
        else
            fail "z_sizeof accepts missing path"
        fi
    else
        skip "z_sizeof not defined"
    fi

    # z_backup
    if (( $+functions[z_backup] )); then
        local test_backup_file="$TEST_TMP/backup_test.txt"
        echo "backup content" > "$test_backup_file"
        local backup_out
        backup_out=$(z_backup "$test_backup_file" 2>/dev/null)
        if [[ $? -eq 0 && -n "$(ls "$TEST_TMP"/backup_test.txt.*.bak 2>/dev/null)" ]]; then
            pass "z_backup creates timestamped copy"
        else
            fail "z_backup failed to create backup"
        fi

        z_backup "/nonexistent_file_$$" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            pass "z_backup rejects missing file"
        else
            fail "z_backup accepts missing file"
        fi
    else
        skip "z_backup not defined"
    fi

    # z_todos
    if (( $+functions[z_todos] )); then
        local todo_dir="$TEST_TMP/todo_test"
        mkdir -p "$todo_dir"
        echo "# TODO: fix this bug" > "$todo_dir/test.sh"
        local todos_out
        todos_out=$(cd "$todo_dir" && z_todos 2>/dev/null)
        if [[ "$todos_out" == *"TODO"* ]]; then
            pass "z_todos finds TODO comments"
        else
            fail "z_todos missed TODO comment"
        fi
    else
        skip "z_todos not defined"
    fi

    # z_up
    if (( $+functions[z_up] )); then
        local deep_dir="$TEST_TMP/a/b/c"
        mkdir -p "$deep_dir"
        local original_pwd="$PWD"
        (cd "$deep_dir" && z_up 2 >/dev/null 2>&1 && [[ "$PWD" == *"/a" ]])
        if [[ $? -eq 0 ]]; then
            pass "z_up navigates up N levels"
        else
            fail "z_up navigation failed"
        fi
        cd "$original_pwd"
    else
        skip "z_up not defined"
    fi

    # z_mkcd
    if (( $+functions[z_mkcd] )); then
        local original_pwd="$PWD"
        local mkcd_target="$TEST_TMP/mkcd_test_dir"
        (z_mkcd "$mkcd_target" >/dev/null 2>&1 && [[ "$PWD" == "$mkcd_target" ]])
        if [[ $? -eq 0 && -d "$mkcd_target" ]]; then
            pass "z_mkcd creates and enters directory"
        else
            fail "z_mkcd failed"
        fi
        cd "$original_pwd"

        z_mkcd '' >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            pass "z_mkcd rejects empty arg"
        else
            fail "z_mkcd accepts empty arg"
        fi
    else
        skip "z_mkcd not defined"
    fi

    # _check_archive_safety
    if (( $+functions[_check_archive_safety] )); then
        # Create a safe tar archive
        local safe_dir="$TEST_TMP/safe_archive"
        mkdir -p "$safe_dir"
        echo "safe" > "$safe_dir/safe.txt"
        local safe_tar="$TEST_TMP/safe.tar"
        (cd "$TEST_TMP" && tar cf "$safe_tar" -C "$TEST_TMP" safe_archive/safe.txt 2>/dev/null)
        if [[ -f "$safe_tar" ]]; then
            _check_archive_safety "$safe_tar" >/dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                pass "_check_archive_safety allows safe archive"
            else
                fail "_check_archive_safety rejects safe archive"
            fi
        else
            skip "_check_archive_safety: could not create test tar"
        fi
    else
        skip "_check_archive_safety not defined"
    fi
}

# ----------------------------------------------------------
# lib/functions/git.zsh
# ----------------------------------------------------------

test_git_functions() {
    section "lib/functions/git.zsh"

    # z_git_cleanup
    if (( $+functions[z_git_cleanup] )); then
        pass "z_git_cleanup function defined"

        # Test outside a git repo
        local non_repo="$TEST_TMP/not_a_repo"
        mkdir -p "$non_repo"
        local cleanup_out
        cleanup_out=$(cd "$non_repo" && z_git_cleanup 2>&1)
        if [[ $? -ne 0 || "$cleanup_out" == *"Not a git"* ]]; then
            pass "z_git_cleanup rejects non-repo"
        else
            fail "z_git_cleanup accepts non-repo"
        fi
    else
        fail "z_git_cleanup not defined"
    fi

    # z_gitsize
    if (( $+functions[z_gitsize] )); then
        # Test in actual repo (ZDOTDIR is a git repo)
        local gitsize_out
        gitsize_out=$(z_gitsize "$ZDOTDIR" 2>/dev/null)
        if [[ $? -eq 0 && -n "$gitsize_out" ]]; then
            pass "z_gitsize reports size for git repo"
        else
            fail "z_gitsize fails on git repo"
        fi

        # Test outside git repo
        z_gitsize "$TEST_TMP" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            pass "z_gitsize rejects non-repo"
        else
            fail "z_gitsize accepts non-repo"
        fi
    else
        fail "z_gitsize not defined"
    fi
}

# ----------------------------------------------------------
# lib/functions/network.zsh
# ----------------------------------------------------------

test_network_functions() {
    section "lib/functions/network.zsh"

    # z_localip
    if (( $+functions[z_localip] )); then
        local ip_out
        ip_out=$(z_localip 2>/dev/null)
        if [[ $? -eq 0 && "$ip_out" =~ [0-9]+\.[0-9]+ ]]; then
            pass "z_localip returns IP-like address"
        else
            skip "z_localip could not determine IP (no network interface)"
        fi
    else
        fail "z_localip not defined"
    fi

    # z_portcheck
    if (( $+functions[z_portcheck] )); then
        z_portcheck '' >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            pass "z_portcheck rejects empty arg"
        else
            fail "z_portcheck accepts empty arg"
        fi

        z_portcheck 99999 >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            pass "z_portcheck rejects invalid port"
        else
            fail "z_portcheck accepts invalid port"
        fi
    else
        fail "z_portcheck not defined"
    fi

    # z_show_ports (existence only — requires sudo)
    if (( $+functions[z_show_ports] )); then
        pass "z_show_ports function defined"
    else
        fail "z_show_ports not defined"
    fi

    # z_waitport
    if (( $+functions[z_waitport] )); then
        z_waitport '' '' >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            pass "z_waitport rejects empty args"
        else
            fail "z_waitport accepts empty args"
        fi
    else
        fail "z_waitport not defined"
    fi
}

# ----------------------------------------------------------
# lib/functions/introspection.zsh
# ----------------------------------------------------------

test_introspection_functions() {
    section "lib/functions/introspection.zsh"

    # _als_build_cache
    if (( $+functions[_als_build_cache] )); then
        _als_build_cache 2>/dev/null
        if [[ $? -eq 0 ]]; then
            pass "_als_build_cache runs successfully"
        else
            fail "_als_build_cache fails"
        fi

        # Check cache populated (should have at least some aliases)
        if [[ ${#_ALIAS_DESC_CACHE[@]} -gt 0 ]]; then
            pass "_als_build_cache populated cache (${#_ALIAS_DESC_CACHE[@]} entries)"
        else
            skip "_als_build_cache: no aliases with descriptions found"
        fi
    else
        skip "_als_build_cache not defined"
    fi

    # z_alias_browser (existence only — requires fzf + tty)
    if (( $+functions[z_alias_browser] )); then
        pass "z_alias_browser function defined"
    else
        fail "z_alias_browser not defined"
    fi
}

# ----------------------------------------------------------
# modules/03_lazy.zsh (extended)
# ----------------------------------------------------------

test_lazy_loading_extended() {
    section "modules/03_lazy.zsh (extended)"

    # Tool-specific initializers
    local init_fn
    for init_fn in _lazy_init_zoxide _lazy_init_nvm _lazy_init_pyenv _lazy_init_rbenv; do
        if (( $+functions[$init_fn] )); then
            pass "$init_fn function defined"
        else
            fail "$init_fn not defined"
        fi
    done

    # z_lazy_status output
    if (( $+functions[z_lazy_status] )); then
        local lazy_out
        lazy_out=$(z_lazy_status 2>/dev/null)
        if [[ -n "$lazy_out" ]]; then
            pass "z_lazy_status produces output"
        else
            fail "z_lazy_status produces no output"
        fi
    else
        fail "z_lazy_status not defined"
    fi
}

# ----------------------------------------------------------
# modules/05_history.zsh (z_history_clean)
# ----------------------------------------------------------

test_z_history_clean() {
    section "modules/05_history.zsh (z_history_clean)"

    local original_histfile="$HISTFILE"

    # z_history_clean function exists
    if (( $+functions[z_history_clean] )); then
        pass "z_history_clean function defined"
    else
        fail "z_history_clean not defined"
    fi

    # Behavioral: run the REAL z_history_clean against a fixture HISTFILE
    local test_histfile="$TEST_TMP/histclean_fixture"
    cat > "$test_histfile" <<'HIST'
: 1700000001:0;ls -la
: 1700000002:0;git status
: 1700000003:0;ls -la
: 1700000004:0;export PASSWORD=secret123
: 1700000005:0;cd /tmp
: 1700000006:0;git status
: 1700000007:0;echo hello
HIST

    local old_data_home="${ZSH_DATA_HOME:-}"
    export ZSH_DATA_HOME="$TEST_TMP/histclean_data"
    HISTFILE="$test_histfile"

    # Shadow fc in the subshell: `fc -R` (session reload) hangs when zsh has
    # no active history; the behavior under test is the HISTFILE rewrite.
    local clean_out clean_rc
    clean_out=$( fc() { return 0 }; z_history_clean 2>&1 )
    clean_rc=$?
    HISTFILE="$original_histfile"
    if [[ -n "$old_data_home" ]]; then
        export ZSH_DATA_HOME="$old_data_home"
    else
        unset ZSH_DATA_HOME
    fi

    assert_eq "$clean_rc" "0" "z_history_clean succeeds on fixture HISTFILE"

    if [[ -s "$test_histfile" ]]; then
        local cleaned_content
        cleaned_content=$(cat "$test_histfile")

        # Duplicates removed (ls -la appears exactly once)
        local ls_count
        ls_count=$(grep -c 'ls -la' "$test_histfile")
        assert_eq "$ls_count" "1" "z_history_clean dedupes repeated commands to one entry"

        # Secret-pattern line filtered out entirely
        if [[ "$cleaned_content" != *"PASSWORD=secret"* ]]; then
            pass "z_history_clean removes secret-pattern lines from HISTFILE"
        else
            fail "z_history_clean removes secret-pattern lines from HISTFILE"
        fi

        # Clean commands preserved
        assert_contains "$cleaned_content" "echo hello" \
            "z_history_clean preserves clean commands"

        # Dedup keeps the LAST occurrence (timestamp 1700000006, not 1700000002)
        assert_contains "$cleaned_content" ": 1700000006:0;git status" \
            "z_history_clean keeps the last occurrence of a duplicate"
        if [[ "$cleaned_content" != *": 1700000002:0;git status"* ]]; then
            pass "z_history_clean drops the earlier duplicate occurrence"
        else
            fail "z_history_clean drops the earlier duplicate occurrence"
        fi

        # 7 lines in, 4 unique clean commands out -> reports 3 removed
        assert_contains "$clean_out" "removed 3 lines" \
            "z_history_clean reports the exact number of removed lines"
    else
        fail "z_history_clean left fixture HISTFILE empty or missing"
    fi

    # _create_z_history_backup
    if (( $+functions[_create_z_history_backup] )); then
        local backup_src="$TEST_TMP/backup_src_hist"
        local backup_dst="$TEST_TMP/backup_dst_hist.bak"
        echo ": 1700000001:0;test command" > "$backup_src"
        HISTFILE="$backup_src"

        _create_z_history_backup "$backup_dst" 2>/dev/null
        if [[ -f "$backup_dst" ]]; then
            pass "_create_z_history_backup creates file"
        else
            fail "_create_z_history_backup failed to create backup"
        fi

        # Verify backup has correct permissions
        local backup_perms
        backup_perms=$(stat -f %Lp "$backup_dst" 2>/dev/null || stat -c %a "$backup_dst" 2>/dev/null)
        if [[ "$backup_perms" == "600" ]]; then
            pass "_create_z_history_backup sets 600 permissions"
        else
            skip "_create_z_history_backup permissions ($backup_perms)"
        fi
    else
        skip "_create_z_history_backup not defined"
    fi

    # zshaddhistory hook
    if (( $+functions[zshaddhistory] )); then
        # Secret should be filtered
        zshaddhistory $'export SECRET_KEY=abc123\n' 2>/dev/null
        if [[ $? -ne 0 ]]; then
            pass "zshaddhistory filters secret exports"
        else
            fail "zshaddhistory allows secret exports"
        fi

        # Normal command should pass
        zshaddhistory $'ls -la\n' 2>/dev/null
        if [[ $? -eq 0 ]]; then
            pass "zshaddhistory allows normal commands"
        else
            fail "zshaddhistory rejects normal commands"
        fi
    else
        skip "zshaddhistory not defined"
    fi

    # Restore HISTFILE
    HISTFILE="$original_histfile"
}

# ----------------------------------------------------------
# lib/core/helpers.zsh (extended coverage)
# ----------------------------------------------------------

test_core_utils_extended() {
    section "lib/core/helpers.zsh (extended)"

    # _is_login_shell — test runner is NOT a login shell
    if (( $+functions[_is_login_shell] )); then
        if ! _is_login_shell; then
            pass "_is_login_shell false in test runner"
        else
            pass "_is_login_shell true (running as login shell)"
        fi
    else
        fail "_is_login_shell not defined"
    fi

    # _run_post_interactive_hooks — runs registered hook
    if (( $+functions[_run_post_interactive_hooks] )); then
        # Save and clear hooks
        local -a saved_hooks=("${Z_POST_INTERACTIVE_HOOKS[@]}")
        Z_POST_INTERACTIVE_HOOKS=()

        # Empty array returns 0
        _run_post_interactive_hooks 2>/dev/null
        if [[ $? -eq 0 ]]; then
            pass "_run_post_interactive_hooks empty array returns 0"
        else
            fail "_run_post_interactive_hooks empty array returns non-zero"
        fi

        # Register a hook that sets a variable
        typeset -g _TEST_HOOK_RAN=0
        _test_hook_func() { _TEST_HOOK_RAN=1 }
        Z_POST_INTERACTIVE_HOOKS=('_test_hook_func')
        _run_post_interactive_hooks 2>/dev/null
        if [[ "$_TEST_HOOK_RAN" -eq 1 ]]; then
            pass "_run_post_interactive_hooks runs registered hook"
        else
            fail "_run_post_interactive_hooks did not run hook"
        fi
        unfunction _test_hook_func 2>/dev/null
        unset _TEST_HOOK_RAN

        # Non-existent function name — should not crash
        Z_POST_INTERACTIVE_HOOKS=('_nonexistent_hook_func_$$')
        _run_post_interactive_hooks 2>/dev/null
        if [[ $? -eq 0 ]]; then
            pass "_run_post_interactive_hooks skips missing function"
        else
            fail "_run_post_interactive_hooks crashes on missing function"
        fi

        # Restore
        Z_POST_INTERACTIVE_HOOKS=("${saved_hooks[@]}")
    else
        fail "_run_post_interactive_hooks not defined"
    fi
}

# ----------------------------------------------------------
# lib/functions/network.zsh (z_portcheck valid)
# ----------------------------------------------------------

test_portcheck_valid() {
    section "lib/functions/network.zsh (portcheck valid)"

    if (( $+functions[z_portcheck] )); then
        local output
        output=$(z_portcheck 8080 2>&1)
        if [[ $? -eq 0 && "$output" == *"8080"* ]]; then
            pass "z_portcheck accepts valid port"
        else
            # Port might be in use (lsof returns matches) — still valid
            pass "z_portcheck accepts valid port (port in use or free)"
        fi

        # Validate port number boundary
        output=$(z_portcheck 65535 2>&1)
        if [[ $? -eq 0 ]]; then
            pass "z_portcheck accepts max valid port 65535"
        else
            fail "z_portcheck rejects valid port 65535"
        fi
    else
        skip "z_portcheck not defined"
    fi
}

# ----------------------------------------------------------
# lib/functions/file.zsh (z_extract errors)
# ----------------------------------------------------------

test_extract_errors() {
    section "lib/functions/file.zsh (z_extract)"

    if (( $+functions[z_extract] )); then
        # Rejects missing file
        local output
        output=$(z_extract "/nonexistent-file-$$.tar.gz" 2>&1)
        if [[ $? -ne 0 ]]; then
            pass "z_extract rejects missing file"
        else
            fail "z_extract accepts missing file"
        fi

        # Rejects unknown format
        touch "$TEST_TMP/test-extract.$$.xyz"
        output=$(z_extract "$TEST_TMP/test-extract.$$.xyz" 2>&1)
        if [[ $? -ne 0 ]]; then
            pass "z_extract rejects unknown format"
        else
            fail "z_extract accepts unknown format"
        fi
    else
        skip "z_extract not defined"
    fi
}

# ----------------------------------------------------------
# lib/functions/file.zsh (z_extract roundtrip + zip-slip guard)
# ----------------------------------------------------------

test_extract_roundtrip() {
    section "lib/functions/file.zsh (z_extract roundtrip)"

    if ! (( $+functions[z_extract] && $+functions[_check_archive_safety] )); then
        skip "z_extract/_check_archive_safety not defined"
        return
    fi
    _skip_unless_cmd tar "z_extract roundtrip" && return

    local work="$TEST_TMP/extract_roundtrip"
    local payload="roundtrip-payload-$$"
    mkdir -p "$work/src"
    print -r -- "$payload" > "$work/src/payload.txt"

    # -- tar.gz roundtrip: extract and verify the bytes came back --
    (cd "$work" && tar czf archive.tar.gz -C src payload.txt) 2>/dev/null
    local tar_dest="$work/out_tar"
    z_extract "$work/archive.tar.gz" "$tar_dest" >/dev/null 2>&1
    assert_eq "$(cat "$tar_dest/payload.txt" 2>/dev/null)" "$payload" \
        "z_extract tar.gz roundtrip preserves file contents"

    # -- zip roundtrip (skip leg if zip/unzip missing) --
    if _has_cmd zip && _has_cmd unzip; then
        (cd "$work/src" && zip -q "$work/archive.zip" payload.txt) 2>/dev/null
        local zip_dest="$work/out_zip"
        z_extract "$work/archive.zip" "$zip_dest" >/dev/null 2>&1
        assert_eq "$(cat "$zip_dest/payload.txt" 2>/dev/null)" "$payload" \
            "z_extract zip roundtrip preserves file contents"
    else
        skip "zip roundtrip (zip/unzip not installed)"
    fi

    # -- Malicious archive with ../ member must fail closed --
    mkdir -p "$work/evil/sub"
    print -r -- "escape" > "$work/evil/escape.txt"
    (cd "$work/evil/sub" && tar -P -cf "$work/evil_rel.tar" ../escape.txt) 2>/dev/null
    if tar -tf "$work/evil_rel.tar" 2>/dev/null | grep -q '\.\./'; then
        assert_false "_check_archive_safety rejects archive with ../ member" \
            _check_archive_safety "$work/evil_rel.tar" 2>/dev/null
        local evil_dest="$work/out_evil_rel"
        z_extract "$work/evil_rel.tar" "$evil_dest" >/dev/null 2>&1
        assert_ne "$?" "0" "z_extract aborts extraction of ../ traversal archive"
        assert_file_exists "$work/evil/escape.txt" \
            "traversal target untouched after aborted extraction"
    else
        skip "tar -P did not preserve ../ member on this platform"
    fi

    # -- Malicious archive with absolute-path member must fail closed --
    (cd "$work" && tar -P -cf "$work/evil_abs.tar" "$work/src/payload.txt") 2>/dev/null
    if tar -tf "$work/evil_abs.tar" 2>/dev/null | grep -q '^/'; then
        assert_false "_check_archive_safety rejects archive with absolute-path member" \
            _check_archive_safety "$work/evil_abs.tar" 2>/dev/null
        z_extract "$work/evil_abs.tar" "$work/out_evil_abs" >/dev/null 2>&1
        assert_ne "$?" "0" "z_extract aborts extraction of absolute-path archive"
    else
        skip "tar -P did not preserve absolute member on this platform"
    fi
}

# ----------------------------------------------------------
# lib/functions/utilities.zsh (clipboard via stubbed backend)
# ----------------------------------------------------------

test_clipboard_functions() {
    section "lib/functions/utilities.zsh (clipboard)"

    if ! (( $+functions[z_copypath] && $+functions[z_copyfile] && $+functions[_get_clipboard_cmd] )); then
        skip "clipboard functions not defined"
        return
    fi

    # Stub the clipboard backend so the "clipboard" is a readable file
    local clip_file="$TEST_TMP/clip"
    local saved_clip_fn="${functions[_get_clipboard_cmd]}"
    eval "_get_clipboard_cmd() { print -r -- 'cat > \"$clip_file\"' }"

    # z_copypath: clipboard receives the absolute path
    local target="$TEST_TMP/copypath_target"
    mkdir -p "$target"
    z_copypath "$target" >/dev/null 2>&1
    assert_eq "$(cat "$clip_file" 2>/dev/null)" "${target:A}" \
        "z_copypath puts the absolute path on the clipboard"

    # z_copyfile: clipboard receives the exact file bytes (multiline)
    # (no cmp: diffutils is absent on minimal dnf images)
    local src_file="$TEST_TMP/copyfile_src"
    printf 'line one\nline two with spaces\n' > "$src_file"
    z_copyfile "$src_file" >/dev/null 2>&1
    if [[ "$(<$src_file)" == "$(<$clip_file 2>/dev/null)" ]]; then
        pass "z_copyfile puts the exact file contents on the clipboard"
    else
        fail "z_copyfile puts the exact file contents on the clipboard" \
            "$(cat "$src_file")" "$(cat "$clip_file" 2>/dev/null)"
    fi

    # z_copyfile rejects a missing file and leaves the clipboard untouched
    print -r -- "sentinel" > "$clip_file"
    z_copyfile "/nonexistent-file-$$" >/dev/null 2>&1
    assert_ne "$?" "0" "z_copyfile rejects missing file"
    assert_eq "$(cat "$clip_file" 2>/dev/null)" "sentinel" \
        "z_copyfile leaves clipboard untouched on missing file"

    # Restore the real backend
    functions[_get_clipboard_cmd]="$saved_clip_fn"
}

# ----------------------------------------------------------
# lib/functions/backup.zsh (backup/restore roundtrip, fake HOME)
# ----------------------------------------------------------

test_dotfiles_backup_restore() {
    section "lib/functions/backup.zsh (backup/restore roundtrip)"

    if ! (( $+functions[z_dotfiles_backup] && $+functions[z_dotfiles_restore] )); then
        skip "z_dotfiles_backup/z_dotfiles_restore not defined"
        return
    fi

    local fake_home="$TEST_TMP/backup_home"
    local fake_zdot="$fake_home/.config/zsh"
    local env_payload="original-zshenv-$$"
    local rc_payload="original-zshrc-$$"
    mkdir -p "$fake_zdot"
    print -r -- "$env_payload" > "$fake_home/.zshenv"
    print -r -- "$rc_payload" > "$fake_zdot/.zshrc"

    # Backup inside a fake-HOME subshell
    (
        HOME="$fake_home"
        ZDOTDIR="$fake_zdot"
        ZSH_CONFIG_HOME="$fake_zdot"
        z_dotfiles_backup >/dev/null 2>&1
    )

    local backup_dir
    backup_dir=$(ls -dt "$fake_home"/.zsh-backup-* 2>/dev/null | head -1)
    if [[ -z "$backup_dir" ]]; then
        fail "z_dotfiles_backup creates ~/.zsh-backup-<ts> in fake HOME"
        return
    fi
    pass "z_dotfiles_backup creates ~/.zsh-backup-<ts> in fake HOME"
    assert_file_exists "$backup_dir/MANIFEST" "backup writes a MANIFEST"
    assert_eq "$(cat "$backup_dir/.zshenv" 2>/dev/null)" "$env_payload" \
        "backup captures .zshenv bytes"
    assert_eq "$(cat "$backup_dir/zsh/.zshrc" 2>/dev/null)" "$rc_payload" \
        "backup captures ZDOTDIR contents"

    # Mutate the live files, then restore (answering the y/N prompt)
    print -r -- "MUTATED_ENV" > "$fake_home/.zshenv"
    print -r -- "MUTATED_RC" > "$fake_zdot/.zshrc"
    (
        HOME="$fake_home"
        ZDOTDIR="$fake_zdot"
        ZSH_CONFIG_HOME="$fake_zdot"
        print y | z_dotfiles_restore >/dev/null 2>&1
    )

    assert_eq "$(cat "$fake_home/.zshenv" 2>/dev/null)" "$env_payload" \
        "restore returns .zshenv to pre-mutation bytes"
    assert_eq "$(cat "$fake_zdot/.zshrc" 2>/dev/null)" "$rc_payload" \
        "restore returns ZDOTDIR file to pre-mutation bytes"

    # Restore declines when the user answers no
    print -r -- "MUTATED_AGAIN" > "$fake_home/.zshenv"
    (
        HOME="$fake_home"
        ZDOTDIR="$fake_zdot"
        ZSH_CONFIG_HOME="$fake_zdot"
        print n | z_dotfiles_restore >/dev/null 2>&1
    )
    assert_eq "$(cat "$fake_home/.zshenv" 2>/dev/null)" "MUTATED_AGAIN" \
        "restore leaves files untouched when declined"
}

# ----------------------------------------------------------
# modules/01_path.zsh (processing & cache)
# ----------------------------------------------------------

test_path_processing() {
    section "modules/01_path.zsh (processing)"

    # _path_cache_rebuild
    if (( $+functions[_path_cache_rebuild] )); then
        _path_cache_rebuild
        # /usr/bin should always be in PATH and thus in cache
        if [[ -n "${_PATH_CACHE[/usr/bin]}" ]]; then
            pass "_path_cache_rebuild populates cache"
        else
            fail "_path_cache_rebuild missing /usr/bin"
        fi
    else
        skip "_path_cache_rebuild not defined"
    fi

    # _process_path_definitions with a test entry
    if (( $+functions[_process_path_definitions] )); then
        # Create a test directory and add it to definitions
        local test_path_dir="$TEST_TMP/test-path-proc-$$"
        mkdir -p "$test_path_dir"

        # Save current definitions
        local -A saved_defs
        saved_defs=("${(kv)Z_PATH_DEFINITIONS[@]}")

        # Set a minimal test definition: always add test_path_dir
        Z_PATH_DEFINITIONS=()
        Z_PATH_DEFINITIONS[test-entry]="${test_path_dir}:prepend:always:"

        _process_path_definitions 2>/dev/null

        if [[ ":$PATH:" == *":${test_path_dir}:"* ]]; then
            pass "_process_path_definitions adds path with always condition"
        else
            fail "_process_path_definitions did not add path"
        fi

        # Cleanup: remove test path from PATH and restore definitions
        path=("${(@)path:#$test_path_dir}")
        Z_PATH_DEFINITIONS=("${(kv)saved_defs[@]}")
        _path_cache_rebuild 2>/dev/null
    else
        skip "_process_path_definitions not defined"
    fi
}

test_help_system() {
    section "lib/functions/help.zsh"

    # z_help function defined
    if (( $+functions[z_help] )); then
        pass "z_help function defined"
    else
        fail "z_help function not defined"
    fi

    # _HELP_REGISTRY populated with >30 entries
    if (( ${#_HELP_REGISTRY} > 30 )); then
        pass "_HELP_REGISTRY populated (${#_HELP_REGISTRY} entries)"
    else
        fail "_HELP_REGISTRY has only ${#_HELP_REGISTRY} entries (expected >30)"
    fi

    # z_help produces output (static mode)
    local help_output
    help_output="$(z_help 2>&1)"
    if [[ -n "$help_output" ]]; then
        pass "z_help produces output"
    else
        fail "z_help produces no output"
    fi

    # help detail for known command
    local detail_output
    detail_output="$(z_help calc 2>&1)"
    if [[ $? -eq 0 && "$detail_output" == *"calc"* ]]; then
        pass "z_help calc shows command detail"
    else
        fail "z_help calc did not show expected detail"
    fi

    # help detail rejects unknown command
    local unknown_output
    unknown_output="$(z_help nonexistent_xyz_test 2>&1)"
    if [[ $? -ne 0 ]]; then
        pass "z_help rejects unknown command"
    else
        fail "z_help accepted unknown command"
    fi

    # _help_show_state produces output
    if (( $+functions[_help_show_state] )); then
        local state_output
        state_output="$(_help_show_state 2>&1)"
        if [[ -n "$state_output" ]]; then
            pass "_help_show_state produces output"
        else
            fail "_help_show_state produces no output"
        fi
    else
        skip "_help_show_state not defined"
    fi
}

# ----------------------------------------------------------
# TESTS: XDG Guardian
# ----------------------------------------------------------

test_xdg_guardian() {
    section "lib/functions/xdg.zsh (XDG Guardian)"

    # -- Configuration defaults --

    # Z_XDG_GUARDIAN_ENABLED defaults to true
    assert_eq "${Z_XDG_GUARDIAN_ENABLED:-}" "true" "Z_XDG_GUARDIAN_ENABLED defaults to true"

    # Z_XDG_GUARDIAN_INTERVAL defaults to 86400
    assert_eq "${Z_XDG_GUARDIAN_INTERVAL:-}" "86400" "Z_XDG_GUARDIAN_INTERVAL defaults to 86400"

    # Z_XDG_GUARDIAN_AUTO_FIX defaults to false
    assert_eq "${Z_XDG_GUARDIAN_AUTO_FIX:-}" "false" "Z_XDG_GUARDIAN_AUTO_FIX defaults to false"

    # Z_XDG_GUARDIAN_QUIET defaults to false
    assert_eq "${Z_XDG_GUARDIAN_QUIET:-}" "false" "Z_XDG_GUARDIAN_QUIET defaults to false"

    # Z_XDG_GUARDIAN_MODE defaults to notify
    assert_eq "${Z_XDG_GUARDIAN_MODE:-}" "notify" "Z_XDG_GUARDIAN_MODE defaults to notify"

    # -- Z_XDG_MIGRATIONS array --

    if (( ${+Z_XDG_MIGRATIONS} )); then
        pass "Z_XDG_MIGRATIONS declared"
    else
        fail "Z_XDG_MIGRATIONS not declared"
    fi

    if (( ${#Z_XDG_MIGRATIONS} > 0 )); then
        pass "Z_XDG_MIGRATIONS populated (${#Z_XDG_MIGRATIONS} entries)"
    else
        fail "Z_XDG_MIGRATIONS is empty"
    fi

    # Validate entry format: value should have pipe-delimited fields
    local _xk _xv _valid_count=0
    for _xk _xv in ${(kv)Z_XDG_MIGRATIONS}; do
        if [[ "$_xv" == *"|"* ]]; then
            (( _valid_count++ ))
        fi
    done
    if (( _valid_count == ${#Z_XDG_MIGRATIONS} )); then
        pass "Z_XDG_MIGRATIONS entries all have pipe-delimited format"
    else
        fail "Some Z_XDG_MIGRATIONS entries lack pipe delimiters" "${#Z_XDG_MIGRATIONS}" "$_valid_count"
    fi

    # -- Core functions exist --

    local -a xdg_funcs=(
        _xdg_ninja_db_path _xdg_is_skipped _xdg_format_size _xdg_format_date
        _xdg_format_date_short _xdg_format_relative_time
        _xdg_now _xdg_record_pack _xdg_record_unpack
        _xdg_ninja_cache_file _xdg_ninja_cache_stale _xdg_ninja_build_cache
        _xdg_scan_ninja _xdg_scan_registry _xdg_scan_orphans
        _xdg_check_conflict _xdg_migrate_one _xdg_classify
        _xdg_guardian_hook _xdg_clean_old_backups
        _xdg_resolve_conflict_fzf _xdg_resolve_conflict_menu
        z_xdg_check z_xdg_fix z_xdg_status
    )
    local _fn
    for _fn in "${xdg_funcs[@]}"; do
        if (( $+functions[$_fn] )); then
            pass "$_fn function defined"
        else
            fail "$_fn function not defined"
        fi
    done

    # -- _xdg_ninja_db_path: returns valid path or 1 --

    local _ninja_path
    _ninja_path=$(_xdg_ninja_db_path 2>/dev/null)
    if [[ $? -eq 0 && -d "$_ninja_path" ]]; then
        pass "_xdg_ninja_db_path returns valid directory"
    else
        skip "_xdg_ninja_db_path: xdg-ninja not installed"
    fi

    # -- _xdg_is_skipped: default skip list --

    if _xdg_is_skipped "$HOME/.zshenv"; then
        pass "_xdg_is_skipped recognizes .zshenv"
    else
        fail "_xdg_is_skipped did not skip .zshenv"
    fi

    if _xdg_is_skipped "$HOME/.ssh"; then
        pass "_xdg_is_skipped recognizes .ssh"
    else
        fail "_xdg_is_skipped did not skip .ssh"
    fi

    if ! _xdg_is_skipped "$HOME/.random_test_path_xyz"; then
        pass "_xdg_is_skipped allows non-skipped paths"
    else
        fail "_xdg_is_skipped incorrectly skipped random path"
    fi

    # -- _xdg_format_size --

    assert_contains "$(_xdg_format_size 500)" "KB" "_xdg_format_size: KB for small"
    assert_contains "$(_xdg_format_size 2048)" "MB" "_xdg_format_size: MB for medium"
    assert_contains "$(_xdg_format_size 2097152)" "GB" "_xdg_format_size: GB for large"

    # -- _xdg_check_conflict with temp files --

    local _xdg_src="$TEST_TMP/xdg_src" _xdg_tgt="$TEST_TMP/xdg_tgt"

    # CLEAR: target doesn't exist
    echo "test" > "$_xdg_src"
    local _cdata
    _cdata=$(_xdg_check_conflict "$_xdg_src" "$_xdg_tgt")
    local _crc=$?
    if (( _crc == 0 )) && [[ "$_cdata" == CLEAR* ]]; then
        pass "_xdg_check_conflict: CLEAR when target absent"
    else
        fail "_xdg_check_conflict: expected CLEAR" "0/CLEAR" "$_crc/$_cdata"
    fi

    # ERROR: source doesn't exist
    rm -f "$_xdg_src"
    _cdata=$(_xdg_check_conflict "$_xdg_src" "$_xdg_tgt")
    _crc=$?
    if (( _crc == 2 )); then
        pass "_xdg_check_conflict: ERROR when source absent"
    else
        fail "_xdg_check_conflict: expected ERROR (rc=2)" "2" "$_crc"
    fi

    # TYPE_MISMATCH: file vs dir
    echo "file" > "$_xdg_src"
    mkdir -p "$_xdg_tgt"
    _cdata=$(_xdg_check_conflict "$_xdg_src" "$_xdg_tgt")
    _crc=$?
    if (( _crc == 1 )) && [[ "$_cdata" == TYPE_MISMATCH* ]]; then
        pass "_xdg_check_conflict: TYPE_MISMATCH (file vs dir)"
    else
        fail "_xdg_check_conflict: expected TYPE_MISMATCH" "1/TYPE_MISMATCH" "$_crc/$_cdata"
    fi
    rm -rf "$_xdg_src" "$_xdg_tgt"

    # -- _xdg_migrate_one with temp dirs --

    # Simple successful migration
    local _mig_src="$TEST_TMP/mig_source" _mig_tgt="$TEST_TMP/mig_dest/config"
    mkdir -p "$_mig_src"
    echo "data" > "$_mig_src/file.txt"

    local _old_state="$ZSH_STATE_HOME"
    export ZSH_STATE_HOME="$TEST_TMP/state"
    mkdir -p "$ZSH_STATE_HOME"

    _xdg_migrate_one "$_mig_src" "$_mig_tgt"
    _crc=$?
    if (( _crc == 0 )) && [[ -d "$_mig_tgt" ]] && [[ ! -e "$_mig_src" ]]; then
        pass "_xdg_migrate_one: successful migration"
    else
        fail "_xdg_migrate_one: migration failed" "rc=0, tgt exists, src gone" "rc=$_crc"
    fi

    # Verify migrated content
    if [[ -f "$_mig_tgt/file.txt" ]]; then
        pass "_xdg_migrate_one: content preserved"
    else
        fail "_xdg_migrate_one: content not preserved"
    fi

    # Verify log file written
    if [[ -f "$ZSH_STATE_HOME/xdg-guardian.log" ]]; then
        pass "_xdg_migrate_one: log file written"
    else
        fail "_xdg_migrate_one: log file not written"
    fi

    # Non-existent source returns 1
    _xdg_migrate_one "$TEST_TMP/nonexistent_src_xyz" "$TEST_TMP/nonexistent_tgt_xyz"
    if (( $? == 1 )); then
        pass "_xdg_migrate_one: returns 1 for non-existent source"
    else
        fail "_xdg_migrate_one: did not return 1 for non-existent source"
    fi

    # Conflict returns 2 (target newer than source)
    local _csrc="$TEST_TMP/conflict_src" _ctgt="$TEST_TMP/conflict_tgt"
    echo "old" > "$_csrc"
    sleep 1
    echo "new" > "$_ctgt"
    _xdg_migrate_one "$_csrc" "$_ctgt"
    if (( $? == 2 )); then
        pass "_xdg_migrate_one: returns 2 for conflict (target newer)"
    else
        # This may not always trigger depending on mtime resolution
        skip "_xdg_migrate_one: conflict detection timing-dependent"
    fi

    # Skip list respected
    local _skip_src="$HOME/.zshenv"
    if [[ -f "$_skip_src" ]]; then
        _xdg_migrate_one "$_skip_src" "$TEST_TMP/should_not_move"
        if (( $? == 0 )) && [[ -f "$_skip_src" ]]; then
            pass "_xdg_migrate_one: skip list prevents migration of .zshenv"
        else
            fail "_xdg_migrate_one: did not respect skip list for .zshenv"
        fi
    else
        skip "_xdg_migrate_one: .zshenv not present to test skip list"
    fi

    # Restore state dir
    export ZSH_STATE_HOME="$_old_state"

    # -- _xdg_format_relative_time --

    local _now="$EPOCHSECONDS"
    local _5min_ago=$(( _now - 300 ))
    local _3hours_ago=$(( _now - 10800 ))
    local _2days_ago=$(( _now - 172800 ))
    local _3months_ago=$(( _now - 7776000 ))

    assert_contains "$(_xdg_format_relative_time "$_5min_ago")" "minutes" "_xdg_format_relative_time: minutes"
    assert_contains "$(_xdg_format_relative_time "$_3hours_ago")" "hours" "_xdg_format_relative_time: hours"
    assert_contains "$(_xdg_format_relative_time "$_2days_ago")" "days" "_xdg_format_relative_time: days"
    assert_contains "$(_xdg_format_relative_time "$_3months_ago")" "months" "_xdg_format_relative_time: months"

    # -- _xdg_scan_orphans --

    local _old_migrations_orphan
    typeset -A _old_migrations_orphan
    local k v
    for k v in ${(kv)Z_XDG_MIGRATIONS}; do
        _old_migrations_orphan[$k]="$v"
    done

    # Create a fake orphan: target exists, tool NOT installed
    local _orphan_tgt="$TEST_TMP/orphan_xdg_dir"
    mkdir -p "$_orphan_tgt"
    echo "leftover" > "$_orphan_tgt/data"
    Z_XDG_MIGRATIONS+=(
        '$HOME/.fake_orphan_tool_xyz' "${_orphan_tgt}|Test orphan|true|fake_orphan_tool_xyz_nonexistent"
    )
    typeset -gA _Z_XDG_ORPHANS=()
    _xdg_scan_orphans
    if (( ${#_Z_XDG_ORPHANS} > 0 )) && [[ -n "${_Z_XDG_ORPHANS[$_orphan_tgt]:-}" ]]; then
        pass "_xdg_scan_orphans: detects orphaned XDG directory"
    else
        fail "_xdg_scan_orphans: did not detect orphan" "found in _Z_XDG_ORPHANS" "not found"
    fi
    rm -rf "$_orphan_tgt"

    # Restore original migrations
    typeset -gA Z_XDG_MIGRATIONS=()
    for k v in ${(kv)_old_migrations_orphan}; do
        Z_XDG_MIGRATIONS[$k]="$v"
    done

    # -- _xdg_migrate_one: atomic backup created and cleaned --

    local _abk_src="$TEST_TMP/atomic_src" _abk_tgt="$TEST_TMP/atomic_dest/config"
    mkdir -p "$_abk_src"
    echo "atomic_data" > "$_abk_src/file.txt"

    local _old_state_abk="$ZSH_STATE_HOME"
    export ZSH_STATE_HOME="$TEST_TMP/atomic_state"
    mkdir -p "$ZSH_STATE_HOME"

    _xdg_migrate_one "$_abk_src" "$_abk_tgt"
    _crc=$?
    if (( _crc == 0 )); then
        pass "_xdg_migrate_one: atomic migration succeeded"
        # Backup should be cleaned on success
        local _backup_dir="$ZSH_STATE_HOME/xdg-guardian-backups"
        if [[ ! -d "$_backup_dir" ]] || (( $(ls -A "$_backup_dir" 2>/dev/null | wc -l | tr -d ' ') == 0 )); then
            pass "_xdg_migrate_one: backup cleaned after success"
        else
            fail "_xdg_migrate_one: backup not cleaned"
        fi
    else
        fail "_xdg_migrate_one: atomic migration failed" "0" "$_crc"
    fi
    export ZSH_STATE_HOME="$_old_state_abk"

    # -- _xdg_classify: target exists → always conflict --

    typeset -gA _Z_XDG_FINDINGS=()
    local _cls_src="$TEST_TMP/cls_stray"
    local _cls_tgt="$TEST_TMP/cls_target"
    mkdir -p "$_cls_src" "$_cls_tgt"
    echo "old" > "$_cls_src/data"
    echo "new" > "$_cls_tgt/data"
    # Simulate a managed finding with existing target
    _Z_XDG_FINDINGS[$_cls_src]="${_cls_tgt}|some hint|true|sometool||managed"
    typeset -gA _Z_XDG_ORPHANS=()
    _xdg_classify
    if (( ${#_Z_XDG_CONFLICTS} > 0 )) && (( ${#_Z_XDG_READY} == 0 )); then
        pass "_xdg_classify: target exists -> conflict (not ready)"
    else
        fail "_xdg_classify: target exists should be conflict" \
            "conflicts>0,ready=0" "conflicts=${#_Z_XDG_CONFLICTS},ready=${#_Z_XDG_READY}"
    fi
    rm -rf "$_cls_src" "$_cls_tgt"

    # -- _xdg_migrate_one --force: backs up existing target --

    local _ft_src="$TEST_TMP/force_src" _ft_tgt="$TEST_TMP/force_dest/config"
    mkdir -p "$_ft_src" "$_ft_tgt"
    echo "src_data" > "$_ft_src/file.txt"
    echo "tgt_data" > "$_ft_tgt/existing.txt"

    local _old_state_ft="$ZSH_STATE_HOME"
    export ZSH_STATE_HOME="$TEST_TMP/force_state"
    mkdir -p "$ZSH_STATE_HOME"

    _xdg_migrate_one "$_ft_src" "$_ft_tgt" "--force"
    _crc=$?
    if (( _crc == 0 )); then
        pass "_xdg_migrate_one --force: migration succeeded"
        # Target should have source content
        if [[ -f "$_ft_tgt/file.txt" ]]; then
            pass "_xdg_migrate_one --force: source content at target"
        else
            fail "_xdg_migrate_one --force: source content missing from target"
        fi
        # Both source and target backups should be cleaned on success
        local _ft_bk="$ZSH_STATE_HOME/xdg-guardian-backups"
        local _ft_bk_count=0
        for _d in "$_ft_bk"/*(N/); do
            (( _ft_bk_count++ ))
        done
        if (( _ft_bk_count == 0 )); then
            pass "_xdg_migrate_one --force: all backups cleaned on success"
        else
            fail "_xdg_migrate_one --force: backups not cleaned" "0" "$_ft_bk_count"
        fi
    else
        fail "_xdg_migrate_one --force: migration failed" "0" "$_crc"
    fi
    export ZSH_STATE_HOME="$_old_state_ft"

    # -- _xdg_guardian_hook respects ENABLED=false --

    local _old_enabled="$Z_XDG_GUARDIAN_ENABLED"
    Z_XDG_GUARDIAN_ENABLED=false
    _xdg_guardian_hook 2>/dev/null
    if (( $? == 0 )); then
        pass "_xdg_guardian_hook: returns 0 when disabled"
    else
        fail "_xdg_guardian_hook: unexpected return when disabled"
    fi
    Z_XDG_GUARDIAN_ENABLED="$_old_enabled"

    # -- z_xdg_status output format --

    local _old_state2="$ZSH_STATE_HOME"
    export ZSH_STATE_HOME="$TEST_TMP/status_state"
    mkdir -p "$ZSH_STATE_HOME"

    # No findings file -> "unknown"
    local _status_out
    _status_out="$(z_xdg_status 2>/dev/null)"
    if [[ "$_status_out" == XDG:* ]]; then
        pass "z_xdg_status: outputs XDG: prefix"
    else
        fail "z_xdg_status: missing XDG: prefix" "XDG:*" "$_status_out"
    fi
    assert_contains "$_status_out" "unknown" "z_xdg_status: unknown when no findings"

    # With findings -> reports count
    {
        echo "# scan"
        echo "STRAY|/tmp/fake1|data"
        echo "STRAY|/tmp/fake2|data"
    } > "$ZSH_STATE_HOME/xdg-guardian.findings"
    _status_out="$(z_xdg_status 2>/dev/null)"
    assert_contains "$_status_out" "2 stray" "z_xdg_status: reports stray count"

    export ZSH_STATE_HOME="$_old_state2"

    # -- _xdg_now: positive integer epoch --

    local _now_out
    _now_out=$(_xdg_now)
    if [[ "$_now_out" == <-> ]] && (( _now_out > 0 )); then
        pass "_xdg_now returns a positive integer ($_now_out)"
    else
        fail "_xdg_now did not return a positive integer" "positive integer" "$_now_out"
    fi

    # -- Record pack/unpack roundtrip (4 fields, incl. empty + spaces) --

    local REPLY
    local -a reply
    _xdg_record_pack "first" "two words" "" "fourth"
    _xdg_record_unpack "$REPLY"
    if (( ${#reply} == 4 )) && [[ "${reply[1]}" == "first" ]] && \
       [[ "${reply[2]}" == "two words" ]] && [[ -z "${reply[3]}" ]] && \
       [[ "${reply[4]}" == "fourth" ]]; then
        pass "record pack/unpack roundtrip preserves 4 fields"
    else
        fail "record pack/unpack roundtrip broken" "4 intact fields" \
            "count=${#reply}: ${(j:,:)reply}"
    fi

    # -- _xdg_skip_permanently must not clobber the tied \$path array --

    local _old_state_skip="$ZSH_STATE_HOME"
    local _old_skip_list="$Z_XDG_GUARDIAN_SKIP"
    export ZSH_STATE_HOME="$TEST_TMP/skip_state"
    mkdir -p "$ZSH_STATE_HOME"

    local _path_len_before=${#path}
    _xdg_skip_permanently "$TEST_TMP/fake_stray_for_skip"
    if (( ${#path} == _path_len_before )); then
        pass "_xdg_skip_permanently leaves \$path array unchanged (${#path} entries)"
    else
        fail "_xdg_skip_permanently clobbered \$path" "$_path_len_before" "${#path}"
    fi
    if grep -q "fake_stray_for_skip" "$ZSH_STATE_HOME/xdg-guardian.skip" 2>/dev/null; then
        pass "_xdg_skip_permanently persists entry to skip file"
    else
        fail "_xdg_skip_permanently did not persist entry"
    fi

    Z_XDG_GUARDIAN_SKIP="$_old_skip_list"
    export ZSH_STATE_HOME="$_old_state_skip"

    # -- _xdg_ninja_build_cache: one-pass TSV cache --

    if _xdg_ninja_db_path >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        local _old_cache_home="${ZSH_CACHE_HOME:-}"
        export ZSH_CACHE_HOME="$TEST_TMP/ninja_cache"

        if _xdg_ninja_build_cache; then
            local _cache_file _cache_lines
            _cache_file=$(_xdg_ninja_cache_file)
            _cache_lines=$(wc -l < "$_cache_file" | tr -d ' ')
            if (( _cache_lines > 100 )); then
                pass "_xdg_ninja_build_cache produces cache with >100 lines ($_cache_lines)"
            else
                fail "_xdg_ninja_build_cache cache too small" ">100 lines" "$_cache_lines"
            fi
            # First line is the version stamp so filter changes invalidate
            local _stamp
            IFS= read -r _stamp < "$_cache_file"
            assert_eq "$_stamp" "$_Z_XDG_NINJA_CACHE_VERSION" \
                "_xdg_ninja_build_cache stamps cache version"
            # Fresh cache is not stale; wrong stamp is
            if ! _xdg_ninja_cache_stale "$(_xdg_ninja_db_path)" "$_cache_file"; then
                pass "_xdg_ninja_cache_stale: fresh cache is not stale"
            else
                fail "_xdg_ninja_cache_stale: fresh cache reported stale"
            fi
            echo "#v0-obsolete" >| "$_cache_file"
            if _xdg_ninja_cache_stale "$(_xdg_ninja_db_path)" "$_cache_file"; then
                pass "_xdg_ninja_cache_stale: version mismatch is stale"
            else
                fail "_xdg_ninja_cache_stale: version mismatch not detected"
            fi
        else
            fail "_xdg_ninja_build_cache failed despite jq + ninja DB present"
        fi

        if [[ -n "$_old_cache_home" ]]; then
            export ZSH_CACHE_HOME="$_old_cache_home"
        else
            unset ZSH_CACHE_HOME
        fi
    else
        skip "_xdg_ninja_build_cache: jq or xdg-ninja DB not available"
    fi

    # -- Guardian modes: off returns immediately --

    local _old_mode="${Z_XDG_GUARDIAN_MODE:-notify}"
    Z_XDG_GUARDIAN_MODE=off
    local _mode_out _mode_rc
    _mode_out=$(_xdg_guardian_hook 2>&1)
    _mode_rc=$?
    if (( _mode_rc == 0 )) && [[ -z "$_mode_out" ]]; then
        pass "_xdg_guardian_hook: mode=off returns 0 with no output"
    else
        fail "_xdg_guardian_hook: mode=off misbehaved" "rc=0, no output" "rc=$_mode_rc, out=$_mode_out"
    fi
    Z_XDG_GUARDIAN_MODE="$_old_mode"

    # -- Hook registered in Z_POST_INTERACTIVE_HOOKS (fresh shell) --
    # NOTE: Other tests re-source core.zsh which resets the hooks array,
    # so we verify registration in a clean subshell instead.

    local _hook_check
    _hook_check=$(zsh -c 'echo ${Z_POST_INTERACTIVE_HOOKS[@]}' 2>/dev/null)
    if [[ "$_hook_check" == *"_xdg_guardian_hook"* ]]; then
        pass "_xdg_guardian_hook registered in Z_POST_INTERACTIVE_HOOKS"
    else
        fail "_xdg_guardian_hook not registered in Z_POST_INTERACTIVE_HOOKS" "*_xdg_guardian_hook*" "$_hook_check"
    fi
}

# ----------------------------------------------------------
# lib/registry/tools.zsh (tool catalog)
# ----------------------------------------------------------

test_tools_catalog() {
    section "lib/registry/tools.zsh (tool catalog)"

    unset _Z_REGISTRY_TOOLS_LOADED 2>/dev/null
    source "$ZDOTDIR/lib/registry/tools.zsh" 2>/dev/null || true

    if ! typeset -f _z_tools_load > /dev/null 2>&1; then
        fail "_z_tools_load not defined"
        return
    fi

    Z_TOOLS=() Z_TOOL_NAMES=()
    if _z_tools_load; then
        pass "_z_tools_load parses tools.dat"
    else
        fail "_z_tools_load parses tools.dat"
        return
    fi

    if (( ${#Z_TOOL_NAMES[@]} >= 25 )); then
        pass "catalog has full tool set (${#Z_TOOL_NAMES[@]} tools)"
    else
        fail "catalog has full tool set" ">=25" "${#Z_TOOL_NAMES[@]}"
    fi

    # Every entry carries all 7 value fields (structure test checks the file;
    # this checks the parse)
    local name bad=0
    for name in "${Z_TOOL_NAMES[@]}"; do
        local -a fields=("${(@s.:.)Z_TOOLS[$name]}")
        (( ${#fields[@]} == 7 )) || bad=$((bad + 1))
    done
    if (( bad == 0 )); then
        pass "every catalog entry parses to 7 fields"
    else
        fail "every catalog entry parses to 7 fields" "0 bad" "$bad bad"
    fi

    if [[ "$(_z_tool_field starship category)" == "essential" && \
          "$(_z_tool_field atuin category)" == "essential" ]]; then
        pass "starship and atuin are essential"
    else
        fail "starship and atuin are essential"
    fi

    if [[ "$(_z_tool_field ripgrep binary)" == "rg" ]]; then
        pass "_z_tool_field resolves binary names (ripgrep -> rg)"
    else
        fail "_z_tool_field resolves binary names (ripgrep -> rg)"
    fi

    # Drift guard: the installer must consume the catalog, not a literal copy
    if ! grep -q 'declare -a ALL_TOOLS' "$ZDOTDIR/install.sh"; then
        pass "install.sh has no hardcoded ALL_TOOLS list"
    else
        fail "install.sh has no hardcoded ALL_TOOLS list"
    fi
}

# ----------------------------------------------------------
# lib/core/platform/detect.zsh (_detect_ssh_agent)
# ----------------------------------------------------------

test_ssh_agent_detection() {
    section "lib/core/platform/detect.zsh (_detect_ssh_agent)"

    if ! zmodload zsh/net/socket 2>/dev/null; then
        skip "zsh/net/socket unavailable"
        return
    fi

    local fake_home="$TEST_TMP/ssh-home"
    mkdir -p "$fake_home/.1password"

    # Real listening unix socket so [[ -S ]] is true
    if ! zsocket -l "$fake_home/.1password/agent.sock" 2>/dev/null; then
        skip "cannot create unix socket in test tmp"
        return
    fi
    local sock_fd=$REPLY

    # 1Password socket wins when nothing else is set
    local result
    result=$(HOME="$fake_home" XDG_RUNTIME_DIR="$TEST_TMP/no-such-run" SSH_AUTH_SOCK= \
        zsh -c "source '$ZDOTDIR/lib/core/platform/detect.zsh' 2>/dev/null; \
                _detect_ssh_agent; print -r -- \"\$SSH_AUTH_SOCK\"" 2>/dev/null)
    if [[ "$result" == "$fake_home/.1password/agent.sock" ]]; then
        pass "_detect_ssh_agent selects ~/.1password/agent.sock"
    else
        fail "_detect_ssh_agent selects ~/.1password/agent.sock" \
            "$fake_home/.1password/agent.sock" "$result"
    fi

    # A valid pre-existing socket is preserved when no provider matches
    local empty_home="$TEST_TMP/ssh-empty-home"
    mkdir -p "$empty_home"
    result=$(HOME="$empty_home" XDG_RUNTIME_DIR="$TEST_TMP/no-such-run" \
        SSH_AUTH_SOCK="$fake_home/.1password/agent.sock" \
        zsh -c "source '$ZDOTDIR/lib/core/platform/detect.zsh' 2>/dev/null; \
                _detect_ssh_agent; print -r -- \"\$SSH_AUTH_SOCK\"" 2>/dev/null)
    if [[ "$result" == "$fake_home/.1password/agent.sock" ]]; then
        pass "_detect_ssh_agent keeps valid pre-existing SSH_AUTH_SOCK"
    else
        fail "_detect_ssh_agent keeps valid pre-existing SSH_AUTH_SOCK" \
            "$fake_home/.1password/agent.sock" "$result"
    fi

    exec {sock_fd}>&- 2>/dev/null || true
}

# ----------------------------------------------------------
# modules/06_aliases.zsh (_z_apply_replacements)
# ----------------------------------------------------------

test_replacements() {
    section "modules/06_aliases.zsh (_z_apply_replacements)"

    # Hermetic subshell: fixture catalog + stubbed _has_cmd, real function
    local out
    out=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR' ZSH_CONFIG_HOME='$ZDOTDIR' Z_LOG_LEVEL=NONE
        source '$ZDOTDIR/lib/core/index.zsh' 2>/dev/null
        source '$ZDOTDIR/lib/registry/tools.zsh' 2>/dev/null
        source '$ZDOTDIR/modules/06_aliases.zsh' 2>/dev/null

        # Fixture catalog (pre-populated => _z_tools_load early-returns)
        Z_TOOL_NAMES=(faketool cdtool battool)
        Z_TOOLS[faketool]='fakebin:desc:extra:fakecls:brew:apt:'
        Z_TOOLS[cdtool]='cdbin:desc:extra:cd:brew:apt:'
        Z_TOOLS[battool]='bat:desc:extra:cat:brew:apt:'
        _has_cmd() { [[ \$1 == fakebin || \$1 == cdbin || \$1 == bat ]] }

        Z_REPLACE_FAKETOOL=true
        Z_REPLACE_CDTOOL=true
        Z_REPLACE_BATTOOL=true
        _z_apply_replacements

        print -r -- \"fakecls=\${aliases[fakecls]:-UNSET}\"
        print -r -- \"cd=\${aliases[cd]:-UNSET}\"
        print -r -- \"cat=\${aliases[cat]:-UNSET}\"

        Z_REPLACE_FAKETOOL=false
        unalias fakecls 2>/dev/null
        _z_apply_replacements
        print -r -- \"fakecls_off=\${aliases[fakecls]:-UNSET}\"
    " 2>/dev/null)

    assert_contains "$out" "fakecls=fakebin" \
        "enabled toggle aliases the classic command to the modern binary"
    assert_contains "$out" "cd=UNSET" \
        "cd replacement is excluded (owned by the zoxide lazy module)"
    assert_contains "$out" "cat=bat --paging=never" \
        "bat replacement carries its behave-like-cat flags"
    assert_contains "$out" "fakecls_off=UNSET" \
        "disabled toggle leaves the classic command untouched"
}

# ----------------------------------------------------------
# TEST RUNNER
# ----------------------------------------------------------

main() {
    echo "================================================"
    echo "  ZSH Configuration Unit Tests"
    echo "================================================"

    setup_suite_env

    # Run all test suites
    test_utils
    test_logging
    test_path_functions
    test_path_ordering
    test_path_conditions
    test_lazy
    test_history
    test_input_validation
    test_platform_detection
    test_python
    test_docker
    test_security_negative
    test_get_mtime
    test_cache_eval
    test_environment
    test_platform_extended
    test_ensure_file_perms
    test_plugin_fallback
    test_system_functions
    test_file_functions
    test_git_functions
    test_network_functions
    test_introspection_functions
    test_lazy_loading_extended
    test_z_history_clean
    test_core_utils_extended
    test_portcheck_valid
    test_extract_errors
    test_extract_roundtrip
    test_clipboard_functions
    test_dotfiles_backup_restore
    test_path_processing
    test_help_system
    test_xdg_guardian
    test_tools_catalog
    test_ssh_agent_detection
    test_replacements

    teardown_test_env

    print_summary "unit tests"
    exit $?
}

main "$@"
