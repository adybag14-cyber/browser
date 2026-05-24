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
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - Run `bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - Prefer a Zig `0.15.2` toolchain
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - `0.15.2`
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md": """
    # Issue #3 Zig Toolchain Archive Restore Route

    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only`
    """,
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh": r"""
    REFERENCE_PATHS=(
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Read-first Zig line recovery note."
        "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|Archive-staging companion note."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness companion."
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note."
        "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Surface checker."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Route printer."
        "scripts/linux/restore_issue3_fallback_zig_toolchain.sh|file|Fallback restore helper."
        "scripts/linux/restore_zig_toolchain_archive.sh|file|Generic archive restore helper."
        "scripts/check_linux_build_readiness.py|file|Readiness helper."
        "build.zig.zon|file|Manifest surface."
    )
    CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Route helper stays visible."
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/restore_issue3_fallback_zig_toolchain.sh|Fallback restore helper stays visible."
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Archive companion stays visible."
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|Fallback bundle stays visible."
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|0.15.2|Expected Zig line stays visible."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|Linux note points at route."
        "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|restore_zig_toolchain_archive.sh|Archive restore helper stays visible."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_issue3_zig_toolchain_recovery_route_surface.sh|Route points at its surface checker."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Route points at archive restore note."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|restore_issue3_fallback_zig_toolchain.sh|Route points at fallback restore helper."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|build.zig.zon|Route reads branch minimum from manifest."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_linux_build_readiness.py|Route points to readiness helper."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--toolchains-root|Route supports explicit toolchains root."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--saved-archives-root|Route supports explicit saved archives root."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--offline-deps-root|Route supports explicit offline deps root."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--fallback-zig-archive|Route supports explicit fallback archive."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|surface_check|Structured output keeps the fail-fast surface check."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|matching_readiness|Structured output keeps the matching readiness command."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|fallback_restore_check|Structured output keeps the fallback restore surface check."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|fallback_restore|Structured output keeps the fallback restore command."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Fallback archive staging|Text output keeps the fallback staging section."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Discovered Zig candidates: none|Text output keeps the empty-candidate state."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|No branch-compatible Zig candidate is staged yet.|Text output keeps the no-match state."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Saved archives root:|Text output keeps the saved archives root."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Offline deps root:|Text output keeps the offline deps root."
        "scripts/linux/restore_issue3_fallback_zig_toolchain.sh|--check-only|Fallback restore helper supports check-only."
        "scripts/linux/restore_zig_toolchain_archive.sh|--check-only|Archive restore helper supports check-only."
    )
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": r"""
    build_zon = repo_root / "build.zig.zon"
    minimum_zig = "0.15.2"
    fallback_zig_archive = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    patterns = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")
    archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    "surface_check": "bash scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh"
    "archive_restore_surface_check": "bash scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    "discovery": "python scripts/check_linux_build_readiness.py --repo-root /tmp/browser --skip-zig-check --skip-rust-check --expect-saved-archives --saved-archives-root /tmp/memory/repo_archives/browser/dependencies --toolchains-root /tmp/toolchains"
    "matching_readiness": "python scripts/check_linux_build_readiness.py --repo-root /tmp/browser --zig /tmp/toolchains/zig-0.15.7/zig --expect-saved-archives --saved-archives-root /tmp/memory/repo_archives/browser/dependencies --expect-offline-deps --offline-deps-root /tmp/offline-deps --require-prebuilt-v8 --toolchains-root /tmp/toolchains"
    "fallback_restore_check": "bash scripts/linux/restore_issue3_fallback_zig_toolchain.sh --check-only"
    "fallback_restore": "bash scripts/linux/restore_issue3_fallback_zig_toolchain.sh"
    "matches expected-line"
    "mismatched-line"
    "older-than-minimum"
    "Fallback archive staging"
    "Discovered Zig candidates: none"
    "No branch-compatible Zig candidate is staged yet."
    "Saved archives root:"
    "Offline deps root:"
    --toolchains-root
    --saved-archives-root
    --offline-deps-root
    --fallback-zig-archive
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
    "scripts/linux/restore_issue3_fallback_zig_toolchain.sh": """
    Usage:
      bash scripts/linux/restore_issue3_fallback_zig_toolchain.sh --check-only
    """,
    "scripts/linux/restore_zig_toolchain_archive.sh": """
    Usage:
      bash scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only
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
        cls.archive_restore_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
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
        cls.fallback_restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_issue3_fallback_zig_toolchain.sh"
        )
        cls.archive_restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_zig_toolchain_archive.sh"
        )

    def test_route_note_keeps_the_expected_zig_guidance_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "0.15.2",
        ):
            self.assertIn(fragment, self.zig_route_note)

    def test_archive_restore_note_stays_linked_to_the_recovery_route(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "zig-0.15.2.tar.xz --check-only",
        ):
            self.assertIn(fragment, self.archive_restore_note)

    def test_linux_note_and_runtime_gates_still_point_back_to_zig_recovery(self) -> None:
        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
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
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|',
            '"scripts/linux/restore_issue3_fallback_zig_toolchain.sh|file|',
            '"scripts/linux/restore_zig_toolchain_archive.sh|file|',
            '"scripts/check_linux_build_readiness.py|file|',
            '"build.zig.zon|file|Manifest surface',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/restore_issue3_fallback_zig_toolchain.sh|',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|0.15.2|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|restore_zig_toolchain_archive.sh|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|build.zig.zon|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_linux_build_readiness.py|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--toolchains-root|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--saved-archives-root|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--offline-deps-root|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--fallback-zig-archive|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|surface_check|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|matching_readiness|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|fallback_restore_check|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|fallback_restore|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Fallback archive staging|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Discovered Zig candidates: none|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|No branch-compatible Zig candidate is staged yet.|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Saved archives root:|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Offline deps root:|',
            '"scripts/linux/restore_issue3_fallback_zig_toolchain.sh|--check-only|',
            '"scripts/linux/restore_zig_toolchain_archive.sh|--check-only|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_helper_keeps_manifest_discovery_and_matching_readiness_guidance(self) -> None:
        for fragment in (
            'build_zon = repo_root / "build.zig.zon"',
            'archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"',
            'fallback_zig_archive = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            '"surface_check": "bash scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh',
            '"archive_restore_surface_check": "bash scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh',
            '"discovery": "python scripts/check_linux_build_readiness.py',
            "--skip-zig-check --skip-rust-check --expect-saved-archives",
            "--saved-archives-root /tmp/memory/repo_archives/browser/dependencies",
            "--toolchains-root /tmp/toolchains",
            '"matching_readiness": "python scripts/check_linux_build_readiness.py',
            "--expect-offline-deps --offline-deps-root /tmp/offline-deps --require-prebuilt-v8",
            '"fallback_restore_check": "bash scripts/linux/restore_issue3_fallback_zig_toolchain.sh --check-only"',
            '"fallback_restore": "bash scripts/linux/restore_issue3_fallback_zig_toolchain.sh"',
            "Fallback archive staging",
            "Discovered Zig candidates: none",
            "No branch-compatible Zig candidate is staged yet.",
            "Saved archives root:",
            "Offline deps root:",
            "--saved-archives-root",
            "--offline-deps-root",
            "--fallback-zig-archive",
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
            "def resolve_default_toolchains_root(repo_root):",
            "def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):",
            "def discover_toolchain_zig_candidates(toolchains_root):",
            "def describe_zig_toolchain_candidate(minimum_zig, zig_path):",
            "--fallback-zig-archive",
            "--toolchains-root",
            "def test_same_version_line_matches_major_minor_only",
            "def test_resolve_fallback_zig_archive_prefers_default_agent_files",
            "def test_discover_toolchain_zig_candidates_and_describe_versions",
            "def test_parser_accepts_fallback_zig_archive",
            "discovered a staged Zig candidate",
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_restore_helpers_keep_surface_only_modes_visible(self) -> None:
        self.assertIn("--check-only", self.fallback_restore_helper)
        self.assertIn("--check-only", self.archive_restore_helper)

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
