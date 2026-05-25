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
    - Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet
    - `python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .`
    - Print The Route
    - `bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `--saved-archives-root /path/to/memory/repo_archives/browser/dependencies`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    - Zig `0.15.x`
    - attached Zig `0.17` dev bundle
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `check_issue3_zig_toolchain_match.sh`
    - `check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `archive_restore_surface_check`
    - Archive restore surface check
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `0.15.x` toolchain is available
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - Linux or WSL reruns
    """,
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh": r"""
    Usage:
      bash scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh \
        [--repo-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--archive /path/to/zig-0.15.2.tar.xz] \
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
        [--offline-deps-root /path/to/offline-deps] \
        [--json]
    check_issue3_zig_toolchain_archive_restore_route_surface.sh
    check_issue3_saved_zig_archive_candidates.py
    "saved_archive_candidates"
    Saved archive discovery
    restore_zig_toolchain_archive.sh
    show_issue3_zig_toolchain_recovery_route.sh
    Archive restore commands
    --saved-archives-root
    --offline-deps-root
    """,
    "scripts/linux/restore_zig_toolchain_archive.sh": """
    Usage:
      bash scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only
    Saved Zig toolchain restore surface check passed.
    Suggested follow-up commands:
    --check-only
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": """
    check_issue3_zig_toolchain_archive_restore_route_surface.sh
    archive_restore_surface_check
    Archive restore surface check
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": """
    def helper():
        return "--saved-archives-root"
    """,
    "scripts/check_linux_build_readiness.py": """
    def helper():
        return "--toolchains-root"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-archive-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ZigToolchainArchiveRestoreSurfaceTest(unittest.TestCase):
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
        cls.runtime_gate_note = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.archive_restore_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_zig_toolchain_archive.sh"
        )
        cls.recovery_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.saved_archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_archive_restore_note_keeps_route_surface_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet",
            "python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
            "Print The Route",
            "bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "Zig `0.15.x`",
            "attached Zig `0.17` dev bundle",
        ):
            self.assertIn(fragment, self.archive_restore_note)

    def test_companion_notes_keep_archive_restore_route_linked(self) -> None:
        for fragment in (
            "check_issue3_zig_toolchain_match.sh",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "archive_restore_surface_check",
            "Archive restore surface check",
        ):
            self.assertIn(fragment, self.recovery_note)

        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "`0.15.x` toolchain is available",
        ):
            self.assertIn(fragment, self.build_readiness_note)

        self.assertIn("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", self.runtime_gate_note)

    def test_route_and_restore_helpers_keep_archive_commands_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--repo-root /path/to/browser-repo",
            "--toolchains-root /path/to/toolchains",
            "--archive /path/to/zig-0.15.2.tar.xz",
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--offline-deps-root /path/to/offline-deps",
            "--json",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "check_issue3_saved_zig_archive_candidates.py",
            '"saved_archive_candidates"',
            "Saved archive discovery",
            "restore_zig_toolchain_archive.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "Archive restore commands",
            "--saved-archives-root",
            "--offline-deps-root",
        ):
            self.assertIn(fragment, self.archive_restore_route)

        for fragment in (
            "--check-only",
            "Saved Zig toolchain restore surface check passed.",
            "Suggested follow-up commands:",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_helper_chain_and_manifest_stay_aligned(self) -> None:
        for fragment in (
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "archive_restore_surface_check",
            "Archive restore surface check",
        ):
            self.assertIn(fragment, self.recovery_route)

        self.assertIn("--saved-archives-root", self.saved_archive_helper)
        self.assertIn("--toolchains-root", self.readiness_helper)

        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
