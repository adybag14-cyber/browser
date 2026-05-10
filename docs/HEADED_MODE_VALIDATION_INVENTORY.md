# Headed Mode Validation Inventory

This note complements the existing validation routing docs by answering a
different question: how much of the current probe tree is still portable across
Windows checkouts, and how much is still tied to the historical repo path
`C:\Users\adyba\src\lightpanda-browser`.

Use this together with:

- `docs/HEADED_MODE_VALIDATION_GATES.md`
- `docs/WINDOWS_FULL_USE.md`
- `scripts/windows/show_headed_validation_suites.ps1`
- `scripts/windows/get_headed_probe_inventory.ps1`

## Why This Exists

The branch already has a named suite map and change-area routing helpers.
What it did not have was a compact inventory pass that can:

- count the current probe scripts per named suite
- flag which suites are still path-bound because their probes embed the old
  checkout root
- give future runs one command that turns that portability state into visible
  output before a Windows validation pass starts

## Inventory Command

From the repo root on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\get_headed_probe_inventory.ps1
```

For machine-readable output:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\get_headed_probe_inventory.ps1 -Format Json
```

For a markdown snapshot:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\get_headed_probe_inventory.ps1 -Format Markdown
```

## Status Meanings

- `portable`: the suite directories exist and the inventory did not find the
  old hardcoded repo root in those probe scripts
- `path-bound`: the suite exists, but at least one probe still assumes the old
  checkout path
- `missing-directories`: the suite mapping points at a directory that is not
  present in the checkout

## Current Expected Behavior

Today, most headed suites are still expected to show `path-bound` because the
probe tree was originally authored around one Windows checkout location.

That is not a reason to discard the suite map. It is a reason to make the
constraint explicit before a run tries to widen validation.

## Recommended Use

1. Use `show_headed_validation_suites.ps1` or
   `docs/HEADED_MODE_VALIDATION_GATES.md` to choose the smallest relevant
   suite.
2. Run `get_headed_probe_inventory.ps1` to see whether that suite is portable
   or still path-bound in the current checkout.
3. If it is path-bound, either run from the expected Windows repo root or log
   the portability constraint as part of the validation result.
4. Treat conversion away from the historical hardcoded repo path as a
   validation-discipline task, not a runtime-engine change.

## Follow-Up

The next validation cleanup should convert the remaining probe scripts in
`tmp-browser-smoke/` to repo-relative path discovery so the existing named
gates can run unchanged from arbitrary Windows checkout locations.
