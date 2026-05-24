from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md": """
# Issue #3 Restored-Checkout Re-entry Route

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `../browser-memory-snapshot`
- `--expect-helper-surface`
""",
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
# Issue #3 Saved Browser Snapshot Restore Route

- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `--sync-helper-surface`
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
# Issue #3 Enter-Submit Runtime Revalidation

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`
""",
    "scripts/check_issue3_restored_checkout.py": """
RESTORED_CHECKOUT_PATHS = (
    ("build.zig", "top-level build entrypoint"),
    ("build.zig.zon", "dependency manifest"),
    ("docs/HEADED_MODE_ROADMAP.md", "headed-mode roadmap"),
    ("docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md", "headed-mode production guide"),
    ("src/browser/Page.zig", "page runtime surface"),
    ("src/display/win32_backend.zig", "Win32 backend runtime surface"),
)
HELPER_SURFACE_PATHS = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note"),
    ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "runtime revalidation note"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot restore note"),
    ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry note"),
    ("docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md", "saved-archive integrity note"),
    ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness note"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
    ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
    ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness checker"),
    ("scripts/linux/restore_saved_browser_snapshot.sh", "saved snapshot restore helper"),
    ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved snapshot route printer"),
    ("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux build-readiness route printer"),
    ("scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh", "runtime revalidation route printer"),
)
parser.add_argument("--helper-root")
parser.add_argument("--expect-helper-surface")
parser.add_argument("--json")
parser.add_argument("--self-test")
Suggested next step: rerun restore_saved_browser_snapshot.sh with --sync-helper-surface
""",
    "scripts/check_issue3_saved_memory_inputs.py": """
REQUIRED_MEMORY_FILES = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
)
Saved Memory input check passed.
""",
    "scripts/check_issue3_saved_archive_integrity.py": """
DEFAULT_FALLBACK_ZIG_SHA256 = "f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818"
""",
    "scripts/check_linux_build_readiness.py": """
def build_parser():
    parser.add_argument("--skip-zig-check")
    parser.add_argument("--expect-saved-archives")
""",
    "scripts/linux/restore_saved_browser_snapshot.sh": """
--check-only
--helper-root
--sync-helper-surface
Follow-up helper root:
Suggested follow-up checks:
show_issue3_linux_build_readiness_route.sh
show_issue3_enter_submit_runtime_revalidation_route.sh
""",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": """
--helper-root
--sync-helper-surface
Saved-Memory preflight against the restored checkout:
show_issue3_linux_build_readiness_route.sh
show_issue3_enter_submit_runtime_revalidation_route.sh
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
python scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot
""",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": """
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
python scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --expect-helper-surface
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-restored-checkout-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3RestoredCheckoutReentryRouteSurfaceTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
        )
        cls.saved_snapshot_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        )
        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.revalidation_note = read_text(
            cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )
        cls.restored_checkout_helper = read_text(
            cls.repo_root / "scripts/check_issue3_restored_checkout.py"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.saved_archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_archive_integrity.py"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )
        cls.snapshot_route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        cls.build_route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.runtime_route_printer = read_text(
            cls.repo_root
            / "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
        )

    def test_route_note_keeps_restored_checkout_reentry_chain_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "../browser-memory-snapshot",
            "--expect-helper-surface",
        ):
            self.assertIn(fragment, self.route_note)

    def test_companion_notes_keep_restored_checkout_helper_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "--sync-helper-surface",
        ):
            self.assertIn(fragment, self.saved_snapshot_note)

        for fragment in (
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        ):
            self.assertIn(fragment, self.runtime_gates)

        for fragment in (
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
        ):
            self.assertIn(fragment, self.revalidation_note)

    def test_restored_checkout_helper_keeps_required_paths_surface_and_guidance(self) -> None:
        for fragment in (
            '("build.zig", "top-level build entrypoint")',
            '("build.zig.zon", "dependency manifest")',
            '("docs/HEADED_MODE_ROADMAP.md", "headed-mode roadmap")',
            '("docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md", "headed-mode production guide")',
            '("src/browser/Page.zig", "page runtime surface")',
            '("src/display/win32_backend.zig", "Win32 backend runtime surface")',
            '("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note")',
            '("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "runtime revalidation note")',
            '("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot restore note")',
            '("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry note")',
            '("docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md", "saved-archive integrity note")',
            '("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness note")',
            '("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper")',
            '("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper")',
            '("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper")',
            '("scripts/check_linux_build_readiness.py", "Linux build-readiness checker")',
            '("scripts/linux/restore_saved_browser_snapshot.sh", "saved snapshot restore helper")',
            '("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved snapshot route printer")',
            '("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux build-readiness route printer")',
            '("scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh", "runtime revalidation route printer")',
            "--helper-root",
            "--expect-helper-surface",
            "--json",
            "--self-test",
            "rerun restore_saved_browser_snapshot.sh with --sync-helper-surface",
        ):
            self.assertIn(fragment, self.restored_checkout_helper)

    def test_neighbor_helpers_keep_followup_restore_and_preflight_surface_visible(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/blocker_intelligence.yaml",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

        self.assertIn("DEFAULT_FALLBACK_ZIG_SHA256", self.saved_archive_helper)

        for fragment in (
            "--skip-zig-check",
            "--expect-saved-archives",
        ):
            self.assertIn(fragment, self.readiness_helper)

        for fragment in (
            "--check-only",
            "--helper-root",
            "--sync-helper-surface",
            "Follow-up helper root:",
            "Suggested follow-up checks:",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
        ):
            self.assertIn(fragment, self.restore_helper)

        for fragment in (
            "--helper-root",
            "--sync-helper-surface",
            "Saved-Memory preflight against the restored checkout:",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
        ):
            self.assertIn(fragment, self.snapshot_route_printer)

    def test_followup_route_printers_keep_restored_checkout_gate_visible(self) -> None:
        self.assertIn(
            "python scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot",
            self.build_route_printer,
        )
        for fragment in (
            "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "python scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --expect-helper-surface",
        ):
            self.assertIn(fragment, self.runtime_route_printer)


if __name__ == "__main__":
    unittest.main()
