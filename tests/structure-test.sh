#!/usr/bin/env bash
# ==============================================================================
# REPO STRUCTURE TEST
# Mechanically verifies that every repo-relative path referenced by the
# installer, workflows, and tests actually exists in the tree.
# ------------------------------------------------------------------------------
# Context: guards against path drift after file renames (e.g. module
#   renumbering) breaking install.sh, CI workflows, or test scripts.
# Scope: L0 lint layer; run via `just lint` and CI. Read-only, bash-3.2-safe.
# ==============================================================================

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
CHECKS=0

pass() { printf 'ok: %s\n' "$1"; CHECKS=$((CHECKS + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); CHECKS=$((CHECKS + 1)); }

# ----------------------------------------------------------
# 1. ESSENTIAL_FILES ENTRIES EXIST
# ----------------------------------------------------------
essential_count=0
while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    essential_count=$((essential_count + 1))
    if [ -f "$REPO_ROOT/$entry" ]; then
        pass "essential file exists: $entry"
    else
        fail "essential file missing: $entry (referenced in install.sh ESSENTIAL_FILES)"
    fi
done < <(awk '/^ESSENTIAL_FILES=\(/,/^\)/' "$REPO_ROOT/install.sh" \
    | sed -n 's/^[[:space:]]*"\([^"]*\)".*/\1/p')

if [ "$essential_count" -lt 5 ]; then
    fail "ESSENTIAL_FILES extraction found only $essential_count entries — awk block parse broke?"
else
    pass "ESSENTIAL_FILES extraction yielded $essential_count entries"
fi

# ----------------------------------------------------------
# 2. PATH LITERALS IN INSTALLER / WORKFLOWS / TESTS EXIST
# Extracts literal modules/*.zsh and lib/**.zsh tokens; skips
# globs, variables, and paths constructed at runtime.
# ----------------------------------------------------------
# --exclude: this script's own catalog-candidate strings are not references.
referenced_paths="$(
    grep -rhoE --exclude='structure-test.sh' '(modules|lib)/[A-Za-z0-9_/.-]+\.(zsh|dat)' \
        "$REPO_ROOT/install.sh" \
        "$REPO_ROOT/.github/workflows/" \
        "$REPO_ROOT/tests/" 2>/dev/null \
    | grep -v '[*$]' | sort -u
)"

while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    if [ -e "$REPO_ROOT/$ref" ]; then
        pass "referenced path exists: $ref"
    else
        fail "referenced path missing: $ref (grep it in install.sh/.github/tests to locate the stale reference)"
    fi
done <<< "$referenced_paths"

# ----------------------------------------------------------
# 3. TOOL CATALOG FORMAT
# Every non-comment line: 7 colon-delimited fields, unique names.
# ----------------------------------------------------------
catalog=""
for candidate in "$REPO_ROOT/lib/registry/tools.dat" "$REPO_ROOT/lib/registry/_install.dat"; do
    [ -f "$candidate" ] && catalog="$candidate" && break
done

if [ -z "$catalog" ]; then
    fail "tool catalog not found (lib/registry/tools.dat or _install.dat)"
else
    bad_lines="$(grep -vE '^[[:space:]]*(#|$)' "$catalog" | awk -F: 'NF != 7 {print NR": "$0}')"
    if [ -n "$bad_lines" ]; then
        fail "catalog lines without exactly 7 colon-fields in ${catalog##*/}:"
        printf '%s\n' "$bad_lines" | head -5
    else
        pass "catalog format valid: every entry in ${catalog##*/} has 7 fields"
    fi

    dupes="$(grep -vE '^[[:space:]]*(#|$)' "$catalog" | cut -d: -f1 | sort | uniq -d)"
    if [ -n "$dupes" ]; then
        fail "duplicate catalog names: $(printf '%s ' $dupes)"
    else
        pass "catalog names unique"
    fi
fi

# ----------------------------------------------------------
# SUMMARY
# ----------------------------------------------------------
echo "---"
if [ "$FAILURES" -gt 0 ]; then
    printf 'FAIL: structure test — %d of %d checks failed\n' "$FAILURES" "$CHECKS"
    exit 1
fi
printf 'ok: structure test — all %d checks passed\n' "$CHECKS"
