from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "build.zig.zon": """
    .{
        .name = "browser",
        .version = "0.0.0",
        .minimum_zig_version = "0.15.2",
        .dependencies = .{
            .v8 = .{ .path = "../zig-v8-fork" },
            .@"boringssl-zig" = .{ .path = "../boringssl-zig" },
        },
    }
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md": """
    # Issue #3 Zig Toolchain Archive Restore Route

    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `0.15.x`
    - `0.17` dev bundle
    - `../memory/repo_archives/browser/dependencies`
    - `restore_zig_toolchain_archive.sh`
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `0.15.x`
    - `0.17` fallback archive
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `../toolchains`
    - `0.15.x`
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    ARCHIVE_PATTERNS = ("*.tar", "*.tar.gz", "*.tgz", "*.tar.xz", "*.zip")
    def normalize_saved_archives_root(saved_archives_root):
        return saved_archives_root
    def resolve_default_saved_archives_root(repo_root):
        return repo_root.parent / "memory" / "repo_archives" / "browser"
    def resolve_default_toolchains_root(repo_root):
        return repo_root.parent / "toolchains"
    def resolve_default_fallback_archive(repo_root):
        return repo_root.parent / "agent_files"
    def discover_zig_archives(root):
        return []
    def choose_preferred_archive(expected, archive_reports):
        return None
    def build_restore_command(repo_root, toolchains_root, archive_path, check_only):
        return []
    "saved_archives_root"
    "toolchains_root"
    "preferred_archive"
    "fallback_archive"
    "restore_check"
    "restore"
    "no saved Zig archive under"
    "not branch-compatible validation evidence"
    """,
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh \
        [--repo-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--archive /path/to/zig-0.15.2.tar.xz] \
        [--offline-deps-root /path/to/offline-deps] \
        [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
        [--json]
    SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    SAVED_ARCHIVE_CANDIDATES_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_zig_archive_candidates.py"
    RESTORE_SCRIPT="${REPO_ROOT}/scripts/linux/restore_zig_toolchain_archive.sh"
    RECOVERY_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    READINESS_SCRIPT="${REPO_ROOT}/scripts/check_linux_build_readiness.py"
    "saved_archive_candidates"
    "restore_check_only"
    "restore"
    "full_readiness"
    "Saved archive discovery"
    "Archive restore commands"
    "Suggested follow-up"
    "Replace <restored-zig-path>"
    "Use the saved-archive discovery command before hand-building an archive path"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-archive-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedZigArchiveRouteSurfaceTest(unittest.TestCase):
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
        cls.recovery_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.saved_archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )
        cls.archive_restore_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_archive_restore_note_keeps_saved_archive_route_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "`0.15.x`",
            "`0.17` dev bundle",
            "../memory/repo_archives/browser/dependencies",
        ):
            self.assertIn(fragment, self.archive_restore_note)

    def test_recovery_and_build_readiness_notes_keep_archive_restore_handoff(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "`0.15.x`",
            "`0.17` fallback archive",
        ):
            self.assertIn(fragment, self.recovery_note)

        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "../toolchains",
            "`0.15.x`",
        ):
            self.assertIn(fragment, self.build_readiness_note)

    def test_saved_archive_helper_keeps_candidate_discovery_and_restore_surface(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'ARCHIVE_PATTERNS = ("*.tar", "*.tar.gz", "*.tgz", "*.tar.xz", "*.zip")',
            "def normalize_saved_archives_root(saved_archives_root):",
            "def resolve_default_saved_archives_root(repo_root):",
            "def resolve_default_toolchains_root(repo_root):",
            "def resolve_default_fallback_archive(repo_root):",
            "def discover_zig_archives(root):",
            "def choose_preferred_archive(expected, archive_reports):",
            "def build_restore_command(repo_root, toolchains_root, archive_path, check_only):",
            '"saved_archives_root"',
            '"toolchains_root"',
            '"preferred_archive"',
            '"fallback_archive"',
            '"restore_check"',
            '"restore"',
            "no saved Zig archive under",
            "not branch-compatible validation evidence",
        ):
            self.assertIn(fragment, self.saved_archive_helper)

    def test_archive_restore_helper_keeps_route_printer_commands_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--repo-root /path/to/browser-repo",
            "--toolchains-root /path/to/toolchains",
            "--archive /path/to/zig-0.15.2.tar.xz",
            "--offline-deps-root /path/to/offline-deps",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "--json",
            'SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"',
            'SAVED_ARCHIVE_CANDIDATES_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_zig_archive_candidates.py"',
            'RESTORE_SCRIPT="${REPO_ROOT}/scripts/linux/restore_zig_toolchain_archive.sh"',
            'RECOVERY_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"',
            'READINESS_SCRIPT="${REPO_ROOT}/scripts/check_linux_build_readiness.py"',
            '"saved_archive_candidates"',
            '"restore_check_only"',
            '"restore"',
            '"full_readiness"',
            "Saved archive discovery",
            "Archive restore commands",
            "Suggested follow-up",
            "Replace <restored-zig-path>",
            "Use the saved-archive discovery command before hand-building an archive path",
        ):
            self.assertIn(fragment, self.archive_restore_helper)

    def test_manifest_still_declares_branch_expected_zig_line(self) -> None:
        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
