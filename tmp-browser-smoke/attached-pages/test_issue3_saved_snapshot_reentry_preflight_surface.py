from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/linux/run_issue3_saved_snapshot_reentry_preflight.sh": """
    #!/usr/bin/env bash

    Usage:
      bash scripts/linux/run_issue3_saved_snapshot_reentry_preflight.sh \\
        [--repo-root /path/to/browser-repo] \\
        [--helper-root /path/to/live/browser-repo] \\
        [--memory-root /path/to/workspace/memory] \\
        [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \\
        [--destination /path/to/browser-memory-snapshot] \\
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
        [--sync-helper-surface] \\
        [--run] \\
        [--json]

    DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
    DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
    DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    SURFACE_CHECK_COMMAND="bash ${REPO_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh --repo-root ${REPO_ROOT}"
    ARCHIVE_SURFACE_COMMAND="python ${REPO_ROOT}/scripts/check_issue3_saved_browser_snapshot_archive_surface.py --repo-root ${REPO_ROOT}"
    RESTORE_COMMAND="bash ${REPO_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh --browser-root ${REPO_ROOT} --helper-root ${HELPER_ROOT} --memory-root ${MEMORY_ROOT} --archive ${ARCHIVE_PATH} --destination ${DESTINATION}"
    RESTORED_CHECKOUT_COMMAND="python ${REPO_ROOT}/scripts/check_issue3_restored_checkout.py --repo-root ${DESTINATION} --helper-root ${HELPER_ROOT} --expect-helper-surface"
    SAVED_MEMORY_PREFLIGHT_COMMAND="python ${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py --repo-root ${DESTINATION} --helper-root ${HELPER_ROOT}"
    ARCHIVE_INTEGRITY_COMMAND="python ${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py --repo-root ${DESTINATION}"
    BUILD_READINESS_COMMAND="python ${REPO_ROOT}/scripts/check_linux_build_readiness.py --repo-root ${DESTINATION} --skip-zig-check"
    "Saved-browser-snapshot route surface"
    "Saved snapshot archive helper surface"
    "Saved snapshot restore surface"
    "Restored-checkout readiness"
    "Saved-Memory preflight"
    "Saved-archive integrity"
    "Linux build-readiness preflight"
    "issue3-saved-snapshot-reentry-preflight"
    "Prefer --sync-helper-surface when the saved snapshot archive does not already carry the current helper docs and route scripts."
    "Keep the restored-checkout readiness check ahead of the saved-Memory and archive-integrity preflights so stale helper-surface drift fails fast."
    "Treat this helper as a restore and trust bundle, not as proof that the direct runtime lane is ready to reopen."
    """,
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh": """
    #!/usr/bin/env bash
    bash scripts/linux/run_issue3_saved_snapshot_reentry_preflight.sh --json
    """,
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py": """
    from pathlib import Path
    ARCHIVE_NAME = "01-browser-fork-headed-mode-foundation.zip"
    """,
    "scripts/linux/restore_saved_browser_snapshot.sh": """
    #!/usr/bin/env bash
    declare -a HELPER_SURFACE_PATHS=(
      "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
      "scripts/check_issue3_saved_memory_inputs.py"
      "scripts/check_issue3_saved_archive_integrity.py"
      "scripts/check_issue3_restored_checkout.py"
      "scripts/linux/restore_saved_browser_snapshot.sh"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
    )
    """,
    "scripts/check_issue3_restored_checkout.py": """
    HELPER_SURFACE_PATHS = (
        ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "gates"),
        ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory"),
        ("scripts/check_issue3_saved_archive_integrity.py", "archive-integrity"),
        ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "route"),
    )
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    REQUIRED_RESTORED_HELPER_FILES = (
        ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "gates"),
        ("scripts/check_issue3_saved_archive_integrity.py", "archive-integrity"),
        ("scripts/check_issue3_restored_checkout.py", "restored-checkout"),
        ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "route"),
    )
    """,
    "scripts/check_issue3_saved_archive_integrity.py": """
    REQUIRED_ARCHIVE_BASENAME = "01-browser-fork-headed-mode-foundation.zip"
    REQUIRED_FALLBACK_ZIG_BASENAME = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    """,
    "scripts/check_linux_build_readiness.py": """
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-zig-check", action="store_true")
    parser.add_argument("--fallback-zig-archive")
    """,
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": """
    #!/usr/bin/env bash
    echo issue3-saved-snapshot-route
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Reentry Gates
    """,
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
    # Issue #3 Saved Browser Snapshot Route
    """,
}


