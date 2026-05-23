from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
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
REDUCED_GOOGLE_FIXTURE_COMMAND="browser browse --headed --window_width 1366 --window_height 900 ${REDUCED_GOOGLE_FIXTURE_URL}"
LIVE_GOOGLE_COMMAND="browser browse --headed --window_width 1366 --window_height 900 ${LIVE_GOOGLE_URL}"

docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md
docs/WINDOWS_FULL_USE.md

Use this handoff only after the Linux or WSL saved-snapshot, offline-inputs, Rust, and Zig-line gates are already green.
Run windows_runtime_surface first so missing PowerShell helpers or nearby docs fail fast before the broader Windows route reopens.
Run windows_runtime_route next when you want the fuller replay ladder, narrower helper order, and nearby-note guidance on one Windows surface.
Use reduced_google_probe before the direct fixture or live Google when you want the quickest headed Win32 yes-or-no signal with the current runtime traces.
Check the runtime and wndproc trace patterns after reduced or live Google runs when focus, text commit, or submit still drift.
Treat live Google as the last step in this handoff, not the first one.
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
Target `Page.zig` slice
Target `win32_backend.zig` slice
Focused regression coverage
""",
    "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md": """
chrome-google-home-title-probe.ps1
runtime-input-backend
wndproc-input
""",
    "docs/WINDOWS_FULL_USE.md": """
google-form-controls-enter-order
google-shared-enter-order
""",
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": """
docs/ISSUE3_RUNTIME_REENTRY_GATES.md
scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
""",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": """
"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"
google_home_title_probe.html?google-home-probe=1
""",
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1": """
Write-Host "probe"
""",
    "src/browser/tests/page/google_home_title_probe.html": """
<title>probe</title>
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-windows-handoff-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3WindowsRuntimeHandoffRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.handoff_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_windows_runtime_handoff_route.sh"
        )

    def test_helper_keeps_read_first_docs_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md",
            "docs/WINDOWS_FULL_USE.md",
        ):
            self.assertIn(fragment, self.handoff_helper)

    def test_helper_keeps_windows_and_google_commands_visible(self) -> None:
        for fragment in (
            r".\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            r".\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1",
            r".\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1",
            "zig build -Dtarget=x86_64-windows-msvc --summary all",
            "google_home_title_probe.html?google-home-probe=1",
            "https://www.google.com/",
        ):
            self.assertIn(fragment, self.handoff_helper)

    def test_helper_keeps_trace_patterns_visible(self) -> None:
        for fragment in (
            "tmp-browser-smoke/google-investigation-next/runtime-input-backend-<pid>.log",
            "tmp-browser-smoke/google-investigation-next/wndproc-input-<pid>.log",
        ):
            self.assertIn(fragment, self.handoff_helper)

    def test_helper_keeps_working_rules_visible(self) -> None:
        for fragment in (
            "Use this handoff only after the Linux or WSL saved-snapshot, offline-inputs, Rust, and Zig-line gates are already green.",
            "Run windows_runtime_surface first so missing PowerShell helpers or nearby docs fail fast before the broader Windows route reopens.",
            "Run windows_runtime_route next when you want the fuller replay ladder, narrower helper order, and nearby-note guidance on one Windows surface.",
            "Use reduced_google_probe before the direct fixture or live Google when you want the quickest headed Win32 yes-or-no signal with the current runtime traces.",
            "Check the runtime and wndproc trace patterns after reduced or live Google runs when focus, text commit, or submit still drift.",
            "Treat live Google as the last step in this handoff, not the first one.",
        ):
            self.assertIn(fragment, self.handoff_helper)


if __name__ == "__main__":
    unittest.main()
