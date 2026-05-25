# Issue #3 Saved-Memory Helper-Surface Alignment

Use this note when the Linux or WSL issue `#3` re-entry lane needs to prove that
the saved-memory preflight is checking the same helper surface that the
restored-checkout route expects.

## Why This Exists

The re-entry lane has two different checkpoints that can talk about the helper
surface:

- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_helper_surface_alignment.py`

If the saved-memory and restored-checkout helpers drift apart, a run can get a
false "ready" signal from the saved-memory preflight and only discover the
mismatch later when the restored-checkout route or a broader build-readiness
route fails.

## What To Run

From the browser repo root:

```bash
python scripts/check_issue3_saved_memory_helper_surface_alignment.py
```

Use `--json` when another helper or a future automation step needs the path diff
as structured output.

## Working Rule

When this helper reports paths that only exist in the restored-checkout
contract, update the saved-memory preflight before trusting it as the narrower
gate for Linux or WSL re-entry.

Treat label mismatches the same way: they do not block file presence by
themselves, but they are still a sign that the two route surfaces are drifting
apart and should be brought back into sync before a later run relies on them as
parallel documentation of the same gate.