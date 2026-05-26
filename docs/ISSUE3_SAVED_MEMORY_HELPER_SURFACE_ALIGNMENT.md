# Issue #3 Saved-Memory Helper-Surface Alignment

Use this note when the Linux or WSL issue `#3` re-entry lane needs to prove that
the saved-memory preflight, restored-checkout helper, and saved-memory route
surface are still describing the same issue `#11` helper contract.

## Why This Exists

The re-entry lane has a few different surfaces that can drift apart:

- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/check_issue11_saved_memory_helper_contract.py`
- `scripts/check_issue11_reentry_inventory_consistency.py`

If these helpers stop agreeing, a run can get a false "ready" signal from the
saved-memory preflight and only discover the mismatch later when the
restored-checkout route or a broader build-readiness rerun fails.

## What To Run

From the browser repo root:

```bash
python scripts/check_issue11_saved_memory_helper_contract.py
python scripts/check_issue11_reentry_inventory_consistency.py
```

Use `--json` when another helper or a future automation step needs the path
contract as structured output.

## Working Rule

When `check_issue11_saved_memory_helper_contract.py` reports under-reported
restored-checkout fragments, update the narrower saved-memory preflight before
trusting it as the first Linux or WSL gate.

When `check_issue11_reentry_inventory_consistency.py` reports missing issue `#11`
paths, update the listed helper inventories before relying on restored helper
surface sync, saved-memory route output, or later build-readiness reruns as
parallel descriptions of the same re-entry contract.
