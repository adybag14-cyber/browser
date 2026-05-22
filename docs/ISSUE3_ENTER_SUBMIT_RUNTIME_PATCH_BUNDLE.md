# Issue #3 Enter-Submit Runtime Patch Bundle

This branch-local patch bundle preserves the exact revalidated runtime fix for the remaining headed Google input gap on `fork/headed-mode-foundation`.

## Scope

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

## Why this file exists

The direct runtime fix is still the highest-priority lane, but some autonomous environments can only publish smaller create-only files safely. This bundle keeps the exact two-file runtime patch on the branch so the next writable checkout can apply it without depending on Memory-only artifacts.

## Revalidation status

On 2026-05-22, the live branch blob SHAs for the two target files still matched the saved patch base exactly:

- `src/browser/Page.zig`: `4baba018ca1dd351f3313c498545d71d6478a28d`
- `src/display/win32_backend.zig`: `af5afd2ab02dad63812185a4ae5cb43dd7f55eea`

That means the next writable checkout can replay the patch directly.

## Apply from a checkout rooted at `fork/headed-mode-foundation`

```bash
patch -p4 < docs/issue3-enter-submit-runtime-revalidated.patch
```

## Validation route after applying

Prefer the reduced Google fixture and the focused Win32 tests before jumping back to the real homepage:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1
.\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

## What the patch changes

- defers native Enter-submit on text-like inputs until the keypress phase in `Page.zig`
- preserves a queued pending input for Enter submit only while the focused input remains active
- replaces scalar Win32 text-input suppression counting with byte-matched queued suppressions
- keeps later real text from being dropped when stale suppression bytes no longer match
- adds focused regression coverage for the reduced Google fixture and Win32 suppression ordering
