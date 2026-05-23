# Issue #3 Restored Checkout Reuse Route

Use this note when `../browser-memory-snapshot` already exists and the next run
should decide whether that restored checkout can be reused directly, reused with
the live helper root, or refreshed with `--sync-helper-surface`.

This route keeps the already-restored checkout path small so future Linux or
WSL runs do not have to reopen the broader saved-snapshot restore note when the
archive extraction step is no longer the main question.

Companion helpers:

- `scripts/linux/check_issue3_restored_checkout_surface.sh`
- `scripts/linux/show_issue3_restored_checkout_route.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when any of these are true:

- `../browser-memory-snapshot` already exists beside the workspace and the next
  run wants the smallest truthful follow-up surface
- a restored checkout already contains the core `Page.zig` and
  `win32_backend.zig` issue `#3` files, but it is not obvious whether the
  current helper surface also exists there
- the next run wants to avoid a full restore replay unless the existing
  checkout is genuinely stale or incomplete

## Surface Check

From the live browser repo root:

```bash
bash ./scripts/linux/check_issue3_restored_checkout_surface.sh
bash ./scripts/linux/show_issue3_restored_checkout_route.sh
```

The surface checker reports whether the restored checkout still has the core
runtime files and whether follow-up helpers should run from the restored
checkout itself or from the live helper root.

The route helper prints the smallest next-step command list for the current
state:

- self-contained restored checkout
- restored checkout plus live helper root
- or refresh-required restore path

Use `--json` when another helper needs the reuse route as structured output.
Use `--restored-root /path/to/checkout` when the reusable checkout lives
somewhere other than `../browser-memory-snapshot`.

## Ready Follow-up

When the restored checkout is already usable, keep the route tight:

```bash
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

If the restored checkout still lacks the newer helper surface but the live repo
root has it, the route helper will instead keep those commands anchored to the
live helper root while still targeting `../browser-memory-snapshot` as
`--repo-root`.

## Refresh To Self-Contained

When the restored checkout already has the runtime files but should be upgraded
into a self-contained follow-up root, refresh it with the current helper
surface:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --destination ../browser-memory-snapshot --sync-helper-surface --check-only
bash ./scripts/linux/restore_saved_browser_snapshot.sh --destination ../browser-memory-snapshot --sync-helper-surface --force
```

That path is useful when the saved archive snapshot is still valid for the core
runtime files, but the branch-local helper docs and route printers have moved
forward since the archive was created.

## Working Rules

- Prefer this reuse route once a restored checkout already exists.
- Reopen the broader saved-browser-snapshot restore note only when the checkout
  is missing, incomplete, or needs a full refresh.
- Keep the live helper root as the command surface when the restored checkout is
  older than the current helper ladder.
- Use the self-contained refresh when the next Linux or WSL run should stay
  inside the restored checkout after the helper surface is copied in.
