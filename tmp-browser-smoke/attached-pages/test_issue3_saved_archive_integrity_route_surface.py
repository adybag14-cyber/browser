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
    - `scripts/check_issue3_saved_browser_snapshot_archive_surface.py`
    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `--require-fallback-zig`
    - `python ./scripts/check_issue3_saved_archive_integrity.py --repo-root .`
    - `python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py --repo-root .`
    - `python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .`
    - `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    """,
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md": """
    # Issue #3 Saved Browser Snapshot Archive Surface

    - `scripts/check_issue3_saved_browser_snapshot_archive_surface.py`
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_restored_checkout.py`
    - `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
    - `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `build.zig.zon`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/linux/restore_saved_browser_snapshot.sh`
    - `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `--sync-helper-surface`
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
    - `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
    - `python scripts/check_issue3_saved_archive_integrity.py --repo-root .`
    """,
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
    - `scripts/check_issue3_saved_archive_integrity.py`
    - Saved-archive integrity preflight against the restored checkout:
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `python scripts/check_issue3_saved_archive_integrity.py --repo-root .`
    """,
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh": """
    \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Read-first saved-archive-integrity note for the blocked issue #3 recovery path.\"
    \"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md|file|Saved snapshot archive-surface note that should stay nearby before restore trusts the older snapshot zip.\"
    \"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot restore note that should keep the archive-integrity preflight visible before restore or follow-up work.\"
    \"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux or WSL build-readiness note that should keep the archive-integrity preflight visible before offline staging.\"
    \"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the archive-integrity preflight visible before runtime re-entry.\"
    \"scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Compact route printer for the saved-archive-integrity path.\"
    \"scripts/check_issue3_saved_archive_integrity.py|file|SHA-256 helper that verifies the saved repo and dependency bundle fingerprints.\"
    \"scripts/check_issue3_saved_browser_snapshot_archive_surface.py|file|Helper that proves whether the saved snapshot zip already carries the current issue #3 restore and runtime helper surface.\"
    \"scripts/check_issue3_saved_memory_inputs.py|file|Presence preflight that should follow the checksum and snapshot-surface route checks before restore or build work.\"
    \"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser-snapshot restore route that should stay reachable after archive verification.\"
    \"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux or WSL build-readiness route that should stay reachable after archive verification.\"
    \"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Direct runtime re-entry route that should stay reachable after archive verification.\"
    \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_browser_snapshot_archive_surface.py|The route note keeps the saved snapshot archive-surface helper visible after checksum verification.\"
    \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|--require-fallback-zig|The route note keeps the strict fallback Zig mode visible.\"
    \"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|The runtime re-entry gates keep the exact archive-integrity command visible before focused Zig validation.\"
    \"scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved snapshot archive surface:|The route printer still prints the saved snapshot archive-surface step.\"
    \"scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved-Memory presence preflight:|The route printer still prints the post-checksum presence preflight.\"
    \"scripts/check_issue3_saved_archive_integrity.py|DEFAULT_FALLBACK_ZIG_SHA256|The SHA-256 helper still exposes the expected fallback Zig fingerprint.\"
    \"scripts/check_issue3_saved_archive_integrity.py|Suggested next step: refresh the mismatched archive|The SHA-256 helper still reports the mismatch recovery guidance.\"
    """,
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_saved_archive_integrity_route.sh \\
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
        [--require-fallback-zig]

    \"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md\"
    \"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md\"
    \"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md\"
    \"docs/ISSUE3_RUNTIME_REENTRY_GATES.md\"
    ROUTE_SURFACE_COMMAND=\"bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh --repo-root ${REPO_ROOT}\"
    VERIFY_COMMAND=\"python ./scripts/check_issue3_saved_archive_integrity.py --repo-root ${REPO_ROOT}\"
    STRICT_VERIFY_COMMAND=\"${VERIFY_COMMAND} --require-fallback-zig\"
    SNAPSHOT_SURFACE_COMMAND=\"python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py --repo-root ${REPO_ROOT}\"
    PRESENCE_PREFLIGHT_COMMAND=\"python ./scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}\"
    RESTORE_ROUTE_COMMAND=\"bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root ${REPO_ROOT}\"
    BUILD_ROUTE_COMMAND=\"bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${REPO_ROOT}\"
    RUNTIME_ROUTE_COMMAND=\"bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ${REPO_ROOT}\"
    \"Saved snapshot archive surface:\"
    \"Saved-Memory presence preflight:\"
    \"Strict archive verification when fallback Zig must also match:\"
    """,
    "scripts/check_issue3_saved_archive_integrity.py": """
    EXPECTED_MEMORY_ARCHIVES = (
        (\"repo_archives/browser/01-browser-fork-headed-mode-foundation.zip\", \"saved repo snapshot\", \"d1ce047d2f9dd5a9dd7c5a661f3f0caeeac0ff51a19bcdb3c9f3104c081babf0\"),
        (\"repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz\", \"saved Rust toolchain archive\", \"ce552d6bf22a2544ea78647d98cb405d5089af58dbcaa4efea711bf8becd71c5\"),
        (\"repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip\", \"saved html5ever dependency archive\", \"701e646bd43917993a20cd155472c1d122d0ac38d1ee908396beff44add74cea\"),
        (\"repo_archives/browser/dependencies/03-boringssl-zig-main.zip\", \"saved BoringSSL archive\", \"db924bb0a15f31f3a6ff9848f357585ea09b20e80b584cccbd45ab69ffeda564\"),
        (\"repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip\", \"saved browser dependency archive\", \"e4905ad079f421dfc9c116172ab873666afab4eae8afdeed0d00dc8a4c4368f9\"),
    )
    DEFAULT_FALLBACK_ZIG_NAME = \"zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz\"
    DEFAULT_FALLBACK_ZIG_SHA256 = \"f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818\"
    --require-fallback-zig
    --json
    Saved archive integrity check passed.
    Suggested next step: refresh the mismatched archive
    """,
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py": """
    DEFAULT_ARCHIVE_NAME = \"01-browser-fork-headed-mode-foundation.zip\"
    REQUIRED_PATHS = [
        (\"build.zig.zon\", \"Snapshot manifest expected in a reusable restored checkout.\"),
        (\"docs/ISSUE3_RUNTIME_REENTRY_GATES.md\", \"Runtime re-entry gate note that current issue #3 follow-up runs expect before reopening the direct runtime lane.\"),
        (\"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md\", \"Direct issue #3 runtime revalidation note for the narrowed Page.zig and win32_backend.zig path.\"),
        (\"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md\", \"Saved-archive integrity note that should stay available before restore or runtime follow-up trust the saved snapshot.\"),
        (\"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md\", \"Read-first saved-browser-snapshot restore note for the blocked issue #3 runtime lane.\"),
        (\"docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md\", \"Restored-checkout re-entry note that should stay available after restore succeeds.\"),
        (\"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md\", \"Linux or WSL build-readiness note that current follow-up runs expect after restore.\"),
        (\"scripts/check_issue3_saved_memory_inputs.py\", \"Saved-Memory preflight that checks the repo archive, blocker file, and dependency bundles.\"),
        (\"scripts/check_issue3_restored_checkout.py\", \"Restored-checkout readiness helper that should stay available after restore.\"),
        (\"scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1\", \"Windows runtime re-entry helper that should stay available when the restored helper surface is current.\"),
        (\"scripts/linux/show_issue3_saved_archive_integrity_route.sh\", \"Compact route printer for the saved-archive-integrity path.\"),
        (\"scripts/linux/restore_saved_browser_snapshot.sh\", \"Restore helper that supports --check-only and --sync-helper-surface.\"),
        (\"scripts/linux/show_issue3_saved_browser_snapshot_route.sh\", \"Compact route printer for the saved-browser-snapshot restore path.\"),
        (\"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh\", \"Companion direct runtime re-entry route printer after restore.\"),
    ]
    \"recommended_restore_mode\": (\"sync-helper-surface\" if missing_paths else \"plain\")
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    repo_archives/browser/01-browser-fork-headed-mode-foundation.zip
    repo_archives/browser/README.md
    repo_archives/browser/blocker_intelligence.yaml
    """,
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": """
    Saved-archive integrity preflight against the restored checkout:
    scripts/check_issue3_saved_archive_integrity.py
    """,
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
    Saved archive integrity preflight:
    scripts/check_issue3_saved_archive_integrity.py
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-saved-archive-integrity-")
    )
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
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md"
        )
        cls.gate_note = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.snapshot_route = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        )
        cls.build_route = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
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
        cls.snapshot_surface_helper = read_text(
            cls.repo_root
            / "scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.snapshot_route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        cls.build_route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )

    def test_route_note_keeps_checksum_snapshot_and_followup_routes_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "--require-fallback-zig",
            "python ./scripts/check_issue3_saved_archive_integrity.py --repo-root .",
            "python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py --repo-root .",
            "python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .",
        ):
            self.assertIn(fragment, self.route_note)

    def test_snapshot_archive_surface_note_keeps_restore_mode_contract_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "build.zig.zon",
            "--sync-helper-surface",
        ):
            self.assertIn(fragment, self.snapshot_note)

    def test_surface_checker_keeps_archive_integrity_contracts_in_scope(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Read-first saved-archive-integrity note",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md|file|Saved snapshot archive-surface note",
            "scripts/check_issue3_saved_archive_integrity.py|file|SHA-256 helper",
            "scripts/check_issue3_saved_browser_snapshot_archive_surface.py|file|Helper that proves whether the saved snapshot zip already carries the current issue #3 restore and runtime helper surface.",
            "scripts/check_issue3_saved_memory_inputs.py|file|Presence preflight",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser-snapshot restore route",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux or WSL build-readiness route",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Direct runtime re-entry route",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|--require-fallback-zig|The route note keeps the strict fallback Zig mode visible.",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|The runtime re-entry gates keep the exact archive-integrity command visible before focused Zig validation.",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved snapshot archive surface:|The route printer still prints the saved snapshot archive-surface step.",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved-Memory presence preflight:|The route printer still prints the post-checksum presence preflight.",
            "scripts/check_issue3_saved_archive_integrity.py|DEFAULT_FALLBACK_ZIG_SHA256|The SHA-256 helper still exposes the expected fallback Zig fingerprint.",
            "scripts/check_issue3_saved_archive_integrity.py|Suggested next step: refresh the mismatched archive|The SHA-256 helper still reports the mismatch recovery guidance.",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_printer_keeps_checksum_snapshot_presence_and_followup_steps_visible(self) -> None:
        for fragment in (
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--require-fallback-zig",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "ROUTE_SURFACE_COMMAND",
            "VERIFY_COMMAND",
            "STRICT_VERIFY_COMMAND",
            "SNAPSHOT_SURFACE_COMMAND",
            "PRESENCE_PREFLIGHT_COMMAND",
            "RESTORE_ROUTE_COMMAND",
            "BUILD_ROUTE_COMMAND",
            "RUNTIME_ROUTE_COMMAND",
            "Saved snapshot archive surface:",
            "Saved-Memory presence preflight:",
            "Strict archive verification when fallback Zig must also match:",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_helper_and_followup_surfaces_keep_the_same_integrity_handoff(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
            "repo_archives/browser/dependencies/03-boringssl-zig-main.zip",
            "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
            "DEFAULT_FALLBACK_ZIG_NAME = \"zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz\"",
            "DEFAULT_FALLBACK_ZIG_SHA256 = \"f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818\"",
            "--require-fallback-zig",
            "Saved archive integrity check passed.",
        ):
            self.assertIn(fragment, self.integrity_helper)

        for fragment in (
            "DEFAULT_ARCHIVE_NAME = \"01-browser-fork-headed-mode-foundation.zip\"",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "\"recommended_restore_mode\": (",
            "\"sync-helper-surface\" if missing_paths else \"plain\"",
        ):
            self.assertIn(fragment, self.snapshot_surface_helper)

        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/README.md",
            "repo_archives/browser/blocker_intelligence.yaml",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

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

    def test_gate_snapshot_and_build_notes_keep_archive_integrity_order_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
        ):
            self.assertIn(fragment, self.gate_note)

        for fragment in (
            "scripts/check_issue3_saved_archive_integrity.py",
            "Saved-archive integrity preflight against the restored checkout:",
        ):
            self.assertIn(fragment, self.snapshot_route)

        for fragment in (
            "scripts/check_issue3_saved_archive_integrity.py",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
        ):
            self.assertIn(fragment, self.build_route)


if __name__ == "__main__":
    unittest.main()
