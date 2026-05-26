# Issue #3 Saved Zig Readiness Bridge Route

Use this note when the Linux or WSL headed runtime re-entry lane needs one
compact bridge between the saved Zig archive helper and the broader
build-readiness helper before the direct issue #3 runtime patch is reopened.

This route exists to keep the "what should happen next?" decision on a
branch-local helper surface. The bridge helper compares staged Zig candidates,
saved Zig archive candidates, and the broader Linux build-readiness helper so a
rerun can decide whether it should reuse a staged toolchain, restore a saved
archive, or fall back to the attached Zig bundle.

Companion helpers:

- `scripts/linux/check_issue3_saved_zig_readiness_bridge_route_surface.sh`
- `scripts/linux/show_issue3_saved_zig_readiness_bridge_route.sh`
- `scripts/check_issue3_saved_zig_readiness_bridge.py`
- `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_progress_tracker_route.sh`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`

## When To Use It

Use this route when any of these are true:

- a rerun needs a compact answer for whether to reuse a staged Zig toolchain or
  restore a saved archive first
- the saved Zig archive candidate helper and the broader build-readiness helper
  are both relevant, and the next action should be surfaced from one place
- a restored checkout is nested under a deeper workspace layout and the route
  should auto-discover the nearest `memory`, `toolchains`, `offline-deps`, and
  `agent_files` roots
- a rerun wants the exact follow-up commands for the next Zig step without
  rebuilding them by hand
- a run wants a fail-fast surface check before it trusts the bridge helper's
  output

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_zig_readiness_bridge_route_surface.sh
```

Use `--json` when another helper wants the surfaced route metadata as structured
output.

The surface checker confirms that the branch-local note, bridge helper, saved
Zig archive helper, broader build-readiness helper, and issue #11 progress
tracker note are all in place before a rerun trusts the bridge helper output.

## Surface The Next Zig Action

After the surface check passes, run:

```bash
python ./scripts/check_issue3_saved_zig_readiness_bridge.py --repo-root .
```

Use `--expect-offline-deps` when the next Linux or WSL readiness rerun must
also prove cached offline inputs. Use `--require-prebuilt-v8` when the reopened
build-readiness lane still depends on a prebuilt V8 archive.

Use `--json` when another helper wants the staged-Zig, saved-Zig, and next-step
decision data as structured output.

## Follow The Surfaced Next Action

The bridge helper can surface one of four outcomes:

- reuse a staged matching Zig toolchain and rerun broader Linux build-readiness
- restore a preferred saved Zig archive and then rerun the matching-line gate
- restore only the attached fallback Zig bundle when no saved branch-compatible
  archive is visible
- return to saved Zig archive discovery when neither a staged match nor a saved
  restore candidate is available

Run the surfaced commands in order. When the helper reports a staged matching
candidate, continue with `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`. When it
reports a saved archive restore path, keep
`docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md` and
`docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md` open while staging the archive.

## Working Rules

- Run the bridge surface check first so route drift fails before a rerun trusts
  the staged-versus-saved Zig decision.
- Prefer a staged matching `0.15.x` Zig toolchain when one is already visible
  under `../toolchains`.
- Prefer a saved branch-compatible Zig archive over the attached fallback `0.17`
  bundle whenever a saved archive is available.
- Treat the attached Zig `0.17` bundle as a surfaced stopgap only, not as
  branch-compatible validation evidence.
- Use `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md` when the slice is still about
  saved inputs, toolchain recovery, or Linux or WSL readiness gates rather than
  reopening the direct runtime patch.
