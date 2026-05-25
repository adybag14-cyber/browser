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
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `PATH`, `CARGO`, and `RUSTC`
    - saved Rust archive candidate discovery and staged-toolchain reuse
    """,
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md": """
    # Issue #3 Workspace-Context Route

    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - a ready-to-rerun saved Rust route command
    - a ready-to-rerun saved Rust archive candidates command
    - a ready-to-rerun staged Rust toolchain candidates command
    """,
    "scripts/linux/show_issue3_progress_tracker_route.sh": """
    SAVED_RUST_ROUTE_SURFACE_COMMAND="bash ..."
    SAVED_RUST_ARCHIVE_CANDIDATES_COMMAND="python3 ..."
    STAGED_RUST_TOOLCHAIN_CANDIDATES_COMMAND="python3 ..."
    "saved_rust_toolchain_route_surface"
    "saved_rust_archive_candidates"
    "staged_rust_toolchain_candidates"
    "show_issue3_saved_rust_toolchain_route.sh"
    "check_issue3_saved_rust_archive_candidates.py"
    "check_issue3_staged_rust_toolchain_candidates.py"
    """,
    "scripts/check_issue3_workspace_context.py": """
    "suggested_saved_rust_route_command"
    "suggested_saved_rust_archive_candidates_command"
    "suggested_staged_rust_toolchain_candidates_command"
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
    "scripts/check_issue3_saved_rust_archive_candidates.py"
    "scripts/check_issue3_staged_rust_toolchain_candidates.py"
    "--saved-archives-root"
    "--toolchains-root"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-progress-rust-handoff-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ProgressTrackerSavedRustHandoffTest(unittest.TestCase):
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
        cls.workspace_note = read_text(
            cls.repo_root / "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md"
        )
        cls.progress_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_progress_tracker_route.sh"
        )
        cls.workspace_helper = read_text(
            cls.repo_root / "scripts/check_issue3_workspace_context.py"
        )

    def test_progress_tracker_note_keeps_saved_rust_handoff_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "PATH`, `CARGO`, and `RUSTC`",
            "saved Rust archive candidate discovery and staged-toolchain reuse",
        ):
            self.assertIn(fragment, self.progress_note)

    def test_workspace_context_note_keeps_saved_rust_followups_in_order(self) -> None:
        ordered_fragments = (
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "a ready-to-rerun saved Rust route command",
            "a ready-to-rerun saved Rust archive candidates command",
            "a ready-to-rerun staged Rust toolchain candidates command",
        )
        last_index = -1
        for fragment in ordered_fragments:
            current_index = self.workspace_note.index(fragment)
            self.assertGreater(current_index, last_index)
            last_index = current_index

    def test_progress_tracker_route_keeps_saved_rust_commands_and_json_fields_visible(self) -> None:
        for fragment in (
            "SAVED_RUST_ROUTE_SURFACE_COMMAND=",
            "SAVED_RUST_ARCHIVE_CANDIDATES_COMMAND=",
            "STAGED_RUST_TOOLCHAIN_CANDIDATES_COMMAND=",
            '"saved_rust_toolchain_route_surface"',
            '"saved_rust_archive_candidates"',
            '"staged_rust_toolchain_candidates"',
            '"show_issue3_saved_rust_toolchain_route.sh"',
            '"check_issue3_saved_rust_archive_candidates.py"',
            '"check_issue3_staged_rust_toolchain_candidates.py"',
        ):
            self.assertIn(fragment, self.progress_route)

    def test_workspace_helper_keeps_saved_rust_command_family_visible(self) -> None:
        for fragment in (
            '"suggested_saved_rust_route_command"',
            '"suggested_saved_rust_archive_candidates_command"',
            '"suggested_staged_rust_toolchain_candidates_command"',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh"',
            '"scripts/check_issue3_saved_rust_archive_candidates.py"',
            '"scripts/check_issue3_staged_rust_toolchain_candidates.py"',
            '"--saved-archives-root"',
            '"--toolchains-root"',
        ):
            self.assertIn(fragment, self.workspace_helper)


if __name__ == "__main__":
    unittest.main()
