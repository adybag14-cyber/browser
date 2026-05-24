from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    """,
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
    # Issue #3 Saved Browser Snapshot Restore Route

    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - saved-Memory preflight against the restored checkout
    - `--fallback-zig-archive`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `--fallback-zig-archive`
    - `python scripts/check_issue3_saved_memory_inputs.py --repo-root .`
    """,
    "scripts/check_issue3_restored_checkout.py": """
    parser.add_argument("--helper-root")
    parser.add_argument("--expect-helper-surface")
    """,
    "scripts/check_linux_build_readiness.py": """
    def build_parser():
        parser.add_argument("--skip-zig-check")
        parser.add_argument("--fallback-zig-archive")
    """,
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": r"""
    SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${DESTINATION}"
    SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND="python ${DESTINATION}/scripts/check_issue3_saved_memory_inputs.py --repo-root ${DESTINATION}"
    --fallback-zig-archive
    saved-Memory preflight against the restored checkout
    """,
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": r"""
    SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"
    --fallback-zig-archive
    "Saved Memory input preflight:"
    "Run the saved_memory_inputs command before the broader saved-archive preflight"
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    REQUIRED_MEMORY_FILES: tuple[tuple[str, str], ...] = (
        ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
        ("repo_archives/browser/README.md", "saved repo notes"),
        ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
        ("repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz", "saved Rust toolchain archive"),
        ("repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip", "saved html5ever dependency archive"),
        ("repo_archives/browser/dependencies/03-boringssl-zig-main.zip", "saved BoringSSL archive"),
        ("repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip", "saved browser dependency archive"),
    )

    OPTIONAL_MEMORY_FILES: tuple[tuple[str, str], ...] = (
        ("repo_archives/browser/session_entry_register.yaml", "session entry register"),
    )

    REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
        ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry guide"),
        ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved-browser-snapshot restore guide"),
        ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry guide"),
        ("docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md", "saved-archive integrity guide"),
        ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness guide"),
        ("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "Zig toolchain recovery guide"),
        ("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", "Zig toolchain archive restore guide"),
        ("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "offline build inputs guide"),
        ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain guide"),
        ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
        ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
        ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
        ("scripts/check_linux_build_readiness.py", "Linux build-readiness helper"),
        ("scripts/linux/restore_saved_browser_snapshot.sh", "saved-browser-snapshot restore helper"),
        ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved-browser-snapshot route helper"),
        ("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux build-readiness route helper"),
        ("scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh", "runtime re-entry route helper"),
        ("scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh", "saved Rust toolchain surface checker"),
        ("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "saved Rust toolchain route helper"),
        ("scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh", "Zig toolchain recovery surface checker"),
        ("scripts/linux/show_issue3_zig_toolchain_recovery_route.sh", "Zig toolchain recovery route helper"),
        ("scripts/linux/check_issue3_offline_build_inputs_route_surface.sh", "offline build inputs surface checker"),
        ("scripts/linux/show_issue3_offline_build_inputs_route.sh", "offline build inputs route helper"),
        ("scripts/linux/prepare_offline_build_inputs.sh", "offline build inputs preparation helper"),
    )

    DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
    EXPECTED_REPO_SNAPSHOT_PREFIX = "browser-fork-headed-mode-foundation/"
    REQUIRED_REPO_ROOT_FILE = "build.zig.zon"

    parser.add_argument("--memory-root")
    parser.add_argument("--agent-files-root")
    parser.add_argument("--restored-checkout-root")
    parser.add_argument("--fallback-zig-archive")
    parser.add_argument("--skip-archive-integrity-check")
    parser.add_argument("--json")
    parser.add_argument("--self-test")

    def resolve_default_memory_root(repo_root): ...
    def path_has_live_helper_surface(path): ...
    def resolve_default_helper_root(repo_root): ...
    def resolve_default_agent_files_root(repo_root): ...
    def resolve_default_restored_checkout_root(repo_root): ...
    def collect_repo_root_result(repo_root): ...
    def archive_integrity_result(path, label): ...
    def collect_restored_checkout_result(restored_checkout_root): ...
    def collect_helper_surface_sync_result(helper_root, restored_checkout_root): ...
    def emit_text(result): ...

    "saved repo snapshot"
    "saved repo notes"
    "blocker intelligence"
    "saved Rust toolchain archive"
    "saved html5ever dependency archive"
    "saved BoringSSL archive"
    "saved browser dependency archive"
    "session entry register"
    "fallback Zig archive"
    "Saved Memory input check passed."
    "Saved Memory input check failed."
    "point --repo-root at a live or restored browser checkout before trusting this preflight"
    "suggested next step: re-run the saved-browser restore with --sync-helper-surface before Linux or WSL follow-up work"
    "Suggested next step: point --repo-root at a real browser checkout, restore or remount readable saved repo and dependency archives, and rerun the helper before reopening the issue #3 runtime route."
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-memory-helper-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class SavedMemoryInputsHelperSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.snapshot_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.restored_checkout_helper = read_text(
            cls.repo_root / "scripts/check_issue3_restored_checkout.py"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.snapshot_route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        cls.build_route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )

    def test_helper_keeps_required_memory_and_helper_surface_contract_visible(self) -> None:
        for fragment in (
            '("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot")',
            '("repo_archives/browser/README.md", "saved repo notes")',
            '("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence")',
            '("repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz", "saved Rust toolchain archive")',
            '("repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip", "saved html5ever dependency archive")',
            '("repo_archives/browser/dependencies/03-boringssl-zig-main.zip", "saved BoringSSL archive")',
            '("repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip", "saved browser dependency archive")',
            '("repo_archives/browser/session_entry_register.yaml", "session entry register")',
            '("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry guide")',
            '("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved-browser-snapshot restore guide")',
            '("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness guide")',
            '("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "Zig toolchain recovery guide")',
            '("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", "Zig toolchain archive restore guide")',
            '("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "offline build inputs guide")',
            '("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain guide")',
            '("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper")',
            '("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper")',
            '("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper")',
            '("scripts/check_linux_build_readiness.py", "Linux build-readiness helper")',
            '("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved-browser-snapshot route helper")',
            '("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux build-readiness route helper")',
            '("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "saved Rust toolchain route helper")',
            '("scripts/linux/show_issue3_zig_toolchain_recovery_route.sh", "Zig toolchain recovery route helper")',
            '("scripts/linux/show_issue3_offline_build_inputs_route.sh", "offline build inputs route helper")',
            '("scripts/linux/prepare_offline_build_inputs.sh", "offline build inputs preparation helper")',
            'DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"',
            'EXPECTED_REPO_SNAPSHOT_PREFIX = "browser-fork-headed-mode-foundation/"',
            'REQUIRED_REPO_ROOT_FILE = "build.zig.zon"',
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_helper_keeps_path_resolution_and_reporting_surface_visible(self) -> None:
        for fragment in (
            '--memory-root',
            '--agent-files-root',
            '--restored-checkout-root',
            '--fallback-zig-archive',
            '--skip-archive-integrity-check',
            '--json',
            '--self-test',
            'def resolve_default_memory_root(repo_root)',
            'def path_has_live_helper_surface(path)',
            'def resolve_default_helper_root(repo_root)',
            'def resolve_default_agent_files_root(repo_root)',
            'def resolve_default_restored_checkout_root(repo_root)',
            'def collect_repo_root_result(repo_root)',
            'def archive_integrity_result(path, label)',
            'def collect_restored_checkout_result(restored_checkout_root)',
            'def collect_helper_surface_sync_result(helper_root, restored_checkout_root)',
            'def emit_text(result)',
            'fallback Zig archive',
            'Saved Memory input check passed.',
            'Saved Memory input check failed.',
            'point --repo-root at a live or restored browser checkout before trusting this preflight',
            'suggested next step: re-run the saved-browser restore with --sync-helper-surface before Linux or WSL follow-up work',
            'Suggested next step: point --repo-root at a real browser checkout, restore or remount readable saved repo and dependency archives, and rerun the helper before reopening the issue #3 runtime route.',
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_neighbor_routes_keep_saved_memory_preflight_visible(self) -> None:
        for fragment in (
            'docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md',
            'scripts/check_issue3_saved_memory_inputs.py',
            'scripts/check_linux_build_readiness.py',
            'scripts/linux/show_issue3_saved_browser_snapshot_route.sh',
        ):
            self.assertIn(fragment, self.runtime_gates)

        for fragment in (
            'scripts/check_issue3_saved_memory_inputs.py',
            'scripts/check_issue3_saved_archive_integrity.py',
            'scripts/linux/show_issue3_linux_build_readiness_route.sh',
            'scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh',
            'saved-Memory preflight against the restored checkout',
            '--fallback-zig-archive',
        ):
            self.assertIn(fragment, self.snapshot_route_note)

        for fragment in (
            'scripts/check_issue3_saved_memory_inputs.py',
            'scripts/check_issue3_saved_archive_integrity.py',
            'scripts/linux/show_issue3_saved_browser_snapshot_route.sh',
            'scripts/linux/show_issue3_saved_rust_toolchain_route.sh',
            'scripts/linux/show_issue3_zig_toolchain_recovery_route.sh',
            '--fallback-zig-archive',
            'python scripts/check_issue3_saved_memory_inputs.py --repo-root .',
        ):
            self.assertIn(fragment, self.build_readiness_note)

    def test_route_printers_and_companion_helpers_keep_saved_memory_followups_visible(self) -> None:
        for fragment in (
            'SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${DESTINATION}"',
            'SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND="python ${DESTINATION}/scripts/check_issue3_saved_memory_inputs.py --repo-root ${DESTINATION}"',
            '--fallback-zig-archive',
            'saved-Memory preflight against the restored checkout',
        ):
            self.assertIn(fragment, self.snapshot_route_printer)

        for fragment in (
            'SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"',
            '--fallback-zig-archive',
            '"Saved Memory input preflight:"',
            '"Run the saved_memory_inputs command before the broader saved-archive preflight"',
        ):
            self.assertIn(fragment, self.build_route_printer)

        for fragment in (
            '--helper-root',
            '--expect-helper-surface',
        ):
            self.assertIn(fragment, self.restored_checkout_helper)

        for fragment in (
            '--skip-zig-check',
            '--fallback-zig-archive',
        ):
            self.assertIn(fragment, self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
