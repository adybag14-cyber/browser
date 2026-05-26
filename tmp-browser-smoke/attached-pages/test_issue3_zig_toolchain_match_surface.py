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
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md": """
    # Issue #3 Saved Zig Archive Candidates Route

    - `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - no staged Zig candidate under `../toolchains`
    - `0.15.x` line
    - attached `0.17`
    - infer the Zig version from the archive's top-level extracted directory
    - Prefer a saved Zig `0.15.2` or other `0.15.x` archive
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/check_linux_build_readiness.py`
    - `0.15.x` line
    - `0.17` fallback archive
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
    - `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
    - `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `0.15.x` line
    - Prefer an exact saved Zig `0.15.2` archive
    - `check_issue3_saved_zig_archive_candidates.py --repo-root .`
    """,
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh": r"""
    Usage:
      bash scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh \
        [--repo-root /path/to/browser-repo] \
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
        [--toolchains-root /path/to/toolchains] \
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
        [--json]
    doc_path = repo_root / "docs" / "ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"
    helper_path = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
    restore_helper_path = repo_root / "scripts" / "linux" / "restore_zig_toolchain_archive.sh"
    build_zon_path = repo_root / "build.zig.zon"
    "saved_archives_root"
    "toolchains_root"
    "minimum_zig"
    "zig_archives"
    "commands"
    "failures"
    "restore_check"
    "restore"
    """,
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh": r"""
    ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"
    PROGRESS_TRACKER_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
    SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh")"
    CANDIDATE_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_zig_archive_candidates.py")"
    MATCHING_LINE_GATE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_match.sh")"
    BUILD_READINESS_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_linux_build_readiness.py")"
    ARCHIVE_RESTORE_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh")"
    RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh")"
    "candidate_discovery"
    "matching_line_gate"
    "linux_build_readiness"
    "archive_restore_surface_check"
    "progress_tracker_route"
    "zig_recovery_route"
    "saved-archives root override accepts either repo_archives/browser or repo_archives/browser/dependencies"
    "Default root discovery walks up ancestor directories first"
    """,
    "scripts/linux/check_issue3_zig_toolchain_match.sh": r"""
    Usage:
      bash scripts/linux/check_issue3_zig_toolchain_match.sh \
        [--repo-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
        [--json]
    "saved_zig_archives"
    "preferred_saved_archive"
    "preferred_saved_archive_restore_check"
    "preferred_saved_archive_restore"
    "saved_archive_discovery_command"
    "fallback_zig_archive"
    "show_issue3_zig_toolchain_recovery_route.sh --repo-root"
    "saved Zig archive"
    "matches that line but is not staged yet"
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"
    ARCHIVE_PATTERNS = ("*.tar", "*.tar.gz", "*.tgz", "*.tar.xz", "*.zip")
    ZIG_BINARY_SUFFIXES = ("/zig", "/bin/zig", "/zig.exe", "/bin/zig.exe")
    def build_saved_archive_search_roots(saved_archives_root):
        return [saved_archives_root]
    def infer_archive_top_level(path):
        return None
    def looks_like_zig_toolchain_archive(path, version, top_level):
        return True
    def discover_zig_archives(search_roots):
        return []
    def describe_archive(expected, path):
        return {}
    def choose_preferred_archive(expected, archive_reports):
        return None
    def build_restore_command(repo_root, toolchains_root, archive_path, *, check_only):
        return []
    "saved_archives_search_roots"
    "preferred_archive"
    "fallback_archive"
    "restore_check"
    "restore"
    "no saved Zig archive under"
    "matches the branch's expected"
    "use the fallback archive only as a surfaced stopgap"
    """,
    "scripts/check_linux_build_readiness.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
        "zig*/zig",
        "zig*/bin/zig",
        "*/zig",
        "*/bin/zig",
        "zig",
    )
    SAVED_ARCHIVE_GLOBS = {
        "rust_toolchain": "01-rust-*.tar.xz",
        "html5ever": "02-litefetch-html5ever-*.zip",
        "boringssl": "03-boringssl-zig-main.zip",
        "browser_deps": "04-zig-browser-depo.tar.zip",
    }
    def resolve_default_toolchains_root(repo_root):
        return repo_root.parent / "toolchains"
    def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):
        return fallback_zig_archive
    def discover_toolchain_zig_candidates(toolchains_root):
        return []
    def describe_zig_toolchain_candidate(minimum_zig, zig_path):
        return [], "0.15.7", "matches expected 0.15.x line"
    "suggested_prepare_command"
    "fallback_zig_status"
    "retry `zig build` with a Zig 0.15.2 toolchain"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-match-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ZigToolchainMatchSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"
        )
        cls.recovery_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh"
        )
        cls.match_helper = read_text(
            cls.repo_root / "scripts/linux/check_issue3_zig_toolchain_match.sh"
        )
        cls.candidate_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_route_note_keeps_saved_archive_candidate_contract_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "no staged Zig candidate under `../toolchains`",
            "`0.15.x` line",
            "attached `0.17`",
            "top-level extracted directory",
            "Prefer a saved Zig `0.15.2` or other `0.15.x` archive",
        ):
            self.assertIn(fragment, self.route_note)

    def test_recovery_and_build_readiness_notes_stay_linked_to_saved_candidates(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/check_linux_build_readiness.py",
            "`0.15.x` line",
            "`0.17` fallback archive",
        ):
            self.assertIn(fragment, self.recovery_note)

        for fragment in (
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "`0.15.x` line",
            "Prefer an exact saved Zig `0.15.2` archive",
            "check_issue3_saved_zig_archive_candidates.py --repo-root .",
        ):
            self.assertIn(fragment, self.build_readiness_note)

    def test_surface_checker_keeps_required_json_contract_and_restore_surface(self) -> None:
        for fragment in (
            "check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--toolchains-root /path/to/toolchains",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            'doc_path = repo_root / "docs" / "ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"',
            'helper_path = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"',
            'restore_helper_path = repo_root / "scripts" / "linux" / "restore_zig_toolchain_archive.sh"',
            'build_zon_path = repo_root / "build.zig.zon"',
            '"saved_archives_root"',
            '"toolchains_root"',
            '"minimum_zig"',
            '"zig_archives"',
            '"commands"',
            '"failures"',
            '"restore_check"',
            '"restore"',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_helper_keeps_candidate_discovery_matching_gate_and_readiness_handoff(self) -> None:
        for fragment in (
            'ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"',
            'PROGRESS_TRACKER_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"',
            'SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh")',
            'CANDIDATE_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_zig_archive_candidates.py")',
            'MATCHING_LINE_GATE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_match.sh")',
            'BUILD_READINESS_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_linux_build_readiness.py")',
            'ARCHIVE_RESTORE_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh")',
            'RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh")',
            '"candidate_discovery"',
            '"matching_line_gate"',
            '"linux_build_readiness"',
            '"archive_restore_surface_check"',
            '"progress_tracker_route"',
            '"zig_recovery_route"',
            "saved-archives root override accepts either repo_archives/browser or repo_archives/browser/dependencies",
            "Default root discovery walks up ancestor directories first",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_candidate_and_matching_helpers_keep_saved_archive_selection_visible(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'ARCHIVE_PATTERNS = ("*.tar", "*.tar.gz", "*.tgz", "*.tar.xz", "*.zip")',
            'ZIG_BINARY_SUFFIXES = ("/zig", "/bin/zig", "/zig.exe", "/bin/zig.exe")',
            "def build_saved_archive_search_roots(saved_archives_root):",
            "def infer_archive_top_level(path):",
            "def looks_like_zig_toolchain_archive(path, version, top_level):",
            "def discover_zig_archives(search_roots):",
            "def describe_archive(expected, path):",
            "def choose_preferred_archive(expected, archive_reports):",
            "def build_restore_command(repo_root, toolchains_root, archive_path, *, check_only):",
            '"saved_archives_search_roots"',
            '"preferred_archive"',
            '"fallback_archive"',
            '"restore_check"',
            '"restore"',
            "no saved Zig archive under",
            "matches the branch's expected",
            "use the fallback archive only as a surfaced stopgap",
        ):
            self.assertIn(fragment, self.candidate_helper)

        for fragment in (
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            '"saved_zig_archives"',
            '"preferred_saved_archive"',
            '"preferred_saved_archive_restore_check"',
            '"preferred_saved_archive_restore"',
            '"saved_archive_discovery_command"',
            '"fallback_zig_archive"',
            "show_issue3_zig_toolchain_recovery_route.sh --repo-root",
            "saved Zig archive",
            "matches that line but is not staged yet",
        ):
            self.assertIn(fragment, self.match_helper)

    def test_readiness_helper_and_manifest_stay_aligned_with_saved_zig_route(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "DEFAULT_ZIG_TOOLCHAIN_GLOBS = (",
            '"zig*/zig"',
            '"zig*/bin/zig"',
            "SAVED_ARCHIVE_GLOBS = {",
            '"browser_deps": "04-zig-browser-depo.tar.zip"',
            "def resolve_default_toolchains_root(repo_root):",
            "def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):",
            "def discover_toolchain_zig_candidates(toolchains_root):",
            "def describe_zig_toolchain_candidate(minimum_zig, zig_path):",
            '"suggested_prepare_command"',
            '"fallback_zig_status"',
            "retry `zig build` with a Zig 0.15.2 toolchain",
        ):
            self.assertIn(fragment, self.readiness_helper)

        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
