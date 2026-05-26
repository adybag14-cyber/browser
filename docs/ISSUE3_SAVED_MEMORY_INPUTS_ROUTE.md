# Issue #3 Saved Memory Inputs Route

Use this note when a Linux, WSL, or scheduled headed-mode run needs to prove the
saved Memory inputs are present before it reopens checkout restore, build-
readiness, or the direct issue `#3` runtime lane.

This route keeps the saved repo snapshot, notes, blocker file, dependency
archives, optional fallback Zig bundle, the low-volume progress-tracker handoff,
the dedicated saved-archive integrity handoff, the saved Zig archive candidate
handoff, the workspace-context handoff, and the immediate next helper routes on
one compact branch-local surface.

Companion helpers:

- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
- `scripts/check_issue3_saved_zig_archive_candidates.py`
- `scripts/linux/check_issue3_workspace_context_route_surface.sh`
- `scripts/linux/show_issue3_workspace_context_route.sh`
- `scripts/check_issue3_workspace_context.py`
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
- the current checkout sits deeper than the default sibling layout and the next
  saved-input, restore, or build-readiness helper would otherwise guess the
  wrong workspace roots
- the direct issue `#3` runtime patch is still blocked and the run needs the
  progress-tracker handoff, the dedicated saved-archive integrity handoff, the
  saved Zig archive candidate handoff, and the workspace-context route back on
  one compact helper surface before it widens into restore or build-readiness
  follow-up

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh
```

Use `--json` when another helper wants the surface-check result as structured
output.

## Surface Workspace Roots First When Layout Is Unusual

If the checkout was restored deeper than the default sibling layout, or the next
route would otherwise have to guess `memory`, `agent_files`, `toolchains`, or
`offline-deps` roots, surface those paths first:

```bash
bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh
bash ./scripts/linux/show_issue3_workspace_context_route.sh
python ./scripts/check_issue3_workspace_context.py --repo-root .
```

Use the printed workspace-context output to decide whether this saved-Memory
route should keep its defaults or whether it should be rerun with explicit
`--memory-root`, `--agent-files-root`, `--restored-checkout-root`, or
`--fallback-zig-archive` overrides before broader Linux or WSL follow-up.

The branch-local saved-Memory route already searches the nearest ancestor
workspace for `memory/`, `agent_files/`, `toolchains/`, and `offline-deps`
roots before it falls back to sibling defaults. Reopen the workspace-context
surface first when the layout is unusual so the run can confirm those discovered
roots before it trusts the default route output.

## When Repo Root Is Already The Restored Checkout

When the current shell is already rooted inside `../browser-memory-snapshot` or
another deeper restored checkout, do not assume the saved-memory preflight can
still infer the live helper root, `memory/`, `agent_files/`, or the restored
checkout path from the immediate parent alone.

In that situation, print the workspace-context route first and then rerun the
saved-memory preflight with explicit roots so the live helper surface and saved
artifacts stay anchored to the real workspace paths:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py \
  --repo-root /path/to/browser-memory-snapshot \
  --helper-root /path/to/live/browser \
  --memory-root /path/to/workspace/memory \
  --agent-files-root /path/to/workspace/agent_files \
  --restored-checkout-root /path/to/browser-memory-snapshot
```

Keep those explicit overrides in place until the workspace-context output and
the saved-memory preflight agree on the same resolved roots. This is especially
important when the restored checkout is being used as its own follow-up root but
helper drift still needs to be checked against a separate live branch checkout.

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

If the extracted snapshot may lag behind the current live helper surface, run
the preflight from the restored tree but keep `--helper-root` pointed at the
live branch checkout before you trust route commands from that restored tree:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --restored-checkout-root ../browser-memory-snapshot
```

That path catches stale restored snapshots before a run tries to invoke newer
route notes or helper scripts from the extracted archive itself.

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
- Run the workspace-context route first when the checkout sits deeper than the
  default sibling layout or the next helper would otherwise guess the wrong
  `memory`, `agent_files`, `toolchains`, or `offline-deps` roots.
- The saved-Memory route defaults now reuse the nearest ancestor workspace
  roots they can find before they fall back to sibling guesses. Confirm those
  discovered roots with the workspace-context surface before trusting default
  route output from an unusual restored layout.
- When the current repo root is itself a deeper restored checkout, prefer the
  explicit `--helper-root`, `--memory-root`, `--agent-files-root`, and
  `--restored-checkout-root` override set instead of trusting default sibling
  inference.
- Run the saved-input preflight before broader Linux or WSL helper output is
  treated as trustworthy.
- Use `--skip-archive-integrity-check` only for a quick presence-only branch
  decision, not for honest archive validation.
- Use the restored-checkout override when a reusable checkout already exists
  and the route should confirm that helper surface before broader route output
  is trusted.
- Use the live-helper restored-checkout preflight when the extracted snapshot
  may be older than the current helper surface and the run needs that drift to
  fail before it starts calling route commands from the restored tree.
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
