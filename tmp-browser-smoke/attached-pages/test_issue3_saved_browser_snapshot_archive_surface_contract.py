from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md": """
    # Issue #3 Saved Browser Snapshot Archive Surface

    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/windows/HeadedValidationHelpers.ps1`
    - `scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
    - `scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1`
    - `scripts/windows/start_attached_pages_catalog.ps1`
    - `tmp-browser-smoke/attached-pages/README.md`
    - `tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py`
    - `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
    - `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
    - `scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh`
    - `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
    - `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
    - `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/restore_saved_rust_toolchain.sh`
    - `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
    - `scripts/linux/show_issue3_offline_build_inputs_route.sh`
    - `scripts/linux/prepare_offline_build_inputs.sh`
    """,
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py": """
    REQUIRED_PATHS = [
        ("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "toolchain recovery note"),
        ("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", "saved Zig archive note"),
        ("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "offline build inputs note"),
        ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain note"),
        ("scripts/check_issue3_saved_archive_integrity.py", "saved archive integrity helper"),
        ("scripts/check_linux_build_readiness.py", "Linux build-readiness helper"),
        ("scripts/windows/HeadedValidationHelpers.ps1", "Windows headed validation helper"),
        ("scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1", "Windows runtime surface check"),
        ("scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1", "Windows replay surface check"),
        ("scripts/windows/start_attached_pages_catalog.ps1", "Windows attached-pages launcher"),
        ("tmp-browser-smoke/attached-pages/README.md", "Attached-pages runbook"),
        ("tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py", "Attached-pages launcher"),
        ("scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh", "archive integrity surface"),
        ("scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh", "saved snapshot surface"),
        ("scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh", "restored checkout surface"),
        ("scripts/linux/check_issue3_linux_build_readiness_route_surface.sh", "build readiness surface"),
        ("scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh", "runtime revalidation surface"),
        ("scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh", "Zig recovery surface"),
        ("scripts/linux/show_issue3_zig_toolchain_recovery_route.sh", "Zig recovery route"),
        ("scripts/linux/restore_issue3_fallback_zig_toolchain.sh", "fallback Zig restore"),
        ("scripts/linux/restore_zig_toolchain_archive.sh", "saved Zig restore"),
        ("scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh", "saved Rust surface"),
        ("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "saved Rust route"),
        ("scripts/linux/restore_saved_rust_toolchain.sh", "saved Rust restore"),
        ("scripts/linux/check_issue3_offline_build_inputs_route_surface.sh", "offline inputs surface"),
        ("scripts/linux/show_issue3_offline_build_inputs_route.sh", "offline inputs route"),
        ("scripts/linux/prepare_offline_build_inputs.sh", "offline inputs restore"),
    ]
    "recommended_restore_mode": ("sync-helper-surface" if missing_paths else "plain")
    """,
    "scripts/check_issue3_restored_checkout.py": """
    HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
        ("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "Zig toolchain recovery note"),
        ("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", "Zig toolchain archive restore note"),
        ("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "offline build-inputs note"),
        ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain note"),
        ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
        ("scripts/check_linux_build_readiness.py", "Linux build-readiness checker"),
        ("scripts/windows/HeadedValidationHelpers.ps1", "Windows headed validation helper"),
        ("scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1", "Windows runtime surface checker"),
        ("scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1", "Windows replay surface checker"),
        ("scripts/windows/start_attached_pages_catalog.ps1", "Windows attached-pages launcher"),
        ("tmp-browser-smoke/attached-pages/README.md", "attached-pages launcher runbook"),
        ("tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py", "attached-pages catalog launcher"),
        ("scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh", "saved-archive integrity surface check"),
        ("scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh", "saved snapshot surface check"),
        ("scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh", "restored-checkout re-entry route surface check"),
        ("scripts/linux/check_issue3_linux_build_readiness_route_surface.sh", "Linux build-readiness surface check"),
        ("scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh", "runtime revalidation surface check"),
        ("scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh", "Zig toolchain recovery surface check"),
        ("scripts/linux/show_issue3_zig_toolchain_recovery_route.sh", "Zig toolchain recovery route printer"),
        ("scripts/linux/restore_issue3_fallback_zig_toolchain.sh", "fallback Zig restore helper"),
        ("scripts/linux/restore_zig_toolchain_archive.sh", "saved Zig archive restore helper"),
        ("scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh", "saved Rust route surface check"),
        ("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "saved Rust route printer"),
        ("scripts/linux/restore_saved_rust_toolchain.sh", "saved Rust restore helper"),
        ("scripts/linux/check_issue3_offline_build_inputs_route_surface.sh", "offline inputs surface check"),
        ("scripts/linux/show_issue3_offline_build_inputs_route.sh", "offline inputs route printer"),
        ("scripts/linux/prepare_offline_build_inputs.sh", "offline inputs restore helper"),
    )
    """,
    "scripts/linux/restore_saved_browser_snapshot.sh": """
    declare -a HELPER_SURFACE_PATHS=(
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md"
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md"
        "scripts/check_issue3_saved_archive_integrity.py"
        "scripts/check_linux_build_readiness.py"
        "scripts/windows/HeadedValidationHelpers.ps1"
        "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1"
        "scripts/windows/start_attached_pages_catalog.ps1"
        "tmp-browser-smoke/attached-pages/README.md"
        "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
        "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh"
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
        "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh"
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
        "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
        "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh"
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        "scripts/linux/restore_issue3_fallback_zig_toolchain.sh"
        "scripts/linux/restore_zig_toolchain_archive.sh"
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
        "scripts/linux/restore_saved_rust_toolchain.sh"
        "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh"
        "scripts/linux/show_issue3_offline_build_inputs_route.sh"
        "scripts/linux/prepare_offline_build_inputs.sh"
    )
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-snapshot-archive-surface-contract-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedBrowserSnapshotArchiveSurfaceContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.snapshot_doc = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md"
        )
        cls.archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
        )
        cls.restored_helper = read_text(
            cls.repo_root / "scripts/check_issue3_restored_checkout.py"
        )
        cls.restore_script = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )

    def test_snapshot_doc_mentions_newer_synced_helper_surface(self) -> None:
        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/windows/HeadedValidationHelpers.ps1",
            "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            "scripts/windows/start_attached_pages_catalog.ps1",
            "tmp-browser-smoke/attached-pages/README.md",
            "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
        ):
            self.assertIn(fragment, self.snapshot_doc)

    def test_archive_helper_tracks_the_same_newer_surface(self) -> None:
        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/windows/HeadedValidationHelpers.ps1",
            "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            "scripts/windows/start_attached_pages_catalog.ps1",
            "tmp-browser-smoke/attached-pages/README.md",
            "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
            '"recommended_restore_mode": ("sync-helper-surface" if missing_paths else "plain")',
        ):
            self.assertIn(fragment, self.archive_helper)

    def test_archive_helper_aligns_with_restore_and_restored_checkout_surfaces(self) -> None:
        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/windows/HeadedValidationHelpers.ps1",
            "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            "scripts/windows/start_attached_pages_catalog.ps1",
            "tmp-browser-smoke/attached-pages/README.md",
            "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
        ):
            self.assertIn(fragment, self.restored_helper)
            self.assertIn(fragment, self.restore_script)


if __name__ == "__main__":
    unittest.main()
