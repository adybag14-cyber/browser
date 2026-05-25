from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/check_issue3_workspace_context.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"
    def infer_toolchains_root(repo_root: Path) -> tuple[Path, bool]:
    def infer_memory_root(repo_root: Path) -> tuple[Path, bool]:
    def infer_saved_archives_root(repo_root: Path) -> tuple[Path, bool]:
    def infer_agent_files_root(repo_root: Path) -> tuple[Path, bool]:
    def infer_offline_deps_root(repo_root: Path) -> tuple[Path, bool]:
    def infer_restored_checkout_root(repo_root: Path) -> tuple[Path, bool]:
    def infer_fallback_zig_archive(
    def collect_context(repo_root: Path, explicit_archive: Path | None) -> dict[str, object]:
    "toolchains_root"
    "toolchains_root_found"
    "memory_root"
    "memory_root_found"
    "saved_archives_root"
    "saved_archives_root_found"
    "agent_files_root"
    "agent_files_root_found"
    "offline_deps_root"
    "offline_deps_root_found"
    "restored_checkout_root"
    "restored_checkout_root_found"
    "fallback_zig_archive"
    "fallback_zig_archive_found"
    "suggested_readiness_command"
    "suggested_progress_tracker_route_command"
    "suggested_build_readiness_route_command"
    "suggested_saved_snapshot_route_command"
    "suggested_zig_recovery_route_command"
    "suggested_zig_match_command"
    "suggested_saved_zig_archive_candidates_command"
    "scripts/linux/show_issue3_progress_tracker_route.sh"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    "scripts/linux/check_issue3_zig_toolchain_match.sh"
    "scripts/check_issue3_saved_zig_archive_candidates.py"
    "--memory-root"
    "--saved-archives-root"
    "--toolchains-root"
    "--offline-deps-root"
    "--destination"
    "--sync-helper-surface"
    "--fallback-zig-archive"
    class WorkspaceContextTests(unittest.TestCase):
    def test_locates_roots_above_nested_checkout(self) -> None:
    def test_defaults_when_ancestor_roots_are_missing(self) -> None:
    def test_explicit_fallback_archive_overrides_search(self) -> None:
    def test_missing_build_zon_fails_cleanly(self) -> None:
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(WorkspaceContextTests)
    """,
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md": """
    # Issue #3 Workspace-Context Route

    - `scripts/check_issue3_workspace_context.py`
    - `scripts/check_linux_build_readiness.py`
    - `show_issue3_progress_tracker_route.sh`
    - `show_issue3_saved_browser_snapshot_route.sh`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    - `show_issue3_saved_zig_archive_candidates_route.sh`
    - `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - the shared `toolchains` directory
    - the saved Memory browser archives
    - the attached fallback Zig archive under `agent_files`
    - the nearest shared offline dependency root
    - the practical restored-checkout root
    """,
    "scripts/linux/show_issue3_workspace_context_route.sh": """
    "workspace_context_helper"
    "fallback_zig_archive"
    "toolchains_root"
    "saved_archives_root"
    "offline_deps_root"
    "restored_checkout_root"
    "readiness_command"
    "show_issue3_progress_tracker_route.sh"
    "show_issue3_saved_browser_snapshot_route.sh"
    "show_issue3_linux_build_readiness_route.sh"
    "show_issue3_zig_toolchain_recovery_route.sh"
    "show_issue3_saved_zig_archive_candidates_route.sh"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-workspace-helper-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3WorkspaceContextHelperSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.helper_text = read_text(
            cls.repo_root / "scripts/check_issue3_workspace_context.py"
        )
        cls.route_note = read_text(
            cls.repo_root / "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_workspace_context_route.sh"
        )

    def test_helper_keeps_root_resolution_contract_visible(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"',
            "def infer_toolchains_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_memory_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_saved_archives_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_agent_files_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_offline_deps_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_restored_checkout_root(repo_root: Path) -> tuple[Path, bool]:",
            "def infer_fallback_zig_archive(",
            "def collect_context(repo_root: Path, explicit_archive: Path | None) -> dict[str, object]:",
            '"toolchains_root"',
            '"toolchains_root_found"',
            '"memory_root"',
            '"memory_root_found"',
            '"saved_archives_root"',
            '"saved_archives_root_found"',
            '"agent_files_root"',
            '"agent_files_root_found"',
            '"offline_deps_root"',
            '"offline_deps_root_found"',
            '"restored_checkout_root"',
            '"restored_checkout_root_found"',
            '"fallback_zig_archive"',
            '"fallback_zig_archive_found"',
            '"suggested_readiness_command"',
            '"suggested_progress_tracker_route_command"',
            '"suggested_build_readiness_route_command"',
            '"suggested_saved_snapshot_route_command"',
            '"suggested_zig_recovery_route_command"',
            '"suggested_zig_match_command"',
            '"suggested_saved_zig_archive_candidates_command"',
        ):
            self.assertIn(fragment, self.helper_text)

    def test_helper_threads_followup_routes_and_required_overrides(self) -> None:
        for fragment in (
            '"scripts/linux/show_issue3_progress_tracker_route.sh"',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh"',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"',
            '"scripts/linux/check_issue3_zig_toolchain_match.sh"',
            '"scripts/check_issue3_saved_zig_archive_candidates.py"',
            '"--memory-root"',
            '"--saved-archives-root"',
            '"--toolchains-root"',
            '"--offline-deps-root"',
            '"--destination"',
            '"--sync-helper-surface"',
            '"--fallback-zig-archive"',
        ):
            self.assertIn(fragment, self.helper_text)

    def test_helper_self_test_keeps_the_key_workspace_scenarios(self) -> None:
        for fragment in (
            "class WorkspaceContextTests(unittest.TestCase):",
            "def test_locates_roots_above_nested_checkout(self) -> None:",
            "def test_defaults_when_ancestor_roots_are_missing(self) -> None:",
            "def test_explicit_fallback_archive_overrides_search(self) -> None:",
            "def test_missing_build_zon_fails_cleanly(self) -> None:",
            "suite = unittest.defaultTestLoader.loadTestsFromTestCase(WorkspaceContextTests)",
        ):
            self.assertIn(fragment, self.helper_text)

    def test_route_note_and_printer_keep_helper_handoff_visible(self) -> None:
        for fragment in (
            "`scripts/check_issue3_workspace_context.py`",
            "`scripts/check_linux_build_readiness.py`",
            "`show_issue3_progress_tracker_route.sh`",
            "`show_issue3_saved_browser_snapshot_route.sh`",
            "`show_issue3_zig_toolchain_recovery_route.sh`",
            "`show_issue3_saved_zig_archive_candidates_route.sh`",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "the shared `toolchains` directory",
            "the saved Memory browser archives",
            "the attached fallback Zig archive under `agent_files`",
            "the nearest shared offline dependency root",
            "the practical restored-checkout root",
        ):
            self.assertIn(fragment, self.route_note)

        for fragment in (
            '"workspace_context_helper"',
            '"fallback_zig_archive"',
            '"toolchains_root"',
            '"saved_archives_root"',
            '"offline_deps_root"',
            '"restored_checkout_root"',
            '"readiness_command"',
            '"show_issue3_progress_tracker_route.sh"',
            '"show_issue3_saved_browser_snapshot_route.sh"',
            '"show_issue3_linux_build_readiness_route.sh"',
            '"show_issue3_zig_toolchain_recovery_route.sh"',
            '"show_issue3_saved_zig_archive_candidates_route.sh"',
        ):
            self.assertIn(fragment, self.route_printer)


if __name__ == "__main__":
    unittest.main()
