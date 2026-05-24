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
    - `--require-fallback-zig`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `show_issue3_saved_browser_snapshot_route.sh`
    - `show_issue3_linux_build_readiness_route.sh`
    - `show_issue3_enter_submit_runtime_revalidation_route.sh`
    """,
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
    # Issue #3 Saved Browser Snapshot Route

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
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh": r"""
    ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh --repo-root ${REPO_ROOT}"
    VERIFY_COMMAND="python scripts/check_issue3_saved_archive_integrity.py --repo-root ${REPO_ROOT}"
    STRICT_VERIFY_COMMAND="${VERIFY_COMMAND} --require-fallback-zig"
    PRESENCE_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"
    RESTORE_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root ${REPO_ROOT}"
    BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${REPO_ROOT}"
    RUNTIME_ROUTE_COMMAND="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ${REPO_ROOT}"
    Saved-Memory presence preflight:
    """,
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh": r"""
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/linux/show_issue3_saved_archive_integrity_route.sh|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|--require-fallback-zig|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_linux_build_readiness_route.sh|"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Saved-archive integrity preflight against the restored checkout:|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|"
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|--require-fallback-zig|"
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved-Memory presence preflight:|"
    "scripts/check_issue3_saved_archive_integrity.py|DEFAULT_FALLBACK_ZIG_SHA256|"
    "scripts/check_issue3_saved_archive_integrity.py|Suggested next step: refresh the mismatched archive|"
    """,
    "scripts/check_issue3_saved_archive_integrity.py": """
    EXPECTED_MEMORY_ARCHIVES = (
        ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot", "sha"),
        ("repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz", "saved Rust toolchain archive", "sha"),
        ("repo_archives/browser/dependencies/03-boringssl-zig-main.zip", "saved BoringSSL archive", "sha"),
        ("repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip", "saved browser dependency archive", "sha"),
    )
    DEFAULT_FALLBACK_ZIG_SHA256 = "f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818"
    parser.add_argument("--require-fallback-zig")
    parser.add_argument("--json")
    parser.add_argument("--self-test")
    print("Suggested next step: refresh the mismatched archive from the saved Memory source before trusting restore, Linux build-readiness, or issue #3 runtime re-entry work.")
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    print("saved memory inputs")
    """,
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": """
    Saved-archive integrity preflight against the restored checkout:
    python scripts/check_issue3_saved_archive_integrity.py --repo-root .
    """,
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
    Saved archive integrity preflight:
    scripts/check_issue3_saved_archive_integrity.py
    """,
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": """
    runtime route
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-archive-route-"))
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
        cls.snapshot_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        )
        cls.linux_route_note = read_text(
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
        cls.integrity_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_archive_integrity.py"
        )
        cls.snapshot_route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        cls.linux_route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_route_note_keeps_checksum_presence_and_followup_routes_visible(self) -> None:
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

    def test_route_helper_keeps_surface_verify_presence_and_followup_commands(self) -> None:
        for fragment in (
            'ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh',
            'VERIFY_COMMAND="python scripts/check_issue3_saved_archive_integrity.py',
            'STRICT_VERIFY_COMMAND="${VERIFY_COMMAND} --require-fallback-zig"',
            'PRESENCE_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py',
            'RESTORE_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh',
            'BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh',
            'RUNTIME_ROUTE_COMMAND="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh',
            "Saved-Memory presence preflight:",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_surface_checker_keeps_route_and_followup_expectations(self) -> None:
        for fragment in (
            '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|"',
            '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/linux/show_issue3_saved_archive_integrity_route.sh|"',
            '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|"',
            '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|--require-fallback-zig|"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Saved-archive integrity preflight against the restored checkout:|"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|"',
            '"scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved-Memory presence preflight:|"',
            '"scripts/check_issue3_saved_archive_integrity.py|DEFAULT_FALLBACK_ZIG_SHA256|"',
            '"scripts/check_issue3_saved_archive_integrity.py|Suggested next step: refresh the mismatched archive|"',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_integrity_helper_keeps_expected_archive_contract_and_cli(self) -> None:
        for fragment in (
            "EXPECTED_MEMORY_ARCHIVES",
            "saved repo snapshot",
            "saved Rust toolchain archive",
            "saved BoringSSL archive",
            "saved browser dependency archive",
            "DEFAULT_FALLBACK_ZIG_SHA256",
            "--require-fallback-zig",
            "--json",
            "--self-test",
            "Suggested next step: refresh the mismatched archive",
        ):
            self.assertIn(fragment, self.integrity_helper)

    def test_followup_notes_and_manifest_keep_archive_integrity_route_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_archive_integrity.py",
            "Saved-archive integrity preflight against the restored checkout:",
        ):
            self.assertIn(fragment, self.snapshot_route_note)

        for fragment in (
            "scripts/check_issue3_saved_archive_integrity.py",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
        ):
            self.assertIn(fragment, self.linux_route_note)

        for fragment in (
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
        ):
            self.assertIn(fragment, self.runtime_gates)

        for fragment in (
            "Saved-archive integrity preflight against the restored checkout:",
            "scripts/check_issue3_saved_archive_integrity.py",
        ):
            self.assertIn(fragment, self.snapshot_route_helper)

        for fragment in (
            "Saved archive integrity preflight:",
            "scripts/check_issue3_saved_archive_integrity.py",
        ):
            self.assertIn(fragment, self.linux_route_helper)

        self.assertIn('.minimum_zig_version = "0.15.2"', self.build_manifest)


if __name__ == "__main__":
    unittest.main()