REQUIRED_HELPER_FILES = (
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
    "scripts/linux/restore_saved_browser_snapshot.sh",
    "scripts/check_issue3_restored_checkout.py",
    "scripts/check_issue3_saved_memory_inputs.py",
    "scripts/check_issue3_saved_archive_integrity.py",
    "scripts/check_linux_build_readiness.py",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
)


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-snapshot-preflight-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedSnapshotReentryPreflightSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.preflight_script = read_text(
            cls.repo_root / "scripts/linux/run_issue3_saved_snapshot_reentry_preflight.sh"
        )
        cls.route_surface = read_text(
            cls.repo_root / "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
        )
        cls.archive_surface = read_text(
            cls.repo_root / "scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
        )
        cls.restore_script = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )
        cls.restored_checkout = read_text(
            cls.repo_root / "scripts/check_issue3_restored_checkout.py"
        )
        cls.saved_memory = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.archive_integrity = read_text(
            cls.repo_root / "scripts/check_issue3_saved_archive_integrity.py"
        )
        cls.build_readiness = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_preflight_script_keeps_issue3_step_order_visible(self) -> None:
        for fragment in (
            "run_issue3_saved_snapshot_reentry_preflight.sh",
            "--sync-helper-surface",
            "--run",
            "--json",
            "Saved-browser-snapshot route surface",
            "Saved snapshot archive helper surface",
            "Saved snapshot restore surface",
            "Restored-checkout readiness",
            "Saved-Memory preflight",
            "Saved-archive integrity",
            "Linux build-readiness preflight",
            "issue3-saved-snapshot-reentry-preflight",
            "check_issue3_saved_browser_snapshot_route_surface.sh",
            "check_issue3_saved_browser_snapshot_archive_surface.py",
            "restore_saved_browser_snapshot.sh",
            "check_issue3_restored_checkout.py",
            "check_issue3_saved_memory_inputs.py",
            "check_issue3_saved_archive_integrity.py",
            "check_linux_build_readiness.py",
            "--skip-zig-check",
        ):
            self.assertIn(fragment, self.preflight_script)

    def test_preflight_script_keeps_restore_and_fallback_rules_visible(self) -> None:
        for fragment in (
            "01-browser-fork-headed-mode-foundation.zip",
            "browser-memory-snapshot",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "Prefer --sync-helper-surface when the saved snapshot archive does not already carry the current helper docs and route scripts.",
            "Keep the restored-checkout readiness check ahead of the saved-Memory and archive-integrity preflights so stale helper-surface drift fails fast.",
            "Treat this helper as a restore and trust bundle, not as proof that the direct runtime lane is ready to reopen.",
        ):
            self.assertIn(fragment, self.preflight_script)

    def test_supporting_helpers_keep_preflight_contract_visible(self) -> None:
        for fragment in (
            "run_issue3_saved_snapshot_reentry_preflight.sh",
            "01-browser-fork-headed-mode-foundation.zip",
            "HELPER_SURFACE_PATHS",
            "REQUIRED_RESTORED_HELPER_FILES",
            "REQUIRED_ARCHIVE_BASENAME",
            "REQUIRED_FALLBACK_ZIG_BASENAME",
            "--skip-zig-check",
        ):
            combined = "\n".join(
                (
                    self.route_surface,
                    self.archive_surface,
                    self.restore_script,
                    self.restored_checkout,
                    self.saved_memory,
                    self.archive_integrity,
                    self.build_readiness,
                )
            )
            self.assertIn(fragment, combined)

    def test_required_helper_files_exist(self) -> None:
        for relative_path in REQUIRED_HELPER_FILES:
            self.assertTrue((self.repo_root / relative_path).is_file(), relative_path)


if __name__ == "__main__":
    unittest.main()
