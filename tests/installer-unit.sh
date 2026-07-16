#!/usr/bin/env bash
# ==============================================================================
# INSTALLER UNIT TESTS
# Behavioral tests for install.sh pure functions, via its source-guard.
# ------------------------------------------------------------------------------
# Context: sources install.sh (main() is skipped when sourced) and exercises
#   apply_profile_preset, resolve_package, find_catalog_index, and
#   should_install_tool against in-memory fixtures.
# Scope: mutates nothing — safe on any machine, no container guard needed.
# NOTE: bash-3.2-safe (no assoc arrays, no mapfile).
# ==============================================================================

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"

# Source install.sh FIRST: it defines its own print_summary (the install
# completion screen), which the harness's print_summary must shadow. It also
# enables -euo pipefail and an ERR trap at its top level while being sourced;
# relax both so recorded assertion failures don't abort the suite.
# shellcheck source=install.sh
. "$REPO_ROOT/install.sh"
set +e +u
set +o pipefail
trap - ERR

# shellcheck source=tests/harness.sh
. "$TESTS_DIR/harness.sh"

# ----------------------------------------------------------
# FIXTURES
# ----------------------------------------------------------

# MENU_* parallel arrays as build_tool_menu would fill them
setup_menu_fixture() {
    MENU_NAMES=(starship atuin eza lazygit)
    MENU_DESCS=("prompt" "history" "ls replacement" "git tui")
    MENU_CATS=(essential essential recommended extra)
    MENU_REPLACES=("" "" "ls" "")
    MENU_SEL=(0 0 0 0)
}

# CAT_* parallel arrays as load_tool_catalog would fill them
setup_catalog_fixture() {
    CAT_NAMES=(starship atuin mas ripgrep)
    CAT_BINS=(starship atuin mas rg)
    CAT_DESCS=("prompt" "history" "app store" "grep replacement")
    CAT_CATEGORIES=(essential essential extra essential)
    CAT_REPLACES_LIST=("" "" "" "grep")
    CAT_BREWS=(starship atuin mas ripgrep)
    CAT_APTS=(SCRIPT atuin "" ripgrep)
}

# ----------------------------------------------------------
# apply_profile_preset
# ----------------------------------------------------------

test_apply_profile_preset() {
    section "install.sh (apply_profile_preset)"

    INSTALL_PROFILE=minimal
    setup_menu_fixture
    apply_profile_preset
    assert_eq "${MENU_SEL[*]}" "1 1 0 0" \
        "minimal preset selects only essential tools"

    INSTALL_PROFILE=recommended
    setup_menu_fixture
    apply_profile_preset
    assert_eq "${MENU_SEL[*]}" "1 1 1 0" \
        "recommended preset selects essential+recommended, excludes extra"

    INSTALL_PROFILE=full
    setup_menu_fixture
    apply_profile_preset
    assert_eq "${MENU_SEL[*]}" "1 1 1 1" \
        "full preset selects every tool"

    # Preset re-application overwrites a prior manual selection
    INSTALL_PROFILE=full
    setup_menu_fixture
    apply_profile_preset
    INSTALL_PROFILE=minimal
    apply_profile_preset
    assert_eq "${MENU_SEL[*]}" "1 1 0 0" \
        "switching preset full->minimal deselects non-essential tools"
}

# ----------------------------------------------------------
# find_catalog_index
# ----------------------------------------------------------

test_find_catalog_index() {
    section "install.sh (find_catalog_index)"

    setup_catalog_fixture

    assert_eq "$(find_catalog_index starship)" "0" \
        "find_catalog_index resolves first catalog entry to index 0"
    assert_eq "$(find_catalog_index atuin)" "1" \
        "find_catalog_index resolves mid-catalog entry to its index"
    assert_eq "$(find_catalog_index ripgrep)" "3" \
        "find_catalog_index resolves last catalog entry to its index"
    assert_eq "$(find_catalog_index no-such-tool)" "-1" \
        "find_catalog_index echoes -1 for an unknown tool"
    assert_eq "$(find_catalog_index '')" "-1" \
        "find_catalog_index echoes -1 for an empty name"
}

# ----------------------------------------------------------
# resolve_package
# ----------------------------------------------------------

test_resolve_package() {
    section "install.sh (resolve_package)"

    setup_catalog_fixture

    assert_eq "$(resolve_package 0 brew)" "starship" \
        "resolve_package picks the brew column for brew"
    assert_eq "$(resolve_package 3 apt)" "ripgrep" \
        "resolve_package picks the apt column for apt"
    assert_eq "$(resolve_package 0 apt)" "SCRIPT:starship" \
        "resolve_package promotes SCRIPT to SCRIPT:<tool>"
    assert_eq "$(resolve_package 2 apt)" "" \
        "resolve_package echoes empty for macOS-only tool (empty apt column)"
    assert_eq "$(resolve_package 2 brew)" "mas" \
        "resolve_package still resolves macOS-only tool via brew"
}

# ----------------------------------------------------------
# should_install_tool
# ----------------------------------------------------------

