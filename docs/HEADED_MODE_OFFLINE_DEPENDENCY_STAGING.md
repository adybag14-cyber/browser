# Headed Mode Offline Dependency Staging

Use this note when a Linux or WSL headed-mode run needs to build or validate the
`fork/headed-mode-foundation` branch without assuming fresh network access or a
fully pre-staged sibling workspace.

This runbook is intentionally narrow. Its job is to keep future runs from
misclassifying missing dependency setup or an incompatible Zig toolchain as a
headed-mode source regression.

Keep these nearby:

- `build.zig.zon`
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` when the replay is already
  narrowed to the Google Enter-submit runtime slice

## Branch baseline

The branch currently declares this minimum Zig version in `build.zig.zon`:

- `0.15.2`

Practical rule:

- treat Zig `0.15.2` as the first-choice validation baseline for Linux or WSL
  build work on this fork
- treat the attached `0.17.0-dev.299` toolchain only as a fallback diagnostic
  tool unless the same slice already proved itself under the branch-compatible
  baseline
- if Zig `0.17.x` fails in untouched branch files before your focused change is
  even exercised, do not treat that by itself as proof that the headed-mode
  source regressed

## Saved archive set for headed-mode runs

When the work is being restored from the saved headed-mode archive bundle, the
known local inputs are:

- browser repo snapshot:
  - `01-browser-fork-headed-mode-foundation.zip`
- dependency archives:
  - `dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz`
  - `dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip`
  - `dependencies/03-boringssl-zig-main.zip`
  - `dependencies/04-zig-browser-depo.tar.zip`

Use those exact files first before reaching for remote downloads.

## Required sibling layout

`build.zig.zon` expects these sibling paths to exist next to the browser repo:

- `../zig-v8-fork`
- `../boringssl-zig`

A working parent layout looks like this:

```text
<work-parent>/
  browser/
  zig-v8-fork/
  boringssl-zig/
  deps-cache/
```

The browser checkout can have any folder name, but `zig-v8-fork` and
`boringssl-zig` need to exist as real sibling directories.

## Restore order

Use this order before the first Linux or WSL build retry:

1. Extract the browser snapshot into a writable checkout.
2. Extract `03-boringssl-zig-main.zip` so the sibling directory is named
   `boringssl-zig`.
3. Extract `04-zig-browser-depo.tar.zip` so the sibling directory
   `zig-v8-fork` exists.
4. Keep the `02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip`
   bundle nearby for staged Rust/html5ever dependencies and the saved third-
   party tarballs.
5. Keep the Rust `1.79.0` archive nearby when the local environment does not
   already provide a working Rust toolchain for the html5ever build steps.

## Failure classification before source edits

Treat these as setup failures first:

- missing `../zig-v8-fork`
- missing `../boringssl-zig`
- `403` fetch failures for `brotli`, `zlib`, `nghttp2`, or `curl`
- a Zig `0.17.x` parser or API failure in untouched branch files before the
  focused validation target runs

Treat these as stronger signals that source debugging may be warranted:

- the sibling paths exist
- the branch-compatible Zig baseline is in use
- the build has been retried with explicit cache dirs
- the failure now points at the focused headed-mode slice rather than unrelated
  untouched files

## Recommended first commands

From the browser checkout:

```bash
zig version
zig build --help
zig build test --summary all \
  --cache-dir .zig-cache-recover \
  --global-cache-dir .zig-global-cache-recover
```

If the run is validating only a narrower slice, keep the same cache-dir pattern
for the first focused retry so the failure surface stays easy to compare.

## Offline dependency rule

`build.zig.zon` still points `brotli`, `zlib`, `nghttp2`, and `curl` at GitHub
URLs. That means a Linux or WSL run can still fail even when the source tree is
fine if those package fetches have not already been satisfied offline.

Practical rule:

- treat missing third-party package fetches as dependency staging work first
- only move to headed-mode source debugging after the sibling layout exists and
  the offline package/cache path has been retried

## When issue #3 is the active target

If the current goal is the Google Enter-submit runtime fix, use this runbook to
stage the checkout first and then reopen:

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`

That keeps the setup boundary separate from the actual runtime boundary in
`src/browser/Page.zig` and `src/display/win32_backend.zig`.

## Exit condition for this runbook

Do not say the branch is blocked on headed-mode source alone until all of these
are true:

- the sibling dependency layout exists
- the saved archive set has been staged or consciously ruled out
- the Zig baseline has been checked against the branch minimum
- the first explicit-cache build retry has been attempted

Only after that should the run switch from dependency staging into source-level
headed-mode debugging.