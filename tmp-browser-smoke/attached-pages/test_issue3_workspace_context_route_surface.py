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
    - `bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh`
    - `bash ./scripts/linux/show_issue3_workspace_context_route.sh`
    - `python scripts/check_issue3_workspace_context.py --repo-root .`
    - `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - `build.zig.zon`
    - the shared `toolchains` directory
    - the saved Memory browser archives
    - the attached fallback Zig archive under `agent_files`
    - the nearest shared offline dependency root
    - the practical restored-checkout root
    1. the current repo root
    2. the nearest shared `toolchains` root
    3. the nearest saved browser-archives root under `memory/repo_archives/browser`
    4. the nearest `agent_files` root
    5. the fallback Zig archive path it resolved
    6. the nearest shared offline dependency root
    7. the practical restored-checkout root
    8. a ready-to-rerun `scripts/check_linux_build_readiness.py` command
    9. a ready-to-rerun issue `#11` progress-tracker route command
    10. a ready-to-rerun saved browser-snapshot route command
    11. a ready-to-rerun Zig recovery route command
    12. a ready-to-rerun Zig matching-line gate command
    13. a ready-to-rerun saved Zig archive candidates command
    - `scripts/check_linux_build_readiness.py`
    - issue `#11` progress-tracker route command
    - `show_issue3_saved_browser_snapshot_route.sh`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    - `show_issue3_saved_zig_archive_candidates_route.sh`
    """,
    "scripts/linux/check_issue3_workspace_context_route_surface.sh": """
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md
    scripts/linux/check_issue3_workspace_context_route_surface.sh
    scripts/linux/show_issue3_workspace_context_route.sh
    scripts/check_issue3_workspace_context.py
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|check_issue3_workspace_context_route_surface.sh
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_workspace_context_route.sh
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|check_issue3_workspace_context.py
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|issue `#11` progress-tracker route command
    scripts/linux/show_issue3_workspace_context_route.sh|workspace-context route
    scripts/linux/show_issue3_workspace_context_route.sh|check_issue3_workspace_context.py
    scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_progress_tracker_route.sh
    scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_saved_browser_snapshot_route.sh
    scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_zig_toolchain_recovery_route.sh
    scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_saved_zig_archive_candidates_route.sh
    scripts/linux/show_issue3_workspace_context_route.sh|resolved_roots
    """,
    "scripts/linux/show_issue3_workspace_context_route.sh": """
    Issue #3 workspace-context route
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md
    scripts/linux/check_issue3_workspace_context_route_surface.sh
    python scripts/check_issue3_workspace_context.py --repo-root /fixture/browser
    "resolved_roots"
    "toolchains_root"
    "memory_root"
    "saved_archives_root"
    "agent_files_root"
    "offline_deps_root"
    "restored_checkout_root"
    "fallback_zig_archive"
    show_issue3_progress_tracker_route.sh
    show_issue3_saved_browser_snapshot_route.sh
    show_issue3_linux_build_readiness_route.sh
    show_issue3_zig_toolchain_recovery_route.sh
    check_issue3_zig_toolchain_match.sh
    show_issue3_saved_zig_archive_candidates_route.sh
    Route surface check:
    Workspace-context helper:
    Follow-up routes
    Issue #11 progress-tracker route:
    Saved browser-snapshot route:
    Linux or WSL build-readiness route:
    Zig recovery route:
    Zig matching-line gate:
    Saved Zig archive-candidates route:
    """,
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
    "memory_root"
    "saved_archives_root"
    "agent_files_root"
    "offline_deps_root"
    "restored_checkout_root"
    "fallback_zig_archive"
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
    "--sync-helper-surface"
    "--saved-archives-root"
    "--toolchains-root"
    "--fallback-zig-archive"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-workspace-context-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3WorkspaceContextRouteSurfaceTest(unittest.TestCase):
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
        cls.route_surface = read_text(
            cls.repo_root / "scripts/linux/check_issue3_workspace_context_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_workspace_context_route.sh"
        )
        cls.workspace_helper = read_text(
            cls.repo_root / "scripts/check_issue3_workspace_context.py"
        )

    def test_route_note_keeps_workspace_context_surfaces_and_followups_visible(self) -> None:
        for fragment in (
            "`scripts/linux/check_issue3_workspace_context_route_surface.sh`",
            "`scripts/linux/show_issue3_workspace_context_route.sh`",
            "`scripts/check_issue3_workspace_context.py`",
            "`docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`",
            "`docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`",
            "`docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`",
            "`docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`",
            "`docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`",
            "bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh",
            "bash ./scripts/linux/show_issue3_workspace_context_route.sh",
            "python scripts/check_issue3_workspace_context.py --repo-root .",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "issue `#11` progress-tracker route command",
            "`show_issue3_saved_browser_snapshot_route.sh`",
            "`show_issue3_zig_toolchain_recovery_route.sh`",
            "`show_issue3_saved_zig_archive_candidates_route.sh`",
            "`scripts/check_linux_build_readiness.py`",
            "the shared `toolchains` directory",
            "the saved Memory browser archives",
            "the attached fallback Zig archive under `agent_files`",
            "the nearest shared offline dependency root",
            "the practical restored-checkout root",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_note_lists_resolved_outputs_in_ordered_handoff(self) -> None:
        ordered_fragments = (
            "1. the current repo root",
            "2. the nearest shared `toolchains` root",
            "3. the nearest saved browser-archives root under `memory/repo_archives/browser`",
            "4. the nearest `agent_files` root",
            "5. the fallback Zig archive path it resolved",
            "6. the nearest shared offline dependency root",
            "7. the practical restored-checkout root",
            "8. a ready-to-rerun `scripts/check_linux_build_readiness.py` command",
            "9. a ready-to-rerun issue `#11` progress-tracker route command",
            "10. a ready-to-rerun saved browser-snapshot route command",
            "11. a ready-to-rerun Zig recovery route command",
            "12. a ready-to-rerun Zig matching-line gate command",
            "13. a ready-to-rerun saved Zig archive candidates command",
        )
        last_index = -1
        for fragment in ordered_fragments:
            current_index = self.route_note.index(fragment)
            self.assertGreater(current_index, last_index)
            last_index = current_index

    def test_route_surface_checker_tracks_workspace_note_printer_and_followups(self) -> None:
        for fragment in (
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "scripts/linux/check_issue3_workspace_context_route_surface.sh",
            "scripts/linux/show_issue3_workspace_context_route.sh",
            "scripts/check_issue3_workspace_context.py",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|check_issue3_workspace_context_route_surface.sh",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_workspace_context_route.sh",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|check_issue3_workspace_context.py",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|issue `#11` progress-tracker route command",
            "scripts/linux/show_issue3_workspace_context_route.sh|workspace-context route",
            "scripts/linux/show_issue3_workspace_context_route.sh|check_issue3_workspace_context.py",
            "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_progress_tracker_route.sh",
            "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_saved_zig_archive_candidates_route.sh",
            "scripts/linux/show_issue3_workspace_context_route.sh|resolved_roots",
        ):
            self.assertIn(fragment, self.route_surface)

    def test_route_printer_keeps_resolved_roots_and_followup_commands_together(self) -> None:
        for fragment in (
            "Issue #3 workspace-context route",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "scripts/linux/check_issue3_workspace_context_route_surface.sh",
            "python scripts/check_issue3_workspace_context.py --repo-root /fixture/browser",
            '"resolved_roots"',
            '"toolchains_root"',
            '"memory_root"',
            '"saved_archives_root"',
            '"agent_files_root"',
            '"offline_deps_root"',
            '"restored_checkout_root"',
            '"fallback_zig_archive"',
            "show_issue3_progress_tracker_route.sh",
            "show_issue3_saved_browser_snapshot_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "check_issue3_zig_toolchain_match.sh",
            "show_issue3_saved_zig_archive_candidates_route.sh",
            "Route surface check:",
            "Workspace-context helper:",
            "Follow-up routes",
            "Issue #11 progress-tracker route:",
            "Saved browser-snapshot route:",
            "Linux or WSL build-readiness route:",
            "Zig recovery route:",
            "Zig matching-line gate:",
            "Saved Zig archive-candidates route:",
        ):
            self.assertIn(fragment, self.route_printer)

        route_surface_index = self.route_printer.index("Route surface check:")
        helper_index = self.route_printer.index("Workspace-context helper:")
        followups_index = self.route_printer.index("Follow-up routes")
        issue11_index = self.route_printer.index("Issue #11 progress-tracker route:")
        saved_snapshot_index = self.route_printer.index("Saved browser-snapshot route:")
        zig_recovery_index = self.route_printer.index("Zig recovery route:")
        saved_zig_index = self.route_printer.index("Saved Zig archive-candidates route:")
        self.assertLess(route_surface_index, helper_index)
        self.assertLess(helper_index, followups_index)
        self.assertLess(followups_index, issue11_index)
        self.assertLess(issue11_index, saved_snapshot_index)
        self.assertLess(saved_snapshot_index, zig_recovery_index)
        self.assertLess(zig_recovery_index, saved_zig_index)

    def test_workspace_helper_keeps_route_command_contract_visible(self) -> None:
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
            '"memory_root"',
            '"saved_archives_root"',
            '"agent_files_root"',
            '"offline_deps_root"',
            '"restored_checkout_root"',
            '"fallback_zig_archive"',
            '"suggested_readiness_command"',
            '"suggested_progress_tracker_route_command"',
            '"suggested_build_readiness_route_command"',
            '"suggested_saved_snapshot_route_command"',
            '"suggested_zig_recovery_route_command"',
            '"suggested_zig_match_command"',
            '"suggested_saved_zig_archive_candidates_command"',
            '"scripts/linux/show_issue3_progress_tracker_route.sh"',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh"',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"',
            '"scripts/linux/check_issue3_zig_toolchain_match.sh"',
            '"scripts/check_issue3_saved_zig_archive_candidates.py"',
            '"--sync-helper-surface"',
            '"--saved-archives-root"',
            '"--toolchains-root"',
            '"--fallback-zig-archive"',
        ):
            self.assertIn(fragment, self.workspace_helper)


if __name__ == "__main__":
    unittest.main()
