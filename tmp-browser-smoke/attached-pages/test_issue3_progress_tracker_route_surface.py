from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    # Issue #3 Progress Tracker Route

    - issue `#11`
    - `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
    - `scripts/linux/show_issue3_progress_tracker_route.sh`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `scripts/check_linux_build_readiness.py`
    - `show_issue3_saved_memory_inputs_route.sh`
    - `show_issue3_linux_build_readiness_route.sh`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    Goal:
    Achieved:
    """,
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md": """
    # Issue #3 Saved Memory Inputs Route

    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - issue `#11`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
    - `scripts/linux/show_issue3_progress_tracker_route.sh`
    """,
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh": """
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    docs/ISSUE3_RUNTIME_REENTRY_GATES.md
    docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    scripts/linux/check_issue3_progress_tracker_route_surface.sh
    scripts/linux/show_issue3_progress_tracker_route.sh
    scripts/check_issue3_saved_memory_inputs.py
    scripts/check_issue3_saved_archive_integrity.py
    scripts/check_linux_build_readiness.py
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_progress_tracker_route_surface.sh
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_progress_tracker_route.sh
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|issue `#11`
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|Goal:
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|Achieved:
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_linux_build_readiness_route.sh
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_memory_inputs_route.sh
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_linux_build_readiness.py
    docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    scripts/linux/show_issue3_progress_tracker_route.sh|issue #11 progress-tracker route
    scripts/linux/show_issue3_progress_tracker_route.sh|Goal:
    scripts/linux/show_issue3_progress_tracker_route.sh|Achieved:
    scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_saved_memory_inputs_route.sh
    scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_linux_build_readiness_route.sh
    scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_zig_toolchain_recovery_route.sh
    scripts/linux/show_issue3_progress_tracker_route.sh|issue_url
    scripts/linux/show_issue3_progress_tracker_route.sh|start_comment_template
    scripts/linux/show_issue3_progress_tracker_route.sh|completion_comment_template
    """,
    "scripts/linux/show_issue3_progress_tracker_route.sh": """
    Google issue #3 issue #11 progress-tracker route
    Issue URL:   https://github.com/adybag14-cyber/browser/issues/11
    issue_url
    start_comment_template
    completion_comment_template
    Goal:
    Started:
    Next:
    Achieved:
    Completed:
    Commit:
    Validation:
    show_issue3_saved_memory_inputs_route.sh
    show_issue3_linux_build_readiness_route.sh
    show_issue3_zig_toolchain_recovery_route.sh
    Route surface check:
    Saved-Memory follow-up route:
    Linux or WSL build-readiness route:
    Zig toolchain recovery route:
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-progress-tracker-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ProgressTrackerRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.progress_note = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.saved_memory_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.surface_script = read_text(
            cls.repo_root / "scripts/linux/check_issue3_progress_tracker_route_surface.sh"
        )
        cls.route_script = read_text(
            cls.repo_root / "scripts/linux/show_issue3_progress_tracker_route.sh"
        )

    def test_progress_note_keeps_issue11_handoff_and_followups_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "scripts/check_linux_build_readiness.py",
            "show_issue3_saved_memory_inputs_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "Goal:",
            "Achieved:",
        ):
            self.assertIn(fragment, self.progress_note)

    def test_saved_memory_and_build_readiness_notes_keep_progress_route_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "issue `#11`",
        ):
            self.assertIn(fragment, self.saved_memory_note)

        for fragment in (
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
        ):
            self.assertIn(fragment, self.build_readiness_note)

    def test_surface_checker_keeps_route_contract_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_progress_tracker_route_surface.sh",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_progress_tracker_route.sh",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|issue `#11`",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|Goal:",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|Achieved:",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_linux_build_readiness_route.sh",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_memory_inputs_route.sh",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_linux_build_readiness.py",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "scripts/linux/show_issue3_progress_tracker_route.sh|issue #11 progress-tracker route",
            "scripts/linux/show_issue3_progress_tracker_route.sh|Goal:",
            "scripts/linux/show_issue3_progress_tracker_route.sh|Achieved:",
            "scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_saved_memory_inputs_route.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh|issue_url",
            "scripts/linux/show_issue3_progress_tracker_route.sh|start_comment_template",
            "scripts/linux/show_issue3_progress_tracker_route.sh|completion_comment_template",
        ):
            self.assertIn(fragment, self.surface_script)

    def test_route_printer_keeps_templates_and_followups_together(self) -> None:
        for fragment in (
            "Google issue #3 issue #11 progress-tracker route",
            "https://github.com/adybag14-cyber/browser/issues/11",
            "issue_url",
            "start_comment_template",
            "completion_comment_template",
            "Goal:",
            "Started:",
            "Next:",
            "Achieved:",
            "Completed:",
            "Commit:",
            "Validation:",
            "show_issue3_saved_memory_inputs_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "Route surface check:",
            "Saved-Memory follow-up route:",
            "Linux or WSL build-readiness route:",
            "Zig toolchain recovery route:",
        ):
            self.assertIn(fragment, self.route_script)

        surface_index = self.route_script.index("Route surface check:")
        saved_memory_index = self.route_script.index("Saved-Memory follow-up route:")
        build_index = self.route_script.index("Linux or WSL build-readiness route:")
        zig_index = self.route_script.index("Zig toolchain recovery route:")
        self.assertLess(surface_index, saved_memory_index)
        self.assertLess(saved_memory_index, build_index)
        self.assertLess(build_index, zig_index)


if __name__ == "__main__":
    unittest.main()
