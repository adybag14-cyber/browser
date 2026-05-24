from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": r"""
    # Issue #3 Runtime Re-entry Gates
    scripts/linux/show_issue3_windows_runtime_handoff_route.sh
    If Linux or WSL staging has already cleared both gates and the next operator needs the narrower Windows-only replay ladder back on one surface, print the compact handoff route first:
    bash ./scripts/linux/show_issue3_windows_runtime_handoff_route.sh
    Use that handoff after the reduced Google probe when the next step is the Windows build, reduced fixture, live Google, and trace-inspection ladder on one compact bridge.
    use the Linux-or-WSL-to-Windows handoff route when the gates are green and the next operator needs the Windows-only replay ladder reopened from a Linux or WSL staging pass
    """,
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh": r"""
    #!/usr/bin/env bash
    WINDOWS_SURFACE_SCRIPT='.\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1'
    WINDOWS_ROUTE_SCRIPT='.\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1'
    REDUCED_GOOGLE_PROBE_SCRIPT='.\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1'
    REDUCED_GOOGLE_FIXTURE_URL='http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1'
    LIVE_GOOGLE_URL='https://www.google.com/'
    TRACE_RUNTIME_PATTERN='tmp-browser-smoke/google-investigation-next/runtime-input-backend-<pid>.log'
    TRACE_WNDPROC_PATTERN='tmp-browser-smoke/google-investigation-next/wndproc-input-<pid>.log'
    WINDOWS_SURFACE_COMMAND="powershell -ExecutionPolicy Bypass -File ${WINDOWS_SURFACE_SCRIPT}"
    WINDOWS_ROUTE_COMMAND="powershell -ExecutionPolicy Bypass -File ${WINDOWS_ROUTE_SCRIPT}"
    WINDOWS_BUILD_COMMAND='zig build -Dtarget=x86_64-windows-msvc --summary all'
    REDUCED_GOOGLE_PROBE_COMMAND="powershell -ExecutionPolicy Bypass -File ${REDUCED_GOOGLE_PROBE_SCRIPT}"
    REDUCED_GOOGLE_FIXTURE_COMMAND="lightpanda.exe browse --headed --window_width 1366 --window_height 900 ${REDUCED_GOOGLE_FIXTURE_URL}"
    LIVE_GOOGLE_COMMAND="lightpanda.exe browse --headed --window_width 1366 --window_height 900 ${LIVE_GOOGLE_URL}"
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md"
    "docs/WINDOWS_FULL_USE.md"
    "windows_runtime_surface": "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
    "windows_runtime_route": "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1"
    "windows_build": "zig build -Dtarget=x86_64-windows-msvc --summary all"
    "reduced_google_probe": "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"
    "reduced_google_fixture": "lightpanda.exe browse --headed --window_width 1366 --window_height 900 http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"
    "live_google": "lightpanda.exe browse --headed --window_width 1366 --window_height 900 https://www.google.com/"
    Use this handoff only after the Linux or WSL saved-snapshot, offline-inputs, Rust, and Zig-line gates are already green.
    Run windows_runtime_surface first so missing PowerShell helpers or nearby docs fail fast before the broader Windows route reopens.
    Check the runtime and wndproc trace patterns after reduced or live Google runs when focus, text commit, or submit still drift.
    Treat live Google as the last step in this handoff, not the first one.
    """,
    "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md": r"""
    # Issue #3 Click-Focus Trace Replay
    powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
    powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"
    tmp-browser-smoke/google-investigation-next/runtime-input-backend-<pid>.log
    tmp-browser-smoke/google-investigation-next/wndproc-input-<pid>.log
    Treat older copies of those trace files as stale until the current headed replay rewrites them.
    """,
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": r"""
    # Issue #3 Enter-Submit Runtime Revalidation
    zig build -Dtarget=x86_64-windows-msvc --summary all
    powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
    .\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
    inspect `runtime-input-backend-*.log`
    inspect `wndproc-input-*.log`
    """,
    "docs/WINDOWS_FULL_USE.md": r"""
    powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
    powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
    Treat those four runs as a narrowing ladder and only widen back out to attached pages or live Google once you know which rung is the first one to fail.
    """,
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": r"""
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    "docs/WINDOWS_FULL_USE.md"
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
    "src/browser/tests/page/google_home_title_probe.html"
    """,
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r'''
    surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
    build = $buildCommand
    reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"
    reduced_google_fixture = "& ""$resolvedBrowserExe"" browse --headed --window_width 1366 --window_height 900 ""http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"""
    live_google = "& ""$resolvedBrowserExe"" browse --headed --window_width 1366 --window_height 900 ""https://www.google.com/"""
    "Shared click-first route:"
    "Reduced Google probe:"
    "Reduced Google fixture:"
    ''',
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1": r"""
    $probeUrl = "http://127.0.0.1:$Port/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"
    $browseTrace = Join-Path $scriptRoot "browse-render.log"
    $rendererTrace = Join-Path $scriptRoot "runtime-renderer.log"
    $sessionTrace = Join-Path $scriptRoot "session-wait.log"
    Get-ChildItem -Path $scriptRoot -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue
    Get-ChildItem -Path $scriptRoot -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-runtime-handoff-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3WindowsRuntimeHandoffRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runtime_gates = read_text(cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
        cls.handoff_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_windows_runtime_handoff_route.sh"
        )
        cls.clickfocus_note = read_text(
            cls.repo_root / "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md"
        )
        cls.revalidation_note = read_text(
            cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )
        cls.windows_guide = read_text(cls.repo_root / "docs/WINDOWS_FULL_USE.md")
        cls.windows_surface = read_text(
            cls.repo_root
            / "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )
        cls.windows_route = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        cls.reduced_probe = read_text(
            cls.repo_root
            / "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
        )

    def test_runtime_gates_keep_the_windows_handoff_route_visible(self) -> None:
        for fragment in (
            "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
            "If Linux or WSL staging has already cleared both gates and the next operator needs the narrower Windows-only replay ladder back on one surface, print the compact handoff route first:",
            "bash ./scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
            "Use that handoff after the reduced Google probe when the next step is the Windows build, reduced fixture, live Google, and trace-inspection ladder on one compact bridge.",
            "use the Linux-or-WSL-to-Windows handoff route when the gates are green and the next operator needs the Windows-only replay ladder reopened from a Linux or WSL staging pass",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_handoff_route_keeps_read_first_docs_and_windows_commands_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md",
            "docs/WINDOWS_FULL_USE.md",
            "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "zig build -Dtarget=x86_64-windows-msvc --summary all",
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html?google-home-probe=1",
            "https://www.google.com/",
        ):
            self.assertIn(fragment, self.handoff_route)

    def test_handoff_route_keeps_trace_patterns_and_working_rules_visible(self) -> None:
        for fragment in (
            "runtime-input-backend-<pid>.log",
            "wndproc-input-<pid>.log",
            "saved-snapshot, offline-inputs, Rust, and Zig-line gates are already green",
            "Run windows_runtime_surface first",
            "Check the runtime and wndproc trace patterns after reduced or live Google runs",
            "Treat live Google as the last step in this handoff, not the first one.",
        ):
            self.assertIn(fragment, self.handoff_route)

    def test_neighbor_docs_keep_clickfocus_and_reduced_fixture_replay_context_visible(self) -> None:
        for fragment in (
            "enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus",
            "show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle",
            "runtime-input-backend-<pid>.log",
            "wndproc-input-<pid>.log",
        ):
            self.assertIn(fragment, self.clickfocus_note)

        for fragment in (
            "zig build -Dtarget=x86_64-windows-msvc --summary all",
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html?google-home-probe=1",
            "runtime-input-backend-*.log",
            "wndproc-input-*.log",
        ):
            self.assertIn(fragment, self.revalidation_note)

    def test_windows_guides_and_helpers_keep_the_same_handoff_rungs_visible(self) -> None:
        for fragment in (
            "google-shared-enter-order",
            "enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus",
            "only widen back out to attached pages or live Google",
        ):
            self.assertIn(fragment, self.windows_guide)

        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/WINDOWS_FULL_USE.md",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html",
        ):
            self.assertIn(fragment, self.windows_surface)

        for fragment in (
            'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            "reduced_google_probe = Format-RepoRootCommand",
            "http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1",
            'live_google = "& ""$resolvedBrowserExe"" browse --headed --window_width 1366 --window_height 900',
            "Shared click-first route:",
            "Reduced Google probe:",
            "Reduced Google fixture:",
        ):
            self.assertIn(fragment, self.windows_route)

    def test_reduced_probe_keeps_the_trace_artifacts_used_by_the_handoff(self) -> None:
        for fragment in (
            "google_home_title_probe.html?google-home-probe=1",
            'Join-Path $scriptRoot "browse-render.log"',
            'Join-Path $scriptRoot "runtime-renderer.log"',
            'Join-Path $scriptRoot "session-wait.log"',
            'Filter "runtime-input-backend-*.log"',
            'Filter "wndproc-input-*.log"',
        ):
            self.assertIn(fragment, self.reduced_probe)


if __name__ == "__main__":
    unittest.main()
