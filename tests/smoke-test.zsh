#!/bin/zsh
# ==============================================================================
# * ZSH CONFIGURATION SMOKE TEST
# ? Validates installation and shell functionality.
# ? Run: ./scripts/smoke-test.zsh [--verbose]
# ==============================================================================

set -e

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
WARNINGS=0

# ----------------------------------------------------------
# * TEST HELPERS
# ----------------------------------------------------------

pass() {
    echo "${GREEN}✓${NC} $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo "${RED}✗${NC} $1"
    FAILED=$((FAILED + 1))
}

warn() {
    echo "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

info() {
    [[ "$VERBOSE" == "true" ]] && echo "${BLUE}→${NC} $1"
    return 0
}

section() {
    echo ""
    echo "${BLUE}═══${NC} $1 ${BLUE}═══${NC}"
}

# ----------------------------------------------------------
# * ENVIRONMENT SETUP
# ----------------------------------------------------------

section "Environment"

# Detect ZDOTDIR
if [[ -z "$ZDOTDIR" ]]; then
    # Try common locations
    if [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/zsh" ]]; then
        export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
    elif [[ -d "$HOME/.config/zsh" ]]; then
        export ZDOTDIR="$HOME/.config/zsh"
    else
        fail "ZDOTDIR not set and config not found"
        exit 1
    fi
fi

info "ZDOTDIR=$ZDOTDIR"
info "HOME=$HOME"
info "XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-not set}"

# Verify ZDOTDIR exists
if [[ -d "$ZDOTDIR" ]] || [[ -L "$ZDOTDIR" ]]; then
    if [[ -L "$ZDOTDIR" ]]; then
        pass "ZDOTDIR exists (symlink → $(readlink "$ZDOTDIR"))"
    else
        pass "ZDOTDIR exists (directory)"
    fi
else
    fail "ZDOTDIR not found at $ZDOTDIR"
    exit 1
fi

# ----------------------------------------------------------
# * FILE STRUCTURE
# ----------------------------------------------------------

section "File Structure"

required_files=(
    ".zshenv"
    ".zshrc"
    "modules/logging.zsh"
    "modules/environment.zsh"
    "modules/path.zsh"
    "lib/utils.zsh"
)

for file in "${required_files[@]}"; do
    if [[ -f "$ZDOTDIR/$file" ]]; then
        pass "$file exists"
    else
        fail "$file missing"
    fi
done

# ----------------------------------------------------------
# * ZSHENV LOADING
# ----------------------------------------------------------

section "Loading .zshenv"

# Test .zshenv loads without errors
zshenv_output=$(zsh -c "
    export ZDOTDIR='$ZDOTDIR'
    source \$ZDOTDIR/.zshenv 2>&1
    echo 'ZSHENV_OK'
" 2>&1)

if [[ "$zshenv_output" == *"ZSHENV_OK"* ]]; then
    pass ".zshenv loads without errors"
else
    fail ".zshenv failed to load"
    echo "  Output: $zshenv_output"
fi

# ----------------------------------------------------------
# * CORE FUNCTIONS (.zshenv)
# ----------------------------------------------------------

section "Core Functions (from .zshenv)"

core_functions=(
    "_log"
    "_has_cmd"
    "_safe_source"
    "_is_macos"
    "_is_linux"
)

for func in "${core_functions[@]}"; do
    result=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        source \$ZDOTDIR/.zshenv 2>/dev/null
        if (( \$+functions[$func] )); then
            echo 'DEFINED'
        else
            echo 'MISSING'
        fi
    " 2>&1)

    if [[ "$result" == "DEFINED" ]]; then
        pass "$func defined"
    else
        fail "$func missing"
    fi
done

# ----------------------------------------------------------
# * ZSHRC LOADING (NON-INTERACTIVE)
# ----------------------------------------------------------

section "Loading .zshrc (non-interactive)"

# Test .zshrc loads - capture errors, don't swallow them
zshrc_output=$(zsh -c "
    export ZDOTDIR='$ZDOTDIR'
    export ZSH_LOG_LEVEL=ERROR
    source \$ZDOTDIR/.zshenv
    source \$ZDOTDIR/.zshrc 2>&1
    echo 'ZSHRC_OK'
" 2>&1)

if [[ "$zshrc_output" == *"ZSHRC_OK"* ]]; then
    pass ".zshrc loads without fatal errors"
    # Check for warnings in output
    if [[ "$zshrc_output" == *"error"* ]] || [[ "$zshrc_output" == *"Error"* ]]; then
        warn ".zshrc had non-fatal errors (check logs)"
        $VERBOSE && echo "  Output: $zshrc_output"
    fi
else
    fail ".zshrc failed to load"
    echo "  Output: $zshrc_output"
fi

# ----------------------------------------------------------
# * INTERACTIVE SHELL TEST
# ----------------------------------------------------------

section "Interactive Shell"

# Use gtimeout on macOS, timeout on Linux
if command -v gtimeout &>/dev/null; then
    TIMEOUT_CMD="gtimeout"
elif command -v timeout &>/dev/null; then
    TIMEOUT_CMD="timeout"
else
    TIMEOUT_CMD=""
fi

# Test that zsh -i can start
if [[ -n "$TIMEOUT_CMD" ]]; then
    interactive_result=$($TIMEOUT_CMD 5 zsh -i -c "echo 'INTERACTIVE_OK'; exit 0" 2>&1 || echo "TIMEOUT_OR_ERROR")
else
    interactive_result=$(zsh -i -c "echo 'INTERACTIVE_OK'; exit 0" 2>&1 || echo "ERROR")
fi

if [[ "$interactive_result" == *"INTERACTIVE_OK"* ]]; then
    pass "Interactive shell starts"
else
    # Interactive may fail in CI without tty - warn instead of fail
    warn "Interactive shell test inconclusive (may need tty)"
    info "Output: $interactive_result"
fi

# ----------------------------------------------------------
# * LOGIN SHELL TEST
# ----------------------------------------------------------

section "Login Shell"

# Test that zsh -l can start
if [[ -n "$TIMEOUT_CMD" ]]; then
    login_result=$($TIMEOUT_CMD 5 zsh -l -c "echo 'LOGIN_OK'; exit 0" 2>&1 || echo "TIMEOUT_OR_ERROR")
else
    login_result=$(zsh -l -c "echo 'LOGIN_OK'; exit 0" 2>&1 || echo "ERROR")
fi

if [[ "$login_result" == *"LOGIN_OK"* ]]; then
    pass "Login shell starts"
else
    warn "Login shell test inconclusive"
    info "Output: $login_result"
fi

# ----------------------------------------------------------
# * USER FUNCTIONS (.zshrc)
# ----------------------------------------------------------

section "User Functions (from .zshrc)"

user_functions=(
    "zsh_version"
    "zsh_lazy_status"
    "path_show"
)

for func in "${user_functions[@]}"; do
    result=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        export ZSH_LOG_LEVEL=ERROR
        source \$ZDOTDIR/.zshenv
        source \$ZDOTDIR/.zshrc 2>/dev/null
        if (( \$+functions[$func] )); then
            echo 'DEFINED'
        else
            echo 'MISSING'
        fi
    " 2>&1)

    if [[ "$result" == "DEFINED" ]]; then
        pass "$func defined"
    else
        fail "$func not loaded (.zshrc modules failed)"
    fi
done

# ----------------------------------------------------------
# * MODULE LOADING
# ----------------------------------------------------------

section "Module Loading"

# Check that HISTFILE is set (required)
histfile_result=$(zsh -c "
    export ZDOTDIR='$ZDOTDIR'
    export ZSH_LOG_LEVEL=ERROR
    source \$ZDOTDIR/.zshenv
    source \$ZDOTDIR/.zshrc 2>/dev/null
    [[ -n \"\$HISTFILE\" ]] && echo 'SET' || echo 'UNSET'
" 2>&1)

if [[ "$histfile_result" == "SET" ]]; then
    pass "History configured (HISTFILE set)"
else
    fail "History not configured (HISTFILE not set)"
fi

# Check EDITOR (optional - depends on what's installed)
editor_result=$(zsh -c "
    export ZDOTDIR='$ZDOTDIR'
    export ZSH_LOG_LEVEL=ERROR
    source \$ZDOTDIR/.zshenv
    source \$ZDOTDIR/.zshrc 2>/dev/null
    [[ -n \"\$EDITOR\" ]] && echo 'SET' || echo 'UNSET'
" 2>&1)

if [[ "$editor_result" == "SET" ]]; then
    pass "Editor detection ran (EDITOR set)"
else
    warn "Editor not detected (no editor installed)"
fi

# ----------------------------------------------------------
# * ALIAS AVAILABILITY
# ----------------------------------------------------------

section "Aliases"

# Test a few core aliases exist
test_aliases=(
    "ll"
    "la"
    ".."
)

for alias_name in "${test_aliases[@]}"; do
    result=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        export ZSH_LOG_LEVEL=ERROR
        source \$ZDOTDIR/.zshenv
        source \$ZDOTDIR/.zshrc 2>/dev/null
        if alias $alias_name >/dev/null 2>&1; then
            echo 'EXISTS'
        else
            echo 'MISSING'
        fi
    " 2>&1)

    if [[ "$result" == "EXISTS" ]]; then
        pass "alias '$alias_name' defined"
    else
        fail "alias '$alias_name' not defined"
    fi
done

# ----------------------------------------------------------
# * SUMMARY
# ----------------------------------------------------------

section "Summary"

echo ""
echo "  ${GREEN}Passed:${NC}   $PASSED"
echo "  ${RED}Failed:${NC}   $FAILED"
echo "  ${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

if [[ $FAILED -gt 0 ]]; then
    echo "${RED}SMOKE TEST FAILED${NC}"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo "${YELLOW}SMOKE TEST PASSED WITH WARNINGS${NC}"
    exit 0
else
    echo "${GREEN}SMOKE TEST PASSED${NC}"
    exit 0
fi
