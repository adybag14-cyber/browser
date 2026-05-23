# Issue #3 Runtime Gate Checker

Use this note when the next run needs a quick answer to one question:

Can the direct issue `#3` runtime patch be reopened honestly, or is the
environment still the blocker?

This helper keeps the answer on one small branch-local command:

- `scripts/check_issue3_runtime_reentry_gates.py`

## What It Checks

The helper condenses the two hard gates from
`docs/ISSUE3_RUNTIME_REENTRY_GATES.md`.

### Publication gate

This gate checks whether the current checkout looks usable for a direct edit to:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

It expects:

- a local `.git` directory
- `build.zig.zon`
- both direct runtime target files
- writable target files

### Toolchain gate

This gate checks whether the Linux or WSL validation surface is still blocked by
environment setup instead of source behavior.

It checks:

- the saved Memory input preflight through
  `scripts/check_issue3_saved_memory_inputs.py`
- the branch minimum Zig line from `build.zig.zon`
- the configured `zig` executable
- staged Zig candidates under `../toolchains`
- sibling path dependencies from `build.zig.zon`

## Basic Use

From the browser repo root:

```bash
python scripts/check_issue3_runtime_reentry_gates.py --repo-root .
```

Use `--json` when another helper or scheduled run wants structured output.

Use `--toolchains-root` when the staged Zig candidates live somewhere other than
the default `../toolchains` location beside the repo root.

Use `--memory-checker` when the saved-Memory preflight helper should be resolved
from an explicit path instead of the branch-local default.

## Exit Behavior

- exit `0`: both gates are open and the direct issue `#3` runtime patch can be
  retried from this checkout
- exit `1`: at least one gate is still blocked

## Self-Test

Run the focused helper tests with:

```bash
python scripts/check_issue3_runtime_reentry_gates.py --self-test
```

## Working Rule

Use this helper before reopening the direct `Page.zig` plus `win32_backend.zig`
patch from a restored checkout or a Linux or WSL validation lane.

If this helper still reports the toolchain gate as blocked, keep working in
build-readiness, offline-input staging, or toolchain recovery instead of
treating untouched-source Zig failures as issue `#3` patch evidence.