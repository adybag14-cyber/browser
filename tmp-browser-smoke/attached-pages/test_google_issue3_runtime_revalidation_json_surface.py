from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r"""
[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [switch]$Json
)

$route = [ordered]@{
    issue = "Google issue #3 Enter-submit runtime revalidation"
    purpose = "Keep the runtime re-entry gates note, the saved-browser-snapshot restore route, the source-based runtime contract checker, the saved-memory preflight, the Linux re-entry helpers, the shared Enter-submit ladder, the focused file-level regression commands, the reduced Google title probe, the runtime-specific revalidation note, and the live Google fallback on one Windows-first helper surface."
    repo_root = $resolvedRepoRoot
    browser_exe = $resolvedBrowserExe
    fallback_zig_archive = $resolvedFallbackZigArchive
    read_first = @(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    )
    target_files = @(
        "src/browser/Page.zig",
        "src/display/win32_backend.zig"
    )
    related_files = @(
        "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        "scripts/check_issue3_saved_memory_inputs.py",
        "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
        "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
        "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "src/browser/tests/page/google_home_title_probe.html",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
        "docs/WINDOWS_FULL_USE.md",
        "scripts/check_linux_build_readiness.py"
    )
    commands = [ordered]@{
        surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand
        saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand
        contract_check = $runtimeContractCheckCommand
        contract_self_test = $runtimeContractSelfTestCommand
        saved_memory_preflight = $savedMemoryPreflightCommand
        linux_runtime_surface = $linuxRuntimeSurfaceCommand
        linux_runtime_route = $linuxRuntimeRouteCommand
        linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
        linux_build_readiness = $linuxBuildReadinessFullCommand
        build = $buildCommand
        focused_page_tests = $focusedPageTestsCommand
        focused_win32_tests = $focusedWin32TestsCommand
        shared_enter_default = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments
        shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments -Switches @("DeferredEnter")
        shared_enter_google = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments -Switches @("GoogleEnterOrder")
        shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments -Switches @("GoogleEnterOrder", "ClickFocus")
        reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1" -Arguments $sharedBrowserArguments
        reduced_google_fixture = "& `"$resolvedBrowserExe`" browse --headed --window_width 1366 --window_height 900 `\"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1`\""
        live_google = "& `"$resolvedBrowserExe`" browse --headed --window_width 1366 --window_height 900 `\"https://www.google.com/`\""
    }
    expected_signals = @(
        "Printable keydown and keypress leave text in the focused Google query input.",
        "Enter keydown alone does not force an early submit transition.",
        "Enter submit happens only after the later keypress-time DOM phase.",
        "Stale queued suppression entries do not drop real later text_input bytes."
    )
    notes = @(
        "Read docs/ISSUE3_RUNTIME_REENTRY_GATES.md before docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md whenever the next run may reopen Page.zig or win32_backend.zig.",
        "Run contract_self_test when you want to prove the checker itself still distinguishes vulnerable and guarded samples before pointing it at a real checkout.",
        "Use shared_enter_google_click when reproducing the click-first path that most closely matches the real homepage boundary from issue #3.",
        "Only jump to reduced_google_fixture or live_google after the source contract check, restored-checkout route, saved-memory preflight, Linux or WSL gating, shared Enter-order ladder, and reduced Google probe agree on the same event ordering."
    )
}

if ($Json) {
    $route | ConvertTo-Json -Depth 6
    exit 0
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-runtime-revalidation-json-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3RuntimeRevalidationJsonSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.helper = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )

    def test_json_switch_and_serializer_stay_visible(self) -> None:
        for fragment in (
            "[switch]$Json",
            "if ($Json) {",
            "ConvertTo-Json -Depth 6",
            "exit 0",
        ):
            self.assertIn(fragment, self.helper)

    def test_route_identity_and_scope_keys_stay_visible(self) -> None:
        for fragment in (
            '$route = [ordered]@{',
            'issue = "Google issue #3 Enter-submit runtime revalidation"',
            'purpose = "Keep the runtime re-entry gates note',
            "repo_root = $resolvedRepoRoot",
            "browser_exe = $resolvedBrowserExe",
            "fallback_zig_archive =",
            "read_first = @(",
            "target_files = @(",
            "related_files = @(",
            "commands = [ordered]@{",
            "expected_signals = @(",
            "notes = @(",
        ):
            self.assertIn(fragment, self.helper)

    def test_json_surface_keeps_read_first_and_related_route_files_visible(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"',
            '"scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            '"scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh"',
            '"scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"',
            '"scripts/check_issue3_saved_memory_inputs.py"',
            '"tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"',
            '"tmp-browser-smoke/form-controls/enter-submit-probe.ps1"',
            '"tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"',
            '"src/browser/tests/page/google_home_title_probe.html"',
            '"docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md"',
            '"docs/WINDOWS_FULL_USE.md"',
            '"scripts/check_linux_build_readiness.py"',
        ):
            self.assertIn(fragment, self.helper)

    def test_json_surface_keeps_replay_command_keys_visible(self) -> None:
        for fragment in (
            "surface_check = Format-RepoRootCommand",
            "saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand",
            "saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand",
            "contract_check = $runtimeContractCheckCommand",
            "contract_self_test = $runtimeContractSelfTestCommand",
            "saved_memory_preflight = $savedMemoryPreflightCommand",
            "linux_runtime_surface = $linuxRuntimeSurfaceCommand",
            "linux_runtime_route = $linuxRuntimeRouteCommand",
            "linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand",
            "linux_build_readiness = $linuxBuildReadinessFullCommand",
            "build = $buildCommand",
            "focused_page_tests = $focusedPageTestsCommand",
            "focused_win32_tests = $focusedWin32TestsCommand",
            "shared_enter_default = Format-RepoRootCommand",
            "shared_enter_deferred = Format-RepoRootCommand",
            "shared_enter_google = Format-RepoRootCommand",
            "shared_enter_google_click = Format-RepoRootCommand",
            "reduced_google_probe = Format-RepoRootCommand",
            "reduced_google_fixture =",
            "live_google =",
        ):
            self.assertIn(fragment, self.helper)

    def test_json_surface_keeps_expected_signals_and_notes_visible(self) -> None:
        for fragment in (
            "Printable keydown and keypress leave text in the focused Google query input.",
            "Enter keydown alone does not force an early submit transition.",
            "Enter submit happens only after the later keypress-time DOM phase.",
            "Stale queued suppression entries do not drop real later text_input bytes.",
            "Read docs/ISSUE3_RUNTIME_REENTRY_GATES.md before docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "Run contract_self_test when you want to prove the checker itself still distinguishes vulnerable and guarded samples",
            "Use shared_enter_google_click when reproducing the click-first path",
            "Only jump to reduced_google_fixture or live_google after the source contract check",
        ):
            self.assertIn(fragment, self.helper)


if __name__ == "__main__":
    unittest.main()
