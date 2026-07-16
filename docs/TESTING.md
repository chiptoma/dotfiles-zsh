# Testing

All testing runs through the [Justfile](../Justfile) — the single entry point for every dev, test, and maintenance task. Run `just` with no arguments to list the recipes.

## Test Layers

| Layer | What it covers | Recipe | Safe locally? |
|-------|----------------|--------|---------------|
| **L0** | Lint & static checks: `bash -n` / `zsh -n` on every shell file, shellcheck (severity: error), `tests/structure-test.sh`, `tests/help-sync-test.zsh` | `just lint` | Yes |
| **L1** | Unit test suite (~30 suites) | `just test-unit` | Yes |
| **L2** | Smoke tests (structure + shell boots) | `just test-smoke` | Yes |
| **L3** | Installer integration (`tests/installer-integration.sh`) — **mutates `$HOME`** | `just test-install` | Container only (see guard below) |
| **L4** | Local docker distro matrix: install + unit + smoke inside each distro image | `just test-docker <distro>` / `just test-docker-all` | Yes (needs Docker) |
| **L5** | CI: quality workflow runs `just lint` / `just test-unit` / `just test-smoke`; platform and installer matrices run on GitHub runners | automatic on push/PR | — |

## Everyday Commands

```bash
just test          # L0 + L1 + L2 — the default local gate, safe on any machine
just lint          # L0 only
just test-unit     # L1 only
just test-smoke    # L2 only
just test-all      # Everything runnable locally: L0-L4 (needs Docker)
```

Supporting recipes:

```bash
just install-dry     # Show what the installer would do (install.sh --dry-run --yes)
just bench           # Benchmark interactive startup (hyperfine, 10 runs)
just docs-commands   # Regenerate docs/COMMANDS.md from the help registry
```

## Docker Distro Matrix (L4)

Each run builds a distro image from `tests/docker/Dockerfile`, then executes the installer integration suite plus unit and smoke tests inside the container (the repo is mounted read-only and copied in):

```bash
just test-docker            # Defaults to ubuntu
just test-docker fedora     # One distro: ubuntu | debian | fedora | rocky | arch | alpine
just test-docker-all        # Full matrix with a summary table
```

Notes:

- `arch` runs emulated (`linux/amd64`) on Apple Silicon and is slower.
- In `test-docker-all`, `arch` and `alpine` failures are downgraded to warnings (known-flaky tier: emulation/musl); the other four distros are required.

## The L3 Guard (FORCE=1)

`just test-install` runs `tests/installer-integration.sh`, which **modifies the current `$HOME`** (installs, repairs, uninstalls). It therefore refuses to run unless it detects a container (`/.dockerenv`) or CI (`CI=true`):

```
FAIL: refusing to run outside a container.
      Use 'just test-docker <distro>' for isolation, or FORCE=1 to override.
```

Prefer `just test-docker <distro>` for isolation. If you really want to run it on a throwaway machine:

```bash
FORCE=1 just test-install
```

Never run this on a machine whose shell setup you care about.

## macOS Caveat

The docker matrix exercises Linux only — there is no macOS container. macOS coverage comes from:

- Running `just test` (L0–L2) natively on your Mac.
- CI's `macos-latest` runners in the platform workflow (L5).

## Writing Tests

Add unit tests to `tests/unit-test.zsh` using the existing framework:

```bash
test_my_feature() {
    # Setup
    local input="test"

    # Execute
    local result=$(my_function "$input")

    # Assert
    assert_eq "$result" "expected" "my_function handles input"
}
```

Structural invariants (file layout, naming conventions) belong in `tests/structure-test.sh`; help-registry sync is enforced by `tests/help-sync-test.zsh` — both run as part of `just lint`.
