from __future__ import annotations

import pathlib
import tempfile
import unittest


FIXTURE_TEXT = """
# Issue #11 Linux Re-entry Route Index

- issue `#11`
- issue `#2`
- issue `#3`
- Memory archive root: `../memory/repo_archives/browser`
- Toolchains root: `../toolchains`
- Offline dependency root: `../offline-deps`
- Attached fallback Zig archive: `../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
- `bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh`
- `bash ./scripts/linux/show_issue3_workspace_context_route.sh`
- `python ./scripts/check_issue3_workspace_context.py --repo-root .`
- `bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh`
- `bash ./scripts/linux/show_issue3_progress_tracker_route.sh`
- `bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
- `bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `python ./scripts/check_issue3_saved_archive_integrity.py --repo-root .`
- `python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .`
- `bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `bash ./scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
- `bash ./scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
- `bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `python ./scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .`
- `python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .`
- `bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
- `bash ./scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
- `python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .`
- `bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
- `bash ./scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
- `bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `bash ./scripts/linux/check_issue3_zig_toolchain_match.sh`
- `bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `python ./scripts/check_linux_build_readiness.py --repo-root .`
- `python ./scripts/check_issue3_build_readiness_rerun.py --repo-root .`
- `bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh`
- `bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- saved-input, archive-integrity, Rust, Zig-line, or offline-dependency checks
- direct `Page.zig` plus `win32_backend.zig` runtime slice
"""


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue11-route-index-"))
    target = root / "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(FIXTURE_TEXT.lstrip("\n"), encoding="utf-8")
    return root


class Issue11LinuxReentryRouteIndexTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = build_fixture_repo()
        cls.route_text = (
            cls.repo_root / "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md"
        ).read_text(encoding="utf-8")

    def test_keeps_issue_handoff_and_shared_roots_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "issue `#2`",
            "issue `#3`",
            "Memory archive root: `../memory/repo_archives/browser`",
            "Toolchains root: `../toolchains`",
            "Offline dependency root: `../offline-deps`",
            "Attached fallback Zig archive: `../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`",
        ):
            self.assertIn(fragment, self.route_text)

    def test_keeps_saved_input_restore_and_progress_tracker_ladder_visible(self) -> None:
        for fragment in (
            "`bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh`",
            "`bash ./scripts/linux/show_issue3_workspace_context_route.sh`",
            "`python ./scripts/check_issue3_workspace_context.py --repo-root .`",
            "`bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh`",
            "`bash ./scripts/linux/show_issue3_progress_tracker_route.sh`",
            "`bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`",
            "`bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh`",
            "`bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`",
            "`bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh`",
            "`python ./scripts/check_issue3_saved_archive_integrity.py --repo-root .`",
            "`python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .`",
            "`bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`",
            "`bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh`",
        ):
            self.assertIn(fragment, self.route_text)

    def test_keeps_rust_zig_and_build_readiness_sequence_visible(self) -> None:
        for fragment in (
            "`bash ./scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`",
            "`bash ./scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`",
            "`bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`",
            "`bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh`",
            "`python ./scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .`",
            "`python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .`",
            "`bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`",
            "`bash ./scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`",
            "`python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .`",
            "`bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`",
            "`bash ./scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`",
            "`bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`",
            "`bash ./scripts/linux/check_issue3_zig_toolchain_match.sh`",
            "`bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`",
            "`bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh`",
            "`python ./scripts/check_linux_build_readiness.py --repo-root .`",
            "`python ./scripts/check_issue3_build_readiness_rerun.py --repo-root .`",
        ):
            self.assertIn(fragment, self.route_text)

    def test_keeps_runtime_handoff_gate_language_visible(self) -> None:
        for fragment in (
            "`bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh`",
            "`bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`",
            "`docs/ISSUE3_RUNTIME_REENTRY_GATES.md`",
            "`docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`",
            "saved-input, archive-integrity, Rust, Zig-line, or offline-dependency checks",
            "direct `Page.zig` plus `win32_backend.zig` runtime slice",
        ):
            self.assertIn(fragment, self.route_text)


if __name__ == "__main__":
    unittest.main()
