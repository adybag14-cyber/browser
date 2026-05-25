from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md": """
    # Issue #3 Zig Toolchain Archive Restore Route

    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    ## Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet
    python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .
    """,
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh": """
    scripts/check_issue3_saved_zig_archive_candidates.py
    Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet
    python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .
    saved_archive_candidates
    Saved archive discovery
    """,
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh": """
    \"saved_archive_candidates\": saved_archive_candidates,
    print(\"Saved archive discovery\")
    print(\"  Use this first when the saved archives root is known but the exact matching Zig archive path is not.\")
    scripts/check_issue3_saved_zig_archive_candidates.py
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": """
    scripts/check_issue3_saved_zig_archive_candidates.py
    saved_archive_candidate_discovery
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-archive-discovery-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ZigArchiveRestoreSavedArchiveDiscoverySurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.archive_restore_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root
            / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        )
        cls.recovery_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )

    def test_archive_restore_note_keeps_saved_archive_discovery_handoff_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet",
            "python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
        ):
            self.assertIn(fragment, self.archive_restore_note)

    def test_surface_checker_guards_saved_archive_discovery_contract(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet",
            "python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
            "saved_archive_candidates",
            "Saved archive discovery",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_printer_keeps_saved_archive_discovery_command_visible(self) -> None:
        for fragment in (
            '\"saved_archive_candidates\": saved_archive_candidates,',
            'print(\"Saved archive discovery\")',
            "scripts/check_issue3_saved_zig_archive_candidates.py",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_recovery_route_still_points_back_to_saved_archive_discovery(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "saved_archive_candidate_discovery",
        ):
            self.assertIn(fragment, self.recovery_route)


if __name__ == "__main__":
    unittest.main()
