# Lightpanda Full Use on Windows (Fork)

This fork now has:

- Runtime browser mode switch (`--browser_mode headless|headed`)
- Runtime viewport controls (`--window_width`, `--window_height`)
- CDP viewport controls (`Emulation.setDeviceMetricsOverride`, `Emulation.clearDeviceMetricsOverride`, `Browser.setWindowBounds`)

## 1) Check Windows prerequisites

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_lightpanda_windows_prereqs.ps1
```

If `SymlinkCreate` fails, enable Windows Developer Mode and reopen your shell.
Without symlink capability, Zig dependency unpacking can fail (`depot_tools`).
`DeveloperMode` can still show `FAIL` if symlink creation already works in your
current shell context.

## 2) Build options

### Pinned Zig 0.17 dev toolchain

For this branch, use the pinned Windows Zig toolchain and stable cache roots:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\invoke_zig017_build.ps1
```

The wrapper defaults to:

- Zig: `C:\Users\adyba\Downloads\zig-x86_64-windows-0.17.0-dev.305+bdfbf432d\zig.exe`
- local cache: `.zig-cache-zig017`
- global cache: `%LOCALAPPDATA%\zig-lightpanda-017`
- V8 import library: `.lp-cache-win\v8-14.0.365.4\out\windows\release\obj\zig\c_v8.lib`
- build mode: `Debug` with `-Dstrip=true`, which keeps warm debug builds fast
  without leaving hundreds of megabytes of MSVC PDBs per cache key

Keep the named Zig 0.17 caches for warm builds. Use
`scripts\windows\manage_build_artifacts.ps1` when a cold rebuild or smoke
artifact cleanup is intentional. `-CleanDefault` prunes smoke outputs, temp
logs, and old Zig 0.17 debug symbols while preserving the pinned dependency
caches.

1. Native Windows build:
- Works only when symlink creation is available in the current shell.
- Then run normal build commands (for example `zig build run -- help`).

2. WSL build (recommended fallback):
- Build and run from WSL where symlink behavior is reliable.
- Connect automation clients from Windows host to the WSL endpoint.

## 3) Runtime usage examples

CLI:

```powershell
.\lightpanda.exe serve --browser_mode headed --window_width 1366 --window_height 768 --host 127.0.0.1 --port 9222
```

Bounded Google headed smoke:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_headed_smoke.ps1
```

The smoke writes only under `tmp-browser-smoke\google-zig017`, uses an explicit
profile directory, captures one screenshot, and cleans its previous artifacts by
default to avoid repeated multi-gigabyte churn. It uses the normal Google
homepage/search flow by default; pass `-BasicSearchMode` only when debugging
Google's basic `gbv=1` fallback path. The default smoke does not click the
Google consent prompt before searching because a fresh Chrome profile can reach
result DOM with the consent overlay present; use `-AcceptConsent` only when
debugging the post-consent path.

Artifact report and cleanup:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\manage_build_artifacts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\manage_build_artifacts.ps1 -CleanSmokeArtifacts -CleanTempLogs
powershell -ExecutionPolicy Bypass -File .\scripts\windows\manage_build_artifacts.ps1 -CleanZig017DebugSymbols
```

CDP viewport override:

- `Emulation.setDeviceMetricsOverride`
- `Emulation.clearDeviceMetricsOverride`
- `Browser.setWindowBounds` with width/height

## 4) Current headed status

`headed` mode now has a native Windows window lifecycle backend:

- window open/close with page lifecycle
- native Win32 message pump on a dedicated thread
- viewport resize wiring from CLI and CDP metrics/window-bounds APIs
- native mouse (down/up/move/wheel/hwheel), click, keydown/keyup, text input (`WM_CHAR`/`WM_UNICHAR`), IME result/preedit composition messages (`WM_IME_COMPOSITION`), back/forward mouse buttons, and window blur wired into page input handling
- native key repeat state is propagated to `KeyboardEvent.repeat`
- text controls now keep insertion at the active caret/selection and support `Ctrl/Meta + A` select-all
- text controls also support word-wise keyboard editing (`Ctrl/Meta + ArrowLeft/ArrowRight`, `Ctrl/Meta + Backspace/Delete`)
- textareas now support vertical and line-aware caret movement (`ArrowUp/ArrowDown`, line-aware `Home/End`, document `Ctrl/Meta + Home/End`)
- keyboard focus traversal now supports `Tab` / `Shift+Tab` with `tabindex` ordering
- native clipboard shortcuts are wired for text controls (`Ctrl/Meta + C/X/V`, `Ctrl+Insert`, `Shift+Insert`, `Shift+Delete`)
- clipboard shortcuts dispatch cancelable `copy`/`cut`/`paste` events and respect `preventDefault()`

Graphical rendering and native input translation are still in-progress:

- frame presentation pipeline
- IME candidate/composition UI and dead-key edge cases
