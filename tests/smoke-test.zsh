#!/bin/zsh
# ==============================================================================
# ZSH CONFIGURATION SMOKE TEST
# Validates installation and shell functionality.
# Run: ./scripts/smoke-test.zsh [--verbose]
# ==============================================================================

set -e

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
WARNINGS=0

# ----------------------------------------------------------
# TEST HELPERS
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
# ENVIRONMENT SETUP
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
# FILE STRUCTURE
# ----------------------------------------------------------

section "File Structure"

required_files=(
    ".zshenv"
    ".zshrc"
    "lib/utils/logging.zsh"
    "lib/utils/core.zsh"
    "lib/utils/index.zsh"
    "lib/functions/index.zsh"
    "lib/functions/system.zsh"
    "modules/environment.zsh"
    "modules/path.zsh"
    "modules/lazy.zsh"
    "modules/history.zsh"
    "modules/aliases.zsh"
)

for file in "${required_files[@]}"; do
    if [[ -f "$ZDOTDIR/$file" ]]; then
        pass "$file exists"
    else
        fail "$file missing"
    fi
done

# ----------------------------------------------------------
# ZSHENV LOADING
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
# CORE FUNCTIONS (.zshenv)
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
# OH MY ZSH CHECK
# ----------------------------------------------------------

section "Oh My Zsh"

