# Issue #3 Re-entry Readiness Route

Use this route when `../browser-memory-snapshot` already exists and the next
question is no longer "how do I restore a checkout?" but "is the restored
checkout actually safe to reuse right now?"

This note adds one compact answer surface on top of the existing helpers:

- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_reentry_readiness.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when all of these are true:

- the saved browser snapshot has already been restored, or may already exist
- the next run wants to reuse that restored checkout instead of re-extracting it
- the run needs one yes-or-no preflight before moving into Linux build-readiness
  or direct runtime re-entry

## One-command Readiness Check

From the live helper checkout:

```bash
python ./scripts/check_issue3_reentry_readiness.py \
  --repo-root ../browser-memory-snapshot
```

That runs the restored-checkout readiness helper first, the saved-Memory
preflight second, and the saved-archive integrity helper third.

If the restored checkout was refreshed with `--sync-helper-surface` or
`--sync-only`, require the synced helper surface explicitly:

```bash
python ./scripts/check_issue3_reentry_readiness.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface
```

If the route only needs presence checks before a quick follow-up, skip the
archive-fingerprint pass:

```bash
python ./scripts/check_issue3_reentry_readiness.py \
  --repo-root ../browser-memory-snapshot \
  --skip-archive-integrity
```

Use `--json` when another helper or scheduled run needs the readiness result as
structured output.

## What It Decides

Treat the restored checkout as ready only when all three checks agree:

- the restored checkout still has the required repo files
- the saved Memory inputs and helper surface are present where the route expects
  them
- the saved repo and dependency archives still match the expected exact
  fingerprints, unless the route intentionally skipped that step

## What It Suggests Next

The readiness helper prints one of these follow-up directions:

- rerun `restore_saved_browser_snapshot.sh --sync-only` or a synced restore when
  helper-surface drift is the real blocker
- repair the saved Memory inputs before treating the restored checkout as a
  trustworthy follow-up root
- resolve archive drift before reopening Linux build-readiness or runtime
  re-entry
- continue directly into
  `scripts/linux/show_issue3_linux_build_readiness_route.sh` when the restored
  checkout and saved inputs are already green

## Working Rule

Prefer this route when the restore step is already done and the next run wants a
single reusable-checkout answer before widening back out to build-readiness or
runtime work.