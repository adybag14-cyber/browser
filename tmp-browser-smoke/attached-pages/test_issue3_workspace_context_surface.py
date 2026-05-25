from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md": """
    # Issue #3 Workspace-Context Route

    - `scripts/linux/check_issue3_workspace_context_route_surface.sh`
    - `scripts/linux/show_issue3_workspace_context_route.sh`
    - `scripts/check_issue3_workspace_context.py`
    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
    - `python scripts/check_issue3_workspace_context.py --repo-root .`
    - `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - the shared `toolchains` directory
    - the saved Memory browser archives
    - the attached fallback Zig archive under `agent_files`
    - the nearest shared offline dependency root
    - the practical restored-checkout root
    """,
    "scripts/linux/check_issue3_workspace_context_route_surface.sh": r"""
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
    scripts/linux/check_issue3_workspace_context_route_surface.sh
    scripts/linux/show_issue3_workspace_context_route.sh
    scripts/check_issue3_workspace_context.py
    scripts/linux/show_issue3_progress_tracker_route.sh
    scripts/linux/show_issue3_saved_browser_snapshot_route.sh
    scripts/linux/show_issue3_linux_build_readiness_route.sh
    scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh
    scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh
    scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
    check_issue3_workspace_context_route_surface.sh
    show_issue3_workspace_context_route.sh
    python scripts/check_issue3_workspace_context.py --repo-root .
    show_issue3_progress_tracker_route.sh
    show_issue3_saved_browser_snapshot_route.sh
    show_issue3_linux_build_readiness_route.sh
    show_issue3_zig_toolchain_recovery_route.sh
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
    fallback_zig_archive
    toolchains_root
    saved_archives_root
    offline_deps_root
    restored_checkout_root
    """,
    "scripts/linux/show_issue3_workspace_context_route.sh": r"""
    helper_script = repo_root / "scripts" / "check_issue3_workspace_context.py"
    route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_workspace_context_route_surface.sh"
    progress_tracker_route_script = repo_root / "scripts" / "linux" / "show_issue3_progress_tracker_route.sh"
    saved_snapshot_route_script = repo_root / "scripts" / "linux" / "show_issue3_saved_browser_snapshot_route.sh"
    linux_build_route_script = repo_root / "scripts" / "linux" / "show_issue3_linux_build_readiness_route.sh"
    zig_recovery_route_script = repo_root / "scripts" / "linux" / "show_issue3_zig_toolchain_recovery_route.sh"
    saved_zig_route_script = repo_root / "scripts" / "linux" / "show_issue3_saved_zig_archive_candidates_route.sh"
    "fallback_zig_archive"
    "toolchains_root"
    "saved_archives_root"
    "offline_deps_root"
    "restored_checkout_root"
    "issue11_progress_tracker_route"
    "saved_browser_snapshot_route"
    "linux_build_readiness_route"
    "zig_toolchain_recovery_route"
    "saved_zig_archive_candidates_route"
    "readiness_command"
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
    Thread --fallback-zig-archive through this route
    Shortest readiness handoff:
    """,
    "scripts/check_issue3_workspace_context.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"
    def ancestor_chain(start: Path) -> list[Path]:
        return []
    def locate_first_existing(start: Path, relative_path: str) -> Path | None:
        return None
    def infer_toolchains_root(repo_root: Path) -> tuple[Path, bool]:
        return repo_root, False
    def infer_memory_root(repo_root: Path) -> tuple[Path, bool]:
        return repo_root, False
    def infer_saved_archives_root(repo_root: Path) -> tuple[Path, bool]:
        return repo_root, False
    def infer_agent_files_root(repo_root: Path) -> tuple[Path, bool]:
        return repo_root, False
    def infer_offline_deps_root(repo_root: Path) -> tuple[Path, bool]:
        return repo_root, False
    def infer_restored_checkout_root(repo_root: Path) -> tuple[Path, bool]:
        return repo_root, False
    def infer_fallback_zig_archive(
        repo_root: Path, explicit_archive: Path | None
    ) -> tuple[Path | None, bool]:
        return explicit_archive, False
    "suggested_readiness_command"
    "suggested_progress_tracker_route_command"
    "suggested_build_readiness_route_command"
    "suggested_saved_snapshot_route_command"
    "suggested_zig_recovery_route_command"
    "suggested_zig_match_command"
    "suggested_saved_zig_archive_candidates_command"
    "fallback_zig_archive_found"
    "restored_checkout_root_found"
    scripts/check_linux_build_readiness.py
    scripts/linux/show_issue3_progress_tracker_route.sh
    scripts/linux/show_issue3_saved_browser_snapshot_route.sh
    scripts/linux/show_issue3_linux_build_readiness_route.sh
    scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
    scripts/check_issue3_saved_zig_archive_candidates.py
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-workspace-context-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3WorkspaceContextSurfaceTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md"
        )
        cls.surface_script = read_text(
            cls.repo_root / "scripts/linux/check_issue3_workspace_context_route_surface.sh"
        )
        cls.route_script = read_text(
            cls.repo_root / "scripts/linux/show_issue3_workspace_context_route.sh"
        )
        cls.helper_script = read_text(
            cls.repo_root / "scripts/check_issue3_workspace_context.py"
        )

    def test_route_note_keeps_workspace_roots_and_followups_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_workspace_context_route_surface.sh",
            "scripts/linux/show_issue3_workspace_context_route.sh",
            "scripts/check_issue3_workspace_context.py",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "python scripts/check_issue3_workspace_context.py --repo-root .",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "the shared `toolchains` directory",
            "the saved Memory browser archives",
            "the attached fallback Zig archive under `agent_files`",
            "the nearest shared offline dependency root",
            "the practical restored-checkout root",
        ):
            self.assertIn(fragment, self.route_note)

    def test_surface_checker_keeps_route_contract_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "scripts/linux/check_issue3_workspace_context_route_surface.sh",
            "scripts/linux/show_issue3_workspace_context_route.sh",
            "scripts/check_issue3_workspace_context.py",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "python scripts/check_issue3_workspace_context.py --repo-root .",
            "fallback_zig_archive",
            "toolchains_root",
            "saved_archives_root",
            "offline_deps_root",
            "restored_checkout_root",
        ):
            self.assertIn(fragment, self.surface_script)

    def test_route_printer_keeps_followup_commands_and_json_fields_visible(self) -> None:
        for fragment in (
            'helper_script = repo_root / "scripts" / "check_issue3_workspace_context.py"',
            'route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_workspace_context_route_surface.sh"',
            'progress_tracker_route_script = repo_root / "scripts" / "linux" / "show_issue3_progress_tracker_route.sh"',
            'saved_snapshot_route_script = repo_root / "scripts" / "linux" / "show_issue3_saved_browser_snapshot_route.sh"',
            'linux_build_route_script = repo_root / "scripts" / "linux" / "show_issue3_linux_build_readiness_route.sh"',
            'zig_recovery_route_script = repo_root / "scripts" / "linux" / "show_issue3_zig_toolchain_recovery_route.sh"',
            'saved_zig_route_script = repo_root / "scripts" / "linux" / "show_issue3_saved_zig_archive_candidates_route.sh"',
            '"fallback_zig_archive"',
            '"toolchains_root"',
            '"saved_archives_root"',
            '"offline_deps_root"',
            '"restored_checkout_root"',
            '"issue11_progress_tracker_route"',
            '"saved_browser_snapshot_route"',
            '"linux_build_readiness_route"',
            '"zig_toolchain_recovery_route"',
            '"saved_zig_archive_candidates_route"',
            '"readiness_command"',
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "Thread --fallback-zig-archive through this route",
            "Shortest readiness handoff:",
        ):
            self.assertIn(fragment, self.route_script)

    def test_helper_keeps_workspace_discovery_and_command_threading_visible(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"',
            "def ancestor_chain(start: Path) -> list[Path]:",
            "def locate_first_existing(start: Path, relative_path: str) -> Path | None:",
            "def infer_toolchains_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_memory_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_saved_archives_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_agent_files_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_offline_deps_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_restored_checkout_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_fallback_zig_archive(",
            '"suggested_readiness_command"',
            '"suggested_progress_tracker_route_command"',
            '"suggested_build_readiness_route_command"',
            '"suggested_saved_snapshot_route_command"',
            '"suggested_zig_recovery_route_command"',
            '"suggested_zig_match_command"',
            '"suggested_saved_zig_archive_candidates_command"',
            '"fallback_zig_archive_found"',
            '"restored_checkout_root_found"',
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
        ):
            self.assertIn(fragment, self.helper_script)


if __name__ == "__main__":
    unittest.main()
