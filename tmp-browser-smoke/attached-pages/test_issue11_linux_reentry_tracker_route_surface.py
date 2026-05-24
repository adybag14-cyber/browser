from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE11_LINUX_REENTRY_TRACKER_ROUTE.md": """
    # Issue #11 Linux Or WSL Re-entry Tracker Route

    - issue `#11`: Headed runtime re-entry: Linux/WSL build and toolchain readiness tracker
    - `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `scripts/check_issue3_saved_snapshot_archive.py`
    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `scripts/linux/show_issue11_linux_reentry_tracker_route.sh`
    - `bash ./scripts/linux/show_issue11_linux_reentry_tracker_route.sh`
    - `check_issue3_saved_memory_inputs_route_surface.sh`
    - `show_issue3_saved_memory_inputs_route.sh`
    - `check_issue3_saved_archive_integrity_route_surface.sh`
    - `show_issue3_saved_archive_integrity_route.sh`
    - `python ./scripts/check_issue3_saved_snapshot_archive.py`
    - `check_issue3_saved_browser_snapshot_route_surface.sh`
    - `show_issue3_saved_browser_snapshot_route.sh`
    - `python ./scripts/check_issue3_restored_checkout.py`
    - `check_issue3_saved_rust_toolchain_route_surface.sh`
    - `show_issue3_saved_rust_toolchain_route.sh`
    - `check_issue3_zig_toolchain_recovery_route_surface.sh`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    - `check_issue3_offline_build_inputs_route_surface.sh`
    - `show_issue3_offline_build_inputs_route.sh`
    - `check_issue3_linux_build_readiness_route_surface.sh`
    - `show_issue3_linux_build_readiness_route.sh`
    - `check_issue3_enter_submit_runtime_revalidation_route_surface.sh`
    - `show_issue3_enter_submit_runtime_revalidation_route.sh`
    """,
    "scripts/linux/show_issue11_linux_reentry_tracker_route.sh": """
    "saved_memory_surface"
    "saved_memory_route"
    "saved_archive_surface"
    "saved_archive_route"
    "saved_snapshot_archive_audit"
    "saved_browser_snapshot_surface"
    "saved_browser_snapshot_route"
    "restored_checkout_check"
    "saved_rust_surface"
    "saved_rust_route"
    "zig_recovery_surface"
    "zig_recovery_route"
    "offline_inputs_surface"
    "offline_inputs_route"
    "linux_build_surface"
    "linux_build_route"
    "runtime_surface"
    "runtime_route"
    docs/ISSUE11_LINUX_REENTRY_TRACKER_ROUTE.md
    docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
    docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
    scripts/check_issue3_saved_snapshot_archive.py
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
    docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    docs/ISSUE3_RUNTIME_REENTRY_GATES.md
    check_issue3_saved_memory_inputs_route_surface.sh
    show_issue3_saved_memory_inputs_route.sh
    check_issue3_saved_archive_integrity_route_surface.sh
    show_issue3_saved_archive_integrity_route.sh
    check_issue3_saved_snapshot_archive.py
    check_issue3_saved_browser_snapshot_route_surface.sh
    show_issue3_saved_browser_snapshot_route.sh
    check_issue3_restored_checkout.py
    check_issue3_saved_rust_toolchain_route_surface.sh
    show_issue3_saved_rust_toolchain_route.sh
    check_issue3_zig_toolchain_recovery_route_surface.sh
    show_issue3_zig_toolchain_recovery_route.sh
    check_issue3_offline_build_inputs_route_surface.sh
    show_issue3_offline_build_inputs_route.sh
    check_issue3_linux_build_readiness_route_surface.sh
    show_issue3_linux_build_readiness_route.sh
    check_issue3_enter_submit_runtime_revalidation_route_surface.sh
    show_issue3_enter_submit_runtime_revalidation_route.sh
    --restored-checkout-root
    --fallback-zig-archive
    Fallback Zig archive:
    Run the saved_memory_surface and saved_memory_route commands first
    Run the saved_archive_surface and saved_archive_route commands before restore or toolchain work
    Run the saved_snapshot_archive_audit command after the saved-archive route
    """
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue11-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11LinuxReentryTrackerRouteSurfaceTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE11_LINUX_REENTRY_TRACKER_ROUTE.md"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue11_linux_reentry_tracker_route.sh"
        )

    def test_route_note_keeps_issue11_scope_and_issue3_companions_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "scripts/check_issue3_saved_snapshot_archive.py",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "scripts/linux/show_issue11_linux_reentry_tracker_route.sh",
            "bash ./scripts/linux/show_issue11_linux_reentry_tracker_route.sh",
            "check_issue3_saved_memory_inputs_route_surface.sh",
            "show_issue3_saved_memory_inputs_route.sh",
            "check_issue3_saved_archive_integrity_route_surface.sh",
            "show_issue3_saved_archive_integrity_route.sh",
            "python ./scripts/check_issue3_saved_snapshot_archive.py",
            "check_issue3_saved_browser_snapshot_route_surface.sh",
            "show_issue3_saved_browser_snapshot_route.sh",
            "python ./scripts/check_issue3_restored_checkout.py",
            "check_issue3_saved_rust_toolchain_route_surface.sh",
            "show_issue3_saved_rust_toolchain_route.sh",
            "check_issue3_zig_toolchain_recovery_route_surface.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "check_issue3_offline_build_inputs_route_surface.sh",
            "show_issue3_offline_build_inputs_route.sh",
            "check_issue3_linux_build_readiness_route_surface.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "check_issue3_enter_submit_runtime_revalidation_route_surface.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_helper_keeps_ordered_commands_and_read_first_companions_visible(self) -> None:
        for fragment in (
            '"saved_memory_surface"',
            '"saved_memory_route"',
            '"saved_archive_surface"',
            '"saved_archive_route"',
            '"saved_snapshot_archive_audit"',
            '"saved_browser_snapshot_surface"',
            '"saved_browser_snapshot_route"',
            '"restored_checkout_check"',
            '"saved_rust_surface"',
            '"saved_rust_route"',
            '"zig_recovery_surface"',
            '"zig_recovery_route"',
            '"offline_inputs_surface"',
            '"offline_inputs_route"',
            '"linux_build_surface"',
            '"linux_build_route"',
            '"runtime_surface"',
            '"runtime_route"',
            "docs/ISSUE11_LINUX_REENTRY_TRACKER_ROUTE.md",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "scripts/check_issue3_saved_snapshot_archive.py",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "--restored-checkout-root",
            "--fallback-zig-archive",
            "Fallback Zig archive:",
            "Run the saved_memory_surface and saved_memory_route commands first",
            "Run the saved_archive_surface and saved_archive_route commands before restore or toolchain work",
            "Run the saved_snapshot_archive_audit command after the saved-archive route",
        ):
            self.assertIn(fragment, self.route_helper)

        saved_memory_index = self.route_helper.index('"saved_memory_surface"')
        saved_archive_index = self.route_helper.index('"saved_archive_surface"')
        audit_index = self.route_helper.index('"saved_snapshot_archive_audit"')
        snapshot_index = self.route_helper.index('"saved_browser_snapshot_surface"')
        restored_index = self.route_helper.index('"restored_checkout_check"')
        rust_index = self.route_helper.index('"saved_rust_surface"')
        zig_index = self.route_helper.index('"zig_recovery_surface"')
        offline_index = self.route_helper.index('"offline_inputs_surface"')
        linux_index = self.route_helper.index('"linux_build_surface"')
        runtime_index = self.route_helper.index('"runtime_surface"')

        self.assertLess(saved_memory_index, saved_archive_index)
        self.assertLess(saved_archive_index, audit_index)
        self.assertLess(audit_index, snapshot_index)
        self.assertLess(snapshot_index, restored_index)
        self.assertLess(restored_index, rust_index)
        self.assertLess(rust_index, zig_index)
        self.assertLess(zig_index, offline_index)
        self.assertLess(offline_index, linux_index)
        self.assertLess(linux_index, runtime_index)


if __name__ == "__main__":
    unittest.main()