# Check if OMZ is installed where .zshrc expects it
omz_path=$(zsh -c "
    export ZDOTDIR='$ZDOTDIR'
    source \$ZDOTDIR/.zshenv 2>/dev/null
    echo \"\$XDG_DATA_HOME/oh-my-zsh\"
" 2>&1)

if [[ -d "$omz_path" ]]; then
    pass "Oh My Zsh found at $omz_path"
else
    warn "Oh My Zsh NOT found at $omz_path (shell will use fallback mode)"
fi

# Test graceful degradation without OMZ
section "OMZ Fallback"

omz_fallback_result=$(zsh -c "
    export ZDOTDIR='$ZDOTDIR'
    export ZSH='/tmp/nonexistent-omz-dir'
    export Z_LOG_LEVEL=NONE
    source \$ZDOTDIR/.zshenv 2>/dev/null
    source \$ZDOTDIR/.zshrc 2>/dev/null
    echo 'FALLBACK_OK'
" 2>&1)

if [[ "$omz_fallback_result" == *"FALLBACK_OK"* ]]; then
    pass "Shell starts without OMZ (graceful fallback)"
else
    fail "Shell fails without OMZ"
    info "Output: $omz_fallback_result"
fi

# ----------------------------------------------------------
# ZSHRC LOADING (NON-INTERACTIVE)
# ----------------------------------------------------------

section "Loading .zshrc (non-interactive)"

# Test .zshrc loads - capture errors, don't swallow them
zshrc_output=$(zsh -c "
    export ZDOTDIR='$ZDOTDIR'
    export Z_LOG_LEVEL=ERROR
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
# INTERACTIVE SHELL TEST
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
# LOGIN SHELL TEST
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
# USER FUNCTIONS (.zshrc)
# ----------------------------------------------------------

section "User Functions (from .zshrc)"

user_functions=(
    "z_version"
    "z_lazy_status"
    "path_show"
)

for func in "${user_functions[@]}"; do
    result=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        export Z_LOG_LEVEL=NONE
        source \$ZDOTDIR/.zshenv 2>/dev/null
        source \$ZDOTDIR/.zshrc 2>/dev/null
        if (( \$+functions[$func] )); then
            echo 'FUNC_DEFINED'
        else
            echo 'FUNC_MISSING'
        fi
    " 2>&1)

    # Use pattern matching to handle OMZ plugin warnings in output
    if [[ "$result" == *"FUNC_DEFINED"* ]]; then
        pass "$func defined"
    elif [[ "$result" == *"FUNC_MISSING"* ]]; then
        fail "$func not defined"
    else
        fail "$func check failed (unexpected output)"
        echo "  Output: $result" | head -5
    fi
done

# ----------------------------------------------------------
# MODULE LOADING
# ----------------------------------------------------------

section "Module Loading"

# Check that HISTFILE is set (required)
histfile_result=$(zsh -c "
    export ZDOTDIR='$ZDOTDIR'
    export Z_LOG_LEVEL=NONE
    source \$ZDOTDIR/.zshenv 2>/dev/null
    source \$ZDOTDIR/.zshrc 2>/dev/null
    [[ -n \"\$HISTFILE\" ]] && echo 'HIST_SET' || echo 'HIST_UNSET'
" 2>&1)

# Use pattern matching to handle OMZ plugin warnings
if [[ "$histfile_result" == *"HIST_SET"* ]]; then
    pass "History configured (HISTFILE set)"
else
    fail "History not configured (HISTFILE not set)"
fi

# Check EDITOR (optional - depends on what's installed)
editor_result=$(zsh -c "
    export ZDOTDIR='$ZDOTDIR'
    export Z_LOG_LEVEL=NONE
    source \$ZDOTDIR/.zshenv 2>/dev/null
    source \$ZDOTDIR/.zshrc 2>/dev/null
    [[ -n \"\$EDITOR\" ]] && echo 'EDITOR_SET' || echo 'EDITOR_UNSET'
" 2>&1)

# Use pattern matching to handle OMZ plugin warnings
if [[ "$editor_result" == *"EDITOR_SET"* ]]; then
    pass "Editor detection ran (EDITOR set)"
else
    warn "Editor not detected (no editor installed)"
fi

# ----------------------------------------------------------
# ALIAS AVAILABILITY
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
        export Z_LOG_LEVEL=NONE
        source \$ZDOTDIR/.zshenv 2>/dev/null
        source \$ZDOTDIR/.zshrc 2>/dev/null
        if alias $alias_name >/dev/null 2>&1; then
            echo 'ALIAS_EXISTS'
        else
            echo 'ALIAS_MISSING'
        fi
    " 2>&1)

    # Use pattern matching to handle OMZ plugin warnings
    if [[ "$result" == *"ALIAS_EXISTS"* ]]; then
        pass "alias '$alias_name' defined"
    else
        fail "alias '$alias_name' not defined"
    fi
done

# ----------------------------------------------------------
# PATH INTEGRATION
# ----------------------------------------------------------

section "PATH Integration"

# PATH should contain /usr/bin after full shell init
path_result=$(zsh -c "
    export ZDOTDIR='$ZDOTDIR'
    export Z_LOG_LEVEL=NONE
    source \$ZDOTDIR/.zshenv 2>/dev/null
    source \$ZDOTDIR/.zshrc 2>/dev/null
    [[ \":\$PATH:\" == *\":/usr/bin:\"* ]] && echo 'USR_BIN_OK' || echo 'USR_BIN_MISSING'
" 2>&1)

if [[ "$path_result" == *"USR_BIN_OK"* ]]; then
    pass "PATH contains /usr/bin after init"
else
    fail "PATH missing /usr/bin after init"
fi

# On macOS, /opt/homebrew/bin should be in PATH if Homebrew installed
if [[ -d /opt/homebrew ]]; then
    brew_path_result=$(zsh -c "
        export ZDOTDIR='$ZDOTDIR'
        export Z_LOG_LEVEL=NONE
        source \$ZDOTDIR/.zshenv 2>/dev/null
        source \$ZDOTDIR/.zshrc 2>/dev/null
        [[ \":\$PATH:\" == *\":/opt/homebrew/bin:\"* ]] && echo 'BREW_OK' || echo 'BREW_MISSING'
    " 2>&1)

    if [[ "$brew_path_result" == *"BREW_OK"* ]]; then
        pass "PATH contains /opt/homebrew/bin (Homebrew)"
    else
        warn "PATH missing /opt/homebrew/bin (Homebrew detected but not in PATH)"
    fi
fi

# Lazy-loaded wrappers should exist as functions after init
lazy_result=$(zsh -c "
    export ZDOTDIR='$ZDOTDIR'
    export Z_LOG_LEVEL=NONE
    source \$ZDOTDIR/.zshenv 2>/dev/null
    source \$ZDOTDIR/.zshrc 2>/dev/null
    local -i count=0
    for fn in z nvm pyenv rbenv; do
        (( \$+functions[\$fn] )) && ((count++))
    done
    echo \"LAZY_WRAPPERS=\$count\"
" 2>&1)

if [[ "$lazy_result" == *"LAZY_WRAPPERS="* ]]; then
    local wrapper_count="${lazy_result##*LAZY_WRAPPERS=}"
    wrapper_count="${wrapper_count%%$'\n'*}"
    if [[ "$wrapper_count" -gt 0 ]]; then
        pass "Lazy wrappers installed ($wrapper_count found)"
    else
        warn "No lazy wrappers found (tools may not be installed)"
    fi
else
    warn "Could not check lazy wrappers"
fi

# ----------------------------------------------------------
# SUMMARY
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
