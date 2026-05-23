from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md": """
# Headed Mode Production Execution Guide

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` when the current replay is narrowed to
  the direct issue `#3` runtime route in `src/browser/Page.zig` and
  `src/display/win32_backend.zig`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` when the current replay is
  staying on the direct issue `#3` Enter-submit runtime slice
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md` when the current replay is
  blocked on Linux or WSL dependency or toolchain staging for that same direct
  issue `#3` runtime route
- `docs/WINDOWS_FULL_USE.md`

- keep the issue `#3` direct runtime re-entry path easy to reopen from the
  top-level docs by surfacing the current gate note, runtime helper, reduced
  Google replay path, and Linux or WSL build-readiness recovery route

Issue `#3` direct runtime re-entry route:
- use `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` as the read-first note
- keep `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` nearby
- run `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
- run `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1`
""",
    "docs/HEADED_MODE_ROADMAP.md": """
# Headed Mode Roadmap (Fork)

## Validation Quick Routes

powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh

- `scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1` and `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1` are the fail-fast surface check and compact direct runtime route when issue #3 replay is already narrowed to the `Page.zig` plus `win32_backend.zig` boundary
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`, `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`, and `scripts/linux/show_issue3_linux_build_readiness_route.sh` are the read-first and fail-fast Linux or WSL surfaces when issue #3 replay is blocked on saved-archive dependency staging or toolchain readiness before the Windows runtime route can resume
""",
    "docs/WINDOWS_FULL_USE.md": """
# Lightpanda Full Use on Windows (Fork)

Use the dedicated Google form-controls Enter-order route after the shared input
probes when issue #3 is already narrowed to the smallest real-surface
Enter-submit checkpoint.

powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1 -GoogleEnterOrder
powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus

What exists today:

- a dedicated Google form-controls Enter-order gate surfaced through `scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order`
- a broader shared Enter-order ladder surfaced through `scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order`
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `scripts/check_linux_build_readiness.py`

### Gate 1: Writable publication path

- a writable checkout of `fork/headed-mode-foundation` is available

### Gate 2: Branch-compatible validation toolchain

```bash
bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
```
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
# Issue #3 Enter-Submit Runtime Revalidation

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`

## Target `Page.zig` slice

## Target `win32_backend.zig` slice

## Focused regression coverage

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1
```

```powershell
.\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```
""",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r"""
$route = [ordered]@{
    read_first = @(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    )
    target_files = @(
        "src/browser/Page.zig",
        "src/display/win32_backend.zig"
    )
    commands = [ordered]@{
        surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        contract_check = "python checker --page Page.zig --win32 win32_backend.zig"
        contract_self_test = "python checker --self-test"
        linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
        linux_build_readiness = $linuxBuildReadinessFullCommand
        shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1"
        reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"
        reduced_google_fixture = "& `"$resolvedBrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1`""
        live_google = "& `"$resolvedBrowserExe`" browse --headed --window_width 1366 --window_height 900 `"https://www.google.com/`""
    }
    expected_signals = @(
        "Stale queued suppression entries do not drop real later text_input bytes."
    )
}

