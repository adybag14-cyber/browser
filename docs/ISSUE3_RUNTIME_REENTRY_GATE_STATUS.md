# Issue #3 Runtime Re-entry Gate Status Helper

Use `scripts/check_issue3_runtime_reentry_gate_status.py` when the next run
needs a compact yes-or-no answer to the two hard gates from
`docs/ISSUE3_RUNTIME_REENTRY_GATES.md` before reopening the direct runtime patch
in:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

## Goal

Keep the re-entry decision short and repeatable.

Instead of manually re-checking the same preconditions across notes and helper
scripts, this helper reports:

- whether the current checkout looks publishable for
  `fork/headed-mode-foundation`
- whether the target runtime files are present and writable
- whether the branch-local helper surface still exists
- whether the sibling dependency layout is staged
- whether the current `zig` on `PATH` matches the branch's expected
  `0.15.2` line from `build.zig.zon`

## Usage

From the browser repo root:

```bash
python scripts/check_issue3_runtime_reentry_gate_status.py
python scripts/check_issue3_runtime_reentry_gate_status.py --json
python scripts/check_issue3_runtime_reentry_gate_status.py --self-test
```

Use `--repo-root` when the browser checkout lives somewhere other than the
current directory.

## How To Read The Output

The helper reports two gate states:

1. `Publication gate`
2. `Toolchain gate`

Treat the direct issue `#3` runtime patch as still blocked unless both gates
report `GREEN`.

When the publication gate is closed, reopen the runtime patch only from a real
writable checkout of `fork/headed-mode-foundation` with the target files
present.

When the toolchain gate is closed, stay on the Linux or WSL build-readiness
route until the sibling dependencies and a branch-compatible Zig line are
staged.

## Working Rule

Use this helper before reopening the direct runtime lane when the branch may
have moved, when the run is starting from a restored checkout, or when the last
failed attempt was caused by environment drift rather than source-level proof.
