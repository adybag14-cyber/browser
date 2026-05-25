from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/check_issue3_saved_memory_helper_surface_alignment.py": """
    SAVED_MEMORY_HELPER = "scripts/check_issue3_saved_memory_inputs.py"
    RESTORE_HELPER = "scripts/linux/restore_saved_browser_snapshot.sh"
    SAVED_MEMORY_BLOCK_RE = re.compile(
        r"REQUIRED_RESTORED_HELPER_FILES:\\s*tuple\\[tuple\\[str, str\\], \\.\\.\\.\\]\\s*=\\s*\\((?P<body>.*?)\\n\\)",
        re.DOTALL,
    )
    RESTORE_HELPER_BLOCK_RE = re.compile(
        r"declare -a HELPER_SURFACE_PATHS=\\((?P<body>.*?)\\n\\)",
        re.DOTALL,
    )
    return {
        "saved_memory_only": saved_memory_only,
        "restore_helper_only": restore_helper_only,
        "ok": not saved_memory_only and not restore_helper_only,
    }
    "Suggested next step: update the saved-memory helper surface or the "
    "restore helper surface so restored-checkout preflight and sync "
    "logic agree before the next Linux/WSL replay."
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
        ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 progress-tracker route"),
        ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md", "saved snapshot archive-surface guide"),
        ("scripts/check_issue3_saved_browser_snapshot_archive_surface.py", "saved snapshot archive-surface helper"),
    )
    """,
    "scripts/linux/restore_saved_browser_snapshot.sh": """
    declare -a HELPER_SURFACE_PATHS=(
      "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md"
      "scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
    )
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-memory-alignment-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedMemoryHelperSurfaceAlignmentTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.alignment_checker = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_helper_surface_alignment.py"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )

    def test_alignment_checker_keeps_inventory_contract_visible(self) -> None:
        for fragment in (
            'SAVED_MEMORY_HELPER = "scripts/check_issue3_saved_memory_inputs.py"',
            'RESTORE_HELPER = "scripts/linux/restore_saved_browser_snapshot.sh"',
            "REQUIRED_RESTORED_HELPER_FILES",
            "HELPER_SURFACE_PATHS",
            '"saved_memory_only": saved_memory_only',
            '"restore_helper_only": restore_helper_only',
            '"ok": not saved_memory_only and not restore_helper_only',
            "restore helper surface so restored-checkout preflight and sync",
        ):
            self.assertIn(fragment, self.alignment_checker)

    def test_saved_memory_helper_keeps_newer_helper_surface_paths_visible(self) -> None:
        for fragment in (
            '"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md"',
            '"scripts/check_issue3_saved_browser_snapshot_archive_surface.py"',
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_restore_helper_keeps_same_helper_surface_paths_visible(self) -> None:
        for fragment in (
            '"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md"',
            '"scripts/check_issue3_saved_browser_snapshot_archive_surface.py"',
        ):
            self.assertIn(fragment, self.restore_helper)


if __name__ == "__main__":
    unittest.main()
