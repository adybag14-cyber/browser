# Issue #11 Linux/WSL Re-entry Preflight

Use `scripts/check_issue3_linux_reentry_preflight.py` when the headed-mode run
is working in issue `#11` and needs one compact command that checks the saved
Memory inputs, saved archive integrity, saved Rust archive choices, staged Rust
toolchain reuse, saved Zig archive choices, and the broader Linux build-
readiness helper in one pass.

## Run It

From the browser repo root:

```bash
python scripts/check_issue3_linux_reentry_preflight.py --repo-root . --json
```

Add the wider offline dependency gate when the next rerun expects
`../offline-deps` and a prebuilt V8 archive to be staged already:

```bash
python scripts/check_issue3_linux_reentry_preflight.py \
  --repo-root . \
  --expect-offline-deps \
  --require-prebuilt-v8
```

## What It Runs

The helper runs these existing branch-local surfaces in order:

1. `scripts/check_issue3_saved_memory_inputs.py`
2. `scripts/check_issue3_saved_archive_integrity.py`
3. `scripts/check_issue3_saved_rust_archive_candidates.py`
4. `scripts/check_issue3_staged_rust_toolchain_candidates.py`
5. `scripts/check_issue3_saved_zig_archive_candidates.py`
6. `scripts/check_linux_build_readiness.py`

## Why This Exists

Issue `#11` is the lower-volume progress lane for Linux or WSL re-entry work.
The branch already had the underlying helpers, but scheduled runs still had to
hop across several commands to learn whether the next blocker was saved inputs,
Rust reuse, Zig-line recovery, or the broader build-readiness gate. This helper
turns that into one quick preflight and preserves each nested helper's
structured next-step output.
