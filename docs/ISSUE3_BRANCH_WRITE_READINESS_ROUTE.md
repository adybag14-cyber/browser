# Issue #3 Branch-Write Readiness Route

Use this note before reopening the direct issue `#3` runtime patch in:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

This route turns the publication gate from `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
into one quick preflight. Its goal is simple: answer whether the current
checkout can safely carry a real branch commit for the narrowed headed Google
Enter-submit fix.

Keep these nearby:

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `scripts/check_issue3_branch_write_readiness.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`

## When To Use It

Use this route when all of these are true:

- the next intended change still targets `Page.zig` plus `win32_backend.zig`
- the remaining question is whether the current environment can publish those
  two large existing-file edits safely
- the run needs a fast yes-or-no answer before touching the runtime patch again

## Quick Check

From a local checkout of `fork/headed-mode-foundation`, run:

```bash
python scripts/check_issue3_branch_write_readiness.py --repo-root .
```

If you need structured output for automation or a tighter branch assertion, run:

```bash
python scripts/check_issue3_branch_write_readiness.py \
  --repo-root . \
  --expect-branch fork/headed-mode-foundation \
  --json
```

## What The Helper Checks

The helper does not pretend to prove every possible GitHub write route. It gives
the branch-local signals that matter most before the direct issue `#3` patch is
reopened:

- the repo root still looks like a browser checkout
- the two target files still exist in that checkout
- the checkout is a real git worktree
- the current branch name is visible
- at least one remote is configured
- `gh` is either unavailable, unauthenticated, or authenticated
- a `GITHUB_TOKEN`-style environment hint is either absent or present

Those signals are enough to separate three practical states:

- `ready`: the checkout is present, the target files exist, the branch matches
  the expected headed-mode branch, and there is at least one plausible branch
  write signal
- `partial`: the checkout is real and the target files are present, but the
  write path still needs confirmation before large-file edits are attempted
- `blocked`: the current environment still should not reopen `Page.zig` and
  `win32_backend.zig`

## Recommended Re-entry Order

1. Run the branch-write readiness helper first.
2. If the helper returns `blocked`, stay off the direct runtime patch.
3. If the helper returns `partial`, verify the actual branch-write method before
   editing large existing files.
4. Only when the helper returns `ready`, move back to:

```bash
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py \
  --page src/browser/Page.zig \
  --win32 src/display/win32_backend.zig
```

5. Then continue with the narrowed re-entry path from
   `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` and
   `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`.

## If The Helper Says `blocked`

Treat the publication gate as still closed and do one of these instead:

- restore or sync a reusable checkout first with
  `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- keep working on build-readiness or validation helpers
- save the next runtime patch attempt for a checkout that can actually commit

## Working Rule

Do not reopen the direct issue `#3` runtime patch just because the source diff
is ready. Reopen it only when the checkout and publication path are ready too.
