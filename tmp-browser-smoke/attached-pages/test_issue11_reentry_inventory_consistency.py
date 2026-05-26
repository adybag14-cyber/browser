from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


FIXTURE_FILES = {
    "scripts/check_issue11_reentry_inventory_consistency.py": """
    EXPECTED_PATHS: tuple[str, ...] = (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "scripts/check_issue3_helper_surface_source.py",
        "scripts/check_issue11_progress_tracker_surface.py",
        "scripts/show_issue11_matching_zig_readiness_command.py",
    )
    TARGET_FILES: tuple[str, ...] = (
        "scripts/check_issue3_saved_memory_inputs.py",
        "scripts/check_issue3_restored_checkout.py",
        "scripts/check_issue3_helper_surface_source.py",
    )
    "Issue #11 helper inventory consistency check passed."
    "Suggested next step: update the listed helper inventories so restored checkouts and helper-surface sync flows require the current issue #11 progress-tracker and matching-Zig helper set."
    "expected_path_count"
    "target_file_count"
    "missing_by_file"
    "missing_expected_paths"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue11-reentry-inventory-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11ReentryInventoryConsistencyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        else:
            cls.repo_root = build_fixture_repo()

        cls.helper_text = (
            cls.repo_root / "scripts/check_issue11_reentry_inventory_consistency.py"
        ).read_text(encoding="utf-8")

    def test_helper_keeps_expected_issue11_surface_paths_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "scripts/check_issue3_helper_surface_source.py",
            "scripts/check_issue11_progress_tracker_surface.py",
            "scripts/show_issue11_matching_zig_readiness_command.py",
        ):
            self.assertIn(fragment, self.helper_text)

    def test_helper_keeps_target_inventory_files_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_helper_surface_source.py",
            "expected_path_count",
            "target_file_count",
            "missing_by_file",
            "missing_expected_paths",
        ):
            self.assertIn(fragment, self.helper_text)

    def test_helper_keeps_success_and_failure_guidance_visible(self) -> None:
        for fragment in (
            "Issue #11 helper inventory consistency check passed.",
            "Suggested next step: update the listed helper inventories so restored checkouts and helper-surface sync flows require the current issue #11 progress-tracker and matching-Zig helper set.",
        ):
            self.assertIn(fragment, self.helper_text)


if __name__ == "__main__":
    unittest.main()
