# Issue #3 Saved Memory Inputs Route

Use this note when a Linux, WSL, or scheduled headed-mode run needs to prove the
saved Memory inputs are present before it reopens checkout restore, build-
readiness, or the direct issue `#3` runtime lane.

This route keeps the saved repo snapshot, notes, blocker file, dependency
archives, optional fallback Zig bundle, the low-volume progress-tracker handoff,
the dedicated saved-archive integrity handoff, the saved Zig archive candidate
handoff, and the immediate next helper routes on one compact branch-local
surface.

Companion helpers:

- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
- `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
- `scripts/check_issue3_saved_zig_archive_candidates.py`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when any of these are true:

- a scheduled run starts by checking Memory first and needs a compact preflight
  before choosing restore, build-readiness, or runtime follow-up
- the next Linux or WSL route depends on the saved repo snapshot and dependency
  archives, and the run wants the exact preflight command plus follow-up routes
  on one surface
- a restored checkout may already exist, but the saved inputs still need a
  fresh preflight before Linux or WSL helper output is trusted
- the current checkout may not sit beside the default `memory/` or
  `agent_files/` folders and the run wants one helper that resolves those paths
  explicitly
- the direct issue `#3` runtime patch is still blocked and the run needs the
  progress-tracker handoff, the dedicated saved-archive integrity route, and the
  saved Zig archive candidate route back on one compact helper surface before it
  widens into restore or build-readiness follow-up

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh
```

Use `--json` when another helper wants the surface-check result as structured
output.

## Print The Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh
```

If the checkout, Memory folder, attached files, or restored checkout root live
somewhere unusual, override the paths:

```bash
bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh \
  --repo-root /path/to/browser \
  --memory-root /path/to/memory \
  --agent-files-root /path/to/agent_files \
  --restored-checkout-root /path/to/browser-memory-snapshot
```

Use `--fallback-zig-archive` when the attached
`zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle should come from an
explicit path instead of the default `../agent_files/` probe beside the repo
workspace.

Use `--json` when another helper wants the resolved command set as structured
output.

## Run The Saved-Memory Preflight

Run the actual saved-input helper after the route surface is green:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .
```

That command checks:

- `repo_archives/browser/01-browser-fork-headed-mode-foundation.zip`
- `repo_archives/browser/README.md`
- `repo_archives/browser/blocker_intelligence.yaml`
- `repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz`
- `repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip`
- `repo_archives/browser/dependencies/03-boringssl-zig-main.zip`
- `repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip`
- the optional session register and fallback Zig archive surface

When the current run only needs a fast presence check before choosing another
lane, use:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py --repo-root . --skip-archive-integrity-check
```

If a reusable checkout already exists and the route should confirm both the
saved inputs and the restored helper surface together, use the restored-
checkout override:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py \
  --repo-root . \
  --restored-checkout-root ../browser-memory-snapshot
```

## Keep The Progress Tracker Visible

If this run is still working in the Linux or WSL re-entry lane and the direct
runtime patch is not ready to reopen yet, keep the lower-volume tracker visible:

```text
docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
```

That note redirects scheduled-run start and completion updates onto issue `#11`
so the run does not retry the capped issue `#2` or issue `#3` threads while the
environment gates are still closed.

## Immediate Follow-up

After the saved-input preflight succeeds, choose the next route based on the
actual missing step:

If exact archive trust, checksum drift, or saved-snapshot helper-surface drift
is still the blocker:

```bash
bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh
```

If the next blocker is choosing a branch-compatible saved Zig `0.15.x` archive
before wider toolchain recovery or build-readiness work:

```bash
bash ./scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh
```

If there is still no reusable checkout beside the workspace:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

If the checkout exists but Linux or WSL toolchain or dependency staging is
still the blocker:

```bash
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
```

If the saved inputs are green and the run is specifically reopening the narrowed
`Page.zig` plus `win32_backend.zig` lane:

```bash
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
```

The route helper prints those same follow-up commands with the resolved repo,
Memory, restored-checkout, and optional fallback Zig paths already filled in.

## Working Rules

- Run the surface check first so helper drift fails fast before the run blames
  missing Memory inputs.
- Run the saved-input preflight before broader Linux or WSL helper output is
  treated as trustworthy.
- Use `--skip-archive-integrity-check` only for a quick presence-only branch
  decision, not for honest archive validation.
- Use the restored-checkout override when a reusable checkout already exists
  and the route should confirm that helper surface before broader route output
  is trusted.
- Keep `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md` visible whenever the route is
  still working in the Linux or WSL re-entry lane so start and completion
  updates go to issue `#11`.
- Use the saved-archive integrity route when the saved-input preflight passes
  but the next question is still whether the exact saved bundles and snapshot
  helper surface are trustworthy enough for restore or staging.
- Use the saved Zig archive candidates route when the next question is which
  saved `0.15.x` archive should be restored before wider Zig recovery or Linux
  build-readiness work resumes.
- Use the saved-browser-snapshot route when the saved archive exists but there
  is still no reusable checkout for Linux or WSL follow-up.
- Use the Linux build-readiness route after the saved-input preflight passes
  and the next blocker is still Rust, Zig, offline dependency staging, or
  prebuilt V8 readiness.
- Use the direct runtime re-entry route only after the saved checkout exists and
  the environment gates are no longer the blocker.
- Treat the attached Zig `0.17` dev bundle as surfaced fallback input only; do
  not treat it as honest issue `#3` validation evidence for this branch.
