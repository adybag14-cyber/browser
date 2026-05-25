from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/check_issue3_saved_memory_inputs.py": """
    repo_archives/browser/01-browser-fork-headed-mode-foundation.zip
    repo_archives/browser/README.md
    repo_archives/browser/blocker_intelligence.yaml
    repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz
    repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip
    docs/ISSUE3_RUNTIME_REENTRY_GATES.md
    docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
    docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md
    docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
    docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
    docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
    docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md
    scripts/check_issue3_saved_memory_inputs.py
    scripts/check_issue3_saved_archive_integrity.py
    scripts/check_issue3_restored_checkout.py
    scripts/check_issue3_workspace_context.py
    scripts/check_linux_build_readiness.py
    scripts/windows/HeadedValidationHelpers.ps1
    scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
    scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1
    scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
    scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1
    scripts/windows/start_attached_pages_catalog.ps1
    tmp-browser-smoke/attached-pages/README.md
    tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py
    scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh
    scripts/linux/show_issue3_saved_browser_snapshot_route.sh
    scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh
    scripts/linux/show_issue3_restored_checkout_reentry_route.sh
    scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
    scripts/linux/show_issue3_saved_archive_integrity_route.sh
    scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
    scripts/linux/show_issue3_linux_build_readiness_route.sh
    scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
    scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
    scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh
    scripts/linux/check_issue3_zig_toolchain_match.sh
    scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh
    scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
    scripts/linux/restore_issue3_fallback_zig_toolchain.sh
    scripts/linux/restore_zig_toolchain_archive.sh
    scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
    scripts/linux/show_issue3_saved_rust_toolchain_route.sh
    scripts/linux/restore_saved_rust_toolchain.sh
    scripts/linux/check_issue3_offline_build_inputs_route_surface.sh
    scripts/linux/show_issue3_offline_build_inputs_route.sh
    scripts/linux/prepare_offline_build_inputs.sh
    DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
    def path_has_live_helper_surface(path):
        return True
    def resolve_default_helper_root(repo_root):
        return repo_root
    helper_surface_sync
    restored-checkout-missing
    Saved Memory input check passed.
    """,
    "scripts/check_issue3_restored_checkout.py": """
    docs/ISSUE3_RUNTIME_REENTRY_GATES.md
    docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
    docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
    docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
    docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
    scripts/check_issue3_saved_memory_inputs.py
    scripts/check_issue3_saved_archive_integrity.py
    scripts/check_issue3_workspace_context.py
    scripts/check_linux_build_readiness.py
    scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh
    scripts/linux/show_issue3_saved_browser_snapshot_route.sh
    scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh
    scripts/linux/show_issue3_saved_memory_inputs_route.sh
    scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh
    scripts/linux/check_issue3_zig_toolchain_match.sh
    scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh
    scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
    scripts/linux/restore_zig_toolchain_archive.sh
    scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh
    scripts/linux/show_issue3_windows_runtime_handoff_route.sh
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-memory-helper-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedMemoryHelperSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.restored_checkout_helper = read_text(
            cls.repo_root / "scripts/check_issue3_restored_checkout.py"
        )

    def test_saved_memory_helper_keeps_core_memory_and_restore_surfaces(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/README.md",
            "repo_archives/browser/blocker_intelligence.yaml",
            "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_workspace_context.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
            "scripts/linux/show_issue3_restored_checkout_reentry_route.sh",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_saved_memory_helper_keeps_windows_and_status_context(self) -> None:
        for fragment in (
            "scripts/windows/HeadedValidationHelpers.ps1",
            "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
            "scripts/windows/start_attached_pages_catalog.ps1",
            "tmp-browser-smoke/attached-pages/README.md",
            "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
            'DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"',
            "path_has_live_helper_surface",
            "resolve_default_helper_root",
            "helper_surface_sync",
            "restored-checkout-missing",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_saved_memory_and_restored_checkout_helpers_share_reentry_contract(self) -> None:
        for fragment in (
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_issue3_workspace_context.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
        ):
            self.assertIn(fragment, self.saved_memory_helper)
            self.assertIn(fragment, self.restored_checkout_helper)


if __name__ == "__main__":
    unittest.main()
