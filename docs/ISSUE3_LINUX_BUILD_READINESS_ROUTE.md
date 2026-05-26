# Issue #3 Linux Build-Readiness Route

Use this note when the direct issue `#3` runtime patch is still blocked on the
toolchain and offline dependency gate, but the run still has the saved Memory
archives available.

This is the Linux or WSL companion for the Windows-first runtime re-entry
helpers:

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
- `scripts/linux/show_issue3_progress_tracker_route.sh`
- `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh`
- `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
- `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
- `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
- `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
- `scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh`
- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
- `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
- `scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh`
- `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh`
- `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/check_issue3_zig_toolchain_match.sh`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_restored_helper_surface_sync.py`
- `scripts/check_issue3_workspace_context.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/check_issue3_staged_zig_toolchain_candidates.py`
- `scripts/check_issue3_build_readiness_rerun.py`
- `scripts/check_issue3_saved_zig_archive_candidates.py`

## Goal

Give the next writable checkout one branch-local route for:

- checking that the saved Memory repo snapshot, notes, blocker file, dependency
  archives, and optional fallback Zig bundle are still present
- checking that the saved repo snapshot and dependency bundles still match the
  expected exact artifacts before a restore or offline staging step trusts them
- surfacing the practical workspace roots for nested or restored checkouts
  before the next readiness rerun or explicit route override is rebuilt by hand
- checking that the Linux build-readiness note and helper surfaces still line up
- surfacing saved Rust archive candidates under the saved archive area before a
  hand-built restore path is guessed
- surfacing staged Rust toolchain candidates under `../toolchains` before host
  Rust or a restore step is blamed for the next readiness rerun
- staging the offline sibling dependencies expected by `build.zig.zon`
- restoring the saved Rust `1.79.0` toolchain through one compact helper route
- surfacing the attached fallback Zig archive location when only the
  builder-attached Zig `0.17` dev bundle is available
- surfacing staged Zig candidates under `../toolchains` before the fallback Zig
  `0.17` path is blamed for branch behavior
- surfacing saved Zig archive candidates under the saved archive area before a
  hand-built restore path is guessed
- failing fast when no staged Zig candidate matches the branch's expected
  `0.15.x` line before the broader readiness rerun is trusted again
- replaying the offline build-inputs restore route, including its saved-archive
  integrity preflight, through one compact helper surface before a raw archive
  command is trusted
- rerunning the readiness helper before trusting focused Zig output
- handing control back to the narrow Windows runtime revalidation route as soon
  as Linux or WSL staging is no longer the blocker

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
```

Use `--json` when another helper needs the surface-check result as structured
output.

## Resolve Workspace Roots When The Checkout Sits Deeper Than Default Layout

If the repo root is nested more deeply than the default sibling layout, surface
the nearest practical roots before rebuilding `--saved-archives-root`,
`--rust-toolchain-dir`, or fallback Zig overrides by hand:

```bash
python scripts/check_issue3_workspace_context.py --repo-root .
```

Use `--json` when another helper needs the surfaced paths as structured output.
That helper prints a ready-to-rerun `scripts/check_linux_build_readiness.py`
command with the discovered `toolchains`, `memory/repo_archives/browser`, and
fallback Zig paths already filled in.

## Restore A Checkout First When Needed

If there is no reusable extracted checkout beside the workspace yet, print the
saved-browser-snapshot route before reopening Linux or WSL staging from the live
repo root:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

That route keeps the saved snapshot surface check, the restore command, the
saved-Memory preflight, and the first build-readiness or runtime follow-up
commands on one branch-local helper surface.

## Recheck Restored Checkout Helper Sync Before Saved-Memory Preflight

If the route plans to reuse `../browser-memory-snapshot` as its own follow-up
helper root, do not jump straight from restore into the saved-Memory preflight.

Run the broader restored-checkout route first:

```bash
bash ./scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh
bash ./scripts/linux/show_issue3_restored_checkout_reentry_route.sh
```

Then run the narrower helper-surface sync route before widening back out to the
saved-Memory or build-readiness helpers:

```bash
bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh

python ./scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface

python ./scripts/check_issue3_restored_helper_surface_sync.py \
  --helper-root . \
  --restored-root ../browser-memory-snapshot
```

That narrower route catches the issue `#11` helper-surface drift that can still
exist even when the broader restored checkout looks usable, and it keeps
`restore_saved_browser_snapshot.sh --sync-only` visible when the fix is just an
in-place helper refresh.

## Run The Saved-Memory Preflight Next

After the surface check passes, confirm the saved Memory repo snapshot,
dependency bundles, and fallback Zig surface before the broader Linux or WSL
readiness helper.

Before dropping straight to the raw preflight, reopen the compact saved-Memory
route when the run wants the presence check, restored-checkout override, and
immediate restore, build-readiness, or runtime follow-up routes on one helper
surface:

```bash
bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh
bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh
```

That route prints the same saved-input preflight with the resolved repo,
Memory, helper, restored-checkout, and fallback Zig paths already filled in.

