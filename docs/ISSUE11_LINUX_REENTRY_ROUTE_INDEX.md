# Issue #11 Linux Re-entry Route Index

Use this note when the direct issue `#3` runtime work is still blocked on Linux
or WSL environment gates and the current run needs one compact branch-local
index instead of hopping between several narrower route notes.

This index is for the lower-volume tracker in issue `#11`:

- https://github.com/adybag14-cyber/browser/issues/11

Do not use the saturated issue `#2` or issue `#3` threads for routine start or
completion updates while the work is still in the saved-input, archive,
toolchain, or offline-dependency lane.

## Goal

Keep the next run on one honest ladder from:

1. issue `#11` progress updates
2. saved-archive trust checks
3. restored-checkout and saved-input checks
4. saved Rust and Zig toolchain recovery
5. Linux or WSL build-readiness reruns
6. the narrower Windows runtime re-entry route once the environment gates turn green

## Expected Shared Roots

Unless the checkout was restored into a different layout, assume these shared
roots first:

- Memory archive root: `../memory/repo_archives/browser`
- Toolchains root: `../toolchains`
- Offline dependency root: `../offline-deps`
- Attached fallback Zig archive: `../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`

When the checkout is nested more deeply than the default sibling layout, surface
practical roots first:

```bash
bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh
bash ./scripts/linux/show_issue3_workspace_context_route.sh
python ./scripts/check_issue3_workspace_context.py --repo-root .
```

## Start With The Progress Tracker Route

Run the surface check before treating issue `#11` as the current status lane:

```bash
bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh
bash ./scripts/linux/show_issue3_progress_tracker_route.sh
```

Use the compact issue update format from that route:

```text
Goal: <state the exact Linux/WSL helper, archive, or toolchain step>
Started: <UTC timestamp>
Next: <state the first concrete helper check or branch-safe change>
```

Post the completion update only after the branch commit exists:

```text
Achieved: <state what helper, note, or route improvement landed>
Completed: <UTC timestamp>
Commit: <commit sha>
Validation: <state the focused helper check or follow-up route>
```

## Prove The Saved Inputs Before Restore Or Staging

If the run still depends on the saved repo archive and dependency bundles, keep
this order:

```bash
bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh
bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh
bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh
python ./scripts/check_issue3_saved_archive_integrity.py --repo-root .
python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .
```

Use `--fallback-zig-archive ../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
when the attached Zig archive is present but not in the default sibling
location expected by the helper.

If there is no reusable checkout yet, reopen the saved-browser-snapshot route
before build-readiness or toolchain reruns:

```bash
bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

## Reopen Rust Before Trusting Host Tooling

When the saved Rust `1.79.0` bundle is part of the path back to honest Linux or
WSL validation, keep the shorter bridge visible first and only drop to the raw
restore route when the explicit shell exports are still needed:

```bash
bash ./scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_build_readiness_route.sh
bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh
python ./scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .
python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
```

## Reopen Zig In Two Steps

First surface saved Zig candidates and stage a real `0.15.x` archive when one is
available:

```bash
bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh
python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .
bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh
```

Then reopen the broader recovery route and the dedicated matching-line gate:

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh
bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
bash ./scripts/linux/check_issue3_zig_toolchain_match.sh
```

Treat the attached Zig `0.17` dev archive as a surfaced fallback only. Do not
count it as honest branch-compatible validation evidence for a checkout that
still expects a `0.15.x` line.

## Re-run Linux Build Readiness Only After The Gates Above

Once the saved inputs, restored checkout, Rust route, and Zig line are all on a
trustworthy path again, reopen the Linux or WSL readiness route:

```bash
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
python ./scripts/check_linux_build_readiness.py --repo-root .
```

If the route already has a matching staged Zig candidate and wants the exact
rerun command surfaced first, use:

```bash
python ./scripts/check_issue3_build_readiness_rerun.py --repo-root .
```

## Hand Control Back To The Runtime Route Only When Ready

Do not reopen the direct `Page.zig` plus `win32_backend.zig` runtime slice while
saved-input, archive-integrity, Rust, Zig-line, or offline-dependency checks are
still the blocker.

Once Linux or WSL build readiness is green again, return to the narrower
runtime route:

```bash
bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
```

Keep `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` and
`docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` open when the route crosses
back from environment recovery into the real runtime patch lane.
