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
            .@\"boringssl-zig\" = .{ .path = "../boringssl-zig" },
        },
    }
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `0.15.x` archive choice
    - `preferred 0.15.x restore path`
    - `saved-archive candidate list`
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md": """
    # Issue #3 Zig Toolchain Archive Restore Route

    - `scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": r"""
    ARCHIVE_PATTERNS = ("zig*.tar", "zig*.tar.gz", "zig*.tgz", "zig*.tar.xz", "zig*.zip")
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    parser.add_argument("--saved-archives-root")
    parser.add_argument("--toolchains-root")
    parser.add_argument("--fallback-zig-archive")
    parser.add_argument("--json", action="store_true")
    def normalize_saved_archives_root(saved_archives_root):
        return saved_archives_root
    def choose_preferred_archive(expected, archive_reports):
        exact_match = next(
    "status": "passed" if preferred_archive is not None else "failed",
    "preferred_archive": preferred_archive,
    "fallback_archive": str(fallback_archive) if fallback_archive is not None else "",
    commands["restore_check"] = format_command(
    commands["restore"] = format_command(
    "commands": commands,
    "failures": failures,
    expected_prefix = f"{parse_semver(minimum_zig)[0]}.{parse_semver(minimum_zig)[1]}.x"
    "no saved Zig archive under {saved_archives_root} matches the branch's expected {expected_prefix} line"
    "no surfaced fallback Zig archive is available beside the repo workspace"
    print("Preferred restore commands:")
    print("Saved Zig archive discovery failed:", file=sys.stderr)
    print(
        "  - use the fallback archive only as a surfaced stopgap; it is not branch-compatible validation evidence",
        file=sys.stderr,
    )
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": r"""
    saved_archive_candidates_script = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
    archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    "saved_archive_candidate_discovery"
    "matching_archive_restore_check"
    "matching_archive_restore"
    "Saved archive candidate discovery"
    "Saved archives root:"
    "The saved-archives-root override accepts either repo_archives/browser or repo_archives/browser/dependencies"
    """,
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh": r"""
    "commands": {
        "surface_check": surface_check,
        "recovery_route": recovery,
    },
    result["commands"]["restore_check_only"] = restore_check
    result["commands"]["restore"] = restore_run
    result["commands"]["full_readiness"] = readiness
    print("Archive restore commands")
    print("Suggested follow-up")
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-zig-json-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedZigArchiveCandidatesJsonContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")
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
        cls.archive_restore_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        )

    def test_manifest_and_recovery_note_keep_expected_zig_route_visible(self) -> None:
        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "`0.15.x` archive choice",
            "`preferred 0.15.x restore path`",
            "`saved-archive candidate list`",
        ):
            self.assertIn(fragment, self.build_manifest + self.recovery_note)

    def test_saved_archive_helper_keeps_json_and_restore_command_contract(self) -> None:
        for fragment in (
            'ARCHIVE_PATTERNS = ("zig*.tar", "zig*.tar.gz", "zig*.tgz", "zig*.tar.xz", "zig*.zip")',
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'parser.add_argument("--saved-archives-root")',
            'parser.add_argument("--toolchains-root")',
            'parser.add_argument("--fallback-zig-archive")',
            'parser.add_argument("--json", action="store_true")',
            "def normalize_saved_archives_root(saved_archives_root):",
            "def choose_preferred_archive(expected, archive_reports):",
            '"status": "passed" if preferred_archive is not None else "failed"',
            '"preferred_archive": preferred_archive',
            '"fallback_archive": str(fallback_archive) if fallback_archive is not None else ""',
            'commands["restore_check"] = format_command(',
            'commands["restore"] = format_command(',
            '"commands": commands',
            '"failures": failures',
            'expected_prefix = f"{parse_semver(minimum_zig)[0]}.{parse_semver(minimum_zig)[1]}.x"',
            "no saved Zig archive under {saved_archives_root} matches the branch's expected {expected_prefix} line",
            "no surfaced fallback Zig archive is available beside the repo workspace",
            'print("Preferred restore commands:")',
            'print("Saved Zig archive discovery failed:", file=sys.stderr)',
            "use the fallback archive only as a surfaced stopgap; it is not branch-compatible validation evidence",
        ):
            self.assertIn(fragment, self.saved_archive_helper)

    def test_recovery_and_archive_restore_routes_keep_saved_archive_handoff_visible(self) -> None:
        for fragment in (
            'saved_archive_candidates_script = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"',
            'archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"',
            '"saved_archive_candidate_discovery"',
            '"matching_archive_restore_check"',
            '"matching_archive_restore"',
            '"Saved archive candidate discovery"',
            '"Saved archives root:"',
            "repo_archives/browser or repo_archives/browser/dependencies",
        ):
            self.assertIn(fragment, self.recovery_route)

        for fragment in (
            '"commands": {',
            '"surface_check": surface_check',
            '"recovery_route": recovery',
            'result["commands"]["restore_check_only"] = restore_check',
            'result["commands"]["restore"] = restore_run',
            'result["commands"]["full_readiness"] = readiness',
            'print("Archive restore commands")',
            'print("Suggested follow-up")',
            "scripts/check_issue3_saved_zig_archive_candidates.py",
        ):
            self.assertIn(fragment, self.archive_restore_route + self.archive_restore_note)


if __name__ == "__main__":
    unittest.main()
