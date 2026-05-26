from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
    # Issue #3 Saved Browser Snapshot Restore Route

    - `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
    - `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md`
    - `scripts/check_issue3_restored_checkout.py`
    - `scripts/check_issue3_restored_helper_surface_sync.py`
    - `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
    - `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
    - `--sync-helper-surface`
    - `--sync-only`
    - `python ../browser-memory-snapshot/scripts/check_issue3_restored_helper_surface_sync.py --helper-root . --restored-root ../browser-memory-snapshot`
    - `python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface`
    - `python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot`
    - `python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot`
    - `bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot`
    - `bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot`

    ## Recommended Self-Contained Restore

    ```bash
    bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface --check-only
    bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface
    bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh --helper-root . --restored-root ../browser-memory-snapshot
    python ../browser-memory-snapshot/scripts/check_issue3_restored_helper_surface_sync.py --helper-root . --restored-root ../browser-memory-snapshot
    python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
    python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
    python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
    bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
    bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
    ```

    If `../browser-memory-snapshot` already exists and only the helper docs and
    route scripts are stale, refresh them in place without re-extracting the saved
    repo archive:

    ```bash
    bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only --check-only
    bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only
    bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh --helper-root . --restored-root ../browser-memory-snapshot
    python ../browser-memory-snapshot/scripts/check_issue3_restored_helper_surface_sync.py --helper-root . --restored-root ../browser-memory-snapshot
    python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
    python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
    python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
    bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
    bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
    ```

    A concrete stale-archive symptom is a restored checkout that still looks like a
    browser repo but is missing newer helper files.
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-saved-snapshot-sync-followups-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedBrowserSnapshotRouteSyncFollowupsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_note = (
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        ).read_text(encoding="utf-8")

    def _section_between(self, start_marker: str, end_marker: str) -> str:
        start = self.route_note.index(start_marker)
        end = self.route_note.index(end_marker, start)
        return self.route_note[start:end]

    def test_route_keeps_restored_helper_sync_surfaces_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_restored_helper_surface_sync.py",
            "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
            "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
            "--sync-helper-surface",
            "--sync-only",
        ):
            self.assertIn(fragment, self.route_note)

    def test_synced_restore_orders_narrow_sync_gate_before_wider_followups(self) -> None:
        synced_section = self._section_between(
            "## Recommended Self-Contained Restore",
            "If `../browser-memory-snapshot` already exists and only the helper docs and",
        )
        ordered_fragments = (
            "bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface --check-only",
            "bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface",
            "bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh --helper-root . --restored-root ../browser-memory-snapshot",
            "python ../browser-memory-snapshot/scripts/check_issue3_restored_helper_surface_sync.py --helper-root . --restored-root ../browser-memory-snapshot",
            "python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface",
            "python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot",
            "python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot",
            "bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot",
            "bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot",
        )
        indices = [synced_section.index(fragment) for fragment in ordered_fragments]
        self.assertEqual(indices, sorted(indices))

    def test_sync_only_refresh_reuses_same_narrow_gate_before_wider_followups(self) -> None:
        sync_only_section = self._section_between(
            "If `../browser-memory-snapshot` already exists and only the helper docs and",
            "A concrete stale-archive symptom is a restored checkout that still looks like a",
        )
        ordered_fragments = (
            "bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only --check-only",
            "bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only",
            "bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh --helper-root . --restored-root ../browser-memory-snapshot",
            "python ../browser-memory-snapshot/scripts/check_issue3_restored_helper_surface_sync.py --helper-root . --restored-root ../browser-memory-snapshot",
            "python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface",
            "python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot",
            "python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot",
            "bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot",
            "bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot",
        )
        indices = [sync_only_section.index(fragment) for fragment in ordered_fragments]
        self.assertEqual(indices, sorted(indices))


if __name__ == "__main__":
    unittest.main()
