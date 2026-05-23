# Issue #3 Restored Checkout Follow-Up

Use this helper after `scripts/linux/restore_saved_browser_snapshot.sh` has
already produced a restored checkout and the next run needs one compact answer
to a narrow question:

- is the restored checkout really present and still a browser checkout?
- if the restore used `--sync-helper-surface`, did that helper surface actually
  arrive inside the restored checkout?
- what exact saved-memory, archive-integrity, build-readiness, and runtime
  route commands should run next?

## Command

From a live helper checkout:

```bash
bash ./scripts/linux/check_issue3_restored_checkout_follow_up.sh \
  --repo-root ../browser-memory-snapshot
```

When the restore used `--sync-helper-surface`, require the synced helper surface
explicitly:

```bash
bash ./scripts/linux/check_issue3_restored_checkout_follow_up.sh \
  --repo-root ../browser-memory-snapshot \
  --expect-synced-helper-surface
```

Use `--helper-root` when the route should keep printing follow-up commands from
another live checkout, and use `--fallback-zig-archive` when the surfaced Zig
bundle is not beside the default helper root.

## What It Checks

- `build.zig.zon` exists in the restored checkout
- the live helper root still has the saved-memory, archive-integrity, Linux
  build-readiness, and runtime route helpers
- when `--expect-synced-helper-surface` is set, the restored checkout also has
  the saved-browser-snapshot note, Linux build-readiness note, runtime gate
  note, and the same core helper scripts inside the restored tree

## Why It Helps

The existing saved-browser-snapshot route explains how to restore a checkout and
how to choose the next Linux or WSL helper surface. This additive helper gives
future runs a quick post-restore guard so they can fail fast on a missing
restored tree or a partial synced helper overlay before they widen back out to
the broader build-readiness or runtime routes.
