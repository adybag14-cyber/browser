from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


FIXTURE_FILES = {
    "scripts/check_issue3_linux_reentry_route_surfaces.py": """
ROUTE_SURFACE_STEPS = (
    ("workspace_context", "Workspace-context surface", "scripts/linux/check_issue3_workspace_context_route_surface.sh", "scripts/linux/show_issue3_workspace_context_route.sh"),
    ("progress_tracker", "Issue #11 progress-tracker surface", "scripts/linux/check_issue3_progress_tracker_route_surface.sh", "scripts/linux/show_issue3_progress_tracker_route.sh"),
    ("saved_snapshot", "Saved snapshot route surface", "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh", "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"),
    ("restored_checkout", "Restored-checkout route surface", "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh", "scripts/linux/show_issue3_restored_checkout_reentry_route.sh"),
    ("saved_memory", "Saved-Memory route surface", "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh", "scripts/linux/show_issue3_saved_memory_inputs_route.sh"),
    ("saved_archive_integrity", "Saved-archive integrity surface", "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh", "scripts/linux/show_issue3_saved_archive_integrity_route.sh"),
    ("saved_rust_toolchain", "Saved-Rust route surface", "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh", "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"),
    ("saved_zig_candidates", "Saved-Zig candidates route surface", "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh", "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh"),
    ("zig_recovery", "Zig recovery route surface", "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh", "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"),
    ("zig_archive_restore", "Zig archive-restore route surface", "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh", "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"),
    ("offline_build_inputs", "Offline build-inputs route surface", "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh", "scripts/linux/show_issue3_offline_build_inputs_route.sh"),
    ("linux_build_readiness", "Linux build-readiness route surface", "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh", "scripts/linux/show_issue3_linux_build_readiness_route.sh"),
    ("runtime_revalidation", "Runtime revalidation surface", "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh", "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"),
    ("windows_runtime_handoff", "Windows runtime handoff surface", "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh", "scripts/linux/show_issue3_windows_runtime_handoff_route.sh"),
)

def choose_next_step(results, repo_root, python_executable):
    return route_command(repo_root, "scripts/linux/show_issue3_workspace_context_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_progress_tracker_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_saved_browser_snapshot_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_restored_checkout_reentry_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_saved_memory_inputs_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_saved_archive_integrity_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_saved_rust_toolchain_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_offline_build_inputs_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_linux_build_readiness_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_windows_runtime_handoff_route.sh")
    return format_command([python_executable, str(repo_root / "scripts" / "check_issue3_linux_reentry_status.py"), "--repo-root", str(repo_root)])
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-linux-reentry-route-surfaces-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3LinuxReentryRouteSurfacesSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        else:
            cls.repo_root = build_fixture_repo()

        cls.helper = (
            cls.repo_root / "scripts/check_issue3_linux_reentry_route_surfaces.py"
        ).read_text(encoding="utf-8")

    def test_helper_keeps_all_route_surface_checks_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_workspace_context_route_surface.sh",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh",
        ):
            self.assertIn(fragment, self.helper)

    def test_helper_keeps_route_handoff_order_visible(self) -> None:
        for fragment in (
            'scripts/linux/show_issue3_workspace_context_route.sh',
            'scripts/linux/show_issue3_progress_tracker_route.sh',
            'scripts/linux/show_issue3_saved_browser_snapshot_route.sh',
            'scripts/linux/show_issue3_restored_checkout_reentry_route.sh',
            'scripts/linux/show_issue3_saved_memory_inputs_route.sh',
            'scripts/linux/show_issue3_saved_archive_integrity_route.sh',
            'scripts/linux/show_issue3_saved_rust_toolchain_route.sh',
            'scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh',
            'scripts/linux/show_issue3_zig_toolchain_recovery_route.sh',
            'scripts/linux/show_issue3_offline_build_inputs_route.sh',
            'scripts/linux/show_issue3_linux_build_readiness_route.sh',
            'scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh',
            'scripts/linux/show_issue3_windows_runtime_handoff_route.sh',
            'check_issue3_linux_reentry_status.py',
        ):
            self.assertIn(fragment, self.helper)


if __name__ == "__main__":
    unittest.main()
