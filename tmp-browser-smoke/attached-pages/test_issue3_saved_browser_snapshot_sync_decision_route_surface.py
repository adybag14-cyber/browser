from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md": """
    # Issue #3 Saved Browser Snapshot Sync Decision Route

    - `scripts/check_issue3_saved_browser_snapshot_sync_decision.py`
    - `plain-restore`
    - `sync-helper-surface`
    - `sync-only`
    - `reuse-existing-checkout`
    - `bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface`
    - `bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only`
    - `python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot`
    - issue `#11`
    - `--json`
    """,
    "scripts/check_issue3_saved_browser_snapshot_sync_decision.py": """
    RESTORE_HELPER_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"
    "plain-restore"
    "sync-helper-surface"
    "sync-only"
    "reuse-existing-checkout"
    "missing_helper_surface_paths"
    "sync_helper_surface_restore"
    "sync_only_refresh"
    "restored_checkout_check"
    "recommended"
    """,
    "scripts/linux/check_issue3_saved_browser_snapshot_sync_decision_route_surface.sh": """
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md
    scripts/check_issue3_saved_browser_snapshot_sync_decision.py
    scripts/linux/check_issue3_saved_browser_snapshot_sync_decision_route_surface.sh
    scripts/linux/show_issue3_saved_browser_snapshot_sync_decision_route.sh
    scripts/linux/restore_saved_browser_snapshot.sh
    scripts/check_issue3_restored_checkout.py
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    plain-restore
    sync-helper-surface
    sync-only
    reuse-existing-checkout
    restore_saved_browser_snapshot.sh --sync-helper-surface
    restore_saved_browser_snapshot.sh --sync-only
    check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot
    RESTORE_HELPER_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"
    """,
    "scripts/linux/show_issue3_saved_browser_snapshot_sync_decision_route.sh": """
    check_issue3_saved_browser_snapshot_sync_decision_route_surface.sh
    check_issue3_saved_browser_snapshot_sync_decision.py
    restore_saved_browser_snapshot.sh --sync-helper-surface
    restore_saved_browser_snapshot.sh --sync-only
    check_issue3_restored_checkout.py
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    plain-restore
    sync-helper-surface
    sync-only
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-sync-decision-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedBrowserSnapshotSyncDecisionRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md"
        )
        cls.sync_decision_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_browser_snapshot_sync_decision.py"
        )
        cls.route_surface_script = read_text(
            cls.repo_root / "scripts/linux/check_issue3_saved_browser_snapshot_sync_decision_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_sync_decision_route.sh"
        )

    def test_route_note_keeps_decision_modes_visible(self) -> None:
        for fragment in (
            "`scripts/check_issue3_saved_browser_snapshot_sync_decision.py`",
            "`plain-restore`",
            "`sync-helper-surface`",
            "`sync-only`",
            "`reuse-existing-checkout`",
            "`bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface`",
            "`bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only`",
            "`python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot`",
            "issue `#11`",
            "`--json`",
        ):
            self.assertIn(fragment, self.route_note)

    def test_surface_checker_keeps_route_dependencies_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md",
            "scripts/check_issue3_saved_browser_snapshot_sync_decision.py",
            "scripts/linux/check_issue3_saved_browser_snapshot_sync_decision_route_surface.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_sync_decision_route.sh",
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "scripts/check_issue3_restored_checkout.py",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "plain-restore",
            "sync-helper-surface",
            "sync-only",
            "reuse-existing-checkout",
            "restore_saved_browser_snapshot.sh --sync-helper-surface",
            "restore_saved_browser_snapshot.sh --sync-only",
            "check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot",
            'RESTORE_HELPER_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"',
        ):
            self.assertIn(fragment, self.route_surface_script)

    def test_route_printer_keeps_follow_up_commands_visible(self) -> None:
        for fragment in (
            "check_issue3_saved_browser_snapshot_sync_decision_route_surface.sh",
            "check_issue3_saved_browser_snapshot_sync_decision.py",
            "restore_saved_browser_snapshot.sh --sync-helper-surface",
            "restore_saved_browser_snapshot.sh --sync-only",
            "check_issue3_restored_checkout.py",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "plain-restore",
            "sync-helper-surface",
            "sync-only",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_helper_keeps_restore_recommendation_keys_visible(self) -> None:
        for fragment in (
            'RESTORE_HELPER_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"',
            '"plain-restore"',
            '"sync-helper-surface"',
            '"sync-only"',
            '"reuse-existing-checkout"',
            '"missing_helper_surface_paths"',
            '"sync_helper_surface_restore"',
            '"sync_only_refresh"',
            '"restored_checkout_check"',
            '"recommended"',
        ):
            self.assertIn(fragment, self.sync_decision_helper)


if __name__ == "__main__":
    unittest.main()