## Keep The Progress Tracker Route Visible

If this run is still working in the Linux or WSL re-entry lane and the direct
runtime patch is not ready to reopen yet, keep the lower-volume tracker handoff
visible before broader build-readiness or Zig helper output is treated as the
current status lane:

```bash
bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh
bash ./scripts/linux/show_issue3_progress_tracker_route.sh
```

That route keeps the issue `#11` start and completion update format, the saved-
Memory follow-up, the Linux build-readiness follow-up, and the Zig recovery
follow-up on one compact helper surface so scheduled runs do not fall back to
the capped issue `#2` or issue `#3` threads while the environment gates are
still closed.

## Verify Archive Integrity Before Offline Staging

After the saved-Memory preflight passes, confirm the saved repo snapshot and
dependency bundles still match the expected SHA-256 fingerprints before offline
staging or restore commands trust them:

```bash
python scripts/check_issue3_saved_archive_integrity.py --repo-root .
```

Use `--fallback-zig-archive` when the attached
`zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle lives somewhere other
than the default `../agent_files/` location beside the repo workspace.
Use `--require-fallback-zig` only when the route needs the fallback Zig archive
itself to be present and fingerprint-matched before later recovery steps can
trust it.

## Surface Staged Zig Candidates Before Saved-Archive Restore

If the route may already have a matching Zig `0.15.x` toolchain staged under
`../toolchains`, reopen the narrower staged-Zig route before falling back to
saved-archive restore work:

```bash
bash ./scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh
```

When the route wants the preferred staged candidate, its shell exports, or the
matching-line follow-up directly, run the staged-candidate helper itself:

```bash
python scripts/check_issue3_staged_zig_toolchain_candidates.py --repo-root .
```

If a matching staged candidate exists, print the exact Linux or WSL rerun
command before broader readiness is retried:

```bash
python scripts/check_issue3_build_readiness_rerun.py --repo-root .
```

Use `--json` when another helper needs the surfaced staged-candidate result,
exports, or rerun command as structured output.

Prefer a surfaced staged Zig `0.15.x` candidate before rebuilding saved-archive
restore commands by hand.

## Surface Saved Zig Archive Candidates Before A Hand-Built Restore

If no staged Zig candidate under `../toolchains` matches the branch's expected
`0.15.x` line and the exact saved archive path is not already known, reopen the
saved-Zig candidate route before hand-picking an archive argument:

```bash
bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh
```

When the route wants the surfaced archive list or restore commands directly,
run the candidate helper itself:

```bash
python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .
```

Prefer an exact saved Zig `0.15.2` archive when one exists. Otherwise prefer
the newest saved archive on the same `0.15.x` line before the attached Zig
`0.17` fallback is treated as the only visible option.

## Reopen The Zig Line Before Trusting Fallback Zig

If the route still only sees the attached Zig `0.17` dev bundle, print the
toolchain recovery surface before treating that fallback as meaningful evidence:

```bash
bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
```

That helper reads the branch minimum Zig line from `build.zig.zon`, checks any
staged `../toolchains` candidates it can probe, and prints the exact
`check_linux_build_readiness.py --zig ...` command to rerun once a matching
`0.15.x` toolchain is available.

Before trusting that broader readiness rerun, run the dedicated matching-line
gate against the same derived toolchains root:

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_match.sh
```

Use `--json` when another helper needs the staged-candidate result as structured
output.

This gate fails fast when no staged Zig executable under `../toolchains`
matches the branch's expected `0.15.x` line, even if the attached `0.17`
fallback archive is visible beside the repo workspace.

If a real Zig `0.15.x` archive is available but has not been staged yet, fail
fast on the archive-restore surface before rebuilding the restore command by
hand:

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh
```

Then use `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md` and
`restore_zig_toolchain_archive.sh` to stage that matching line under
`../toolchains` before rerunning recovery.

## Surface Saved Rust Candidates Before Rebuilding The Restore Path

If the exact saved Rust archive path is not already known or a restored Rust
`1.79.x` toolchain may already be staged under `../toolchains`, surface the
branch-local route helpers before rebuilding the restore command or blaming host
Rust:

```bash
bash ./scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh
bash ./scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh
```

When the route wants the surfaced archive choice or staged candidate result
without reopening the route printers, run the Python helpers directly:

```bash
python scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .
python scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
```

Use `--json` when another helper needs the surfaced archive choice or staged
candidate result as structured output.

Prefer an exact saved Rust `1.79.0` archive when one exists. Otherwise prefer
the newest saved archive on the same `1.79.x` line, and reuse a surfaced staged
`1.79.x` toolchain before rebuilding the restore path by hand.

## Restore The Saved Rust Toolchain Before Broader Readiness

When the route is reusing the saved archives, run the saved Rust surface check
first and then print the saved Rust toolchain route before relying on host
`cargo` or `rustc`:

```bash
bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh
```

That pair keeps the route doc and helper surface aligned first, then keeps the
archive check, restore command, and shell exports on one compact surface before
the broader build-readiness rerun.

## Print The Offline Build-Inputs Route Before Raw Restore

When the route still needs to stage `../zig-v8-fork`, `../boringssl-zig`, and
`../offline-deps`, print the dedicated offline-inputs helper before dropping to
the raw archive command:

```bash
bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh
```

That helper keeps the saved-Memory preflight, the saved-archive integrity
preflight, the `prepare_offline_build_inputs.sh` `--check-only` command, the
real restore command, the saved Rust follow-up, the Zig recovery follow-up, and
the first post-stage readiness rerun on one compact surface.

## Run The Helper

After the saved-memory preflight passes, print the saved-archive-first route:

```bash
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
```

If the repo checkout is not sitting beside the saved Memory folder, run the
workspace-context helper first so the next readiness command or explicit route
overrides use surfaced roots instead of hand-built guesses.

When explicit overrides are still needed, the route helper supports them:

```bash
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh \
  --repo-root /path/to/browser \
  --saved-archives-root /path/to/memory/repo_archives/browser \
  --rust-toolchain-dir /path/to/toolchains/rust-1.79.0
