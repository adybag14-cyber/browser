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

    - `scripts/check_issue3_saved_browser_snapshot_archive_surface.py`
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_restored_checkout.py`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
    - `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - the resolved snapshot archive path
    - the inferred top-level folder inside the zip
    - whether the current helper surface is already present inside the archive
    - which helper paths are missing when the archive is stale
    - whether a plain restore is safe or `--sync-helper-surface` should be used
    - `build.zig.zon`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/linux/restore_saved_browser_snapshot.sh`
    - `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/restore_saved_rust_toolchain.sh`
    - `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
    - `scripts/linux/show_issue3_offline_build_inputs_route.sh`
    - `scripts/linux/prepare_offline_build_inputs.sh`
    - Prefer a plain restore only when the helper reports that the archive already
    - Prefer `--sync-helper-surface` when one or more helper paths are missing from
    """,
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
    # Issue #3 Saved Browser Snapshot Restore Route

    - `scripts/check_issue3_saved_browser_snapshot_archive_surface.py`
    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md`
    - `--sync-helper-surface`
    - `python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py`
    - `python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py --json`
    - The second command checks whether the saved snapshot archive already contains the
    - Prefer the synced restore path when the restored checkout should become its own
    """,
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py": """
    DEFAULT_ARCHIVE_NAME = "01-browser-fork-headed-mode-foundation.zip"
    REQUIRED_PATHS = [
        ("build.zig.zon", "Snapshot manifest expected in a reusable restored checkout."),
        ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "Runtime re-entry gate note."),
        ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "Direct issue #3 runtime revalidation note."),
        ("docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md", "Saved-archive integrity note."),
        ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "Read-first saved-browser-snapshot restore note."),
        ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "Restored-checkout re-entry note."),
        ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux or WSL build-readiness note."),
        ("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "Zig toolchain recovery note."),
        ("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", "Saved Zig archive restore note."),
        ("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "Offline build-inputs note."),
        ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "Saved Rust toolchain route."),
        ("docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md", "Google-shaped attached-page validation note."),
        ("scripts/check_issue3_saved_memory_inputs.py", "Saved-Memory preflight."),
        ("scripts/check_issue3_saved_archive_integrity.py", "Saved-archive integrity helper."),
        ("scripts/check_issue3_restored_checkout.py", "Restored-checkout readiness helper."),
        ("scripts/check_linux_build_readiness.py", "Linux build-readiness helper."),
        ("scripts/windows/HeadedValidationHelpers.ps1", "Shared Windows headed validation helper surface."),
        ("scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh", "Saved-archive-integrity surface checker."),
        ("scripts/linux/show_issue3_saved_archive_integrity_route.sh", "Compact route printer for the saved-archive-integrity path."),
        ("scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh", "Saved snapshot restore surface checker."),
        ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "Compact route printer for the saved-browser-snapshot restore path."),
        ("scripts/linux/restore_saved_browser_snapshot.sh", "Restore helper that supports --check-only and --sync-helper-surface."),
        ("scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh", "Zig toolchain recovery surface checker."),
        ("scripts/linux/check_issue3_zig_toolchain_match.sh", "Zig toolchain matching-line checker."),
        ("scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh", "Zig archive restore surface checker."),
        ("scripts/linux/show_issue3_zig_toolchain_recovery_route.sh", "Zig toolchain recovery route printer."),
        ("scripts/linux/restore_issue3_fallback_zig_toolchain.sh", "Fallback Zig restore helper."),
        ("scripts/linux/restore_zig_toolchain_archive.sh", "Saved Zig archive restore helper."),
        ("scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh", "Saved Rust toolchain surface checker."),
        ("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "Saved Rust toolchain route printer."),
        ("scripts/linux/restore_saved_rust_toolchain.sh", "Saved Rust toolchain restore helper."),
        ("scripts/linux/check_issue3_offline_build_inputs_route_surface.sh", "Offline build-inputs surface checker."),
        ("scripts/linux/show_issue3_offline_build_inputs_route.sh", "Offline build-inputs route printer."),
        ("scripts/linux/prepare_offline_build_inputs.sh", "Offline build-inputs restore helper."),
    ]
    "issue": "issue3-saved-browser-snapshot-archive-surface"
    "archive_top_level_root"
    "helper_surface_complete"
    "recommended_restore_mode"
    "missing_paths"
    "required_paths"
    "sync-helper-surface" if missing_paths else "plain"
    "--sync-helper-surface" if missing else "plain restore is safe"
    "Issue #3 saved browser snapshot archive surface"
    "Recommended restore:"
    "Archive helper surface:"
    "Working rules:"
    "Missing helper paths detected in the saved archive:"
    "The saved archive already carries the current helper surface."
    if args.json:
        print(json.dumps(payload, indent=2))
    return 0 if not payload["missing_paths"] else 2
    """,
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": """
    ROUTE_SURFACE_COMMAND="bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh --repo-root ."
    ARCHIVE_SURFACE_COMMAND="python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py --repo-root ."
    SURFACE_CHECK_COMMAND="bash ./scripts/linux/restore_saved_browser_snapshot.sh --check-only"
    RESTORE_COMMAND="bash ./scripts/linux/restore_saved_browser_snapshot.sh"
    "archive_surface": ${ARCHIVE_SURFACE_COMMAND@Q},
    "surface_check": ${SURFACE_CHECK_COMMAND@Q},
    "restore": ${RESTORE_COMMAND@Q},
    "Run archive_surface next when the saved snapshot may lag the live helper surface"
    "Archive surface"
    print(f"  {ARCHIVE_SURFACE_COMMAND}")
    print(f"  {SURFACE_CHECK_COMMAND}")
    print(f"  {RESTORE_COMMAND}")
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-saved-snapshot-archive-surface-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedBrowserSnapshotArchiveSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.archive_surface_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md"
        )
        cls.snapshot_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        )
        cls.archive_surface_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
        )
        cls.snapshot_route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_BROWSER_SNAPSHOT_ROUTE.sh"
        )

    def test_archive_surface_note_keeps_helper_contract_and_followups_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "the resolved snapshot archive path",
            "the inferred top-level folder inside the zip",
            "whether the current helper surface is already present inside the archive",
            "which helper paths are missing when the archive is stale",
            "whether a plain restore is safe or `--sync-helper-surface` should be used",
            "build.zig.zon",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
            "Prefer a plain restore only when the helper reports that the archive already",
            "Prefer `--sync-helper-surface` when one or more helper paths are missing from",
        ):
            self.assertIn(fragment, self.archive_surface_note)

    def test_snapshot_route_note_keeps_archive_surface_preflight_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md",
            "--sync-helper-surface",
            "python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
            "python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py --json",
            "The second command checks whether the saved snapshot archive already contains the",
            "Prefer the synced restore path when the restored checkout should become its own",
        ):
            self.assertIn(fragment, self.snapshot_route_note)

    def test_archive_surface_helper_keeps_required_paths_output_and_exit_contract(self) -> None:
        for fragment in (
            'DEFAULT_ARCHIVE_NAME = "01-browser-fork-headed-mode-foundation.zip"',
            '("build.zig.zon", "Snapshot manifest expected in a reusable restored checkout.")',
            '("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "Read-first saved-browser-snapshot restore note.")',
            '("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", "Saved Zig archive restore note.")',
            '("scripts/check_linux_build_readiness.py", "Linux build-readiness helper.")',
            '("scripts/linux/check_issue3_zig_toolchain_match.sh", "Zig toolchain matching-line checker.")',
            '("scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh", "Zig archive restore surface checker.")',
            '("scripts/linux/restore_issue3_fallback_zig_toolchain.sh", "Fallback Zig restore helper.")',
            '("scripts/linux/restore_zig_toolchain_archive.sh", "Saved Zig archive restore helper.")',
            '("scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh", "Saved Rust toolchain surface checker.")',
            '("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "Saved Rust toolchain route printer.")',
            '("scripts/linux/restore_saved_rust_toolchain.sh", "Saved Rust toolchain restore helper.")',
            '("scripts/linux/check_issue3_offline_build_inputs_route_surface.sh", "Offline build-inputs surface checker.")',
            '("scripts/linux/show_issue3_offline_build_inputs_route.sh", "Offline build-inputs route printer.")',
            '("scripts/linux/prepare_offline_build_inputs.sh", "Offline build-inputs restore helper.")',
            '"issue": "issue3-saved-browser-snapshot-archive-surface"',
            '"archive_top_level_root"',
            '"helper_surface_complete"',
            '"recommended_restore_mode"',
            '"missing_paths"',
            '"required_paths"',
            '"sync-helper-surface" if missing_paths else "plain"',
            '"--sync-helper-surface" if missing else "plain restore is safe"',
            '"Issue #3 saved browser snapshot archive surface"',
            '"Recommended restore:"',
            '"Archive helper surface:"',
            '"Working rules:"',
            '"Missing helper paths detected in the saved archive:"',
            '"The saved archive already carries the current helper surface."',
            "if args.json:",
            "print(json.dumps(payload, indent=2))",
            'return 0 if not payload["missing_paths"] else 2',
        ):
            self.assertIn(fragment, self.archive_surface_helper)

    def test_snapshot_route_helper_keeps_archive_surface_before_restore_commands(self) -> None:
        for fragment in (
            'ARCHIVE_SURFACE_COMMAND="python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py --repo-root ."',
            '"archive_surface": ${ARCHIVE_SURFACE_COMMAND@Q},',
            '"surface_check": ${SURFACE_CHECK_COMMAND@Q},',
            '"restore": ${RESTORE_COMMAND@Q},',
            '"Run archive_surface next when the saved snapshot may lag the live helper surface"',
            '"Archive surface"',
            'print(f"  {ARCHIVE_SURFACE_COMMAND}")',
            'print(f"  {SURFACE_CHECK_COMMAND}")',
            'print(f"  {RESTORE_COMMAND}")',
        ):
            self.assertIn(fragment, self.snapshot_route_helper)

        archive_index = self.snapshot_route_helper.index('ARCHIVE_SURFACE_COMMAND=')
        surface_check_index = self.snapshot_route_helper.index('SURFACE_CHECK_COMMAND=')
        restore_index = self.snapshot_route_helper.index('RESTORE_COMMAND=')
        self.assertLess(archive_index, surface_check_index)
        self.assertLess(surface_check_index, restore_index)


if __name__ == "__main__":
    unittest.main()
