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
        .dependencies = .{
            .v8 = .{ .path = "../zig-v8-fork" },
            .@"boringssl-zig" = .{ .path = "../boringssl-zig" },
        },
    }
    """,
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    # Issue #3 Progress Tracker Route

    - issue `#11`
    - `Headed runtime re-entry: Linux/WSL build and toolchain readiness tracker`
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    """,
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md": """
    # Issue #3 Saved Archive Integrity Route

    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
    """,
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md": """
    # Issue #3 Saved Zig Archive Candidates Route

    - `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `0.15.x`
    - `0.17`
    - issue `#11`
    """,
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md": """
    # Issue #3 Saved Memory Inputs Route

    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
    - issue `#11`
    - `check_issue3_saved_memory_inputs_route_surface.sh`
    - `show_issue3_saved_memory_inputs_route.sh`
    - `python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .`
    - `show_issue3_saved_archive_integrity_route.sh`
    - `show_issue3_saved_zig_archive_candidates_route.sh`
    - `--skip-archive-integrity-check`
    - `--restored-checkout-root ../browser-memory-snapshot`
    - `show_issue3_saved_browser_snapshot_route.sh`
    - `show_issue3_linux_build_readiness_route.sh`
    - `show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    """,
    "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh": """
    docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
    scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh
    scripts/linux/show_issue3_saved_memory_inputs_route.sh
    scripts/check_issue3_saved_memory_inputs.py
    scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
    scripts/linux/show_issue3_saved_archive_integrity_route.sh
    scripts/check_issue3_saved_archive_integrity.py
    scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh
    scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh
    scripts/check_issue3_saved_zig_archive_candidates.py
    scripts/linux/show_issue3_saved_browser_snapshot_route.sh
    scripts/linux/show_issue3_linux_build_readiness_route.sh
    scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
    issue `#11`
    check_issue3_saved_memory_inputs_route_surface.sh
    show_issue3_saved_memory_inputs_route.sh
    python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .
    show_issue3_saved_archive_integrity_route.sh
    show_issue3_saved_zig_archive_candidates_route.sh
    --skip-archive-integrity-check
    --restored-checkout-root ../browser-memory-snapshot
    zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
    """,
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh": """
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
    issue #11 progress-update handoff
    check_issue3_saved_memory_inputs_route_surface.sh
    check_issue3_saved_memory_inputs.py
    show_issue3_saved_archive_integrity_route.sh
    show_issue3_saved_zig_archive_candidates_route.sh
    Saved-archive integrity route:
    Saved Zig archive candidates route:
    saved_archive_integrity_route
    saved_zig_archive_candidates_route
    --skip-archive-integrity-check
    --restored-checkout-root
    show_issue3_saved_browser_snapshot_route.sh
    show_issue3_linux_build_readiness_route.sh
    show_issue3_enter_submit_runtime_revalidation_route.sh
    restored_checkout_saved_input_preflight
    progress_tracker_route_path
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    repo_archives/browser/01-browser-fork-headed-mode-foundation.zip
    repo_archives/browser/blocker_intelligence.yaml
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
    scripts/check_issue3_saved_archive_integrity.py
    scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
    scripts/linux/restore_zig_toolchain_archive.sh
    Saved Memory input check passed.
    """,
    "scripts/check_issue3_saved_archive_integrity.py": """
    DEFAULT_FALLBACK_ZIG_NAME = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_FALLBACK_ZIG_SHA256 = "f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818"
    EXPECTED_MEMORY_ARCHIVES
    Verify the exact SHA-256 fingerprints
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    ARCHIVE_PATTERNS = ("*.tar", "*.tar.gz", "*.tgz", "*.tar.xz", "*.zip")
    def normalize_saved_archives_root(saved_archives_root):
        return saved_archives_root
    def resolve_default_saved_archives_root(repo_root):
        return repo_root.parent / "memory" / "repo_archives" / "browser"
    def resolve_default_toolchains_root(repo_root):
        return repo_root.parent / "toolchains"
    def resolve_default_fallback_archive(repo_root):
        return repo_root.parent / "agent_files"
    def discover_zig_archives(root):
        return []
    def choose_preferred_archive(expected, archive_reports):
        return None
    def build_restore_command(repo_root, toolchains_root, archive_path, check_only):
        return []
    "saved_archives_root"
    "toolchains_root"
    "preferred_archive"
    "fallback_archive"
    "restore_check"
    "restore"
    no saved Zig archive under
    not branch-compatible validation evidence
    """,
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh": """
    bash scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh
    --repo-root /path/to/browser-repo
    --saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]
    --toolchains-root /path/to/toolchains
    --fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
    --json
    "surface_check"
    "candidate_discovery"
    "matching_line_gate"
    "archive_restore_surface_check"
    "progress_tracker_route"
    "zig_recovery_route"
    Issue #11 progress-tracker route:
    The saved-archives root override accepts either repo_archives/browser or repo_archives/browser/dependencies
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-saved-memory-inputs-route-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedMemoryInputsRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.saved_memory_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md"
        )
        cls.progress_tracker_note = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.archive_integrity_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md"
        )
        cls.saved_zig_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"
        )
        cls.route_surface = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_memory_inputs_route.sh"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.archive_integrity_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_archive_integrity.py"
        )
        cls.saved_zig_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )
        cls.saved_zig_route_helper = read_text(
            cls.repo_root
            / "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_saved_memory_note_keeps_reentry_handoffs_visible(self) -> None:
        for fragment in (
            "`docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`",
            "`docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`",
            "`docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`",
            "issue `#11`",
            "`check_issue3_saved_memory_inputs_route_surface.sh`",
            "`show_issue3_saved_memory_inputs_route.sh`",
            "`python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .`",
            "`show_issue3_saved_archive_integrity_route.sh`",
            "`show_issue3_saved_zig_archive_candidates_route.sh`",
            "`--skip-archive-integrity-check`",
            "`--restored-checkout-root ../browser-memory-snapshot`",
            "`show_issue3_saved_browser_snapshot_route.sh`",
            "`show_issue3_linux_build_readiness_route.sh`",
            "`show_issue3_enter_submit_runtime_revalidation_route.sh`",
            "`zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`",
        ):
            self.assertIn(fragment, self.saved_memory_note)

    def test_progress_and_saved_zig_notes_keep_issue11_and_toolchain_context(self) -> None:
        for fragment in (
            "issue `#11`",
            "Linux/WSL build and toolchain readiness tracker",
            "`scripts/check_issue3_saved_memory_inputs.py`",
            "`scripts/check_linux_build_readiness.py`",
        ):
            self.assertIn(fragment, self.progress_tracker_note)

        for fragment in (
            "`scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`",
            "`scripts/check_issue3_saved_zig_archive_candidates.py`",
            "`scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`",
            "`docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`",
            "`docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`",
            "`docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`",
            "`0.15.x`",
            "`0.17`",
        ):
            self.assertIn(fragment, self.saved_zig_note)

        self.assertIn(
            "`scripts/check_issue3_saved_archive_integrity.py`",
            self.archive_integrity_note,
        )

    def test_route_surface_and_printer_keep_saved_zig_followup_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "show_issue3_saved_archive_integrity_route.sh",
            "show_issue3_saved_zig_archive_candidates_route.sh",
            "--skip-archive-integrity-check",
            "--restored-checkout-root ../browser-memory-snapshot",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        ):
            self.assertIn(fragment, self.route_surface)

        for fragment in (
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "issue #11 progress-update handoff",
            "check_issue3_saved_memory_inputs_route_surface.sh",
            "check_issue3_saved_memory_inputs.py",
            "show_issue3_saved_archive_integrity_route.sh",
            "show_issue3_saved_zig_archive_candidates_route.sh",
            "Saved-archive integrity route:",
            "Saved Zig archive candidates route:",
            "saved_archive_integrity_route",
            "saved_zig_archive_candidates_route",
            "--skip-archive-integrity-check",
            "--restored-checkout-root",
            "show_issue3_saved_browser_snapshot_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "restored_checkout_saved_input_preflight",
            "progress_tracker_route_path",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_helpers_keep_archive_and_toolchain_preflights_visible(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/blocker_intelligence.yaml",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

        for fragment in (
            'DEFAULT_FALLBACK_ZIG_NAME = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'DEFAULT_FALLBACK_ZIG_SHA256 = "f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818"',
            "EXPECTED_MEMORY_ARCHIVES",
            "Verify the exact SHA-256 fingerprints",
        ):
            self.assertIn(fragment, self.archive_integrity_helper)

        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'ARCHIVE_PATTERNS = ("*.tar", "*.tar.gz", "*.tgz", "*.tar.xz", "*.zip")',
            "def normalize_saved_archives_root(saved_archives_root):",
            "def resolve_default_saved_archives_root(repo_root):",
            "def resolve_default_toolchains_root(repo_root):",
            "def resolve_default_fallback_archive(repo_root):",
            "def discover_zig_archives(root):",
            "def choose_preferred_archive(expected, archive_reports):",
            "def build_restore_command(repo_root, toolchains_root, archive_path, check_only):",
            '"saved_archives_root"',
            '"toolchains_root"',
            '"preferred_archive"',
            '"fallback_archive"',
            '"restore_check"',
            '"restore"',
            "no saved Zig archive under",
            "not branch-compatible validation evidence",
        ):
            self.assertIn(fragment, self.saved_zig_helper)

        for fragment in (
            "bash scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "--repo-root /path/to/browser-repo",
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--toolchains-root /path/to/toolchains",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--json",
            '"surface_check"',
            '"candidate_discovery"',
            '"matching_line_gate"',
            '"archive_restore_surface_check"',
            '"progress_tracker_route"',
            '"zig_recovery_route"',
            "Issue #11 progress-tracker route:",
            "The saved-archives root override accepts either repo_archives/browser or repo_archives/browser/dependencies",
        ):
            self.assertIn(fragment, self.saved_zig_route_helper)

    def test_manifest_still_declares_branch_expected_zig_line(self) -> None:
        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
