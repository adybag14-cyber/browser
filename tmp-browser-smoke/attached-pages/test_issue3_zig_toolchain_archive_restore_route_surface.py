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
    - python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .
    - Print The Route
    - bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh
    - --saved-archives-root /path/to/memory/repo_archives/browser/dependencies
    - check_issue3_zig_toolchain_archive_restore_route_surface.sh
    - show_issue3_zig_toolchain_recovery_route.sh
    - Treat the attached Zig `0.17` dev bundle as a surfaced fallback input only
    - not as issue `#3` validation evidence
    - a matching Zig `0.15.x` archive is available
    - bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
    - `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `0.15.x`
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    """,
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh": r"""
    Usage:
      bash scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh \
        [--repo-root /path/to/browser-repo] \
        [--json]
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|scripts/check_issue3_saved_zig_archive_candidates.py"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root ."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Print The Route"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|--saved-archives-root /path/to/memory/repo_archives/browser/dependencies"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh"
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|saved_archive_candidates"
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|Saved archive discovery"
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|Archive restore commands"
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|--saved-archives-root"
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|--offline-deps-root"
    "scripts/linux/restore_zig_toolchain_archive.sh|--check-only"
    "scripts/linux/restore_zig_toolchain_archive.sh|--saved-archives-root"
    "scripts/linux/restore_zig_toolchain_archive.sh|--offline-deps-root"
    "scripts/linux/restore_zig_toolchain_archive.sh|--fallback-zig-archive"
    "scripts/linux/restore_zig_toolchain_archive.sh|normalize_saved_archives_root()"
    "scripts/linux/restore_zig_toolchain_archive.sh|\"saved_archives_root\""
    "scripts/linux/restore_zig_toolchain_archive.sh|\"offline_deps_root\""
    "scripts/linux/restore_zig_toolchain_archive.sh|\"fallback_zig_archive\""
    "scripts/linux/restore_zig_toolchain_archive.sh|\"destination_exists\""
    "scripts/linux/restore_zig_toolchain_archive.sh|Saved Zig toolchain restore surface check passed."
    "scripts/linux/restore_zig_toolchain_archive.sh|Suggested follow-up commands:"
    "scripts/linux/restore_zig_toolchain_archive.sh|--expect-saved-archives"
    "scripts/linux/restore_zig_toolchain_archive.sh|--expect-offline-deps"
    "scripts/linux/restore_zig_toolchain_archive.sh|--require-prebuilt-v8"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    """,
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh": r"""
    Usage:
      bash scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh \
        [--repo-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--archive /path/to/zig-0.15.2.tar.xz] \
        [--offline-deps-root /path/to/offline-deps] \
        [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
        [--json]
    "saved_archive_candidates"
    "restore_check_only"
    "restore"
    "full_readiness"
    "Saved archive discovery"
    "Archive restore commands"
    "show_issue3_zig_toolchain_recovery_route.sh"
    "check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    "--saved-archives-root"
    "--offline-deps-root"
    Replace <restored-zig-path> with the actual zig path printed by restore_zig_toolchain_archive.sh after extraction.
    """,
    "scripts/linux/restore_zig_toolchain_archive.sh": r"""
    Usage:
      scripts/linux/restore_zig_toolchain_archive.sh \
        [--browser-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--archive /path/to/zig-archive.tar.xz] \
        [--destination /path/to/toolchains/zig-0.15.2] \
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
        [--offline-deps-root /path/to/offline-deps] \
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
        [--check-only] \
        [--json] \
        [--force]
    normalize_saved_archives_root()
    "saved_archives_root"
    "offline_deps_root"
    "fallback_zig_archive"
    "follow_up_discovery"
    "follow_up_build_readiness"
    "destination_exists"
    Saved Zig toolchain restore surface check passed.
    Suggested follow-up commands:
    --expect-saved-archives
    --expect-offline-deps
    --require-prebuilt-v8
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": r"""
    build_zon = repo_root / "build.zig.zon"
    fallback_zig_archive = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    archive_restore_surface_check
    fallback_restore_check
    fallback_restore
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    def build_saved_archive_search_roots(saved_archives_root: pathlib.Path) -> list[pathlib.Path]:
        return []
    def choose_preferred_archive(expected: str, archive_reports: list[dict[str, str]]) -> dict[str, str] | None:
        return None
    "saved_archives_search_roots"
    "preferred_archive"
    "fallback_archive"
    "fallback_restore_check"
    "fallback_restore"
    """,
    "scripts/check_linux_build_readiness.py": """
    def build_parser():
        parser.add_argument("--toolchains-root")
        parser.add_argument("--saved-archives-root")
        parser.add_argument("--offline-deps-root")
        parser.add_argument("--fallback-zig-archive")
        parser.add_argument("--zig")
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-archive-restore-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ZigToolchainArchiveRestoreRouteSurfaceTest(unittest.TestCase):
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
        cls.runtime_gates_note = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root / "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_zig_toolchain_archive.sh"
        )
        cls.saved_archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )
        cls.recovery_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
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
            "Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet",
            "python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
            "Print The Route",
            "bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "attached Zig `0.17` dev bundle as a surfaced fallback input only",
            "not as issue `#3` validation evidence",
            "a matching Zig `0.15.x` archive is available",
            "bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only",
        ):
            self.assertIn(fragment, self.archive_restore_note)

    def test_notes_keep_archive_restore_route_linked_into_reentry_chain(self) -> None:
        for fragment in (
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "0.15.x",
        ):
            self.assertIn(fragment, self.build_readiness_note)

        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        ):
            self.assertIn(fragment, self.runtime_gates_note)

        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
        ):
            self.assertIn(fragment, self.recovery_note)

    def test_surface_checker_keeps_route_contract_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|scripts/check_issue3_saved_zig_archive_candidates.py"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root ."',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Print The Route"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|--saved-archives-root /path/to/memory/repo_archives/browser/dependencies"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh"',
            '"scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|saved_archive_candidates"',
            '"scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|Saved archive discovery"',
            '"scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|Archive restore commands"',
            '"scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|--saved-archives-root"',
            '"scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|--offline-deps-root"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|--check-only"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|--saved-archives-root"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|--offline-deps-root"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|--fallback-zig-archive"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|normalize_saved_archives_root()"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|\\"saved_archives_root\\""',
            '"scripts/linux/restore_zig_toolchain_archive.sh|\\"offline_deps_root\\""',
            '"scripts/linux/restore_zig_toolchain_archive.sh|\\"fallback_zig_archive\\""',
            '"scripts/linux/restore_zig_toolchain_archive.sh|\\"destination_exists\\""',
            '"scripts/linux/restore_zig_toolchain_archive.sh|Saved Zig toolchain restore surface check passed."',
            '"scripts/linux/restore_zig_toolchain_archive.sh|Suggested follow-up commands:"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|--expect-saved-archives"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|--expect-offline-deps"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|--require-prebuilt-v8"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_printer_and_restore_helper_keep_followup_surface_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            '"saved_archive_candidates"',
            '"restore_check_only"',
            '"restore"',
            '"full_readiness"',
            "Saved archive discovery",
            "Archive restore commands",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "--saved-archives-root",
            "--offline-deps-root",
            "Replace <restored-zig-path> with the actual zig path printed by restore_zig_toolchain_archive.sh after extraction.",
        ):
            self.assertIn(fragment, self.route_printer)

        for fragment in (
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--offline-deps-root /path/to/offline-deps",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--check-only",
            "normalize_saved_archives_root()",
            '"saved_archives_root"',
            '"offline_deps_root"',
            '"fallback_zig_archive"',
            '"follow_up_discovery"',
            '"follow_up_build_readiness"',
            '"destination_exists"',
            "Saved Zig toolchain restore surface check passed.",
            "Suggested follow-up commands:",
            "--expect-saved-archives",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_saved_archive_helper_and_manifest_keep_expected_zig_surface(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "def build_saved_archive_search_roots(saved_archives_root: pathlib.Path) -> list[pathlib.Path]:",
            "def choose_preferred_archive(expected: str, archive_reports: list[dict[str, str]]) -> dict[str, str] | None:",
            '"saved_archives_search_roots"',
            '"preferred_archive"',
            '"fallback_archive"',
            '"fallback_restore_check"',
            '"fallback_restore"',
        ):
            self.assertIn(fragment, self.saved_archive_helper)

        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
        ):
            self.assertIn(fragment, self.build_manifest)

    def test_companion_helpers_keep_toolchain_root_and_fallback_surface_visible(self) -> None:
        for fragment in (
            'build_zon = repo_root / "build.zig.zon"',
            'fallback_zig_archive = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "archive_restore_surface_check",
            "fallback_restore_check",
            "fallback_restore",
        ):
            self.assertIn(fragment, self.recovery_helper)

        for fragment in (
            "--toolchains-root",
            "--saved-archives-root",
            "--offline-deps-root",
            "--fallback-zig-archive",
            "--zig",
        ):
            self.assertIn(fragment, self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
