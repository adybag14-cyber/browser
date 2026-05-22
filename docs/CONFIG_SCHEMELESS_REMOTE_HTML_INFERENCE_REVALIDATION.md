# Config Scheme-less Remote HTML Inference Revalidation

Use this note when headed startup mode selection is narrowed back to the surviving `src/Config.zig` inference mismatch for HTML and XHTML targets.

This note keeps the confirmed live branch behavior, the intended fix shape, and the focused validation cases together so the next writable checkout can land the real `Config.zig` change without re-deriving the same startup edge cases.

Keep these nearby:

- `src/Config.zig`
- `src/main.zig`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/WINDOWS_FULL_USE.md`

## Goal

Keep headed startup inference on the right side of the local-versus-remote boundary for HTML and XHTML targets:

- bare local attached pages should still infer `browse`
- scheme-less loopback HTML and XHTML targets should still infer `browse`
- scheme-less remote HTML and XHTML targets such as `example.com/attached-page.html` should stay on the normal fetch fallback unless an explicit browse hint is present

## Confirmed live branch facts

On `fork/headed-mode-foundation`, `src/Config.zig` already handles these cases correctly:

- explicit `file://` targets infer `browse`
- local `.xhtml`, `.html`, and `.htm` paths infer `browse`
- fully qualified remote HTML targets such as `https://example.com/attached-page.html` stay on fetch
- scheme-less loopback HTML targets such as `localhost:8123/attached-page.html` infer `browse`

The surviving mismatch is narrower:

- `inferLocalBrowseTarget(...)` still returns `true` for any non-`://` token with an HTML or XHTML suffix
- that means a scheme-less remote target like `example.com/attached-page.html` still infers `browse` before the normal fetch fallback can run
- `src/main.zig` already has a richer host-classification path that separates loopback, local paths, and implicit remote hosts, so `Config.zig` is now the remaining startup surface that drifts

## Direct repro shape

These should stay on fetch when there is no explicit browse hint:

- `lightpanda example.com/attached-page.html`
- `lightpanda example.com/attached-page.xhtml#focus-probe`

These should still infer `browse`:

- `lightpanda localhost:8123/attached-page.html`
- `lightpanda 127.0.0.1:8123/attached-page.html?case=1`
- `lightpanda attached-page.xhtml`
- `lightpanda user_files\\attached-page.html`

## Narrow patch shape

Keep the change local to `src/Config.zig`.

1. Keep `trimLocalBrowseTarget(...)`.
2. Add a small HTML-suffix helper.
3. Add a small scheme-less authority classifier that:
   - extracts the leading authority before `/` or `\\`
   - strips userinfo
   - splits host from optional `:port`
   - treats `localhost`, `.localhost`, `127.x.x.x`, `0.0.0.0`, `[::1]`, and `[0:0:0:0:0:0:0:1]` as loopback
   - treats dotted domain-like authorities such as `example.com` as implicit remote
4. Change `inferLocalBrowseTarget(...)` so it only auto-browses HTML and XHTML tokens when the candidate is local or loopback, not when it is an implicit remote host.

## Focused tests to add in `src/Config.zig`

- `infer mode keeps fetch for scheme-less remote html target without browse hint`
- `infer mode keeps fetch for scheme-less remote xhtml target without browse hint`
- `infer mode keeps browse for scheme-less loopback html target`
- `infer mode keeps browse for scheme-less ipv4 loopback html target`
- keep the existing explicit headed-hint remote browse test unchanged

## Local validation completed before this note

A focused scratch Zig test mirrored the intended `inferLocalBrowseTarget(...)` behavior and the `inferModeSlice(...)` decision point.

Result:

- scheme-less remote `.html` kept `fetch`
- scheme-less remote `.xhtml` kept `fetch`
- scheme-less loopback hostname `.html` kept `browse`
- scheme-less loopback IPv4 `.html` kept `browse`
- `--headed` still forced `browse` for remote HTML

The scratch validation passed all targeted cases under the attached Zig `0.17.0-dev.299+a76ce7710` toolchain.

## Practical rule

Prefer landing the real `src/Config.zig` change from a writable checkout of `fork/headed-mode-foundation`.

If the publication path still only supports full existing-file replacement, treat this note as the re-entry point and keep the change focused to the one surviving helper plus the small test additions above.