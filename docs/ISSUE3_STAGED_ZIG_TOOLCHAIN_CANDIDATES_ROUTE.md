# Issue #3 Staged Zig Toolchain Candidates Route

Use this note when the Linux or WSL headed runtime re-entry lane needs to prove
whether a branch-compatible Zig `0.15.x` toolchain is already staged under
`../toolchains` before it falls back to saved-archive restore work.

This route keeps the staged-toolchain candidate helper, the matching-line gate,
the exact build-readiness rerun helper, and the issue `#11` handoff on one
branch-local surface so future runs do not have to rebuild the staged-toolchain
reuse path by hand.

## Companion Surfaces

- `scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh`
- `scripts/check_issue3_staged_zig_toolchain_candidates.py`
- `scripts/check_issue3_build_readiness_rerun.py`
- `scripts/linux/check_issue3_zig_toolchain_match.sh`
- `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`

## When To Use It

Use this route when any of these are true:

- a run wants to know whether a staged Zig toolchain already satisfies the
  branch's expected `0.15.x` line before unpacking any archive again
- the next rerun needs the preferred staged Zig candidate and its shell exports
  on one compact helper surface
- the saved Zig archive route is visible, but the immediate slice is staged
  toolchain reuse rather than archive selection
- a run needs the exact Linux or WSL build-readiness rerun command once a
  matching staged Zig candidate exists
- issue `#11` is still tracking toolchain recovery work and this staged-toolchain
  reuse slice needs its own lower-volume branch-local route

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh
```

Use `--json` when another helper wants the route-surface result as structured
output.

## Print The Compact Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh
```

Use `--json` when another helper wants the route, staged-candidate discovery,
and rerun commands as structured output.

## Run The Helper

From the browser repo root:

```bash
python ./scripts/check_issue3_staged_zig_toolchain_candidates.py --repo-root .
```

Use `--json` when another helper wants the preferred staged candidate and its
`PATH` plus `ZIG` exports as structured output.

## Fail Fast On The Matching Line

After a preferred staged candidate is visible, prove that the staged toolchains
root really contains a branch-compatible Zig line before broader readiness is
trusted again:

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_match.sh
```

## Print The Exact Readiness Rerun

When a matching staged candidate already exists, print the exact Linux or WSL
rerun command before broader readiness is retried:

```bash
python ./scripts/check_issue3_build_readiness_rerun.py --repo-root .
```

## Working Rules

- Run the route surface check first so missing docs or helper drift fails before
  the run trusts staged-toolchain discovery output.
- Use the staged-toolchain candidate helper before saved-archive restore so a
  matching Zig `0.15.x` toolchain can be reused instead of unpacked again.
- Run the matching-line gate after staged-toolchain discovery so the branch's
  expected Zig line is proven before broader readiness is trusted.
- If no matching staged candidate exists, hand off to
  `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md` or
  `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md` instead of rebuilding restore
  commands by hand.
- When a matching staged candidate does exist, surface
  `scripts/check_issue3_build_readiness_rerun.py` before rerunning the broader
  Linux or WSL build-readiness helper.
- Keep using issue `#11` when this slice is still about saved inputs,
  toolchain recovery, or Linux or WSL readiness gates rather than the direct
  `Page.zig` plus `win32_backend.zig` runtime patch.
