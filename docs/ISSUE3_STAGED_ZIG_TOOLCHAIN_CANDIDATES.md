# Issue #3 Staged Zig Toolchain Candidates

Use this note when the Linux or WSL headed runtime re-entry lane needs a quick
answer about whether `../toolchains` already contains a branch-compatible Zig
`0.15.x` toolchain before another saved archive restore is attempted.

This helper is the staged-toolchain companion to
`scripts/check_issue3_saved_zig_archive_candidates.py`. Use it first when the
workspace may already have a reusable Zig toolchain, and fall back to the saved
archive route only when no matching staged candidate is ready.

## Helper

From the browser repo root:

```bash
python ./scripts/check_issue3_staged_zig_toolchain_candidates.py --repo-root .
```

Use `--json` when another helper wants the preferred staged candidate, the
matching-candidate list, or the surfaced export commands as structured output.

## What It Surfaces

The helper:

1. reads `.minimum_zig_version` from `build.zig.zon`
2. scans `../toolchains` for staged `zig` executables
3. classifies each candidate as:
   - `matches-expected-line`
   - `older-than-minimum`
   - `mismatched-line`
   - `unknown version`
4. prefers an exact `0.15.2` match when present
5. otherwise prefers the highest matching `0.15.x` patch
6. prints `PATH` and `ZIG` exports for the preferred staged candidate

## Working Rules

- Run this helper before `scripts/check_issue3_saved_zig_archive_candidates.py`
  when the current workspace might already have a reusable staged Zig toolchain.
- If this helper reports a preferred staged candidate, reuse that surfaced
  `PATH` and `ZIG` pair before unpacking another archive.
- If this helper fails, move to the saved-archive candidate route and then the
  archive-restore surface instead of guessing which Zig archive to stage next.
- Treat the attached Zig `0.17` archive as a surfaced stopgap only, not as
  honest validation evidence for the blocked issue `#3` runtime patch.