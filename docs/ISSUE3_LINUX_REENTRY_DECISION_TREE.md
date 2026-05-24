# Issue #3 Linux Re-entry Decision Tree

Use this note when the direct issue `#3` runtime patch is still blocked from a
Linux or WSL run and the next question is not "what command exists?" but "which
route should I reopen first?"

This note stays intentionally short. It does not replace the deeper route notes.
It tells the next run which one to open, in what order, and what each answer
means before control hands back to the direct Windows runtime path.

Read this together with:

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## Start Here

If the run already has all of the following, skip to
`docs/ISSUE3_RUNTIME_REENTRY_GATES.md` and reopen the direct Windows runtime
surface instead of replaying the broader Linux staging ladder:

- a reusable checkout for the current helper surface
- the saved Memory inputs visible and preflightable
- the saved offline inputs already staged beside the workspace
- the saved Rust route already replayed or host Rust already proven equivalent
- a matching-line Zig toolchain instead of only the fallback Zig `0.17` bundle

If any of those are still false, use the decision tree below.

## Decision Tree

### 1. Is there a reusable checkout beside the workspace?

If no, print the saved-browser-snapshot route first:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

Prefer the synced helper-surface route when the restored checkout should become
its own follow-up root because the saved archive can lag the current branch
helper files:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh --sync-helper-surface
```

Then run the restored-checkout readiness helper before any saved-input preflight
or archive-integrity step:

```bash
python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface
```

If yes, continue to step 2.

### 2. Are the saved Memory inputs present and trustworthy?

Run the saved-input presence check first:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .
```

If this fails, stop and fix the missing archive or helper-surface problem before
blaming build output.

If it passes, run the exact-archive integrity check next:

```bash
python ./scripts/check_issue3_saved_archive_integrity.py --repo-root .
```

If integrity fails, reopen `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
before any offline staging or Zig retry.

If both checks pass, continue to step 3.

### 3. Are the offline sibling dependencies already staged?

If `../zig-v8-fork`, `../boringssl-zig`, or `../offline-deps` are still missing
or suspect, print the offline-inputs route:

```bash
bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh
```

Use that route before rebuilding the archive arguments by hand. It keeps the
saved-input preflight, archive-integrity check, offline restore surface check,
real restore command, and first follow-up checks on one helper surface.

If the sibling dependencies are already staged and trusted, continue to step 4.

### 4. Is Rust `1.79.0` restored on the intended path?

If `cargo` or `rustc` are missing, host-provided, or no longer aligned with the
saved route, print the saved Rust route:

```bash
bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh
```

Use that route to restore the saved Rust toolchain and reuse the printed
`PATH`, `CARGO`, and `RUSTC` exports before rerunning the broader readiness
helper.

If Rust is already restored and trusted, continue to step 5.

### 5. Is there a matching Zig line, not just the fallback Zig `0.17` archive?

If the run only sees the attached fallback Zig `0.17` bundle, or it cannot yet
prove that a staged candidate under `../toolchains` matches the branch's
expected `0.15.x` line, print the Zig recovery route:

```bash
bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
```

Use that route to decide between:

- reusing a staged matching-line Zig candidate
- staging the fallback Zig archive only as a surfaced diagnostic input
- restoring a real matching `0.15.x` archive under `../toolchains` before the
  broader readiness helper is trusted again

Do not treat Zig `0.17` failures in untouched branch files as issue `#3`
runtime evidence.

If a matching Zig line is already available, continue to step 6.

### 6. Is the broader Linux build-readiness route green?

Once the checkout, saved inputs, offline deps, Rust, and Zig line are all in
place, print the saved-archive-first Linux route:

```bash
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
```

That route is the last broad Linux or WSL gate before the next run should hand
control back to the direct Windows runtime surface.

If it still fails on environment setup, fix that first. If it passes cleanly,
continue to step 7.

### 7. Hand back to the direct Windows runtime route

After the Linux or WSL setup gates are green, stop widening the helper stack and
move back to the direct issue `#3` runtime surfaces:

```bash
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
```

And then, on the Windows side, reopen:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

That is the point where the next run should decide whether the real
`src/browser/Page.zig` plus `src/display/win32_backend.zig` patch can be landed
honestly.

## Quick Rules

- Do not reopen the large runtime files just because some Zig binary exists.
- Do not treat missing offline sibling dependencies as a source regression.
- Do not switch into a restored historical checkout and assume it already
  contains the newest helper files unless the restore used
  `--sync-helper-surface` or a later `--sync-only` refresh.
- Do not skip the saved-input presence and integrity checks when the replay is
  depending on the Memory archives.
- Prefer the smallest route that answers the current blocker, then hand back to
  the direct Windows runtime path as soon as the environment stops being the
  blocker.
