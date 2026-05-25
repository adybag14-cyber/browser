from __future__ import annotations

import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/linux/restore_saved_browser_snapshot.sh": """
    declare -a HELPER_SURFACE_PATHS=(
        \"scripts/check_issue3_saved_archive_integrity.py\"
        \"scripts/check_issue3_saved_rust_archive_candidates.py\"
        \"scripts/check_issue3_staged_rust_toolchain_candidates.py\"
        \"scripts/check_issue3_saved_zig_archive_candidates.py\"
        \"scripts/check_issue3_staged_zig_toolchain_candidates.py\"
    )
    """,
    "scripts/check_issue3_restored_checkout.py": """
    HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
        (\"scripts/check_issue3_saved_archive_integrity.py\", \"saved-archive integrity helper\"),
        (\"scripts/check_issue3_saved_rust_archive_candidates.py\", \"saved Rust archive candidate helper\"),
        (\"scripts/check_issue3_staged_rust_toolchain_candidates.py\", \"staged Rust toolchain candidate helper\"),
        (\"scripts/check_issue3_saved_zig_archive_candidates.py\", \"saved Zig archive candidate helper\"),
        (\"scripts/check_issue3_staged_zig_toolchain_candidates.py\", \"staged Zig toolchain candidate helper\"),
    )
    """,
    "scripts/check_issue3_saved_snapshot_helper_surface_alignment.py": """
    \"scripts/check_issue3_saved_rust_archive_candidates.py\"
    \"scripts/check_issue3_staged_rust_toolchain_candidates.py\"
    \"scripts/check_issue3_saved_zig_archive_candidates.py\"
    \"scripts/check_issue3_staged_zig_toolchain_candidates.py\"
    \"add the missing restored-checkout helper paths to restore_saved_browser_snapshot.sh\"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-snapshot-sync-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class SavedSnapshotRestoreHelperSurfaceSyncTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = build_fixture_repo()
        cls.restore_helper_text = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )
        cls.restored_checkout_helper_text = read_text(
            cls.repo_root / "scripts/check_issue3_restored_checkout.py"
        )
        cls.alignment_helper_text = read_text(
            cls.repo_root / "scripts/check_issue3_saved_snapshot_helper_surface_alignment.py"
        )

    def test_restore_helper_keeps_saved_and_staged_toolchain_candidates_visible(self) -> None:
        for fragment in (
            '\"scripts/check_issue3_saved_rust_archive_candidates.py\"',
            '\"scripts/check_issue3_staged_rust_toolchain_candidates.py\"',
            '\"scripts/check_issue3_saved_zig_archive_candidates.py\"',
            '\"scripts/check_issue3_staged_zig_toolchain_candidates.py\"',
        ):
            self.assertIn(fragment, self.restore_helper_text)

    def test_restored_checkout_contract_keeps_same_candidate_helpers_visible(self) -> None:
        for fragment in (
            '(\"scripts/check_issue3_saved_rust_archive_candidates.py\", \"saved Rust archive candidate helper\")',
            '(\"scripts/check_issue3_staged_rust_toolchain_candidates.py\", \"staged Rust toolchain candidate helper\")',
            '(\"scripts/check_issue3_saved_zig_archive_candidates.py\", \"saved Zig archive candidate helper\")',
            '(\"scripts/check_issue3_staged_zig_toolchain_candidates.py\", \"staged Zig toolchain candidate helper\")',
        ):
            self.assertIn(fragment, self.restored_checkout_helper_text)

    def test_alignment_helper_calls_out_missing_candidate_helpers(self) -> None:
        for fragment in (
            '\"scripts/check_issue3_saved_rust_archive_candidates.py\"',
            '\"scripts/check_issue3_staged_rust_toolchain_candidates.py\"',
            '\"scripts/check_issue3_saved_zig_archive_candidates.py\"',
            '\"scripts/check_issue3_staged_zig_toolchain_candidates.py\"',
            '\"add the missing restored-checkout helper paths to restore_saved_browser_snapshot.sh\"',
        ):
            self.assertIn(fragment, self.alignment_helper_text)


if __name__ == "__main__":
    unittest.main()
