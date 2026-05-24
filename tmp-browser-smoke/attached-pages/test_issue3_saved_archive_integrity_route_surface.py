from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md": """
    # Issue #3 Saved Archive Integrity Route

    - `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
    - `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `--require-fallback-zig`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `show_issue3_saved_browser_snapshot_route.sh`
    - `show_issue3_linux_build_readiness_route.sh`
    - `show_issue3_enter_submit_runtime_revalidation_route.sh`
    """,
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
    # Issue #3 Saved Browser Snapshot Restore Route

    - `scripts/check_issue3_saved_archive_integrity.py`
    - Saved-archive integrity preflight against the restored checkout:
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
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh": """
    REFERENCE_PATHS=(
      \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Read-first note\"
      \"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot note\"
      \"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness note\"
      \"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Runtime gates note\"
      \"scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Route printer\"
      \"scripts/check_issue3_saved_archive_integrity.py|file|SHA-256 helper\"
      \"scripts/check_issue3_saved_memory_inputs.py|file|Presence preflight\"
      \"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Restore route\"
      \"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Build route\"
      \"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Runtime route\"
      \"build.zig.zon|file|Manifest surface\"
    )
    CONTENT_EXPECTATIONS=(
      \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|surface checker visible\"
      \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/linux/show_issue3_saved_archive_integrity_route.sh|route printer visible\"
      \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|sha helper visible\"
      \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|--require-fallback-zig|strict fallback zig visible\"
      \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|presence preflight visible\"
      \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|restore route visible\"
      \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_linux_build_readiness_route.sh|build route visible\"
      \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|runtime route visible\"
      \"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|snapshot note keeps helper visible\"
      \"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Saved-archive integrity preflight against the restored checkout:|snapshot note keeps preflight label visible\"
      \"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|linux note keeps helper visible\"
      \"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|linux note keeps exact command visible\"
      \"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|runtime gates keep note visible\"
      \"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|runtime gates keep surface checker visible\"
      \"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_saved_archive_integrity_route.sh|runtime gates keep route printer visible\"
      \"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|runtime gates keep exact command visible\"
      \"scripts/linux/show_issue3_saved_archive_integrity_route.sh|check_issue3_saved_archive_integrity.py|route printer keeps sha helper visible\"
      \"scripts/linux/show_issue3_saved_archive_integrity_route.sh|--require-fallback-zig|route printer keeps strict fallback zig visible\"
      \"scripts/linux/show_issue3_saved_archive_integrity_route.sh|show_issue3_saved_browser_snapshot_route.sh|route printer keeps restore route visible\"
      \"scripts/linux/show_issue3_saved_archive_integrity_route.sh|show_issue3_linux_build_readiness_route.sh|route printer keeps build route visible\"
      \"scripts/linux/show_issue3_saved_archive_integrity_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|route printer keeps runtime route visible\"
      \"scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved-Memory presence preflight:|route printer keeps presence preflight label visible\"
      \"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-archive integrity preflight against the restored checkout:|snapshot route printer keeps integrity preflight visible\"
      \"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|scripts/check_issue3_saved_archive_integrity.py|snapshot route printer keeps integrity helper visible\"
      \"scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved archive integrity preflight:|build route printer keeps integrity preflight visible\"
      \"scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_saved_archive_integrity.py|build route printer keeps integrity helper visible\"
      \"scripts/check_issue3_saved_archive_integrity.py|DEFAULT_FALLBACK_ZIG_SHA256|sha helper exposes fallback zig fingerprint\"
      \"scripts/check_issue3_saved_archive_integrity.py|Suggested next step: refresh the mismatched archive|sha helper exposes mismatch guidance\"
    )
    """,
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh": """
    check_issue3_saved_archive_integrity.py
    --require-fallback-zig
    show_issue3_saved_browser_snapshot_route.sh
    show_issue3_linux_build_readiness_route.sh
    show_issue3_enter_submit_runtime_revalidation_route.sh
    Saved-Memory presence preflight:
    """,
    "scripts/check_issue3_saved_archive_integrity.py": """
    DEFAULT_FALLBACK_ZIG_SHA256 = \"f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818\"
    Suggested next step: refresh the mismatched archive
    """,
    "scripts/check_issue3_saved_memory_inputs.py": "Saved Memory input check passed.\n",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": """
    Saved-archive integrity preflight against the restored checkout:
    scripts/check_issue3_saved_archive_integrity.py
    """,
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
    Saved archive integrity preflight:
    scripts/check_issue3_saved_archive_integrity.py
    """,
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": """
    bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh
    python scripts/check_issue3_saved_archive_integrity.py --repo-root .
    """,
    "build.zig.zon": '.minimum_zig_version = "0.15.2",\n',
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-archive-integrity-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedArchiveIntegrityRouteSurfaceTest(unittest.TestCase):
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
        cls.build_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_archive_integrity_route.sh"
        )
        cls.integrity_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_archive_integrity.py"
        )
        cls.snapshot_route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        cls.build_route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )

    def test_route_note_keeps_the_helper_chain_visible(self) -> None:
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

    def test_neighbor_notes_keep_the_archive_integrity_step_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_archive_integrity.py",
            "Saved-archive integrity preflight against the restored checkout:",
        ):
            self.assertIn(fragment, self.snapshot_note)

        for fragment in (
            "scripts/check_issue3_saved_archive_integrity.py",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
        ):
            self.assertIn(fragment, self.build_note)

        for fragment in (
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_surface_checker_keeps_route_and_follow_up_expectations_visible(self) -> None:
        for fragment in (
            '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|',
            '"scripts/check_issue3_saved_archive_integrity.py|file|',
            '"scripts/check_issue3_saved_memory_inputs.py|file|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|',
            '"build.zig.zon|file|Manifest surface"',
            '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Saved-archive integrity preflight against the restored checkout:|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_saved_archive_integrity_route.sh|',
            '"scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved-Memory presence preflight:|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|scripts/check_issue3_saved_archive_integrity.py|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_saved_archive_integrity.py|',
            '"scripts/check_issue3_saved_archive_integrity.py|DEFAULT_FALLBACK_ZIG_SHA256|',
            '"scripts/check_issue3_saved_archive_integrity.py|Suggested next step: refresh the mismatched archive|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_printers_keep_archive_integrity_follow_ups_visible(self) -> None:
        for fragment in (
            "check_issue3_saved_archive_integrity.py",
            "--require-fallback-zig",
            "show_issue3_saved_browser_snapshot_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "Saved-Memory presence preflight:",
        ):
            self.assertIn(fragment, self.route_printer)

        for fragment in (
            "Saved-archive integrity preflight against the restored checkout:",
            "scripts/check_issue3_saved_archive_integrity.py",
        ):
            self.assertIn(fragment, self.snapshot_route_printer)

        for fragment in (
            "Saved archive integrity preflight:",
            "scripts/check_issue3_saved_archive_integrity.py",
        ):
            self.assertIn(fragment, self.build_route_printer)

    def test_integrity_helper_keeps_fallback_fingerprint_and_recovery_guidance_visible(self) -> None:
        for fragment in (
            "DEFAULT_FALLBACK_ZIG_SHA256",
            "Suggested next step: refresh the mismatched archive",
        ):
            self.assertIn(fragment, self.integrity_helper)


if __name__ == "__main__":
    unittest.main()
