from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/check_issue3_workspace_context.py": """
    #!/usr/bin/env python3
    from __future__ import annotations
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"
    def collect_context(repo_root, explicit_archive):
        readiness_command = [
            "python",
            "scripts/check_linux_build_readiness.py",
            "--repo-root",
            str(repo_root),
            "--toolchains-root",
            "/tmp/toolchains",
            "--saved-archives-root",
            "/tmp/memory/repo_archives/browser",
            "--offline-deps-root",
            "/tmp/offline-deps",
        ]
        progress_tracker_route_command = [
            "bash",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "--memory-root",
            "/tmp/memory",
            "--restored-checkout-root",
            "/tmp/browser-memory-snapshot",
            "--saved-archives-root",
            "/tmp/memory/repo_archives/browser",
            "--toolchains-root",
            "/tmp/toolchains",
            "--offline-deps-root",
            "/tmp/offline-deps",
        ]
        build_readiness_route_command = [
            "bash",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        ]
        saved_snapshot_route_command = [
            "bash",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "--destination",
            "/tmp/browser-memory-snapshot",
            "--sync-helper-surface",
        ]
        saved_rust_route_command = [
            "bash",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        ]
        saved_rust_archive_candidates_command = [
            "python",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
        ]
        staged_rust_toolchain_candidates_command = [
            "python",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        ]
        zig_recovery_route_command = [
            "bash",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        ]
        zig_match_command = [
            "bash",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
        ]
        saved_zig_archive_candidates_command = [
            "python",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
        ]
        return {
            "suggested_readiness_command": readiness_command,
            "suggested_progress_tracker_route_command": progress_tracker_route_command,
            "suggested_build_readiness_route_command": build_readiness_route_command,
            "suggested_saved_snapshot_route_command": saved_snapshot_route_command,
            "suggested_saved_rust_route_command": saved_rust_route_command,
            "suggested_saved_rust_archive_candidates_command": saved_rust_archive_candidates_command,
            "suggested_staged_rust_toolchain_candidates_command": staged_rust_toolchain_candidates_command,
            "suggested_zig_recovery_route_command": zig_recovery_route_command,
            "suggested_zig_match_command": zig_match_command,
            "suggested_saved_zig_archive_candidates_command": saved_zig_archive_candidates_command,
            "fallback_zig_archive": str(explicit_archive) if explicit_archive else None,
            "fallback_zig_archive_found": explicit_archive is not None,
        }
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-workspace-context-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3WorkspaceContextReentryCommandsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.helper = read_text(cls.repo_root / "scripts/check_issue3_workspace_context.py")

    def test_helper_keeps_core_root_and_archive_discovery_visible(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"',
            '"--toolchains-root"',
            '"--saved-archives-root"',
            '"--offline-deps-root"',
            '"--memory-root"',
            '"--restored-checkout-root"',
        ):
            self.assertIn(fragment, self.helper)

    def test_helper_keeps_reentry_route_commands_visible(self) -> None:
        for fragment in (
            '"scripts/check_linux_build_readiness.py"',
            '"scripts/linux/show_issue3_progress_tracker_route.sh"',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh"',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh"',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh"',
            '"scripts/check_issue3_saved_rust_archive_candidates.py"',
            '"scripts/check_issue3_staged_rust_toolchain_candidates.py"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"',
            '"scripts/linux/check_issue3_zig_toolchain_match.sh"',
            '"scripts/check_issue3_saved_zig_archive_candidates.py"',
        ):
            self.assertIn(fragment, self.helper)

    def test_helper_keeps_saved_snapshot_sync_and_destination_flags_visible(self) -> None:
        for fragment in (
            '"--destination"',
            '"--sync-helper-surface"',
            '"suggested_saved_snapshot_route_command"',
            '"suggested_progress_tracker_route_command"',
            '"suggested_saved_rust_route_command"',
            '"suggested_zig_recovery_route_command"',
        ):
            self.assertIn(fragment, self.helper)

    def test_helper_keeps_fallback_archive_reporting_visible(self) -> None:
        for fragment in (
            '"fallback_zig_archive"',
            '"fallback_zig_archive_found"',
            'str(explicit_archive) if explicit_archive else None',
        ):
            self.assertIn(fragment, self.helper)


if __name__ == "__main__":
    unittest.main()
