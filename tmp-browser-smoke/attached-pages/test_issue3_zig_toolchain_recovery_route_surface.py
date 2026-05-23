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
            .curl = .{ .url = "https://example.invalid/curl.tar.gz" },
        },
    }
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - Run `bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - Prefer a Zig `0.15.2` toolchain
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - `0.15.2`
    """,
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh": r"""
    REFERENCE_PATHS=(
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Read-first Zig line recovery note."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness companion."
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note."
        "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Surface checker."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Route printer."
        "scripts/check_linux_build_readiness.py|file|Readiness helper."
        "build.zig.zon|file|Manifest surface."
    )
    CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Route helper stays visible."
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|Fallback bundle stays visible."
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|0.15.2|Expected Zig line stays visible."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|Linux note points at route."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|build.zig.zon|Route reads branch minimum from manifest."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_linux_build_readiness.py|Route points to readiness helper."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--toolchains-root|Route supports explicit toolchains root."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|Route surfaces fallback archive."
    )
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": r"""
    build_zon = repo_root / "build.zig.zon"
    minimum_zig = "0.15.2"
    fallback_zig_archive = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    patterns = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")
    "surface_check": "bash scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh"
    "discovery": "python scripts/check_linux_build_readiness.py --repo-root /tmp/browser --skip-zig-check --skip-rust-check --expect-saved-archives --saved-archives-root /tmp/memory/repo_archives/browser/dependencies --toolchains-root /tmp/toolchains"
    "matching_readiness": "python scripts/check_linux_build_readiness.py --repo-root /tmp/browser --zig /tmp/toolchains/zig-0.15.7/zig --expect-saved-archives --saved-archives-root /tmp/memory/repo_archives/browser/dependencies --expect-offline-deps --offline-deps-root /tmp/offline-deps --require-prebuilt-v8 --toolchains-root /tmp/toolchains"
    "matches expected-line"
    "mismatched-line"
    "older-than-minimum"
    --toolchains-root
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
    def build_parser():
        parser.add_argument("--fallback-zig-archive")
        parser.add_argument("--toolchains-root")
    class ReadinessHelperTests(unittest.TestCase):
        def test_same_version_line_matches_major_minor_only(self): ...
        def test_resolve_fallback_zig_archive_prefers_default_agent_files(self): ...
        def test_discover_toolchain_zig_candidates_and_describe_versions(self): ...
        def test_parser_accepts_fallback_zig_archive(self): ...
    print("discovered a staged Zig candidate")
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-recovery-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class ZigToolchainRecoveryRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.linux_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.zig_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_route_note_keeps_the_expected_zig_guidance_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "0.15.2",
        ):
            self.assertIn(fragment, self.zig_route_note)

    def test_linux_note_and_runtime_gates_still_point_back_to_zig_recovery(self) -> None:
        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "Prefer a Zig `0.15.2` toolchain",
        ):
            self.assertIn(fragment, self.linux_route_note)

        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_surface_checker_keeps_the_route_helper_and_note_contract(self) -> None:
        for fragment in (
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|',
            '"scripts/check_linux_build_readiness.py|file|',
            '"build.zig.zon|file|Manifest surface',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|0.15.2|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|build.zig.zon|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_linux_build_readiness.py|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--toolchains-root|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_helper_keeps_manifest_discovery_and_matching_readiness_guidance(self) -> None:
        for fragment in (
            'build_zon = repo_root / "build.zig.zon"',
            'fallback_zig_archive = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            '"surface_check": "bash scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh',
            '"discovery": "python scripts/check_linux_build_readiness.py',
            "--skip-zig-check --skip-rust-check --expect-saved-archives",
            "--saved-archives-root /tmp/memory/repo_archives/browser/dependencies",
            "--toolchains-root /tmp/toolchains",
            '"matching_readiness": "python scripts/check_linux_build_readiness.py',
            "--expect-offline-deps --offline-deps-root /tmp/offline-deps --require-prebuilt-v8",
            "matches expected-line",
            "mismatched-line",
            "older-than-minimum",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_readiness_helper_keeps_candidate_discovery_and_toolchain_switches(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "DEFAULT_ZIG_TOOLCHAIN_GLOBS = (",
            '"zig*/zig"',
            '"zig*/bin/zig"',
            'def same_version_line(expected_version: str, actual_version: str) -> bool:',
            'def resolve_default_toolchains_root(repo_root):',
            'def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):',
            'def discover_toolchain_zig_candidates(toolchains_root):',
            'def describe_zig_toolchain_candidate(minimum_zig, zig_path):',
            '--fallback-zig-archive',
            '--toolchains-root',
            'def test_same_version_line_matches_major_minor_only',
            'def test_resolve_fallback_zig_archive_prefers_default_agent_files',
            'def test_discover_toolchain_zig_candidates_and_describe_versions',
            'def test_parser_accepts_fallback_zig_archive',
            "discovered a staged Zig candidate",
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_manifest_still_declares_the_expected_branch_line(self) -> None:
        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
            '.curl = .{ .url = "https://example.invalid/curl.tar.gz" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
