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

    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    """,
    "scripts/check_linux_build_readiness.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    parser.add_argument(
        "--saved-archives-root",
    )
    parser.add_argument(
        "--offline-deps-root",
    )
    parser.add_argument(
        "--toolchains-root",
    )
    parser.add_argument(
        "--fallback-zig-archive",
    )
    "--expect-saved-archives"
    "--expect-offline-deps"
    "--require-prebuilt-v8"
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh         [--repo-root /path/to/browser-repo]         [--toolchains-root /path/to/toolchains]         [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies]         [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz]
    """,
    "scripts/linux/restore_zig_toolchain_archive.sh": """
    Usage:
      scripts/linux/restore_zig_toolchain_archive.sh         [--browser-root /path/to/browser-repo]         [--toolchains-root /path/to/toolchains]         [--archive /path/to/zig-archive.tar.xz]         [--destination /path/to/toolchains/zig-0.15.2]         [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]]         [--offline-deps-root /path/to/offline-deps]         [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz]         [--check-only]         [--json]         [--force]
    DEFAULT_FALLBACK_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    normalize_saved_archives_root()
    "saved_archives_root"
    "offline_deps_root"
    "fallback_zig_archive"
    "destination_exists"
    "follow_up_discovery"
    "follow_up_build_readiness"
    "check_only"
    "force_restore"
    show_issue3_zig_toolchain_recovery_route.sh
    check_linux_build_readiness.py
    --saved-archives-root
    --offline-deps-root
    --expect-saved-archives
    --expect-offline-deps
    --require-prebuilt-v8
    --fallback-zig-archive
    Saved Zig toolchain restore surface check passed.
    Suggested follow-up commands:
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-follow-up-context-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3RestoreZigToolchainFollowUpContextTest(unittest.TestCase):
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
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.recovery_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_zig_toolchain_archive.sh"
        )

    def test_restore_route_note_keeps_follow_up_surfaces_visible(self) -> None:
        for fragment in (
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
        ):
            self.assertIn(fragment, self.archive_restore_note)

    def test_restore_helper_keeps_context_in_usage_json_and_followups(self) -> None:
        for fragment in (
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--offline-deps-root /path/to/offline-deps",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            'DEFAULT_FALLBACK_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "normalize_saved_archives_root()",
            '"saved_archives_root"',
            '"offline_deps_root"',
            '"fallback_zig_archive"',
            '"destination_exists"',
            '"follow_up_discovery"',
            '"follow_up_build_readiness"',
            '"check_only"',
            '"force_restore"',
            "show_issue3_zig_toolchain_recovery_route.sh",
            "check_linux_build_readiness.py",
            "--saved-archives-root",
            "--offline-deps-root",
            "--expect-saved-archives",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
            "--fallback-zig-archive",
            "Saved Zig toolchain restore surface check passed.",
            "Suggested follow-up commands:",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_follow_up_commands_stay_compatible_with_recovery_and_readiness_helpers(self) -> None:
        for fragment in (
            "--saved-archives-root",
            "--offline-deps-root",
            "--toolchains-root",
            "--fallback-zig-archive",
            "--expect-saved-archives",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
        ):
            self.assertIn(fragment, self.readiness_helper)

        for fragment in (
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        ):
            self.assertIn(fragment, self.recovery_route)


if __name__ == "__main__":
    unittest.main()
