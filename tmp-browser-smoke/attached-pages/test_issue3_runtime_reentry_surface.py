from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`

## The Two Hard Gates

### Gate 1: Writable publication path

- a writable checkout of `fork/headed-mode-foundation` is available

### Gate 2: Branch-compatible validation toolchain

```bash
python scripts/check_issue3_saved_memory_inputs.py --repo-root .
bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
```
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
# Issue #3 Enter-Submit Runtime Revalidation

## Current runtime gap

- `Page.zig` still needs a way to defer native text-input Enter submit until keypress-time DOM behavior has had a chance to run.
- `win32_backend.zig` still needs to suppress only the matching later `text_input` bytes that correspond to a just-handled printable keydown.

## Target `Page.zig` slice

- `_defer_native_text_input_enter_submit: bool`
- `_pending_native_enter_submit: ?*Element.Html.Input`

## Target `win32_backend.zig` slice

- replace the scalar `pending_text_input_suppressions` counter with a queued `std.ArrayListUnmanaged(TextInputEvent)`

## Focused regression coverage

- focused reduced Google fixture accepts keyboard text and Enter submit
- reduced Google fixture defers native Enter submit until keypress
- matching later `text_input` is suppressed after printable keydown across batches
- later real text still lands when stale suppression bytes do not match

```powershell
powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1
.\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

Recent scheduled reruns confirmed that the runtime slice still narrows cleanly, but the fallback Linux validation path has two non-issue-specific traps:

