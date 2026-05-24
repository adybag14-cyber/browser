from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "build.zig.zon": """
.{
    .name = "browser",
    .version = "0.0.0",
    .minimum_zig_version = "0.15.2",
}
""",
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md": """
# Issue #3 Saved Archive Integrity Route

- `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `--require-fallback-zig`
""",
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
# Issue #3 Saved Browser Snapshot Route

- `scripts/check_issue3_saved_archive_integrity.py`
Saved-archive integrity preflight against the restored checkout:
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `scripts/check_issue3_saved_archive_integrity.py`
- `python scripts/check_issue3_saved_archive_integrity.py --repo-root .`
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `python scripts/check_issue3_saved_archive_integrity.py --repo-root .`
""",
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh": r"""
VERIFY_COMMAND="python scripts/check_issue3_saved_archive_integrity.py --repo-root ${REPO_ROOT}"
STRICT_VERIFY_COMMAND="${VERIFY_COMMAND} --require-fallback-zig"
PRESENCE_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"
RESTORE_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root ${REPO_ROOT}"
BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${REPO_ROOT}"
RUNTIME_ROUTE_COMMAND="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ${REPO_ROOT}"
Saved-Memory presence preflight:
""",
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|"
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|"
    "scripts/check_issue3_saved_archive_integrity.py|file|"
    "scripts/check_issue3_saved_memory_inputs.py|file|"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|"
    "build.zig.zon|file|"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/linux/show_issue3_saved_archive_integrity_route.sh|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|--require-fallback-zig|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_linux_build_readiness_route.sh|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Saved-archive integrity preflight against the restored checkout:|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_saved_archive_integrity_route.sh|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|"
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|check_issue3_saved_archive_integrity.py|"
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|--require-fallback-zig|"
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|show_issue3_saved_browser_snapshot_route.sh|"
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|show_issue3_linux_build_readiness_route.sh|"
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|"
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved-Memory presence preflight:|"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-archive integrity preflight against the restored checkout:|"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|scripts/check_issue3_saved_archive_integrity.py|"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved archive integrity preflight:|"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_saved_archive_integrity.py|"
    "scripts/check_issue3_saved_archive_integrity.py|DEFAULT_FALLBACK_ZIG_SHA256|"
    "scripts/check_issue3_saved_archive_integrity.py|Suggested next step: refresh the mismatched archive|"
)
""",
    "scripts/check_issue3_saved_archive_integrity.py": """
DEFAULT_FALLBACK_ZIG_SHA256 = "f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818"
print("Suggested next step: refresh the mismatched archive")
""",
    "scripts/check_issue3_saved_memory_inputs.py": """
print("Saved Memory input check passed.")
""",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": """
Saved-archive integrity preflight against the restored checkout:
scripts/check_issue3_saved_archive_integrity.py
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
Saved archive integrity preflight:
scripts/check_issue3_saved_archive_integrity.py
""",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": """
Issue #3 runtime re-entry route
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-archive-integrity-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class SavedArchiveIntegrityRouteSurfaceTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md"
        )
        cls.snapshot_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_archive_integrity_route.sh"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh"
        )
        cls.archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_archive_integrity.py"
        )
        cls.snapshot_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        cls.build_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )

    def test_route_note_keeps_integrity_and_followup_surfaces_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "scripts/check_issue3_saved_archive_integrity.py",
            "--require-fallback-zig",
            "scripts/check_issue3_saved_memory_inputs.py",
            "show_issue3_saved_browser_snapshot_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
        ):
            self.assertIn(fragment, self.route_note)

    def test_related_notes_keep_integrity_route_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_archive_integrity.py",
            "Saved-archive integrity preflight against the restored checkout:",
        ):
            self.assertIn(fragment, self.snapshot_note)
        for fragment in (
            "scripts/check_issue3_saved_archive_integrity.py",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
        ):
            self.assertIn(fragment, self.build_readiness_note)
        for fragment in (
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_route_helper_keeps_verify_and_followup_commands(self) -> None:
        for fragment in (
            "check_issue3_saved_archive_integrity.py",
            "--require-fallback-zig",
            "show_issue3_saved_browser_snapshot_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "Saved-Memory presence preflight:",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_surface_checker_keeps_route_contract_fragments(self) -> None:
        for fragment in (
            '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|"',
            '"scripts/check_issue3_saved_archive_integrity.py|file|"',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|"',
            '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|--require-fallback-zig|"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|"',
            '"scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved-Memory presence preflight:|"',
            '"scripts/check_issue3_saved_archive_integrity.py|DEFAULT_FALLBACK_ZIG_SHA256|"',
            '"scripts/check_issue3_saved_archive_integrity.py|Suggested next step: refresh the mismatched archive|"',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_followup_helpers_and_archive_checker_keep_expected_markers(self) -> None:
        for fragment in (
            "Saved-archive integrity preflight against the restored checkout:",
            "scripts/check_issue3_saved_archive_integrity.py",
        ):
            self.assertIn(fragment, self.snapshot_route)
        for fragment in (
            "Saved archive integrity preflight:",
            "scripts/check_issue3_saved_archive_integrity.py",
        ):
            self.assertIn(fragment, self.build_route)
        for fragment in (
            "DEFAULT_FALLBACK_ZIG_SHA256",
            "Suggested next step: refresh the mismatched archive",
        ):
            self.assertIn(fragment, self.archive_helper)


if __name__ == "__main__":
    unittest.main()