test_should_install_tool() {
    section "install.sh (should_install_tool)"

    # --tools override beats any profile
    SELECTED_TOOLS="eza,jq"
    INSTALL_PROFILE=full
    assert_true "listed tool is installed when --tools is set" \
        should_install_tool eza extra
    assert_false "unlisted essential tool is skipped when --tools is set" \
        should_install_tool starship essential
    assert_false "partial name match does not count as listed" \
        should_install_tool ez extra

    # Profile-based selection when no explicit tool list
    SELECTED_TOOLS=""
    INSTALL_PROFILE=minimal
    assert_true "minimal profile installs essential tools" \
        should_install_tool starship essential
    assert_false "minimal profile skips recommended tools" \
        should_install_tool eza recommended
    assert_false "minimal profile skips extra tools" \
        should_install_tool mas extra

    INSTALL_PROFILE=recommended
    assert_true "recommended profile installs essential tools" \
        should_install_tool starship essential
    assert_true "recommended profile installs recommended tools" \
        should_install_tool eza recommended
    assert_false "recommended profile skips extra tools" \
        should_install_tool mas extra

    INSTALL_PROFILE=full
    assert_true "full profile installs extra tools" \
        should_install_tool mas extra
}

# ----------------------------------------------------------
# persist_replacements
# ----------------------------------------------------------

test_persist_replacements() {
    section "install.sh (persist_replacements)"

    local tmp_home
    tmp_home=$(mktemp -d)
    INSTALL_DIR="$tmp_home"

    # Seed a .zshlocal with user content AND a stale managed block
    cat > "$tmp_home/.zshlocal" << 'FIXTURE'
# my precious user line
alias keepme='echo kept'
# >>> zsh-dotfiles replacements (managed by install.sh) >>>
export Z_REPLACE_OLDTOOL=true
# <<< zsh-dotfiles replacements <<<
# trailing user line
FIXTURE

    REPL_NAMES=(eza gping)
    REPL_TARGETS=(ls ping)
    REPL_SEL=(1 0)
    persist_replacements

    assert_file_contains "$tmp_home/.zshlocal" "alias keepme='echo kept'" \
        "user content before the managed block survives rewrite"
    assert_file_contains "$tmp_home/.zshlocal" "# trailing user line" \
        "user content after the managed block survives rewrite"
    assert_file_contains "$tmp_home/.zshlocal" "export Z_REPLACE_EZA=true" \
        "selected replacement persists as true"
    assert_file_contains "$tmp_home/.zshlocal" "export Z_REPLACE_GPING=false" \
        "unselected replacement persists as false"
    if grep -q "Z_REPLACE_OLDTOOL" "$tmp_home/.zshlocal"; then
        fail "stale managed block is replaced, not accumulated"
    else
        pass "stale managed block is replaced, not accumulated"
    fi
    assert_eq "$(grep -c '>>> zsh-dotfiles replacements' "$tmp_home/.zshlocal")" "1" \
        "exactly one managed block after repeated persists"

    rm -rf "$tmp_home"
}

# ----------------------------------------------------------
# generate_completions
# ----------------------------------------------------------

test_generate_completions() {
    section "install.sh (generate_completions)"

    local tmp_home
    tmp_home=$(mktemp -d)
    INSTALL_DIR="$tmp_home"
    XDG_CACHE_HOME="$tmp_home/cache"
    DRY_RUN=false

    # Catalog fixture: one self-generating tool (present), one whose
    # generator fails, one without a generator
    CAT_NAMES=(faketool breaks plain)
    CAT_BINS=(echo false plainbin)
    CAT_DESCS=("emits completions" "generator fails" "no generator")
    CAT_CATEGORIES=(extra extra extra)
    CAT_REPLACES_LIST=("" "" "")
    CAT_BREWS=(faketool breaks plain)
    CAT_APTS=(faketool breaks plain)
    CAT_COMPLETIONS=("echo '#compdef faketool'" "false" "")

    generate_completions >/dev/null 2>&1

    assert_file_exists "$INSTALL_DIR/completions/_echo" \
        "self-generating tool gets a completion file named by binary"
    assert_file_contains "$INSTALL_DIR/completions/_echo" "#compdef faketool" \
        "generated completion file carries the generator output"
    if [ -e "$INSTALL_DIR/completions/_false" ]; then
        fail "failed generator leaves no completion file behind"
    else
        pass "failed generator leaves no completion file behind"
    fi
    if ls "$INSTALL_DIR/completions"/*.tmp >/dev/null 2>&1; then
        fail "no .tmp droppings remain after generation"
    else
        pass "no .tmp droppings remain after generation"
    fi

    rm -rf "$tmp_home"
}

# ----------------------------------------------------------
# TEST RUNNER
# ----------------------------------------------------------

run_tests() {
    echo "================================================"
    echo "  Installer Unit Tests (pure functions)"
    echo "================================================"

    test_apply_profile_preset
    test_find_catalog_index
    test_resolve_package
    test_should_install_tool
    test_persist_replacements
    test_generate_completions

    print_summary "installer unit"
}

run_tests
