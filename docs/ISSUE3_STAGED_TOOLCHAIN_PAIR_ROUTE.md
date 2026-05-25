# Issue #11 Staged Toolchain Pair Check

Use this note when the Linux or WSL re-entry lane needs one quick answer before
rerunning the broader build-readiness helper:

- is a saved Rust `1.79.x` toolchain already staged under `../toolchains`?
- is a branch-compatible Zig `0.15.x` toolchain already staged there too?
- if both are present, which exports should the next readiness rerun reuse?

Companion helpers:

- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/check_issue3_staged_zig_toolchain_candidates.py`
- `scripts/check_issue3_staged_toolchain_pair.py`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`

## Run It

From the browser repo root:

```bash
python ./scripts/check_issue3_staged_toolchain_pair.py --repo-root .
```

Use `--json` when another helper wants the paired result as structured output.

## What It Does

The helper reuses the existing staged Rust and staged Zig candidate checkers
instead of re-deriving their discovery logic.

It reports:

1. whether both staged-toolchain gates are green at the same time
2. the embedded Rust helper result
3. the embedded Zig helper result
4. the combined shell exports to reuse when both candidates are ready
5. the next recovery step when one side is still missing

## Working Rule

Run this helper after the saved Rust and Zig recovery routes have surfaced their
candidate lists, and before treating `scripts/check_linux_build_readiness.py` as
the next honest Linux or WSL rerun.