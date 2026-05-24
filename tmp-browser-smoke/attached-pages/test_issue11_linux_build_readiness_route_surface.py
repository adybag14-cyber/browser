from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
    - `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
    - `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
    - `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/show_issue3_offline_build_inputs_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `python scripts/check_issue3_saved_archive_integrity.py --repo-root .`
    - `bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
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
    - `bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only`
    """,
    "scripts/check_linux_build_readiness.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
        "zig*/zig",
        "zig*/bin/zig",
    )
    SAVED_ARCHIVE_GLOBS: dict[str, str] = {
        "rust_toolchain": "01-rust-*.tar.xz",
        "html5ever": "02-litefetch-html5ever-*.zip",
        "boringssl": "03-boringssl-zig-main.zip",
        "browser_deps": "04-zig-browser-depo.tar.zip",
    }
    def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:
        return (repo_root.parent / "toolchains").resolve()
    def resolve_fallback_zig_archive(repo_root: pathlib.Path, fallback_zig_archive: pathlib.Path | None) -> pathlib.Path | None:
        candidate = resolve_default_agent_files_root(repo_root) / DEFAULT_FALLBACK_ZIG_ARCHIVE
        return candidate if candidate.is_file() else None
    def discover_toolchain_zig_candidates(toolchains_root: pathlib.Path) -> list[pathlib.Path]:
        return []
    def describe_fallback_zig_archive(minimum_zig: str, fallback_zig_archive: pathlib.Path) -> tuple[list[str], str | None, str]:
        return [], "0.17.0", "mismatched: expected 0.15.x line"
    parser.add_argument("--expect-saved-archives")
    parser.add_argument("--saved-archives-root")
    parser.add_argument("--fallback-zig-archive")
    parser.add_argument("--toolchains-root")
    "discovered a staged Zig candidate at "
    "fallback Zig archive "
    """,
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_linux_build_readiness_route.sh \\
        [--repo-root /path/to/browser-repo] \\
        [--memory-root /path/to/workspace/memory] \\
        [--restored-checkout-root /path/to/browser-memory-snapshot] \\
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \\
        [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \\
        [--offline-deps-root /path/to/offline-deps] \\
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
        [--json]
    SAVED_MEMORY_ROUTE_SURFACE_COMMAND=
    SAVED_MEMORY_ROUTE_COMMAND=
    SAVED_MEMORY_INPUTS_COMMAND=
    SAVED_ARCHIVE_ROUTE_SURFACE_COMMAND=
    SAVED_ARCHIVE_ROUTE_COMMAND=
    SAVED_ARCHIVE_INTEGRITY_COMMAND=
    TOOLCHAIN_ROUTE_COMMAND=
    ZIG_ARCHIVE_RESTORE_CHECK_COMMAND=
    SAVED_RUST_SURFACE_COMMAND=
    OFFLINE_ROUTE_COMMAND=
    Saved-browser-snapshot route when no reusable checkout exists yet:
    Saved Memory route surface check:
    Saved Memory route:
    Saved Memory input preflight:
    Saved archive integrity route surface check:
    Saved archive integrity route:
    Saved archive integrity preflight:
    Zig toolchain recovery route:
    Zig archive restore route when a real 0.15.x archive exists but is not staged yet:
    Saved Rust route surface check:
    Offline build-inputs route:
    Fallback Zig archive:
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
    docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
    docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
    docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
    show_issue3_saved_browser_snapshot_route.sh
    check_issue3_saved_memory_inputs_route_surface.sh
    show_issue3_saved_memory_inputs_route.sh
    show_issue3_saved_archive_integrity_route.sh
    show_issue3_zig_toolchain_recovery_route.sh
    restore_zig_toolchain_archive.sh
    show_issue3_saved_rust_toolchain_route.sh
    show_issue3_offline_build_inputs_route.sh
    restore_saved_rust_toolchain.sh
    scripts/check_issue3_saved_memory_inputs.py
    scripts/check_issue3_saved_archive_integrity.py
    scripts/check_linux_build_readiness.py
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh \\
        [--repo-root /path/to/browser-repo] \\
        [--toolchains-root /path/to/toolchains] \\
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \\
        [--offline-deps-root /path/to/offline-deps] \\
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
        [--json]
    normalize_saved_archives_root
    check_issue3_zig_toolchain_recovery_route_surface.sh
    check_issue3_zig_toolchain_archive_restore_route_surface.sh
    scripts/check_linux_build_readiness.py
    scripts/linux/restore_issue3_fallback_zig_toolchain.sh
    scripts/linux/restore_zig_toolchain_archive.sh
    docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
    build.zig.zon
    surface_check
    matching_readiness
    fallback_restore_check
    fallback_restore
    Fallback archive staging
    Discovered Zig candidates: none
    No branch-compatible Zig candidate is staged yet.
    Saved archives root:
    Offline deps root:
    zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
    """,
    "scripts/linux/restore_issue3_fallback_zig_toolchain.sh": """
    Usage:
      bash scripts/linux/restore_issue3_fallback_zig_toolchain.sh \\
        [--browser-root /path/to/browser-repo] \\
        [--toolchains-root /path/to/toolchains] \\
        [--toolchain-root /path/to/toolchains/zig-0.17.0-dev.299+a76ce7710] \\
        [--archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
        [--check-only] \\
        [--json] \\
        [--force]
    --check-only
    Fallback Zig restore surface check passed.
    Suggested probe after restore:
    This helper only stages the attached fallback bundle
    """,
    "scripts/linux/restore_zig_toolchain_archive.sh": """
    Usage:
      scripts/linux/restore_zig_toolchain_archive.sh \\
        [--browser-root /path/to/browser-repo] \\
        [--toolchains-root /path/to/toolchains] \\
        [--archive /path/to/zig-archive.tar.xz] \\
        [--destination /path/to/toolchains/zig-0.15.2] \\
        [--check-only] \\
        [--json] \\
        [--force]
    Supported archive types:
      .tar, .tar.gz, .tgz, .tar.xz, .zip
    check_issue3_zig_toolchain_archive_restore_route_surface.sh
    show_issue3_zig_toolchain_recovery_route.sh
    scripts/check_linux_build_readiness.py
    --check-only
    follow_up_discovery
    follow_up_build_readiness
    Saved Zig toolchain restore surface check passed.
    Suggested follow-up commands:
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue11-route-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11LinuxBuildReadinessRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.build_readiness_doc = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.zig_recovery_doc = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.zig_archive_doc = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_readiness_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.zig_recovery_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.fallback_restore = read_text(
            cls.repo_root / "scripts/linux/restore_issue3_fallback_zig_toolchain.sh"
        )
        cls.archive_restore = read_text(
            cls.repo_root / "scripts/linux/restore_zig_toolchain_archive.sh"
        )

    def test_build_readiness_doc_keeps_archive_integrity_then_recovery_chain_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
            "bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        ):
            self.assertIn(fragment, self.build_readiness_doc)

        archive_index = self.build_readiness_doc.index(
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root ."
        )
        zig_index = self.build_readiness_doc.index(
            "bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        rust_surface_index = self.build_readiness_doc.index(
            "bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"
        )
        rust_route_index = self.build_readiness_doc.index(
            "bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
        )
        offline_index = self.build_readiness_doc.index(
            "bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh"
        )
        self.assertLess(archive_index, zig_index)
        self.assertLess(zig_index, rust_surface_index)
        self.assertLess(rust_surface_index, rust_route_index)
        self.assertLess(rust_route_index, offline_index)

    def test_zig_route_docs_keep_real_archive_path_ahead_of_fallback_only_staging(self) -> None:
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
            self.assertIn(fragment, self.zig_recovery_doc)

        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only",
        ):
            self.assertIn(fragment, self.zig_archive_doc)

    def test_readiness_helper_keeps_saved_archives_toolchains_and_fallback_zig_contract_visible(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            '"zig*/zig"',
            '"zig*/bin/zig"',
            '"rust_toolchain": "01-rust-*.tar.xz"',
            '"html5ever": "02-litefetch-html5ever-*.zip"',
            '"boringssl": "03-boringssl-zig-main.zip"',
            '"browser_deps": "04-zig-browser-depo.tar.zip"',
            'repo_root.parent / "toolchains"',
            'resolve_default_agent_files_root(repo_root) / DEFAULT_FALLBACK_ZIG_ARCHIVE',
            "def discover_toolchain_zig_candidates(",
            "def describe_fallback_zig_archive(",
            '--expect-saved-archives',
            '--saved-archives-root',
            '--fallback-zig-archive',
            '--toolchains-root',
            "discovered a staged Zig candidate at ",
            "fallback Zig archive ",
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_route_scripts_keep_saved_archive_then_matching_candidate_sequence_visible(self) -> None:
        for fragment in (
            "--memory-root /path/to/workspace/memory",
            "--restored-checkout-root /path/to/browser-memory-snapshot",
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--rust-toolchain-dir /path/to/toolchains/rust-1.79.0",
            "--offline-deps-root /path/to/offline-deps",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "SAVED_MEMORY_ROUTE_SURFACE_COMMAND",
            "SAVED_MEMORY_ROUTE_COMMAND",
            "SAVED_MEMORY_INPUTS_COMMAND",
            "SAVED_ARCHIVE_ROUTE_SURFACE_COMMAND",
            "SAVED_ARCHIVE_ROUTE_COMMAND",
            "SAVED_ARCHIVE_INTEGRITY_COMMAND",
            "TOOLCHAIN_ROUTE_COMMAND",
            "ZIG_ARCHIVE_RESTORE_CHECK_COMMAND",
            "SAVED_RUST_SURFACE_COMMAND",
            "OFFLINE_ROUTE_COMMAND",
            "Saved-browser-snapshot route when no reusable checkout exists yet:",
            "Saved Memory route surface check:",
            "Saved Memory route:",
            "Saved Memory input preflight:",
            "Saved archive integrity route surface check:",
            "Saved archive integrity route:",
            "Saved archive integrity preflight:",
            "Zig toolchain recovery route:",
            "Zig archive restore route when a real 0.15.x archive exists but is not staged yet:",
            "Saved Rust route surface check:",
            "Offline build-inputs route:",
            "Fallback Zig archive:",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "show_issue3_saved_browser_snapshot_route.sh",
            "check_issue3_saved_memory_inputs_route_surface.sh",
            "show_issue3_saved_memory_inputs_route.sh",
            "show_issue3_saved_archive_integrity_route.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "restore_zig_toolchain_archive.sh",
            "show_issue3_saved_rust_toolchain_route.sh",
            "show_issue3_offline_build_inputs_route.sh",
            "restore_saved_rust_toolchain.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.build_readiness_route)

        saved_memory_index = self.build_readiness_route.index("Saved Memory input preflight:")
        saved_archive_index = self.build_readiness_route.index(
            "Saved archive integrity preflight:"
        )
        zig_index = self.build_readiness_route.index("Zig toolchain recovery route:")
        rust_index = self.build_readiness_route.index("Saved Rust route surface check:")
        offline_index = self.build_readiness_route.index("Offline build-inputs route:")
        self.assertLess(saved_memory_index, saved_archive_index)
        self.assertLess(saved_archive_index, zig_index)
        self.assertLess(zig_index, rust_index)
        self.assertLess(rust_index, offline_index)

        for fragment in (
            "--toolchains-root /path/to/toolchains",
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--offline-deps-root /path/to/offline-deps",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "normalize_saved_archives_root",
            "check_issue3_zig_toolchain_recovery_route_surface.sh",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "build.zig.zon",
            "surface_check",
            "matching_readiness",
            "fallback_restore_check",
            "fallback_restore",
            "Fallback archive staging",
            "Discovered Zig candidates: none",
            "No branch-compatible Zig candidate is staged yet.",
            "Saved archives root:",
            "Offline deps root:",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        ):
            self.assertIn(fragment, self.zig_recovery_route)

    def test_restore_helpers_keep_check_only_and_follow_up_contract_visible(self) -> None:
        for fragment in (
            "--toolchain-root /path/to/toolchains/zig-0.17.0-dev.299+a76ce7710",
            "--archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--check-only",
            "Fallback Zig restore surface check passed.",
            "Suggested probe after restore:",
            "This helper only stages the attached fallback bundle",
        ):
            self.assertIn(fragment, self.fallback_restore)

        for fragment in (
            "--archive /path/to/zig-archive.tar.xz",
            "--destination /path/to/toolchains/zig-0.15.2",
            "Supported archive types:",
            ".tar, .tar.gz, .tgz, .tar.xz, .zip",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "--check-only",
            "follow_up_discovery",
            "follow_up_build_readiness",
            "Saved Zig toolchain restore surface check passed.",
            "Suggested follow-up commands:",
        ):
            self.assertIn(fragment, self.archive_restore)


if __name__ == "__main__":
    unittest.main()
