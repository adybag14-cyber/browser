# Issue #3 Re-entry Route Stack

Use this note when a scheduled Linux or WSL run needs one compact answer to a
simple question:

Can this run reopen the blocked issue `#3` runtime lane honestly, or does it
still need more restore, archive, or toolchain preparation first?

This note does not replace the narrower route notes. It sits above them and
keeps the whole re-entry ladder on one small surface.

Read this together with:

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `scripts/linux/check_issue3_reentry_route_stack_surface.sh`
- `scripts/linux/show_issue3_reentry_route_stack.sh`

## When To Use It

Use this stack when all of these are true:

- the next run starts from Linux or WSL
- the direct `Page.zig` plus `win32_backend.zig` patch is still gated
- the run needs to decide quickly whether restore, helper sync, saved-archive
  checks, build-readiness, or Windows handoff should happen next

## Surface Check

Start with the fail-fast stack check:

```bash
bash ./scripts/linux/check_issue3_reentry_route_stack_surface.sh
```

That command verifies the branch-local notes, helper scripts, and route
printers that the stack depends on before the run burns time on restore or
toolchain staging.

## Suggested Stack

Print the route stack after the surface check passes:

```bash
bash ./scripts/linux/show_issue3_reentry_route_stack.sh
```

The printed stack keeps these steps in one order:

1. saved-browser-snapshot restore surface and restore route
2. restored-checkout surface and follow-up route
3. saved-Memory preflight
4. saved-archive-integrity surface and checksum route
5. Linux build-readiness surface and route
6. Linux runtime re-entry surface and route
7. Windows runtime handoff surface

## Working Rules

- Use this note when the problem is route selection, not when a narrower helper
  has already been chosen.
- If no reusable checkout exists yet, stop at the saved-browser-snapshot route
  before asking the build-readiness helper for anything deeper.
- If the restored checkout exists but helper drift is possible, reopen the
  restored-checkout route before trusting Linux or WSL follow-up commands.
- If the saved repo snapshot or dependency bundles are part of the path, keep
  the saved-Memory and saved-archive checks ahead of Linux or WSL readiness.
- Treat the Linux build-readiness route as the last Linux gate before the
  runtime revalidation route, not as proof that the runtime patch itself is
  ready.
- Use the Windows runtime handoff only after the Linux or WSL gates are green.