Write-Host ("  Shared click-first route:   {0}" -f $route.commands.shared_enter_google_click)
""",
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": r"""
$references = @(
    (New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Kind "file" -Purpose "Branch-local gate note for deciding whether the direct issue #3 runtime patch can be reopened honestly."),
    (New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file" -Purpose "Branch-local runtime-first note for the issue #3 Enter-submit revalidation slice."),
    (New-ValidationReference -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Kind "file" -Purpose "Top-level execution guide that should stay aligned with the runtime revalidation route."),
    (New-ValidationReference -Path "docs/HEADED_MODE_ROADMAP.md" -Kind "file" -Purpose "Top-level roadmap that should keep the direct runtime re-entry helper visible from the validation quick routes."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows runbook that should stay nearby when replay widens back out from the runtime-only route."),
    (New-ValidationReference -Path "src/browser/Page.zig" -Kind "file" -Purpose "Browser-side target for deferred native Enter submit handling."),
    (New-ValidationReference -Path "src/display/win32_backend.zig" -Kind "file" -Purpose "Win32 backend target for queued text-input suppression matching and deferred Enter ordering."),
    (New-ValidationReference -Path "scripts/check_linux_build_readiness.py" -Kind "file" -Purpose "Branch-compatible build-readiness helper referenced by the runtime re-entry gates note."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Kind "file" -Purpose "Helper that prints the gated Windows-first Enter-submit runtime route."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Shared Enter-submit probe ladder used before the reduced Google fixture."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py" -Kind "file" -Purpose "Source-based checker for the direct Page.zig and win32_backend.zig runtime bridge markers."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1" -Kind "file" -Purpose "Reduced Google title probe used before reopening live Google."),
    (New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "Reduced Google fixture referenced by the runtime revalidation route.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Purpose "The gate note keeps the runtime revalidation note in the required re-entry order."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_enter_submit_runtime_contract.py" -Purpose "The gate note keeps the source-based runtime contract checker visible before replay widens."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/check_linux_build_readiness.py" -Purpose "The gate note keeps the build-readiness helper visible before focused Zig output is trusted."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "The production guide keeps the fail-fast runtime surface checker visible from the direct issue #3 re-entry route."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "The production guide keeps the compact runtime revalidation helper visible from the direct issue #3 re-entry route."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "The roadmap quick routes keep the fail-fast runtime surface checker visible before the direct issue #3 route widens."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "The roadmap quick routes keep the compact runtime revalidation helper visible before the direct issue #3 route widens."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "src/browser/Page.zig" -Purpose "The runtime revalidation note keeps Page.zig named as a direct target."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "src/display/win32_backend.zig" -Purpose "The runtime revalidation note keeps win32_backend.zig named as a direct target."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "chrome-google-home-title-probe.ps1" -Purpose "The runtime revalidation note keeps the focused Google title probe visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "google_home_title_probe.html?google-home-probe=1" -Purpose "The runtime revalidation note keeps the reduced Google fixture replay command visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Target `Page.zig` slice" -Purpose "The runtime revalidation note keeps the Page.zig work boundary explicit."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Target `win32_backend.zig` slice" -Purpose "The runtime revalidation note keeps the Win32 backend work boundary explicit."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Focused regression coverage" -Purpose "The runtime revalidation note keeps the narrow regression expectations visible."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet "google-form-controls-enter-order" -Purpose "Windows guide still surfaces the Google-shaped Enter-order route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"' -Purpose "The helper points directly at the runtime re-entry gates note."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"' -Purpose "The helper keeps the runtime revalidation note on the same read-first surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand' -Purpose "The helper prints the light preflight build-readiness command before focused Zig output is trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_build_readiness = $linuxBuildReadinessFullCommand' -Purpose "The helper prints the full build-readiness command for the re-entry gate."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"' -Purpose "The helper exposes the fail-fast surface checker before the runtime replay commands."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"' -Purpose "The helper keeps the shared click-first Enter-order route visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"' -Purpose "The helper prints the focused Google title probe command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "google_home_title_probe.html?google-home-probe=1" -Purpose "The helper prints the reduced Google fixture replay command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Stale queued suppression entries do not drop real later text_input bytes." -Purpose "The helper keeps the stale-suppression success signal visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Shared click-first route:" -Purpose "The helper output prints the click-first Google ordering route.")
)
""",
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should stay read-first before the direct runtime route is reopened."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note that should keep the Page.zig and win32_backend.zig target narrow."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux or WSL build-readiness companion used when the direct runtime route is blocked on toolchain staging."
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|Fail-fast Linux or WSL surface checker for the direct issue #3 runtime route."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Compact Linux or WSL route printer for the direct issue #3 runtime lane."
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Fail-fast Linux build-readiness checker used before offline staging is blamed on source changes."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer used before focused Zig output is trusted."
    "scripts/check_linux_build_readiness.py|file|Branch-local build-readiness helper used by the Linux or WSL recovery route."
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py|file|Source-based checker for the direct Page.zig and win32_backend.zig runtime bridge markers."
)

CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|The gate note keeps the Linux or WSL runtime surface checker visible before the direct runtime patch is reopened."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|The gate note keeps the compact Linux or WSL runtime helper visible before the direct runtime patch is reopened."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_contract.py|The Linux or WSL runtime helper prints the source-based runtime contract check."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_linux_build_readiness_route_surface.sh|The Linux or WSL runtime helper keeps the build-readiness surface check visible before focused Zig output is trusted."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_linux_build_readiness_route.sh|The Linux or WSL runtime helper keeps the build-readiness route printer visible when the toolchain gate is still closed."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|chrome-google-home-title-probe.ps1|The Linux or WSL runtime helper still prints the reduced Google Windows follow-up probe."
)
""",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": r"""
SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh --repo-root ${REPO_ROOT}"
CONTRACT_CHECK_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --page ${PAGE_SOURCE_PATH} --win32 ${WIN32_SOURCE_PATH}"
CONTRACT_SELF_TEST_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --self-test"
LINUX_BUILD_SURFACE_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root ${REPO_ROOT}"
LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${REPO_ROOT}"
LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check"
LINUX_BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT}"
FOCUSED_PAGE_TESTS_COMMAND="zig test src/browser/Page.zig"
FOCUSED_WIN32_TESTS_COMMAND="zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
WINDOWS_BUILD_COMMAND="zig build -Dtarget=x86_64-windows-msvc --summary all"
REDUCED_GOOGLE_PROBE_COMMAND="powershell -ExecutionPolicy Bypass -File ./tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
REDUCED_GOOGLE_FIXTURE_COMMAND="${BROWSER_EXE} browse --headed --window_width 1366 --window_height 900 http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"
LIVE_GOOGLE_COMMAND="${BROWSER_EXE} browse --headed --window_width 1366 --window_height 900 https://www.google.com/"

docs/ISSUE3_RUNTIME_REENTRY_GATES.md
docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
src/browser/Page.zig
src/display/win32_backend.zig

Run surface_check first when the branch may have moved and you want the direct issue #3 docs and helper surfaces checked before replay.
Run contract_check before build or replay when you need a thin source-based yes-or-no answer about whether the Page.zig and win32_backend.zig bridge markers are present on the current branch.
If the toolchain gate is still closed, run linux_build_surface and then linux_build_route before treating focused Zig output as issue-specific evidence.
After the Linux or WSL gates turn green, move back to the Windows build and reduced Google probe before widening to live Google.
""",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": """
PAGE_REQUIRED_MARKERS = (
    "_defer_native_text_input_enter_submit: bool = false",
    "_pending_native_enter_submit: ?*Element.Html.Input = null",
    "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
)

WIN32_REQUIRED_MARKERS = (
    "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
    "page.beginDeferredNativeTextInputEnterSubmit();",
    "try page.applyDeferredNativeTextInputEnterSubmit();",
    "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
)

PAGE_TEST_MARKERS = (
    'test "Page reduced Google fixture defers native Enter submit until keypress" {',
    "page.beginDeferredNativeTextInputEnterSubmit();",
    "try page.applyDeferredNativeTextInputEnterSubmit();",
)

WIN32_TEST_MARKERS = (
    'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
    'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
)

VULNERABLE_PAGE = "submitCurrentInput"
GUARDED_PAGE = "Page reduced Google fixture defers native Enter submit until keypress"
VULNERABLE_WIN32 = "pending_text_input_suppressions: u32 = 0"
GUARDED_WIN32 = "win32 dispatchInput allows later real text when stale suppression bytes do not match"
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
""",
    "scripts/check_linux_build_readiness.py": """
def build_parser():
    parser.add_argument("--skip-zig-check")
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": """
param(
    [switch]$GoogleEnterOrder,
    [switch]$ClickFocus
)
""",
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1": """
$probe = "google-home-title"
""",
    "src/browser/Page.zig": """
pub fn page() void {}
""",
    "src/display/win32_backend.zig": """
pub fn backend() void {}
""",
    "src/browser/tests/page/google_home_title_probe.html": """
<!doctype html>
<title>probe</title>
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-runtime-reentry-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3RuntimeReentryGatesSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.production_guide = read_text(
            cls.repo_root / "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md"
        )
        cls.roadmap = read_text(cls.repo_root / "docs/HEADED_MODE_ROADMAP.md")
        cls.windows_full_use = read_text(cls.repo_root / "docs/WINDOWS_FULL_USE.md")
        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.runtime_note = read_text(
            cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )
        cls.windows_route = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        cls.windows_surface = read_text(
            cls.repo_root
            / "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )
        cls.linux_surface = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
        )
        cls.linux_route = read_text(
            cls.repo_root
            / "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
        )
        cls.runtime_contract = read_text(
            cls.repo_root
            / "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
        )

    def test_top_level_docs_keep_direct_runtime_reentry_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        ):
            self.assertIn(fragment, self.production_guide)

        for fragment in (
            "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "check_issue3_linux_build_readiness_route_surface.sh",
            "show_issue3_linux_build_readiness_route.sh",
        ):
            self.assertIn(fragment, self.roadmap)

    def test_runtime_gate_note_keeps_windows_and_linux_reentry_surfaces_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
            "scripts/check_linux_build_readiness.py",
            "Gate 1: Writable publication path",
            "Gate 2: Branch-compatible validation toolchain",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_runtime_revalidation_note_keeps_the_narrow_issue3_target(self) -> None:
        for fragment in (
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "chrome-google-home-title-probe.ps1",
            "Target `Page.zig` slice",
            "Target `win32_backend.zig` slice",
            "Focused regression coverage",
            "google_home_title_probe.html?google-home-probe=1",
        ):
            self.assertIn(fragment, self.runtime_note)

    def test_windows_route_helper_keeps_contract_build_readiness_and_probe_ladder(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"src/browser/Page.zig"',
            '"src/display/win32_backend.zig"',
            'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            'contract_check = "python checker --page Page.zig --win32 win32_backend.zig"',
            'contract_self_test = "python checker --self-test"',
            "linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand",
            "linux_build_readiness = $linuxBuildReadinessFullCommand",
            'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"',
            'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"',
            "google_home_title_probe.html?google-home-probe=1",
            "Stale queued suppression entries do not drop real later text_input bytes.",
            "Shared click-first route:",
        ):
            self.assertIn(fragment, self.windows_route)

    def test_windows_surface_checker_keeps_reference_and_content_expectations(self) -> None:
        for fragment in (
            'New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            'New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            'New-ValidationReference -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md"',
            'New-ValidationReference -Path "docs/HEADED_MODE_ROADMAP.md"',
            'New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md"',
            'New-ValidationReference -Path "src/browser/Page.zig"',
            'New-ValidationReference -Path "src/display/win32_backend.zig"',
            'New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"',
            'New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            'New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_enter_submit_runtime_contract.py"',
            'New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            'New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1"',
            'New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet "google-form-controls-enter-order"',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Stale queued suppression entries do not drop real later text_input bytes."',
        ):
            self.assertIn(fragment, self.windows_surface)

    def test_linux_runtime_surface_and_route_keep_the_same_issue3_lane(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|',
            '"tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py|file|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_contract.py|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_linux_build_readiness_route_surface.sh|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_linux_build_readiness_route.sh|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|chrome-google-home-title-probe.ps1|',
        ):
            self.assertIn(fragment, self.linux_surface)

        for fragment in (
            "SURFACE_CHECK_COMMAND",
            "CONTRACT_CHECK_COMMAND",
            "CONTRACT_SELF_TEST_COMMAND",
            "LINUX_BUILD_SURFACE_COMMAND",
            "LINUX_BUILD_ROUTE_COMMAND",
            "LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND",
            "LINUX_BUILD_READINESS_COMMAND",
            "FOCUSED_PAGE_TESTS_COMMAND",
            "FOCUSED_WIN32_TESTS_COMMAND",
            "WINDOWS_BUILD_COMMAND",
            "REDUCED_GOOGLE_PROBE_COMMAND",
            "REDUCED_GOOGLE_FIXTURE_COMMAND",
            "LIVE_GOOGLE_COMMAND",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "Run surface_check first",
            "Run contract_check before build or replay",
            "After the Linux or WSL gates turn green",
        ):
            self.assertIn(fragment, self.linux_route)

    def test_runtime_contract_checker_keeps_bridge_markers_and_regression_markers(self) -> None:
        for fragment in (
            "_defer_native_text_input_enter_submit: bool = false",
            "_pending_native_enter_submit: ?*Element.Html.Input = null",
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            "page.beginDeferredNativeTextInputEnterSubmit();",
            "try page.applyDeferredNativeTextInputEnterSubmit();",
            'test "Page reduced Google fixture defers native Enter submit until keypress" {',
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
            "VULNERABLE_PAGE",
            "GUARDED_PAGE",
            "VULNERABLE_WIN32",
            "GUARDED_WIN32",
        ):
            self.assertIn(fragment, self.runtime_contract)

    def test_windows_full_use_keeps_google_enter_order_ladder_visible(self) -> None:
        for fragment in (
            "google-form-controls-enter-order",
            "google-shared-enter-order",
            "enter-submit-probe.ps1 -GoogleEnterOrder",
            "enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus",
        ):
            self.assertIn(fragment, self.windows_full_use)


if __name__ == "__main__":
    unittest.main()
