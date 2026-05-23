# Issue #3 Recovery Ladder

Use this when the direct headed Enter-submit runtime patch is still blocked by:

- no reusable local checkout beside the workspace
- no safe publication path for large existing files
- or a toolchain gate that is not green yet

This helper does not replace the narrower route notes. It gives future runs one
ordered entrypoint that points at the saved-snapshot restore path first, then
the saved-input preflight, then the Linux or WSL build-readiness route, and
only then the direct runtime re-entry route.

## Helper

From the browser repo root:

```bash
python scripts/show_issue3_recovery_ladder.py
```

Use `--json` when another helper or scheduled run wants the same route as
structured output.

Use `--restored-checkout /path/to/checkout` when the recovered checkout should
live somewhere other than the default sibling `../browser-memory-snapshot`.

## What It Prints

The recovery ladder prints the steps in this order:

1. show the saved browser snapshot route
2. restore the saved snapshot when no reusable checkout exists yet
3. run the saved Memory input preflight against the target checkout
4. confirm the direct runtime helper surface still exists
5. print the Linux or WSL build-readiness route for that checkout
6. print the narrowed runtime re-entry route for the same checkout

That keeps the next headed-mode recovery attempt aligned to the saved Memory
artifacts instead of depending on a live `git clone` path that may not be
available in the current runtime.