```

Use `--fallback-zig-archive` when the attached
`zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle lives somewhere other
than the default `../agent_files/` location beside the repo workspace.

Use `--json` when another helper needs the command set as structured output.

## What The Route Surfaces

The Linux route now stays short and ordered:

1. A fail-fast surface check using
   `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
2. A workspace-context helper using
   `scripts/check_issue3_workspace_context.py` when a nested checkout needs the
   nearest practical roots surfaced before other route overrides are rebuilt
3. A saved-browser-snapshot restore route using
   `scripts/linux/show_issue3_saved_browser_snapshot_route.sh` when no reusable
   checkout exists yet
4. A restored-checkout route surface check using
   `scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh`
5. A restored-checkout route printer using
   `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
6. A restored-helper-surface sync route surface check using
   `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
7. A restored-helper-surface sync route printer using
   `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
8. A saved-Memory route surface check using
   `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
9. A saved-Memory route printer using
   `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
10. An issue `#11` progress-tracker route surface check using
    `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
11. An issue `#11` progress-tracker route printer using
    `scripts/linux/show_issue3_progress_tracker_route.sh`
12. A saved-Memory preflight using `scripts/check_issue3_saved_memory_inputs.py`
13. A saved-archive integrity preflight using
    `scripts/check_issue3_saved_archive_integrity.py`
14. A staged Zig route surface check using
    `scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh`
15. A staged Zig route printer using
    `scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh`
16. A staged Zig candidate helper using
    `scripts/check_issue3_staged_zig_toolchain_candidates.py`
17. A build-readiness rerun helper using
    `scripts/check_issue3_build_readiness_rerun.py`
18. A Zig-line recovery helper using
    `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
19. A dedicated Zig matching-line gate using
    `scripts/linux/check_issue3_zig_toolchain_match.sh`
20. A saved Zig archive candidate surface check using
    `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
21. A saved Zig archive candidate route using
    `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
22. A saved Zig archive discovery helper using
    `scripts/check_issue3_saved_zig_archive_candidates.py`
23. A Zig archive-restore surface check using
    `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
24. A saved Rust archive route surface check using
    `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
25. A saved Rust archive route using
    `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
26. A staged Rust route surface check using
    `scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh`
27. A staged Rust route using
    `scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh`
28. A saved Rust archive discovery helper using
    `scripts/check_issue3_saved_rust_archive_candidates.py`
29. A staged Rust toolchain candidate helper using
    `scripts/check_issue3_staged_rust_toolchain_candidates.py`
30. A saved Rust route surface check using
    `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
31. A saved Rust restore route using
    `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
32. A dedicated offline build-inputs route using
    `scripts/linux/show_issue3_offline_build_inputs_route.sh`
33. A saved-archive preflight using `scripts/check_linux_build_readiness.py`
34. A `prepare_offline_build_inputs.sh --check-only` command for the offline
    dependency surface
35. A saved Rust `1.79.0` restore command
36. A PATH export that keeps the restored Rust toolchain ahead of any host Rust
37. The attached fallback Zig archive location when it is present beside the
    repo workspace, so runs can surface it without treating it as
    branch-compatible validation evidence
38. A full readiness command that expects the saved archives, offline deps, and
    prebuilt V8 archive to be staged before retrying `zig build`
39. A direct handoff back to the smaller Windows runtime revalidation route
    once the saved-archive and toolchain checks stop being the blocker

## Hand Back To The Windows Runtime Route

When the Linux or WSL build-readiness route stops failing on missing archives,
missing offline deps, Rust setup, or Zig-line mismatch, move back to the direct
issue `#3` Windows runtime surface before reopening a broader replay:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

Use that pair first so the next run rechecks the direct `Page.zig` plus
`win32_backend.zig` route, the shared Enter-order ladder, the reduced Google
fixture, and the current helper-note chain before it widens back out to larger
attached-page or live-Google replay.
