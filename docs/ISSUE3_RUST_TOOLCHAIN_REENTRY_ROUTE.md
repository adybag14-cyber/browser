# Issue #11 Rust Toolchain Re-entry Bridge

Use this note when the Linux or WSL headed-mode re-entry lane needs one quick
answer before broader build-readiness work:

- can the run reuse a staged Rust `1.79.0` toolchain under `../toolchains`
- or should it restore the saved Rust archive from Memory first

This bridge sits between the existing saved-archive helper and the staged
toolchain helper so future reruns do not need to compare both outputs by hand.

Companion helpers:

- `scripts/check_issue3_rust_toolchain_reentry.py`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/check_issue3_staged_build_toolchain_pair.py`
- `scripts/linux/restore_saved_rust_toolchain.sh`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`

## Run It

From the browser repo root:

```bash
python3 ./scripts/check_issue3_rust_toolchain_reentry.py --repo-root .
```

When the run wants one quick answer before the broader Linux build-readiness
route, surface the staged-pair helper directly:

```bash
python3 ./scripts/check_issue3_staged_build_toolchain_pair.py --repo-root .
```

Use `--json` when another helper wants structured output.

## What It Prints

The helper reports:

1. the saved archive search roots it can see for `repo_archives/browser`
2. the staged Rust toolchains and the staged Rust plus Zig toolchain pairs it can probe under `../toolchains`
3. the preferred next action:
   `reuse-staged-toolchain`, `restore-from-saved-archive`, `review-staged-mismatch`, or `blocked`
4. the exact saved-archive, staged-toolchain, and staged-pair helper commands
5. the saved Rust restore check and restore commands when a matching archive is available
6. the exact `check_linux_build_readiness.py` rerun command to use after the Rust decision is made
7. the exact `check_linux_build_readiness.py` rerun command when both the Rust and Zig sides are already reusable

## Working Rule

Run this bridge before reopening the broader Linux build-readiness route when
the next rerun is still deciding whether Rust is already ready enough to reuse.

Prefer the staged-pair helper when the run already has candidate Rust and Zig
toolchains under `../toolchains` and needs the fastest honest answer about
whether a full saved-archive restore can be skipped.