- `zig test src/browser/Page.zig -O Debug` under the attached Zig `0.17.0-dev.299` fallback hits broader module-path and branch/toolchain compatibility errors before the issue-specific assertions run
- `zig test src/display/win32_backend.zig -O Debug` under the same fallback hits the known preexisting Zig 0.17 syntax drift in untouched code before the focused suppression tests run
""",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r"""
$runtimeContractCheckerPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke\google-investigation-next\check_issue3_enter_submit_runtime_contract.py"
$pageSourcePath = Join-Path $resolvedRepoRoot "src\browser\Page.zig"
$win32SourcePath = Join-Path $resolvedRepoRoot "src\display\win32_backend.zig"
$linuxBuildReadinessScriptPath = Join-Path $resolvedRepoRoot "scripts\check_linux_build_readiness.py"

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
        contract_check = "python"
        contract_self_test = "python"
        linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
        linux_build_readiness = $linuxBuildReadinessFullCommand
        shared_enter_default = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1"
        shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("DeferredEnter")
        shared_enter_google = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder")
        shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder", "ClickFocus")
        reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"
        reduced_google_fixture = "& ``"$resolvedBrowserExe``" browse --headed --window_width 1366 --window_height 900 ``"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1``""
        live_google = "& ``"$resolvedBrowserExe``" browse --headed --window_width 1366 --window_height 900 ``"https://www.google.com/``""
    }
    expected_signals = @(
        "Printable keydown and keypress leave text in the focused Google query input.",
        "Enter keydown alone does not force an early submit transition.",
        "Enter submit happens only after the later keypress-time DOM phase.",
        "Stale queued suppression entries do not drop real later text_input bytes."
    )
    notes = @(
        "Run surface_check first",
        "Run contract_check before build or replay",
        "Use linux_build_readiness_skip_zig",
        "Use shared_enter_google_click when reproducing the click-first path",
        "Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig"
    )
}
Write-Host "Shared click-first route:"
""",
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": r"""
(New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Kind "file" -Purpose "Branch-local gate note")
(New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file" -Purpose "Branch-local runtime-first note")
(New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Kind "file" -Purpose "Helper that prints the gated Windows-first Enter-submit runtime route.")
(New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Shared Enter-submit probe ladder used before the reduced Google fixture.")
(New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py" -Kind "file" -Purpose "Source-based checker for the direct Page.zig and win32_backend.zig runtime bridge markers.")
(New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "Reduced Google fixture referenced by the runtime revalidation route.")
(New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Purpose "The gate note keeps the runtime revalidation note in the required re-entry order.")
(New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_enter_submit_runtime_contract.py" -Purpose "The gate note keeps the source-based runtime contract checker visible before replay widens.")
(New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Shared click-first route:" -Purpose "The helper output prints the click-first Google ordering route.")
(New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "google_home_title_probe.html?google-home-probe=1" -Purpose "The helper prints the reduced Google fixture replay command.")
""",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": """
PAGE_REQUIRED_MARKERS = (
    "_defer_native_text_input_enter_submit: bool = false",
    "_pending_native_enter_submit: ?*Element.Html.Input = null",
    "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
)
WIN32_REQUIRED_MARKERS = (
    "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
    "const defer_enter_submit = std.mem.eql(u8, key, \"Enter\");",
    "page.beginDeferredNativeTextInputEnterSubmit();",
    "page.endDeferredNativeTextInputEnterSubmit();",
    "if (defer_enter_submit and allow_text_input) {",
    "try page.applyDeferredNativeTextInputEnterSubmit();",
    "fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void {",
    "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
)
PAGE_TEST_MARKERS = (
    'test "Page reduced Google fixture defers native Enter submit until keypress" {',
)
WIN32_TEST_MARKERS = (
    'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
    'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
)
VULNERABLE_PAGE = "submitCurrentInput"
GUARDED_PAGE = "page.beginDeferredNativeTextInputEnterSubmit();\\ntry page.applyDeferredNativeTextInputEnterSubmit();"
VULNERABLE_WIN32 = "pending_text_input_suppressions: u32 = 0"
GUARDED_WIN32 = "self.pending_text_input_suppressions.clearRetainingCapacity();\\ncontinue;"
def run_self_test(json_output: bool) -> int:
    return 0
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
param(
  [switch]$DeferredEnter,
  [switch]$GoogleEnterOrder,
  [switch]$ClickFocus
)

if ($DeferredEnter -and $GoogleEnterOrder) {
  throw "Choose at most one specialized enter-submit mode."
}

if ($ClickFocus -and -not $GoogleEnterOrder) {
  throw "ClickFocus currently supports only -GoogleEnterOrder."
}

$probeMode = if ($GoogleEnterOrder) {
  "google-enter-order"
} elseif ($DeferredEnter) {
  "deferred-enter"
} else {
  "default-enter"
}

$googleServerPattern = "GOOGLE_ENTER_SUBMIT"
$expectedGoogleSelection = "{0}-{0}" -f $InputText.Length
$googleSubmitPhase = $null
$googleActiveName = $null
$googleActiveId = $null
$googleSelection = $null
$googleEventLog = $null
""",
    "src/browser/tests/page/google_home_title_probe.html": """
document.addEventListener('keydown',function(e){window.__lpEarlyEvents.push('KD:'+[(e.key||''),(e.code||''),e.keyCode,e.which,e.defaultPrevented?1:0].join('|'));},true);
document.addEventListener('keypress',function(e){window.__lpEarlyEvents.push('KP:'+[(e.key||''),(e.code||''),e.keyCode,e.which,e.charCode,e.defaultPrevented?1:0].join('|'));},true);
document.addEventListener('beforeinput',function(e){window.__lpEarlyEvents.push('BI:'+[(e.data||''),e.defaultPrevented?1:0].join('|'));},true);
document.addEventListener('input',function(e){var t=e.target;window.__lpEarlyEvents.push('IN:'+[(t&&t.value)||'',e.defaultPrevented?1:0].join('|'));},true);
q.addEventListener('focus', function(){ mark('FOCUSED'); });
q.addEventListener('input', function(){ mark('TYPED:' + q.value); });
mark('KEYPRESS:' + (e.key || '') + ':' + q.value);
mark('KEYDOWN:' + q.value + ':' + e.keyCode + ':' + e.which);
q.form.addEventListener('submit', function(e){
  e.preventDefault();
  mark('SUBMIT:' + q.value);
});
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-runtime-reentry-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3RuntimeReentrySurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.runtime_note = read_text(
            cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )
        cls.route_helper = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )
        cls.contract_checker = read_text(
            cls.repo_root
            / "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
        )
        cls.enter_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1"
        )
        cls.google_fixture = read_text(
            cls.repo_root / "src/browser/tests/page/google_home_title_probe.html"
        )

    def test_runtime_gates_keep_publication_toolchain_and_saved_input_route(self) -> None:
        for fragment in (
            "## The Two Hard Gates",
            "### Gate 1: Writable publication path",
            "### Gate 2: Branch-compatible validation toolchain",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "check_issue3_enter_submit_runtime_contract.py",
            "scripts/check_issue3_saved_memory_inputs.py --repo-root .",
            "check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "check_linux_build_readiness.py --repo-root . --skip-zig-check",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_runtime_note_keeps_narrow_page_win32_and_probe_contract(self) -> None:
        for fragment in (
            "Page.zig` still needs a way to defer native text-input Enter submit",
            "win32_backend.zig` still needs to suppress only the matching later `text_input` bytes",
            "_defer_native_text_input_enter_submit: bool",
            "_pending_native_enter_submit: ?*Element.Html.Input",
            "std.ArrayListUnmanaged(TextInputEvent)",
            "## Focused regression coverage",
            "reduced Google fixture defers native Enter submit until keypress",
            "later real text still lands when stale suppression bytes do not match",
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html?google-home-probe=1",
            "attached Zig `0.17.0-dev.299` fallback",
        ):
            self.assertIn(fragment, self.runtime_note)

    def test_route_helper_keeps_read_first_commands_and_expected_signals(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"src/browser/Page.zig"',
            '"src/display/win32_backend.zig"',
            'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            "linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand",
            "linux_build_readiness = $linuxBuildReadinessFullCommand",
            'shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1" -Switches @("DeferredEnter")',
            'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder", "ClickFocus")',
            'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"',
            "google_home_title_probe.html?google-home-probe=1",
            "https://www.google.com/",
            "Stale queued suppression entries do not drop real later text_input bytes.",
            "Run surface_check first",
            "Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig",
            'Write-Host "Shared click-first route:"',
        ):
            self.assertIn(fragment, self.route_helper)

    def test_surface_checker_keeps_route_and_fixture_alignment_expectations(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Kind "file"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file"',
            '"scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Kind "file"',
            '"tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file"',
            '"tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py" -Kind "file"',
            '"src/browser/tests/page/google_home_title_probe.html" -Kind "file"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"check_issue3_enter_submit_runtime_contract.py"',
            '"Shared click-first route:"',
            '"google_home_title_probe.html?google-home-probe=1"',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_contract_checker_keeps_bridge_markers_and_self_test_shapes(self) -> None:
        for fragment in (
            "PAGE_REQUIRED_MARKERS",
            "_defer_native_text_input_enter_submit: bool = false",
            "_pending_native_enter_submit: ?*Element.Html.Input = null",
            "beginDeferredNativeTextInputEnterSubmit",
            "applyDeferredNativeTextInputEnterSubmit",
            "WIN32_REQUIRED_MARKERS",
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            "const defer_enter_submit = std.mem.eql(u8, key,",
            "queuePendingTextInputSuppression",
            "shouldSuppressPendingTextInput",
            'test "Page reduced Google fixture defers native Enter submit until keypress" {',
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
            "VULNERABLE_PAGE",
            "GUARDED_PAGE",
            "VULNERABLE_WIN32",
            "GUARDED_WIN32",
            "run_self_test",
        ):
            self.assertIn(fragment, self.contract_checker)

    def test_enter_probe_keeps_deferred_google_and_click_first_telemetry(self) -> None:
        for fragment in (
            "[switch]$DeferredEnter",
            "[switch]$GoogleEnterOrder",
            "[switch]$ClickFocus",
            "Choose at most one specialized enter-submit mode.",
            "ClickFocus currently supports only -GoogleEnterOrder.",
            '"google-enter-order"',
            '"deferred-enter"',
            '$googleServerPattern = "GOOGLE_ENTER_SUBMIT"',
            "$googleSubmitPhase = $null",
            "$googleActiveName = $null",
            "$googleActiveId = $null",
            "$googleSelection = $null",
            "$googleEventLog = $null",
            '$expectedGoogleSelection = "{0}-{0}" -f $InputText.Length',
        ):
            self.assertIn(fragment, self.enter_probe)

    def test_google_fixture_keeps_title_probe_event_markers(self) -> None:
        for fragment in (
            "window.__lpEarlyEvents.push('KD:'",
            "window.__lpEarlyEvents.push('KP:'",
            "window.__lpEarlyEvents.push('BI:'",
            "window.__lpEarlyEvents.push('IN:'",
            "mark('FOCUSED')",
            "mark('TYPED:' + q.value)",
            "mark('KEYPRESS:' + (e.key || '') + ':' + q.value)",
            "mark('KEYDOWN:' + q.value + ':' + e.keyCode + ':' + e.which)",
            "mark('SUBMIT:' + q.value)",
        ):
            self.assertIn(fragment, self.google_fixture)


if __name__ == "__main__":
    unittest.main()
