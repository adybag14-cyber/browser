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

    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/check_linux_build_readiness.py`
    - `0.15.2`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - This helper passes only when at least one staged Zig executable under
      `../toolchains` matches the branch's expected `0.15.x` line.
    - When the only visible input is the attached `0.17` fallback archive, the
      helper fails fast and points the run back at the broader recovery route.
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `0.15.x` toolchain is available
    """,
    "scripts/linux/check_issue3_zig_toolchain_match.sh": r"""
    Usage:
      bash scripts/linux/check_issue3_zig_toolchain_match.sh \
        [--repo-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
        [--json]
    minimum_match = re.search(
        r'\.minimum_zig_version\s*=\s*"([^"]+)"',
        build_zon.read_text(encoding="utf-8"),
    )
    patterns = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")
    if actual_parts < minimum_parts:
        return "older-than-minimum"
    if actual_parts[:2] == minimum_parts[:2]:
        return "matches-expected-line"
    return "mismatched-line"
    "status": "failed" if failures else "passed"
    "matching_zig_candidates": matching_candidates,
    "fallback_zig_archive": fallback_record,
    "suggested_next_step": (
        f"Run bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root {repo_root}"
    )
    print("Discovered Zig candidates: none")
    print("Matching Zig toolchain check passed.")
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": r"""
    route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_recovery_route_surface.sh"
    archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    "matching_readiness"
    "fallback_restore_check"
    "fallback_restore"
    "Saved archives root:"
    "Offline deps root:"
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
    def same_version_line(expected_version: str, actual_version: str) -> bool:
        return True
    def resolve_default_toolchains_root(repo_root):
        return repo_root.parent / "toolchains"
    def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):
        return fallback_zig_archive
    def discover_toolchain_zig_candidates(toolchains_root):
        return []
    def describe_zig_toolchain_candidate(minimum_zig, zig_path):
        return [], "0.15.7", "matches expected 0.15.x line"
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

        cls.recovery_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.match_helper = read_text(
            cls.repo_root / "scripts/linux/check_issue3_zig_toolchain_match.sh"
        )
        cls.recovery_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_recovery_note_keeps_matching_gate_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/check_linux_build_readiness.py",
            "0.15.2",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "matches the branch's expected `0.15.x` line",
            "attached `0.17` fallback archive",
            "points the run back at the broader recovery route",
        ):
            self.assertIn(fragment, self.recovery_note)

    def test_build_readiness_note_stays_linked_to_the_matching_line_route(self) -> None:
        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "`0.15.x` toolchain is available",
        ):
            self.assertIn(fragment, self.build_readiness_note)

    def test_match_helper_keeps_fail_fast_gate_and_followup_route_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/check_issue3_zig_toolchain_match.sh",
            "--repo-root /path/to/browser-repo",
            "--toolchains-root /path/to/toolchains",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--json",
            '.minimum_zig_version\\s*=\\s*"([^"]+)"',
            '("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")',
            '"older-than-minimum"',
            '"matches-expected-line"',
            '"mismatched-line"',
            '"status": "failed" if failures else "passed"',
            '"matching_zig_candidates": matching_candidates',
            '"fallback_zig_archive": fallback_record',
            '"suggested_next_step": (',
            "show_issue3_zig_toolchain_recovery_route.sh --repo-root",
            'print("Discovered Zig candidates: none")',
            'print("Matching Zig toolchain check passed.")',
        ):
            self.assertIn(fragment, self.match_helper)

    def test_companion_helpers_keep_candidate_discovery_surface_in_scope(self) -> None:
        for fragment in (
            'route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_recovery_route_surface.sh"',
            'archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"',
            '"matching_readiness"',
            '"fallback_restore_check"',
            '"fallback_restore"',
            '"Saved archives root:"',
            '"Offline deps root:"',
        ):
            self.assertIn(fragment, self.recovery_helper)

        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "DEFAULT_ZIG_TOOLCHAIN_GLOBS = (",
            '"zig*/zig"',
            '"zig*/bin/zig"',
            'def same_version_line(expected_version: str, actual_version: str) -> bool:',
            "def resolve_default_toolchains_root(repo_root):",
            "def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):",
            "def discover_toolchain_zig_candidates(toolchains_root):",
            "def describe_zig_toolchain_candidate(minimum_zig, zig_path):",
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_manifest_still_declares_branch_expected_zig_line(self) -> None:
        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
