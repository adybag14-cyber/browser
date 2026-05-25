from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md": """
    # Issue #3 Saved Zig Archive Candidates Route

    - `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - no staged Zig candidate under `../toolchains` matches the branch's expected
    - the visible saved archive filename is generic
    - infer the Zig version from the archive's top-level extracted directory
    - exact restore commands for the preferred saved Zig archive
    - fail fast if the saved-archive helper, restore helper, or branch-local note has drifted out of place
    - `bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
    - `python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .`
    - `bash ./scripts/linux/restore_zig_toolchain_archive.sh --check-only ...`
    - `bash ./scripts/linux/restore_zig_toolchain_archive.sh ...`
    - Prefer a saved Zig `0.15.2` or other `0.15.x` archive over the attached
    - fallback `0.17` bundle
    - rerun the matching-line gate and then the broader Linux build-readiness helper before
    - reopening the direct `Page.zig` plus `win32_backend.zig` runtime patch
    """,
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    # Issue #3 Progress Tracker Route

    - Use issue `#11` instead for the lower-volume Linux or WSL re-entry lane
    - `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
    - `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
    - `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
    - `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - `Goal:`
    - `Achieved:`
    """,
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh \\
        [--repo-root /path/to/browser-repo] \\
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \\
        [--toolchains-root /path/to/toolchains] \\
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
        [--json]
    ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"
    PROGRESS_TRACKER_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
    SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
    CANDIDATE_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_zig_archive_candidates.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
    MATCHING_LINE_GATE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_match.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}")"
    RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
    PROGRESS_TRACKER_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_progress_tracker_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
    CANDIDATE_COMMAND="${CANDIDATE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    MATCHING_LINE_GATE_COMMAND="${MATCHING_LINE_GATE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RECOVERY_ROUTE_COMMAND="${RECOVERY_ROUTE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    PROGRESS_TRACKER_ROUTE_COMMAND="${PROGRESS_TRACKER_ROUTE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    "saved_archives_root":
    "toolchains_root":
    "fallback_zig_archive":
    "progress_tracker_route_path":
    "candidate_discovery":
    "matching_line_gate":
    "progress_tracker_route":
    "zig_recovery_route":
    "Use the issue #11 progress-tracker route when this slice is still about saved inputs, toolchain recovery, or Linux or WSL readiness gates."
    "The saved_archives_root override accepts either repo_archives/browser or repo_archives/browser/dependencies and is normalized before discovery runs."
    """,
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh": """
    Usage:
      bash scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh \\
        [--repo-root /path/to/browser-repo] \\
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \\
        [--toolchains-root /path/to/toolchains] \\
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
        [--json]
    doc_path = repo_root / "docs" / "ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"
    helper_path = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
    restore_helper_path = repo_root / "scripts" / "linux" / "restore_zig_toolchain_archive.sh"
    required_keys = (
        "status",
        "repo_root",
        "saved_archives_root",
        "toolchains_root",
        "minimum_zig",
        "zig_archives",
        "commands",
        "failures",
    )
    for key in ("restore_check", "restore"):
    "fallback_zig_archive":
    "helper_status":
    "minimum_zig":
    "saved Zig archive candidate surface check passed."
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    def normalize_saved_archives_root(saved_archives_root):
        dependencies_root = saved_archives_root / "dependencies"
    def infer_archive_version(path):
        top_level = infer_archive_top_level(path)
    def choose_preferred_archive(expected, archive_reports):
        if archive["status"] == "matches-expected-line" and archive["version"] == expected:
    "saved_archives_root":
    "toolchains_root":
    "preferred_archive":
    "fallback_archive":
    "restore_check":
    "restore":
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-zig-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11SavedZigArchiveCandidatesRouteTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"
        )
        cls.progress_route = read_text(cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md")
        cls.route_script = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh"
        )
        cls.surface_script = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh"
        )
        cls.candidate_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )

    def test_route_note_keeps_saved_zig_discovery_restore_and_runtime_gate_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "generic",
            "top-level extracted directory",
            "exact restore commands for the preferred saved Zig archive",
            "fallback `0.17` bundle",
            "reopening the direct `Page.zig` plus `win32_backend.zig` runtime patch",
        ):
            self.assertIn(fragment, self.route_note)

        surface_index = self.route_note.index(
            "bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh"
        )
        discovery_index = self.route_note.index(
            "python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root ."
        )
        restore_index = self.route_note.index(
            "bash ./scripts/linux/restore_zig_toolchain_archive.sh --check-only ..."
        )
        runtime_gate_index = self.route_note.index("reopening the direct `Page.zig`")
        self.assertLess(surface_index, discovery_index)
        self.assertLess(discovery_index, restore_index)
        self.assertLess(restore_index, runtime_gate_index)

    def test_progress_tracker_route_keeps_issue11_handoff_and_saved_zig_route_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "Goal:",
            "Achieved:",
        ):
            self.assertIn(fragment, self.progress_route)

    def test_route_script_threads_fallback_archive_and_issue11_followups(self) -> None:
        for fragment in (
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--toolchains-root /path/to/toolchains",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            'ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"',
            'PROGRESS_TRACKER_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"',
            "check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "check_issue3_saved_zig_archive_candidates.py",
            "check_issue3_zig_toolchain_match.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "show_issue3_progress_tracker_route.sh",
            '--fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")',
            '"saved_archives_root":',
            '"toolchains_root":',
            '"fallback_zig_archive":',
            '"progress_tracker_route_path":',
            '"candidate_discovery":',
            '"matching_line_gate":',
            '"progress_tracker_route":',
            '"zig_recovery_route":',
            "Use the issue #11 progress-tracker route",
            "The saved_archives_root override accepts either repo_archives/browser or repo_archives/browser/dependencies",
        ):
            self.assertIn(fragment, self.route_script)

    def test_surface_script_and_candidate_helper_keep_required_json_contract_visible(self) -> None:
        for fragment in (
            'doc_path = repo_root / "docs" / "ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"',
            'helper_path = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"',
            'restore_helper_path = repo_root / "scripts" / "linux" / "restore_zig_toolchain_archive.sh"',
            '"status"',
            '"repo_root"',
            '"saved_archives_root"',
            '"toolchains_root"',
            '"minimum_zig"',
            '"zig_archives"',
            '"commands"',
            '"failures"',
            '"restore_check"',
            '"restore"',
            '"fallback_zig_archive":',
            '"helper_status":',
            '"minimum_zig":',
            "saved Zig archive candidate surface check passed.",
        ):
            self.assertIn(fragment, self.surface_script)

        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'dependencies_root = saved_archives_root / "dependencies"',
            "top_level = infer_archive_top_level(path)",
            'archive["status"] == "matches-expected-line"',
            '"saved_archives_root":',
            '"toolchains_root":',
            '"preferred_archive":',
            '"fallback_archive":',
            '"restore_check":',
            '"restore":',
        ):
            self.assertIn(fragment, self.candidate_helper)


if __name__ == "__main__":
    unittest.main()
