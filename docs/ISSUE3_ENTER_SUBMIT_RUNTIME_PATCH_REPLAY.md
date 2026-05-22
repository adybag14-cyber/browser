# Issue #3 Enter-Submit Runtime Patch Replay

Use this note when the direct issue `#3` headed runtime fix is ready to be
replayed from a writable checkout of `fork/headed-mode-foundation`.

This is the smallest recovery ladder for the current Google search-box failure.
It keeps the two Zig source files, the branch-side contract checker, the saved
runtime shape, and the reduced headed probe in one place so the next checkout
can move straight into patch replay and validation.

Keep these nearby:

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

## Goal

Land and validate the direct Enter-submit runtime bridge that lets headed Win32
input:

- keep typed text in the focused Google query field
- submit only after the keypress-compatible phase, not too early on native
  `keydown`
- suppress only the matching later `text_input` bytes instead of dropping later
  real text by stale counter state

## Expected starting state

On the current live branch, the contract checker should still report that the
runtime bridge is missing. That failing baseline is useful because it confirms
the checkout is still on the pre-fix side before any patch replay begins.

Run the checker self-test first:

```bash
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test
```

Then run it against the live checkout sources:

```bash
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py \
  --page src/browser/Page.zig \
  --win32 src/display/win32_backend.zig
```

Expected result before the replay:

- exit status is non-zero
- `ISSUE3_ENTER_SUBMIT_RUNTIME_CONTRACT=fail`
- the output points at the missing deferred Enter-submit or byte-matched
  suppression markers

## Replay order

1. Reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` and keep the
   target shape limited to `src/browser/Page.zig` and
   `src/display/win32_backend.zig`.
2. Apply the revalidated Page.zig and Win32 patch pair from the saved handoff
   environment when those patch files are available. If the checkout does not
   have the patch files directly, replay the exact source shape described in
   the revalidation note instead of widening the change.
3. Re-run the runtime contract checker against `Page.zig` and
   `win32_backend.zig`.
4. Only continue once the checker reports
   `ISSUE3_ENTER_SUBMIT_RUNTIME_CONTRACT=pass`.
5. If the checkout already has a branch-compatible Zig toolchain or normal
   build path, run the focused Page.zig and Win32 tests that cover:
   - `Page reduced Google fixture accepts focused keyboard text and Enter submit`
   - `Page reduced Google fixture defers native Enter submit until keypress`
   - `win32 dispatchInput suppresses matching later text_input after printable keydown across batches`
   - `win32 dispatchInput allows later real text when stale suppression bytes do not match`
   - `win32 dispatchInput suppresses matching text after stale entries drop out of order`
6. After the focused tests, use the reduced headed Google probe before jumping
   back to the real homepage:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
```

If the reduced fixture is already the chosen route, this direct browse replay
should also stay nearby:

```powershell
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

## Healthy signals

Treat the replay as healthy when all of these are true:

- the contract checker flips from `fail` to `pass`
- the focused Page.zig and Win32 regression coverage stays on the same two-file
  runtime slice
- the reduced Google title probe keeps text in the focused query field
- Enter waits until the keypress-compatible phase before the submit title
  transition appears
- stale unmatched suppression bytes no longer block later real text

## Practical rule

Prefer replaying this fix from a writable checkout instead of trying to hand
edit large existing files through a publication path that only supports full
file replacement. Keep the change tightly scoped to `Page.zig` and
`win32_backend.zig` until the reduced probe and the focused regression checks
agree on the same event ordering.
