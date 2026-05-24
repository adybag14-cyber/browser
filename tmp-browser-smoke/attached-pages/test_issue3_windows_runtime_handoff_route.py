from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh": """#!/usr/bin/env bash
WINDOWS_SURFACE_SCRIPT='.\\\\scripts\\\\windows\\\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1'
WINDOWS_ROUTE_SCRIPT='.\\\\scripts\\\\windows\\\\show_google_issue3_enter_submit_runtime_revalidation.ps1'
REDUCED_GOOGLE_PROBE_SCRIPT='.\\\\tmp-browser-smoke\\\\google-investigation-next\\\\chrome-google-home-title-probe.ps1'
REDUCED_GOOGLE_FIXTURE_URL='http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1'
LIVE_GOOGLE_URL='https://www.google.com/'
TRACE_RUNTIME_PATTERN='tmp-browser-smoke/google-investigation-next/runtime-input-backend-<pid>.log'
TRACE_WNDPROC_PATTERN='tmp-browser-smoke/google-investigation-next/wndproc-input-<pid>.log'
\"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md\"
\"docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md\"
\"docs/WINDOWS_FULL_USE.md\"
\"windows_runtime_surface\"
\"windows_runtime_route\"
\"windows_build\"
\"reduced_google_probe\"
\"reduced_google_fixture\"
\"live_google\"
zig build -Dtarget=x86_64-windows-msvc --summary all
Fail-fast Windows runtime surface check:
Broader Windows runtime route:
Windows build:
Reduced Google probe:
Reduced Google fixture:
Live Google:
Use this handoff only after the Linux or WSL saved-snapshot, offline-inputs, Rust, and Zig-line gates are already green.
Run the Windows runtime surface check first so missing PowerShell helpers or nearby docs fail fast before the broader Windows route reopens.
Run the broader Windows runtime route next when you want the fuller replay ladder and nearby-note guidance on one Windows surface.
Use the reduced Google probe before the direct fixture or live Google when you want the quickest headed Win32 yes-or-no signal with the current runtime traces.
Check the runtime and wndproc trace files after reduced or live Google runs when focus, text commit, or submit still drift.
Treat live Google as the last step in this handoff, not the first one.
""",
    "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md": """
powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath \"<bundle-html-or-folder>\"
tmp-browser-smoke/google-investigation-next/runtime-input-backend-<pid>.log
tmp-browser-smoke/google-investigation-next/wndproc-input-<pid>.log
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
chrome-google-home-title-probe.ps1
google_home_title_probe.html?google-home-probe=1
runtime-input-backend-*.log
wndproc-input-*.log
""",
    "docs/WINDOWS_FULL_USE.md": """
google-form-controls-enter-order
google-shared-enter-order
attached-html-target-bundle
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-windows-handoff-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3WindowsRuntimeHandoffRouteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.handoff_script = read_text(
            cls.repo_root / "scripts/linux/show_issue3_windows_runtime_handoff_route.sh"
        )
        cls.clickfocus_note = read_text(
            cls.repo_root / "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md"
        )
        cls.runtime_note = read_text(
            cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )
        cls.windows_full_use = read_text(cls.repo_root / "docs/WINDOWS_FULL_USE.md")

    def test_handoff_script_keeps_read_first_notes_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md",
            "docs/WINDOWS_FULL_USE.md",
        ):
            self.assertIn(fragment, self.handoff_script)

    def test_handoff_script_keeps_command_ladder_visible(self) -> None:
        for fragment in (
            "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "zig build -Dtarget=x86_64-windows-msvc --summary all",
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html?google-home-probe=1",
            "https://www.google.com/",
            "runtime-input-backend-<pid>.log",
            "wndproc-input-<pid>.log",
            '\"windows_runtime_surface\"',
            '\"windows_runtime_route\"',
            '\"windows_build\"',
            '\"reduced_google_probe\"',
            '\"reduced_google_fixture\"',
            '\"live_google\"',
            "Fail-fast Windows runtime surface check:",
            "Broader Windows runtime route:",
            "Reduced Google probe:",
            "Reduced Google fixture:",
            "Live Google:",
        ):
            self.assertIn(fragment, self.handoff_script)

    def test_handoff_script_keeps_gating_notes_visible(self) -> None:
        for fragment in (
            "saved-snapshot, offline-inputs, Rust, and Zig-line gates are already green",
            "Run the Windows runtime surface check first",
            "Run the broader Windows runtime route next",
            "Use the reduced Google probe before the direct fixture or live Google",
            "Check the runtime and wndproc trace files after reduced or live Google runs",
            "Treat live Google as the last step in this handoff",
        ):
            self.assertIn(fragment, self.handoff_script)

    def test_clickfocus_note_keeps_narrow_replay_order_visible(self) -> None:
        for fragment in (
            "enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus",
            "show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle",
            "runtime-input-backend-<pid>.log",
            "wndproc-input-<pid>.log",
        ):
            self.assertIn(fragment, self.clickfocus_note)

    def test_runtime_and_windows_notes_keep_google_replay_rungs_visible(self) -> None:
        for fragment in (
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html?google-home-probe=1",
            "runtime-input-backend-*.log",
            "wndproc-input-*.log",
        ):
            self.assertIn(fragment, self.runtime_note)

        for fragment in (
            "google-form-controls-enter-order",
            "google-shared-enter-order",
            "attached-html-target-bundle",
        ):
            self.assertIn(fragment, self.windows_full_use)


if __name__ == "__main__":
    unittest.main()
