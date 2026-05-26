from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md": """
    # Issue #11 Linux Re-entry Route Index

    - https://github.com/adybag14-cyber/browser/issues/11
    - `../memory/repo_archives/browser`
    - `../toolchains`
    - `../offline-deps`
    - `../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - `scripts/linux/check_issue3_workspace_context_route_surface.sh`
    - `scripts/linux/show_issue3_workspace_context_route.sh`
    - `scripts/check_issue3_workspace_context.py --repo-root .`
    - `scripts/check_issue11_reentry_inventory_consistency.py --repo-root .`
    - `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
    - `scripts/linux/show_issue3_progress_tracker_route.sh`
    - `scripts/check_issue11_progress_tracker_surface.py --repo-root .`
    - `scripts/check_issue11_toolchains_root_candidates.py --repo-root .`
    - `scripts/linux/show_issue11_runtime_reentry_tracker_route.sh --repo-root .`
    Goal:
    Started:
    Next:
    Achieved:
    Completed:
    Commit:
    Validation:
    - `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
    - `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
    - `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
    - `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
    - `scripts/check_issue3_saved_archive_integrity.py --repo-root .`
    - `scripts/check_issue3_saved_memory_inputs.py --repo-root .`
    - `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .`
    - `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
    - `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/check_linux_build_readiness.py --repo-root .`
    - `scripts/check_issue3_build_readiness_rerun.py --repo-root .`
    - `scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
    """,
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    - issue `#11`
    - `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
    - `scripts/linux/show_issue3_progress_tracker_route.sh`
    """,
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md": """
    - `scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    - `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue11-route-index-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11LinuxReentryRouteIndexSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_index = read_text(
            cls.repo_root / "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md"
        )
        cls.progress_note = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.saved_rust_bridge_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )

    def test_route_index_keeps_issue11_status_lane_and_workspace_roots_visible(self) -> None:
        for fragment in (
            "https://github.com/adybag14-cyber/browser/issues/11",
            "../memory/repo_archives/browser",
            "../toolchains",
            "../offline-deps",
            "../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "scripts/linux/check_issue3_workspace_context_route_surface.sh",
            "scripts/linux/show_issue3_workspace_context_route.sh",
            "scripts/check_issue3_workspace_context.py --repo-root .",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "Goal:",
            "Started:",
            "Next:",
            "Achieved:",
            "Completed:",
            "Commit:",
            "Validation:",
        ):
            self.assertIn(fragment, self.route_index)

    def test_route_index_keeps_live_issue11_helpers_and_excludes_stale_missing_ones(self) -> None:
        for fragment in (
            "scripts/check_issue11_progress_tracker_surface.py --repo-root .",
            "scripts/check_issue11_reentry_inventory_consistency.py --repo-root .",
            "scripts/check_issue11_toolchains_root_candidates.py --repo-root .",
            "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh --repo-root .",
            "scripts/check_issue3_build_readiness_rerun.py --repo-root .",
        ):
            self.assertIn(fragment, self.route_index)

        for fragment in (
            "scripts/check_issue11_workspace_readiness.py --repo-root .",
            "scripts/linux/show_issue11_matching_zig_readiness_command.sh --repo-root .",
        ):
            self.assertNotIn(fragment, self.route_index)

    def test_route_index_keeps_saved_input_rust_zig_and_runtime_handoffs_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
            "scripts/check_issue3_saved_archive_integrity.py --repo-root .",
            "scripts/check_issue3_saved_memory_inputs.py --repo-root .",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .",
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_linux_build_readiness.py --repo-root .",
            "scripts/check_issue3_build_readiness_rerun.py --repo-root .",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        ):
            self.assertIn(fragment, self.route_index)

    def test_companion_notes_keep_index_targets_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
        ):
            self.assertIn(fragment, self.progress_note)

        for fragment in (
            "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
        ):
            self.assertIn(fragment, self.saved_rust_bridge_note)

        for fragment in (
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        ):
            self.assertIn(fragment, self.build_readiness_note)


if __name__ == "__main__":
    unittest.main()
