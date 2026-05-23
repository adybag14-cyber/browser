# Issue #3 Restored Helper Surface Drift Check

Use this helper when a saved browser snapshot has already been restored, but the
next Linux or WSL follow-up step is about to switch from the live helper root
into the restored checkout itself.

The saved archive can lag the current branch-local issue `#3` helper surface.
This check compares the restored checkout against the live helper root so a run
can decide whether it is safe to trust the restored helper scripts directly, or
whether it should keep using the live helper root until the restore is repeated
with helper sync enabled.

## Command

From the live browser helper root:

```bash
python ./scripts/check_issue3_restored_helper_surface_drift.py \
  --helper-root . \
  --restored-root ../browser-memory-snapshot
```

Use `--json` when another helper or wrapper needs structured output.

## Expected Result

- `PASS` means the restored helper surface matches the live helper root for the
  tracked issue `#3` route notes and scripts.
- `WARN` means at least one tracked helper file is missing from the restored
  checkout or differs from the live helper root.
- `FAIL` means the helper root is incomplete or the restored checkout itself is
  not ready to act as a follow-up root.

## Working Rule

- If the drift check passes, it is reasonable to switch follow-up helper
  commands into the restored checkout.
- If it warns, keep the follow-up helpers anchored to the live helper root or
  rerun the restore with `--sync-helper-surface`.
