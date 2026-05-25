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
        .name = .browser,
        .version = "0.0.0",
        .minimum_zig_version = "0.15.2",
        .dependencies = .{
            .v8 = .{
                .path = "../zig-v8-fork",
            },
            .@"boringssl-zig" = .{
                .path = "../boringssl-zig",
            },
            .curl = .{
                .url = "https://github.com/curl/curl/releases/download/curl-8_18_0/curl-8.18.0.tar.gz",
            },
        },
    }
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
    - `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
    - `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
    - `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/check_issue3_workspace_context.py`
    - `python scripts/check_issue3_workspace_context.py --repo-root .`
    - `check_issue3_linux_build_readiness_route_surface.sh`
    - `check_issue3_saved_memory_inputs_route_surface.sh`
    - `show_issue3_saved_memory_inputs_route.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `python scripts/check_issue3_saved_archive_integrity.py --repo-root .`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    - `check_issue3_saved_rust_toolchain_route_surface.sh`
    - `show_issue3_saved_rust_toolchain_route.sh`
    - `show_issue3_offline_build_inputs_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `saved Rust 1.79.0 restore command`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    """,
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": """
    docs/ISSUE3_RUNTIME_REENTRY_GATES.md
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md
    docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
    docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
    scripts/check_issue3_restored_checkout.py
    scripts/check_issue3_saved_memory_inputs.py
    scripts/check_issue3_saved_archive_integrity.py
    scripts/check_issue3_workspace_context.py
    scripts/check_linux_build_readiness.py
    scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
    scripts/linux/show_issue3_linux_build_readiness_route.sh
    scripts/linux/restore_saved_rust_toolchain.sh
    scripts/linux/prepare_offline_build_inputs.sh
    build.zig.zon
    saved Rust 1.79.0 restore command
    zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
    """,
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md
    docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
    docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
    docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
    WORKSPACE_CONTEXT_COMMAND=
    RESTORED_CHECKOUT_ROUTE_SURFACE_COMMAND=
    RESTORED_CHECKOUT_ROUTE_COMMAND=
    SAVED_MEMORY_ROUTE_SURFACE_COMMAND=
    SAVED_MEMORY_ROUTE_COMMAND=
    PROGRESS_TRACKER_ROUTE_SURFACE_COMMAND=
    PROGRESS_TRACKER_ROUTE_COMMAND=
    SAVED_ARCHIVE_ROUTE_SURFACE_COMMAND=
    SAVED_ARCHIVE_ROUTE_COMMAND=
    SAVED_MEMORY_INPUTS_COMMAND=
    SAVED_ARCHIVE_INTEGRITY_COMMAND=
    TOOLCHAIN_ROUTE_COMMAND=
    TOOLCHAIN_MATCH_COMMAND=
    SAVED_ZIG_ARCHIVE_CANDIDATES_COMMAND=
    ZIG_ARCHIVE_RESTORE_CHECK_COMMAND=
    SAVED_RUST_SURFACE_COMMAND=
    SAVED_RUST_ROUTE_COMMAND=
    OFFLINE_ROUTE_COMMAND=
    scripts/check_issue3_workspace_context.py
    Workspace-context helper when the checkout sits deeper than the default sibling layout:
    Saved-browser-snapshot route when no reusable checkout exists yet:
    Restored-checkout route surface check:
    Restored-checkout re-entry route:
    Saved Memory route surface check:
    Saved Memory route:
    Progress-tracker route surface check:
    Progress-tracker route:
    Saved Memory input preflight:
    Saved archive integrity route surface check:
    Saved archive integrity route:
    Saved archive integrity preflight:
    Zig toolchain recovery route:
    Zig matching-line gate:
    Saved Zig archive candidate discovery when the exact 0.15.x archive path is not known yet:
    Zig archive restore route when a real 0.15.x archive exists but is not staged yet:
    Saved Rust route surface check:
    Saved Rust toolchain route:
    Offline build-inputs route:
    Restore the saved Rust 1.79.0 toolchain:
    fallback-zig-archive
    Fallback Zig archive:
    """,
    "scripts/check_issue3_workspace_context.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"
    def infer_toolchains_root(repo_root):
        return repo_root
    def infer_saved_archives_root(repo_root):
        return repo_root
    def infer_offline_deps_root(repo_root):
        return repo_root
    def infer_restored_checkout_root(repo_root):
        return repo_root
    def infer_fallback_zig_archive(repo_root, explicit_archive):
        return explicit_archive
    "suggested_progress_tracker_route_command"
    "suggested_build_readiness_route_command"
    "suggested_saved_snapshot_route_command"
    "suggested_zig_recovery_route_command"
    "suggested_zig_match_command"
    "suggested_saved_zig_archive_candidates_command"
    scripts/linux/show_issue3_progress_tracker_route.sh
    scripts/linux/show_issue3_linux_build_readiness_route.sh
    scripts/linux/show_issue3_saved_browser_snapshot_route.sh
    scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
    scripts/linux/check_issue3_zig_toolchain_match.sh
    scripts/check_issue3_saved_zig_archive_candidates.py
    --sync-helper-surface
    --offline-deps-root
    --fallback-zig-archive
    """,
    "scripts/check_linux_build_readiness.py": """
    .minimum_zig_version = "0.15.2"
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
        "zig*/zig",
        "zig*/bin/zig",
        "*/zig",
        "*/bin/zig",
        "zig",
    )
    "saved Rust toolchain archive"
    "saved browser dependency archive"
    def same_version_line(expected_version: str, actual_version: str) -> bool:
        return True
    def resolve_default_toolchains_root(repo_root):
        return repo_root
    def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):
        return fallback_zig_archive
    def discover_toolchain_zig_candidates(toolchains_root):
        return []
    def describe_zig_toolchain_candidate(minimum_zig, zig_path):
        return [], "0.15.7", "matches expected 0.15.x line"
    """,
    "scripts/linux/restore_saved_rust_toolchain.sh": """
    --check-only
    Saved Rust toolchain restore surface check passed.
    Suggested shell setup:
    """,
    "scripts/linux/prepare_offline_build_inputs.sh": """
    --check-only
    Offline dependency surface check passed.
    Suggested validation command:
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-linux-build-readiness-route-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3LinuxBuildReadinessSurfaceTest(unittest.TestCase):
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
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root / "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.workspace_context_helper = read_text(
            cls.repo_root / "scripts/check_issue3_workspace_context.py"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.saved_rust_restore = read_text(
            cls.repo_root / "scripts/linux/restore_saved_rust_toolchain.sh"
        )
        cls.offline_prepare = read_text(
            cls.repo_root / "scripts/linux/prepare_offline_build_inputs.sh"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_runtime_gates_keep_linux_reentry_route_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_build_readiness_note_keeps_saved_archive_and_workspace_surfaces_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "scripts/check_issue3_workspace_context.py",
            "python scripts/check_issue3_workspace_context.py --repo-root .",
            "check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
            "show_issue3_saved_rust_toolchain_route.sh",
            "show_issue3_offline_build_inputs_route.sh",
            "scripts/check_linux_build_readiness.py",
            "saved Rust 1.79.0 restore command",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        ):
            self.assertIn(fragment, self.build_readiness_note)

    def test_surface_checker_keeps_branch_local_dependencies_in_scope(self) -> None:
        for fragment in (
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_issue3_workspace_context.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
            "build.zig.zon",
            "saved Rust 1.79.0 restore command",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_helper_keeps_ordered_handoff_commands_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "WORKSPACE_CONTEXT_COMMAND",
            "RESTORED_CHECKOUT_ROUTE_SURFACE_COMMAND",
            "RESTORED_CHECKOUT_ROUTE_COMMAND",
            "SAVED_MEMORY_ROUTE_SURFACE_COMMAND",
            "SAVED_MEMORY_ROUTE_COMMAND",
            "PROGRESS_TRACKER_ROUTE_SURFACE_COMMAND",
            "PROGRESS_TRACKER_ROUTE_COMMAND",
            "SAVED_ARCHIVE_ROUTE_SURFACE_COMMAND",
            "SAVED_ARCHIVE_ROUTE_COMMAND",
            "SAVED_MEMORY_INPUTS_COMMAND",
            "SAVED_ARCHIVE_INTEGRITY_COMMAND",
            "TOOLCHAIN_ROUTE_COMMAND",
            "TOOLCHAIN_MATCH_COMMAND",
            "SAVED_ZIG_ARCHIVE_CANDIDATES_COMMAND",
            "ZIG_ARCHIVE_RESTORE_CHECK_COMMAND",
            "SAVED_RUST_SURFACE_COMMAND",
            "SAVED_RUST_ROUTE_COMMAND",
            "OFFLINE_ROUTE_COMMAND",
            "scripts/check_issue3_workspace_context.py",
            "Workspace-context helper when the checkout sits deeper than the default sibling layout:",
            "Saved-browser-snapshot route when no reusable checkout exists yet:",
            "Restored-checkout route surface check:",
            "Restored-checkout re-entry route:",
            "Saved Memory route surface check:",
            "Saved Memory route:",
            "Progress-tracker route surface check:",
            "Progress-tracker route:",
            "Saved archive integrity route surface check:",
            "Saved archive integrity route:",
            "Saved archive integrity preflight:",
            "Zig toolchain recovery route:",
            "Zig matching-line gate:",
            "Saved Zig archive candidate discovery when the exact 0.15.x archive path is not known yet:",
            "Saved Rust route surface check:",
            "Saved Rust toolchain route:",
            "Offline build-inputs route:",
            "Restore the saved Rust 1.79.0 toolchain:",
            "fallback-zig-archive",
            "Fallback Zig archive:",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_workspace_and_readiness_helpers_keep_root_and_toolchain_surfaces_visible(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"',
            "def infer_toolchains_root(repo_root):",
            "def infer_saved_archives_root(repo_root):",
            "def infer_offline_deps_root(repo_root):",
            "def infer_restored_checkout_root(repo_root):",
            "def infer_fallback_zig_archive(repo_root, explicit_archive):",
            '"suggested_progress_tracker_route_command"',
            '"suggested_build_readiness_route_command"',
            '"suggested_saved_snapshot_route_command"',
            '"suggested_zig_recovery_route_command"',
            '"suggested_zig_match_command"',
            '"suggested_saved_zig_archive_candidates_command"',
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "--sync-helper-surface",
            "--offline-deps-root",
            "--fallback-zig-archive",
        ):
            self.assertIn(fragment, self.workspace_context_helper)

        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            '"zig*/zig"',
            '"zig*/bin/zig"',
            '"saved Rust toolchain archive"',
            '"saved browser dependency archive"',
            "def same_version_line(expected_version: str, actual_version: str) -> bool:",
            "def resolve_default_toolchains_root(repo_root):",
            "def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):",
            "def discover_toolchain_zig_candidates(toolchains_root):",
            "def describe_zig_toolchain_candidate(minimum_zig, zig_path):",
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_saved_rust_and_offline_restore_helpers_keep_check_only_surface_visible(self) -> None:
        for fragment in (
            "--check-only",
            "Saved Rust toolchain restore surface check passed.",
            "Suggested shell setup:",
        ):
            self.assertIn(fragment, self.saved_rust_restore)

        for fragment in (
            "--check-only",
            "Offline dependency surface check passed.",
            "Suggested validation command:",
        ):
            self.assertIn(fragment, self.offline_prepare)

    def test_build_manifest_keeps_branch_expected_toolchain_line(self) -> None:
        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{',
            '.path = "../zig-v8-fork"',
            '.@"boringssl-zig" = .{',
            '.path = "../boringssl-zig"',
            '.curl = .{',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
