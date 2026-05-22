# Headed Mode Toolchain Replay

Use this note when the current headed-mode work is blocked on local validation rather than on narrowing the runtime bug itself.

This branch already has a strong runtime breadcrumb for issue `#3` in `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`. This companion note keeps the build and replay side honest so the next run does not lose time on the wrong local toolchain or a half-staged dependency tree.

## When to reopen this note

Use this note first when any of the following happens:

- focused `zig test` commands fail in untouched files before the new regression code even runs
- the runtime slice is already narrowed to `src/browser/Page.zig` and `src/display/win32_backend.zig`
- the next run needs to rebuild the same branch from saved local dependency bundles
- the current environment only has the attached Zig `0.17.0-dev.299+a76ce7710` fallback toolchain

## Practical rule

Treat the attached Zig `0.17.0-dev.299+a76ce7710` toolchain as a fallback inspection tool, not as the default validation toolchain for this branch.

Recent replay attempts showed that the `0.17` dev fallback can fail in untouched branch files before the focused Page/Win32 issue `#3` tests even begin. When that happens, the result does not prove the runtime patch is wrong. It only proves the validation path is not aligned with the branch.

## Dependency layout to stage first

Before blaming headed-mode runtime code, stage the branch in the layout that `build.zig.zon` and the existing Windows/WSL runbooks already expect:

- keep this repository beside `../zig-v8-fork`
- keep this repository beside `../boringssl-zig`
- keep the saved offline bundles for `brotli`, `zlib`, `nghttp2`, and `curl` available to the cache or the sibling checkout rewrite path
- when using the saved local dependency archives, extract them before the first `zig build` attempt so the sibling paths already exist

## Wrong-toolchain symptoms

If the branch is being replayed with the wrong Zig path, the failure usually looks like one of these:

- import-of-file-outside-module-path errors before the focused test body is reached
- syntax or standard-library API failures in untouched files that are not part of the current headed-mode patch
- `src/browser/Page.zig` test failures that stop before the reduced Google fixture assertions run
- `src/display/win32_backend.zig` test failures that stop before the input suppression regression cases run

Treat those as toolchain or invocation problems first.

## Validation order that avoids the known dead end

When the runtime slice is already narrowed, prefer this order:

1. Reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`.
2. Stage the sibling dependency layout and any saved offline bundles.
3. Prove the branch can answer a light command such as `zig build --help` before running focused tests.
4. Use the branch-compatible build path that is already known to work in the current environment.
5. Only then rerun the focused issue `#3` checks for `src/browser/Page.zig` and `src/display/win32_backend.zig`.
6. After the focused checks agree, widen back out to the reduced Google probe and then the real Google homepage.

## Replay targets after the build path is healthy

Keep these together when issue `#3` is the active runtime lane:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`
- `src/browser/tests/page/google_home_title_probe.html`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/WINDOWS_FULL_USE.md`

Use the reduced Google probe before reopening the live homepage. If the reduced probe still shows the keydown, text, and submit phases in the wrong order, stay in the focused runtime slice instead of widening out.

## Handoff rule

If the next run has a writable checkout and a branch-compatible toolchain, reopen the exact runtime fix from `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` and keep the code change limited to `Page.zig` plus `win32_backend.zig` until the focused tests and the reduced probe agree on the same behavior.
