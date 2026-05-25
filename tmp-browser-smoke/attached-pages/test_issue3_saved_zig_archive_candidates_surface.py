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
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `0.15.2`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - `0.15.x` restore candidate
    - `saved-archive candidate list`
    - `preferred 0.15.x restore path`
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md": """
    # Issue #3 Zig Toolchain Archive Restore Route

    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": r"""
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    parser.add_argument("--saved-archives-root")
    parser.add_argument("--toolchains-root")
    parser.add_argument("--fallback-zig-archive")
    def normalize_saved_archives_root(saved_archives_root):
        return saved_archives_root
    def choose_preferred_archive(expected, archive_reports):
        return None
    "preferred_archive": preferred_archive,
    "commands": commands
    print("Preferred restore commands:")
    print("Saved Zig archive discovery failed:", file=sys.stderr)
    print("use the fallback archive only as a surfaced stopgap", file=sys.stderr)
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": r"""
    saved_archive_candidates_script = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
    archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    "saved_archive_candidate_discovery"
    "matching_archive_restore_check"
    "matching_archive_restore"
    "Saved archive candidate discovery"
    "Saved archives root:"
    "Offline deps root:"
    "The saved-archives-root override accepts either repo_archives/browser or repo_archives/browser/dependencies"
    """,
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh": r"""
    scripts/check_issue3_saved_zig_archive_candidates.py
    saved_archive_candidate_discovery
    Saved archive candidate discovery
    Preferred restore commands:
    use the fallback archive only as a surfaced stopgap
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-zig-archives-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedZigArchiveCandidatesSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.recovery_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.archive_restore_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
        )
        cls.saved_archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )
        cls.recovery_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.recovery_surface = read_text(
            cls.repo_root / "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_recovery_note_surfaces_saved_archive_helper(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "saved-archive candidate list",
            "preferred `0.15.x` archive choice",
            "`0.15.x` restore candidate",
        ):
            self.assertIn(fragment, self.recovery_note)

    def test_saved_archive_helper_keeps_candidate_and_restore_contracts_visible(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'parser.add_argument("--saved-archives-root")',
            'parser.add_argument("--toolchains-root")',
            'parser.add_argument("--fallback-zig-archive")',
            "def normalize_saved_archives_root(saved_archives_root):",
            "def choose_preferred_archive(expected, archive_reports):",
            '"preferred_archive": preferred_archive',
            '"commands": commands',
            'print("Preferred restore commands:")',
            'print("Saved Zig archive discovery failed:", file=sys.stderr)',
            "use the fallback archive only as a surfaced stopgap",
        ):
            self.assertIn(fragment, self.saved_archive_helper)

    def test_recovery_route_surfaces_saved_archive_candidate_command(self) -> None:
        for fragment in (
            'saved_archive_candidates_script = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"',
            '"saved_archive_candidate_discovery"',
            '"matching_archive_restore_check"',
            '"matching_archive_restore"',
            '"Saved archive candidate discovery"',
            'Saved archives root:',
            'Offline deps root:',
            "repo_archives/browser ",
            "or repo_archives/browser/dependencies",
        ):
            self.assertIn(fragment, self.recovery_route)

    def test_surface_checker_requires_saved_archive_candidate_handoff(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "saved_archive_candidate_discovery",
            "Saved archive candidate discovery",
            "Preferred restore commands:",
            "use the fallback archive only as a surfaced stopgap",
        ):
            self.assertIn(fragment, self.recovery_surface)

    def test_manifest_still_pins_branch_expected_zig_line(self) -> None:
        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
