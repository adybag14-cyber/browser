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
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
    - `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/check_issue3_staged_zig_toolchain_candidates.py`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/check_linux_build_readiness.py`
    - `show_issue3_saved_memory_inputs_route.sh`
    - `show_issue3_linux_build_readiness_route.sh`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    - `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    Goal:
    Achieved:
    """,
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md": """
    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    """,
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh": r"""
    Usage:
      bash scripts/linux/check_issue3_progress_tracker_route_surface.sh \
        [--repo-root /path/to/browser-repo] \
        [--json]
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|issue \`#11\`|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_saved_rust_archive_candidates.py|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_staged_rust_toolchain_candidates.py|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_zig_archive_candidates_route.sh|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_saved_zig_archive_candidates.py|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_staged_zig_toolchain_candidates.py|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_zig_toolchain_match.sh|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_zig_toolchain_archive_restore_route_surface.sh|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_memory_inputs_route.sh|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_linux_build_readiness_route.sh|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|Goal:|"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|Achieved:|"
    "scripts/linux/show_issue3_progress_tracker_route.sh|saved_rust_toolchain_route_surface|"
    "scripts/linux/show_issue3_progress_tracker_route.sh|saved_rust_toolchain_route|"
    "scripts/linux/show_issue3_progress_tracker_route.sh|saved_zig_archive_route_surface|"
    "scripts/linux/show_issue3_progress_tracker_route.sh|staged_zig_toolchain_candidates|"
    "scripts/linux/show_issue3_progress_tracker_route.sh|zig_toolchain_matching_line_gate|"
    "scripts/linux/show_issue3_progress_tracker_route.sh|zig_archive_restore_surface|"
    "scripts/linux/show_issue3_progress_tracker_route.sh|issue_url|"
    "scripts/linux/show_issue3_progress_tracker_route.sh|start_comment_template|"
    "scripts/linux/show_issue3_progress_tracker_route.sh|completion_comment_template|"
    """,
    "scripts/linux/show_issue3_progress_tracker_route.sh": r"""
    Print the issue #11 progress-tracker route for the blocked issue #3 Linux or
    WSL re-entry lane.
    ISSUE_URL="https://github.com/adybag14-cyber/browser/issues/11"
    SAVED_RUST_ROUTE_SURFACE_COMMAND=
    SAVED_RUST_ROUTE_COMMAND=
    SAVED_ZIG_ARCHIVE_ROUTE_SURFACE_COMMAND=
    STAGED_ZIG_CANDIDATES_COMMAND=
    MATCHING_LINE_GATE_COMMAND=
    ARCHIVE_RESTORE_SURFACE_COMMAND=
    SAVED_MEMORY_ROUTE_COMMAND=
    BUILD_ROUTE_COMMAND=
    ZIG_RECOVERY_ROUTE_COMMAND=
    if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    "fallback_zig_archive":
    "saved_rust_toolchain_route_surface":
    "saved_rust_toolchain_route":
    "saved_zig_archive_route_surface":
    "staged_zig_toolchain_candidates":
    "zig_toolchain_matching_line_gate":
    "zig_archive_restore_surface":
    "issue_url":
    "start_comment_template":
    "completion_comment_template":
    Goal:
    Achieved:
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
        cls.surface_helper = read_text(
            cls.repo_root / "scripts/linux/check_issue3_progress_tracker_route_surface.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_progress_tracker_route.sh"
        )

    def test_progress_note_keeps_issue11_route_and_followups_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/check_issue3_staged_zig_toolchain_candidates.py",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/check_linux_build_readiness.py",
            "show_issue3_saved_memory_inputs_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "Goal:",
            "Achieved:",
        ):
            self.assertIn(fragment, self.progress_note)

    def test_route_stays_visible_from_saved_memory_and_build_readiness_notes(self) -> None:
        for note_text in (self.saved_memory_note, self.build_readiness_note):
            self.assertIn("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", note_text)

    def test_surface_checker_keeps_route_contract_fragments_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "--repo-root /path/to/browser-repo",
            "--json",
            'docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|issue \\`#11\\`|',
            "show_issue3_saved_rust_toolchain_route.sh",
            "check_issue3_saved_rust_toolchain_route_surface.sh",
            "check_issue3_saved_rust_archive_candidates.py",
            "check_issue3_staged_rust_toolchain_candidates.py",
            "show_issue3_saved_zig_archive_candidates_route.sh",
            "check_issue3_saved_zig_archive_candidates.py",
            "check_issue3_staged_zig_toolchain_candidates.py",
            "check_issue3_zig_toolchain_match.sh",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "show_issue3_saved_memory_inputs_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "Goal:",
            "Achieved:",
            "saved_rust_toolchain_route_surface",
            "saved_rust_toolchain_route",
            "saved_zig_archive_route_surface",
            "staged_zig_toolchain_candidates",
            "zig_toolchain_matching_line_gate",
            "zig_archive_restore_surface",
            "issue_url",
            "start_comment_template",
            "completion_comment_template",
        ):
            self.assertIn(fragment, self.surface_helper)

    def test_route_printer_keeps_json_fields_and_followup_commands_visible(self) -> None:
        for fragment in (
            "issue #11 progress-tracker route",
            "https://github.com/adybag14-cyber/browser/issues/11",
            "SAVED_RUST_ROUTE_SURFACE_COMMAND",
            "SAVED_RUST_ROUTE_COMMAND",
            "SAVED_ZIG_ARCHIVE_ROUTE_SURFACE_COMMAND",
            "STAGED_ZIG_CANDIDATES_COMMAND",
            "MATCHING_LINE_GATE_COMMAND",
            "ARCHIVE_RESTORE_SURFACE_COMMAND",
            "SAVED_MEMORY_ROUTE_COMMAND",
            "BUILD_ROUTE_COMMAND",
            "ZIG_RECOVERY_ROUTE_COMMAND",
            'if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]',
            "fallback_zig_archive",
            "saved_rust_toolchain_route_surface",
            "saved_rust_toolchain_route",
            "saved_zig_archive_route_surface",
            "staged_zig_toolchain_candidates",
            "zig_toolchain_matching_line_gate",
            "zig_archive_restore_surface",
            "issue_url",
            "start_comment_template",
            "completion_comment_template",
            "Goal:",
            "Achieved:",
        ):
            self.assertIn(fragment, self.route_helper)


if __name__ == "__main__":
    unittest.main()
