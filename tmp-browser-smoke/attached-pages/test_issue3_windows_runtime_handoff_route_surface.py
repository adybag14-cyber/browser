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
printf '  "read_first": [\n'
printf '    %s,\n' "$(json_escape "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")"
printf '    %s,\n' "$(json_escape "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md")"
printf '    %s\n' "$(json_escape "docs/WINDOWS_FULL_USE.md")"
printf '    "windows_runtime_surface": %s,\n' "$(json_escape "${WINDOWS_SURFACE_COMMAND}")"
printf '    "windows_runtime_route": %s,\n' "$(json_escape "${WINDOWS_ROUTE_COMMAND}")"
printf '    "windows_build": %s,\n' "$(json_escape "${WINDOWS_BUILD_COMMAND}")"
printf '    "reduced_google_probe": %s,\n' "$(json_escape "${REDUCED_GOOGLE_PROBE_COMMAND}")"
printf '    "reduced_google_fixture": %s,\n' "$(json_escape "${REDUCED_GOOGLE_FIXTURE_COMMAND}")"
printf '    "live_google": %s\n' "$(json_escape "${LIVE_GOOGLE_COMMAND}")"
TRACE_RUNTIME_PATTERN='tmp-browser-smoke/google-investigation-next/runtime-input-backend-<pid>.log'
TRACE_WNDPROC_PATTERN='tmp-browser-smoke/google-investigation-next/wndproc-input-<pid>.log'
printf '    %s,\n' "$(json_escape "${TRACE_RUNTIME_PATTERN}")"
printf '    %s\n' "$(json_escape "${TRACE_WNDPROC_PATTERN}")"
Use this handoff only after the Linux or WSL saved-snapshot, offline-inputs, Rust, and Zig-line gates are already green.
Run windows_runtime_surface first so missing PowerShell helpers or nearby docs fail fast before the broader Windows route reopens.
Run windows_runtime_route next when you want the fuller replay ladder, narrower helper order, and nearby-note guidance on one Windows surface.
Use reduced_google_probe before the direct fixture or live Google when you want the quickest headed Win32 yes-or-no signal with the current runtime traces.
Check the runtime and wndproc trace patterns after reduced or live Google runs when focus, text commit, or submit still drift.
Treat live Google as the last step in this handoff, not the first one.
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-runtime-handoff-"))
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

        cls.helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_windows_runtime_handoff_route.sh"
        )

    def test_read_first_docs_stay_visible(self) -> None:
        fragments = (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md",
            "docs/WINDOWS_FULL_USE.md",
        )
        for fragment in fragments:
            self.assertIn(fragment, self.helper)
        positions = [self.helper.index(fragment) for fragment in fragments]
        self.assertEqual(positions, sorted(positions))

    def test_command_surface_stays_visible(self) -> None:
        fragments = (
            '"windows_runtime_surface"',
            '"windows_runtime_route"',
            '"windows_build"',
            '"reduced_google_probe"',
            '"reduced_google_fixture"',
            '"live_google"',
        )
        for fragment in fragments:
            self.assertIn(fragment, self.helper)
        positions = [self.helper.index(fragment) for fragment in fragments]
        self.assertEqual(positions, sorted(positions))

    def test_trace_patterns_and_working_rules_stay_visible(self) -> None:
        for fragment in (
            "tmp-browser-smoke/google-investigation-next/runtime-input-backend-<pid>.log",
            "tmp-browser-smoke/google-investigation-next/wndproc-input-<pid>.log",
            "Use this handoff only after the Linux or WSL saved-snapshot, offline-inputs, Rust, and Zig-line gates are already green.",
            "Run windows_runtime_surface first so missing PowerShell helpers or nearby docs fail fast before the broader Windows route reopens.",
            "Run windows_runtime_route next when you want the fuller replay ladder, narrower helper order, and nearby-note guidance on one Windows surface.",
            "Use reduced_google_probe before the direct fixture or live Google when you want the quickest headed Win32 yes-or-no signal with the current runtime traces.",
            "Check the runtime and wndproc trace patterns after reduced or live Google runs when focus, text commit, or submit still drift.",
            "Treat live Google as the last step in this handoff, not the first one.",
        ):
            self.assertIn(fragment, self.helper)


if __name__ == "__main__":
    unittest.main()
