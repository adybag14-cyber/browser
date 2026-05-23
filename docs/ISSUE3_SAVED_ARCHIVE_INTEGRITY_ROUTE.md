# Issue #3 Saved Archive Integrity Route

Use this route when the saved Memory repo snapshot and dependency bundles are
present, but the next restore or Linux build-readiness run still needs proof
that those files are the expected artifacts instead of stale or manually edited
lookalikes.

This route complements the existing presence-only helper
`scripts/check_issue3_saved_memory_inputs.py`.

Use the presence helper first when the question is "are the required saved files
mounted at all?" Use this integrity helper when the question is "are these the
exact saved files the route expects before restore or offline staging starts?"

Companion helpers:

- `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`

## When To Use It

Use this route when any of these are true:

- the saved archive paths exist, but a run needs to rule out silent drift before
  extracting the snapshot or staging dependencies
- the saved-browser-snapshot restore path is about to be reused after a manual
  archive copy, sync, or workspace move
- the Linux or WSL build-readiness route needs a fast checksum gate before a
  mismatch gets mistaken for a source or toolchain problem

## Surface Check

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
python ./scripts/check_issue3_saved_archive_integrity.py --repo-root .
```

The first command verifies that the route note, route printer, checksum helper,
and companion restore/build-readiness helpers are still present on the branch.

The second command computes the SHA-256 fingerprints for the saved repo
snapshot and the saved dependency archives under `../memory`.

If the attached fallback Zig bundle should also be treated as required, add:

```bash
python ./scripts/check_issue3_saved_archive_integrity.py --repo-root . --require-fallback-zig
```

## Compact Route

When the route should stay on one helper surface instead of rebuilding the
commands by hand, print the route helper:

```bash
bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh
```

Use `--json` when another helper needs the route as structured output.
Use `--fallback-zig-archive /path/to/archive` when the fallback Zig bundle lives
outside the default attached-files location.

## Immediate Follow-up

After the integrity check passes, continue with the next matching route:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root .
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root .
```

If the checksums fail, replace or remount the mismatched archive before
trusting restore, offline staging, or focused issue `#3` re-entry work.

## Working Rules

- Use this route before blaming a broken restore or Linux build-readiness replay
  on the source tree when the saved archives may have drifted.
- Treat checksum mismatch as an input problem first, not as proof that the
  branch or toolchain regressed.
- Keep this route narrow: it verifies saved archive identity, not full toolchain
  or dependency usability.
- Move to the saved-browser-snapshot route or Linux build-readiness route only
  after the presence and integrity gates both pass.
