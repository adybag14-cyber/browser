# Issue #3 Saved Memory Inputs Route

Use this note when a Linux, WSL, or scheduled headed-mode run needs to prove the
saved Memory inputs are present before it reopens checkout restore, build-
readiness, or the direct issue `#3` runtime lane.

This route keeps the saved repo snapshot, notes, blocker file, dependency
archives, optional fallback Zig bundle, the low-volume progress-tracker handoff,
the dedicated saved-archive integrity handoff, the saved Zig archive candidate
handoff, the staged Zig candidate handoff, the saved Rust toolchain, saved Rust
build-readiness, saved Rust archive-candidate handoffs, the staged Rust
candidate handoff, the workspace-context handoff, the restored-helper surface
sync handoff, the issue `#11` saved-memory helper-contract and re-entry
inventory checks, and the immediate next helper routes on one compact
branch-local surface.

Companion helpers:

- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md`
- `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh`
- `scripts/check_issue11_saved_memory_helper_contract.py`
- `scripts/check_issue11_reentry_inventory_consistency.py`
- `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
- `scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh`
- `scripts/check_issue3_saved_zig_archive_candidates.py`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
- `scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/check_issue3_staged_zig_toolchain_candidates.py`
- `scripts/check_issue3_build_readiness_rerun.py`
- `scripts/linux/check_issue3_workspace_context_route_surface.sh`
- `scripts/linux/show_issue3_workspace_context_route.sh`
- `scripts/check_issue3_workspace_context.py`
- `scripts/check_issue3_restored_helper_surface_sync.py`
- `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
- `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
- `scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
- `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
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
  saved Zig archive candidate handoff, the staged Zig candidate handoff, the
  saved Rust follow-up helpers, the staged Rust candidate handoff, the issue
  `#11` helper-contract layer, and the workspace-context plus restored-helper-
  surface sync routes back on one compact helper surface before it widens into
  restore or build-readiness follow-up

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

The branch-local saved-Memory route printer already searches the nearest
ancestor workspace for `memory/`, `agent_files/`, `toolchains/`, and
`offline-deps` roots before it falls back to sibling defaults, and it threads
those discovered roots into the printed follow-up commands. The bare
`python ./scripts/check_issue3_saved_memory_inputs.py --repo-root ...` helper
still uses simpler sibling defaults unless the run passes explicit overrides.
Reopen the workspace-context surface first when the layout is unusual so the run
can confirm those discovered roots before it trusts direct helper invocations.

## Prefer The Nested-Workspace Runner For One-Command Rechecks

When the workspace-context surface already explains the problem and the next step
is simply rerunning the saved-memory preflight with those surfaced roots wired
through automatically, prefer the compact issue `#11` wrapper:

```bash
bash ./scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh
```

That wrapper uses `scripts/check_issue3_workspace_context.py` first, then reruns
`scripts/check_issue3_saved_memory_inputs.py` with the surfaced live helper,
Memory, agent-files, restored-checkout, and optional fallback-Zig paths already
threaded through.

Use the quick-presence version when the run only needs a branch decision:

```bash
bash ./scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh \
  --skip-archive-integrity-check
```

Use `--json` when another helper or a scheduled run wants the surfaced
workspace-context plus the rerun preflight command as structured output.

## When Repo Root Is Already The Restored Checkout

When the current shell is already rooted inside `../browser-memory-snapshot` or
another deeper restored checkout, do not assume the saved-memory preflight can
still infer the live helper root, `memory/`, `agent_files/`, or the restored
checkout path from the immediate parent alone.

In that situation, the compact wrapper above is the safest default because it
surfaces those roots first and then reruns the preflight with explicit
arguments. If the run needs the equivalent command spelled out directly, use:

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

When the layout is unusual, prefer the route-printer command above or the issue
`#11` nested-workspace wrapper so the surfaced workspace roots are threaded into
the preflight automatically. The bare helper invocation keeps sibling defaults
for `memory/`, `agent_files/`, and the restored checkout root unless those
overrides are supplied.

The live `scripts/check_issue3_saved_memory_inputs.py` helper now mirrors the
restore-helper inventory dynamically. When
`restore_saved_browser_snapshot.sh` starts copying a newer saved-Rust,
staged-toolchain, rerun, nested-workspace, or issue `#11` helper-contract file,
the saved-memory preflight will start requiring that same surface instead of
silently accepting an older restored helper set.

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

If the next blocker is checking whether a matching staged Zig candidate already
exists before the run widens back to saved-archive restore or broader recovery:

```bash
bash ./scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh
```

If the next blocker is restoring or validating the saved Rust toolchain before
offline dependency staging or broader build-readiness reruns:

```bash
bash ./scripts/linux/show_issue3_saved_rust_build_readiness_route.sh
```

If the next blocker is narrowing which saved Rust archive candidate should be
restored into the staged toolchain surface:

```bash
bash ./scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh
```

If the next blocker is checking whether a matching staged Rust candidate already
exists before the run unpacks the archive again or widens back to the broader
build-readiness bridge:

```bash
bash ./scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh
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
- The saved-Memory route printer reuses the nearest ancestor workspace roots it
  can find before it falls back to sibling guesses. Confirm those discovered
  roots with the workspace-context surface before trusting direct helper
  invocations from an unusual restored layout.
- Prefer `scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh`
  when the layout is unusual but the next question is still just whether the
  saved-memory preflight passes once those surfaced roots are threaded through
  honestly.
- When the current repo root is itself a deeper restored checkout, prefer the
  issue `#11` wrapper or the explicit `--helper-root`, `--memory-root`,
  `--agent-files-root`, and `--restored-checkout-root` override set instead of
  trusting default sibling inference.
- Treat the saved-memory preflight as a live mirror of the restore-helper
  surface. When `restore_saved_browser_snapshot.sh` widens the copied helper
  set, rerun this route and keep the note aligned instead of assuming the older
  helper list is still authoritative.
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
- Use the staged Zig toolchain candidates route when the next question is
  whether a matching staged Zig already exists before the run restores the
  archive again or widens back to saved-archive discovery.
- Use the saved Rust build-readiness route when the next blocker is still the
  staged Rust toolchain, rerun surface, or saved Rust restore flow that the
  Linux or WSL build-readiness lane depends on next.
- Use the saved Rust archive candidates route when the next question is which
  saved Rust archive should repopulate the staged toolchain surface before
  wider restore or rerun work resumes.
- Use the staged Rust toolchain candidates route when the next question is
  whether a matching staged Rust already exists before the run unpacks the
  archive again or widens back to the broader build-readiness bridge.
- Use the saved-browser-snapshot route when the saved archive exists but there
  is still no reusable checkout for Linux or WSL follow-up.
- Use the Linux build-readiness route after the saved-input preflight passes
  and the next blocker is still Rust, Zig, offline dependency staging, or
  prebuilt V8 readiness.
- Use the direct runtime re-entry route only after the saved checkout exists and
  the environment gates are no longer the blocker.
- Treat the attached Zig `0.17` dev bundle as surfaced fallback input only; do
  not treat it as honest issue `#3` validation evidence for this branch.