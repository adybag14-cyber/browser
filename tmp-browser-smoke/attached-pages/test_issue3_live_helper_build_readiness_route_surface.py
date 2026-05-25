from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/linux/show_issue3_live_helper_build_readiness_route.sh": r"""
Usage:
  bash scripts/linux/show_issue3_live_helper_build_readiness_route.sh \
    [--repo-root /path/to/restored-or-live-browser-repo] \
    [--helper-root /path/to/live/helper/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]
DEFAULT_HELPER_ROOT=
HELPER_ROOT=
HELPER_WORKSPACE_ROOT=
--helper-root
route_surface
workspace_context
restored_checkout_route
saved_memory_route
progress_tracker_route
saved_memory_inputs
saved_archive_integrity
zig_toolchain_route
zig_toolchain_match
saved_rust_route
offline_build_inputs_route
full_readiness
scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
scripts/linux/show_issue3_restored_checkout_reentry_route.sh
scripts/linux/show_issue3_saved_memory_inputs_route.sh
scripts/linux/show_issue3_progress_tracker_route.sh
scripts/check_issue3_saved_memory_inputs.py
scripts/check_issue3_saved_archive_integrity.py
scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
scripts/linux/check_issue3_zig_toolchain_match.sh
scripts/linux/show_issue3_saved_rust_toolchain_route.sh
scripts/linux/show_issue3_offline_build_inputs_route.sh
scripts/check_linux_build_readiness.py
--repo-root $(format_shell_arg "${REPO_ROOT}")
--helper-root $(format_shell_arg "${HELPER_ROOT}")
--memory-root $(format_shell_arg "${MEMORY_ROOT}")
--restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")
--saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}")
--toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")
--offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")
--fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")
Use this route when repo_root is a restored checkout but helper_root should stay on the current live branch-local helper surface.
Keep helper_root threaded into the restored-checkout, saved-Memory, and progress-tracker routes so nested follow-ups do not fall back to stale restored-tree helpers.
Keep repo_root pointed at the restored checkout for saved-input, archive-integrity, Zig, Rust, offline-input, and full-readiness commands so validation still targets the actual replay tree.
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-live-helper-build-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3LiveHelperBuildReadinessRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_script = read_text(
            cls.repo_root / "scripts/linux/show_issue3_live_helper_build_readiness_route.sh"
        )

    def test_route_script_keeps_live_helper_and_restored_checkout_contract_visible(self) -> None:
        for fragment in (
            "show_issue3_live_helper_build_readiness_route.sh",
            "--repo-root /path/to/restored-or-live-browser-repo",
            "--helper-root /path/to/live/helper/browser-repo",
            "DEFAULT_HELPER_ROOT",
            "HELPER_ROOT",
            "HELPER_WORKSPACE_ROOT",
            "route_surface",
            "workspace_context",
            "restored_checkout_route",
            "saved_memory_route",
            "progress_tracker_route",
            "saved_memory_inputs",
            "saved_archive_integrity",
            "zig_toolchain_route",
            "zig_toolchain_match",
            "saved_rust_route",
            "offline_build_inputs_route",
            "full_readiness",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_restored_checkout_reentry_route.sh",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/check_linux_build_readiness.py",
            '--repo-root $(format_shell_arg "${REPO_ROOT}")',
            '--helper-root $(format_shell_arg "${HELPER_ROOT}")',
            '--memory-root $(format_shell_arg "${MEMORY_ROOT}")',
            '--restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")',
            '--saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}")',
            '--toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")',
            '--offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")',
            '--fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")',
            "Use this route when repo_root is a restored checkout but helper_root should stay on the current live branch-local helper surface.",
            "Keep helper_root threaded into the restored-checkout, saved-Memory, and progress-tracker routes so nested follow-ups do not fall back to stale restored-tree helpers.",
            "Keep repo_root pointed at the restored checkout for saved-input, archive-integrity, Zig, Rust, offline-input, and full-readiness commands so validation still targets the actual replay tree.",
        ):
            self.assertIn(fragment, self.route_script)


if __name__ == "__main__":
    unittest.main()
