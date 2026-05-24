# Issue #3 Saved Archive Integrity Route

Use this route before the saved-browser-snapshot restore path, Linux or WSL
build-readiness work, or direct issue `#3` runtime re-entry when the run needs
to confirm that the saved repo and dependency bundles are the exact expected
artifacts rather than merely present at the right paths.

This route turns the existing SHA-256 helper into a standard branch-local
surface so future runs can fail fast on stale or damaged archives before they
reopen deeper headed-mode work.

Companion helpers:

- `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when any of these are true:

- the run depends on the saved Memory repo snapshot or dependency bundles
- the saved-browser-snapshot restore route is about to extract a local checkout
- Linux or WSL build-readiness work is about to trust the saved offline inputs
- the direct `Page.zig` plus `win32_backend.zig` runtime lane is still blocked
  on environment uncertainty and the run needs to rule out archive drift first

## Surface Check

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
```

This verifies that the route note, route printer, SHA-256 helper, saved-Memory
preflight, and the restore or follow-up helpers are still present on the
branch-local helper surface before the run trusts the archive-integrity route.

## Print The Route

When the run wants the archive-integrity commands on one compact surface:

```bash
bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh
```

Use `--json` when another helper needs the route as structured output. Use
`--require-fallback-zig` when the fallback Zig archive must exist and match its
expected SHA-256 before the route is considered green.

## Verify The Saved Archives

Run the SHA-256 helper directly once the route surface is green:

```bash
python ./scripts/check_issue3_saved_archive_integrity.py --repo-root .
```

When the fallback Zig bundle is required for the next route replay, run the
strict form:

```bash
python ./scripts/check_issue3_saved_archive_integrity.py \
  --repo-root . \
  --require-fallback-zig
```

The helper verifies:

- `repo_archives/browser/01-browser-fork-headed-mode-foundation.zip`
- `repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz`
- `repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip`
- `repo_archives/browser/dependencies/03-boringssl-zig-main.zip`
- `repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip`
- the fallback Zig archive when it is explicitly required

## Recommended Order

Keep the early recovery checks in this order:

```bash
bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh
python ./scripts/check_issue3_saved_archive_integrity.py --repo-root .
python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

After the archive-integrity helper is green, continue into whichever downstream
route the run actually needs:

- `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## Working Rules

- Use archive integrity as the first trust check when the saved offline inputs
  are part of the plan.
- Treat checksum mismatch as an environment problem first, not as proof that the
  headed runtime patch regressed.
- Run the saved-Memory presence preflight after the checksum route, not instead
  of it.
- Do not reopen Linux or WSL build-readiness or direct runtime validation on
  top of mismatched saved archives.
- Prefer this route when the current run needs a small, publishable recovery
  step without touching the blocked large runtime files.
