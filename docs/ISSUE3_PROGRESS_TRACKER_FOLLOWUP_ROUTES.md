# Issue #3 Progress Tracker Follow-up Route Surface

Use this note when the issue `#11` tracker is already the right status lane and
the next scheduled Linux or WSL run needs to prove that its follow-up routes
are still present before it trusts them.

This surface is intentionally narrower than the main progress-tracker route.
It focuses on the three follow-up branches that commonly sit between issue
`#11` and the broader Linux or WSL build-readiness rerun:

- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`

Use it with:

- `scripts/linux/check_issue3_progress_tracker_followup_route_surface.sh`
- `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`

## When To Use It

Run this surface when:

- issue `#11` is still the practical place for progress updates
- the next slice is still environment-gated
- the run depends on the saved-Memory route, the saved-archive-integrity route,
  or the saved-Rust archive-candidate route

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_progress_tracker_followup_route_surface.sh
```

Use `--json` when another helper wants the follow-up route-surface result as
structured output.

## Working Rule

If this surface fails, fix the missing follow-up route note or helper before the
run treats issue `#11` as ready to hand off into saved-input, checksum, or
saved-Rust archive-candidate work.
