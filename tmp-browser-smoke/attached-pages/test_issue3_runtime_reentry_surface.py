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

Use this note before reopening the direct issue `#3` runtime patch in:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

Read this together with:

- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/WINDOWS_FULL_USE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `scripts/check_linux_build_readiness.py`

### Gate 1: Writable publication path

- a writable checkout of `fork/headed-mode-foundation` is available

### Gate 2: Branch-compatible validation toolchain

```bash
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
```

## Practical Re-entry Order

1. Reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` and confirm the
   target still stays narrowed to `Page.zig` plus `win32_backend.zig`.
2. Print the helper surface when you want the current branch-local runtime
   commands back on one Windows-first path:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

4. Re-check the branch-side runtime contract markers before touching the patch:

```bash
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py \\
  --page src/browser/Page.zig \\
  --win32 src/display/win32_backend.zig
```

8. Re-check Linux or WSL build readiness before trusting file-level Zig output:

```bash
python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
```

Until then, preserve the narrowed runtime target, use the dedicated runtime
helper to reopen the same branch-local route quickly, use the Linux build-
readiness route when the saved archives must be restaged.
""",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": """
$route = [ordered]@{
    read_first = @(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    )
    target_files = @(
        "src/browser/Page.zig",
        "src/display/win32_backend.zig"
    )
    related_files = @(
        "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
        "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
        "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "src/browser/tests/page/google_home_title_probe.html",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
        "docs/WINDOWS_FULL_USE.md",
        "scripts/check_linux_build_readiness.py"
    )
    commands = [ordered]@{
        surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        contract_check = $runtimeContractCheckCommand
        contract_self_test = $runtimeContractSelfTestCommand
        linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
        linux_build_readiness = $linuxBuildReadinessFullCommand
        shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"
        reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"
        reduced_google_fixture = "& ``\"$resolvedBrowserExe``\" browse --headed --window_width 1366 --window_height 900 ``\"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1``\""
        live_google = "& ``\"$resolvedBrowserExe``\" browse --headed --window_width 1366 --window_height 900 ``\"https://www.google.com/``\""
    }
    expected_signals = @(
        "Printable keydown and keypress leave text in the focused Google query input.",
        "Enter keydown alone does not force an early submit transition.",
        "Enter submit happens only after the later keypress-time DOM phase.",
        "Stale queued suppression entries do not drop real later text_input bytes."
    )
    notes = @(
        "Read docs/ISSUE3_RUNTIME_REENTRY_GATES.md before docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md whenever the next run may reopen Page.zig or win32_backend.zig.",
        "Run surface_check first when branch state may have moved and you want the gate note, helper, and probe files checked before replay.",
        "Run contract_check before build or replay when you need a thin, source-based yes-or-no answer about whether the direct Page.zig and win32_backend.zig bridge markers are present on the current branch.",
        "Use linux_build_readiness_skip_zig when the re-entry depends on Linux or WSL dependency staging and you need to confirm the saved inputs before trusting focused Zig output.",
        "Use shared_enter_google_click when reproducing the click-first path that most closely matches the real homepage boundary from issue #3.",
        "Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig and you want trace-ready output on the reduced fixture first."
    )
}
""",
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": """
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
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py" -Kind "file" -Purpose "Source-based checker for the direct Page.zig and win32_backend.zig runtime bridge markers.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Purpose "The gate note keeps the runtime revalidation note in the required re-entry order."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_enter_submit_runtime_contract.py" -Purpose "The gate note keeps the source-based runtime contract checker visible before replay widens."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "The production guide keeps the fail-fast runtime surface checker visible from the direct issue #3 re-entry route."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "The roadmap quick routes keep the compact runtime revalidation helper visible before the direct issue #3 route widens."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet "google-form-controls-enter-order" -Purpose "Windows guide still surfaces the Google-shaped Enter-order route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"' -Purpose "The helper exposes the fail-fast surface checker before the runtime replay commands."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "google_home_title_probe.html?google-home-probe=1" -Purpose "The helper prints the reduced Google fixture replay command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Stale queued suppression entries do not drop real later text_input bytes." -Purpose "The helper keeps the stale-suppression success signal visible.")
)
""",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": """
PAGE_REQUIRED_MARKERS = (
    "_defer_native_text_input_enter_submit: bool = false",
    "_pending_native_enter_submit: ?*Element.Html.Input = null",
    "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
    "self._pending_native_enter_submit = input;",
)

WIN32_REQUIRED_MARKERS = (
    "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
    "const defer_enter_submit = std.mem.eql(u8, key, \\"Enter\\");",
    "page.beginDeferredNativeTextInputEnterSubmit();",
    "page.endDeferredNativeTextInputEnterSubmit();",
    "queuePendingTextInputSuppression(self, key);",
    "try page.applyDeferredNativeTextInputEnterSubmit();",
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
GUARDED_PAGE = "_pending_native_enter_submit"
VULNERABLE_WIN32 = "pending_text_input_suppressions: u32 = 0,"
GUARDED_WIN32 = "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},"

def run_self_test(json_output: bool) -> int:
    return 0

if __name__ == "__main__":
    raise SystemExit(0)
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
# Issue #3 Enter Submit Runtime Revalidation

Target `Page.zig` slice
Target `win32_backend.zig` slice
Focused regression coverage
chrome-google-home-title-probe.ps1
google_home_title_probe.html?google-home-probe=1
""",
    "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md": """
check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
show_google_issue3_enter_submit_runtime_revalidation.ps1
""",
    "docs/HEADED_MODE_ROADMAP.md": """
check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
show_google_issue3_enter_submit_runtime_revalidation.ps1
""",
    "docs/WINDOWS_FULL_USE.md": """
google-form-controls-enter-order
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

        cls.gates_note = read_text(cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
        cls.helper = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        cls.surface_check = read_text(
            cls.repo_root
            / "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )
        cls.contract_checker = read_text(
            cls.repo_root
            / "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
        )

    def test_gate_note_keeps_runtime_targets_and_reentry_commands_visible(self) -> None:
        for fragment in (
            "`src/browser/Page.zig`",
            "`src/display/win32_backend.zig`",
            "### Gate 1: Writable publication path",
            "### Gate 2: Branch-compatible validation toolchain",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "check_issue3_enter_submit_runtime_contract.py --self-test",
            "python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check",
        ):
            self.assertIn(fragment, self.gates_note)

    def test_gate_note_keeps_linux_and_windows_reentry_routes_together(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/WINDOWS_FULL_USE.md",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.gates_note)

    def test_helper_keeps_read_first_targets_and_replay_commands(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"src/browser/Page.zig"',
            '"src/display/win32_backend.zig"',
            'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            "contract_self_test = $runtimeContractSelfTestCommand",
            "linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand",
            "shared_enter_google_click = Format-RepoRootCommand",
            "reduced_google_probe = Format-RepoRootCommand",
            "google_home_title_probe.html?google-home-probe=1",
            'live_google = "& ``\"$resolvedBrowserExe``\" browse --headed',
        ):
            self.assertIn(fragment, self.helper)

    def test_helper_keeps_expected_signals_and_notes(self) -> None:
        for fragment in (
            "Printable keydown and keypress leave text in the focused Google query input.",
            "Enter keydown alone does not force an early submit transition.",
            "Enter submit happens only after the later keypress-time DOM phase.",
            "Stale queued suppression entries do not drop real later text_input bytes.",
            "Run surface_check first when branch state may have moved",
            "Use linux_build_readiness_skip_zig",
            "Use shared_enter_google_click",
            "Use reduced_google_probe before live Google",
        ):
            self.assertIn(fragment, self.helper)

    def test_surface_checker_keeps_cross_file_reference_contract(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md"',
            '"docs/HEADED_MODE_ROADMAP.md"',
            '"docs/WINDOWS_FULL_USE.md"',
            '"scripts/check_linux_build_readiness.py"',
            '"scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"',
            '"tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"',
            '"src/browser/Page.zig"',
            '"src/display/win32_backend.zig"',
        ):
            self.assertIn(fragment, self.surface_check)

    def test_surface_checker_keeps_content_expectations_for_runtime_route(self) -> None:
        for fragment in (
            'Snippet "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            'Snippet "check_issue3_enter_submit_runtime_contract.py"',
            'Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            'Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1"',
            'Snippet "google-form-controls-enter-order"',
            'Snippet "google_home_title_probe.html?google-home-probe=1"',
            'Snippet "Stale queued suppression entries do not drop real later text_input bytes."',
        ):
            self.assertIn(fragment, self.surface_check)

    def test_contract_checker_keeps_page_and_win32_runtime_markers(self) -> None:
        for fragment in (
            "_defer_native_text_input_enter_submit: bool = false",
            "_pending_native_enter_submit: ?*Element.Html.Input = null",
            "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
            "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            'const defer_enter_submit = std.mem.eql(u8, key, \\"Enter\\");',
            "queuePendingTextInputSuppression(self, key);",
            "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
        ):
            self.assertIn(fragment, self.contract_checker)

    def test_contract_checker_keeps_regression_markers_and_self_test_samples(self) -> None:
        for fragment in (
            'test "Page reduced Google fixture defers native Enter submit until keypress" {',
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
            "VULNERABLE_PAGE",
            "GUARDED_PAGE",
            "VULNERABLE_WIN32",
            "GUARDED_WIN32",
            "run_self_test",
            'if __name__ == "__main__":',
        ):
            self.assertIn(fragment, self.contract_checker)


if __name__ == "__main__":
    unittest.main()
