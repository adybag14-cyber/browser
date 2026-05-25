from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - `0.15.2`
    - `bash ./scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `bash ./scripts/linux/restore_issue3_fallback_zig_toolchain.sh --check-only`
    - `bash ./scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
    - stage the attached fallback archive
    - not branch-compatible validation evidence
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `bash ./scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
    - `bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    """,
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    # Issue #3 Progress Tracker Route

    - issue `#11`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - `Goal:`
    - `Achieved:`
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh \\
        [--repo-root /path/to/browser-repo] \\
        [--toolchains-root /path/to/toolchains] \\
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \\
        [--offline-deps-root /path/to/offline-deps] \\
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
        [--json]
    normalize_saved_archives_root() {
    route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_recovery_route_surface.sh"
    matching_line_gate_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh"
    saved_archive_candidates_script = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
    archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    readiness_script = repo_root / "scripts" / "check_linux_build_readiness.py"
    fallback_restore_script = repo_root / "scripts" / "linux" / "restore_issue3_fallback_zig_toolchain.sh"
    "fallback_zig_archive":
    "fallback_restore_check":
    "fallback_restore":
    "matching_line_gate":
    "saved_archive_candidate_discovery":
    "archive_restore_surface_check":
    "Treat the attached Zig 0.17 dev bundle as a surfaced fallback only"
    "If the only available archive is the attached Zig 0.17 fallback"
    "Fallback archive staging"
    """,
    "scripts/linux/restore_issue3_fallback_zig_toolchain.sh": """
    Usage:
      bash scripts/linux/restore_issue3_fallback_zig_toolchain.sh \\
        [--browser-root /path/to/browser-repo] \\
        [--toolchains-root /path/to/toolchains] \\
        [--toolchain-root /path/to/toolchains/zig-0.17.0-dev.299+a76ce7710] \\
        [--archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
        [--check-only] \\
        [--json] \\
        [--force]
    DEFAULT_TOOLCHAIN_DIR_NAME="zig-0.17.0-dev.299+a76ce7710"
    DEFAULT_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    "browser_root":
    "toolchains_root":
    "toolchain_root":
    "archive_path":
    "zig_bin":
    "check_only":
    "force_restore":
    "toolchain_exists":
    if [[ "${CHECK_ONLY}" == "true" ]]; then
    Fallback Zig restore surface check passed.
    Suggested probe after restore:
    Working rule:
    Stage this fallback only for route discovery and environment checks.
    The branch still expects Zig 0.15.x for honest validation.
    tar -xJf "${ARCHIVE_PATH}" -C "${TOOLCHAIN_ROOT}" --strip-components=1
    Fallback Zig toolchain is ready.
    This staged toolchain is the attached Zig 0.17 fallback.
    """,
    "scripts/check_linux_build_readiness.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
        "zig*/zig",
        "zig*/bin/zig",
        "*/zig",
        "*/bin/zig",
        "zig",
    )
    def resolve_default_toolchains_root(repo_root):
        return repo_root.parent / "toolchains"
    def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):
        return fallback_zig_archive
    def discover_toolchain_zig_candidates(toolchains_root):
        return []
    def describe_fallback_zig_archive(minimum_zig, fallback_zig_archive):
        return [], "0.17.0", "mismatched: expected 0.15.x line"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-fallback-zig-restore-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11FallbackZigRestoreSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.recovery_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.runtime_gates_note = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.progress_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.recovery_route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.fallback_restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_issue3_fallback_zig_toolchain.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_recovery_note_keeps_fallback_restore_stopgap_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "0.15.2",
            "bash ./scripts/linux/check_issue3_zig_toolchain_match.sh",
            "bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "bash ./scripts/linux/restore_issue3_fallback_zig_toolchain.sh --check-only",
            "bash ./scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "stage the attached fallback archive",
            "not branch-compatible validation evidence",
        ):
            self.assertIn(fragment, self.recovery_note)

    def test_runtime_and_progress_notes_keep_fallback_route_in_scope(self) -> None:
        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_linux_build_readiness.py",
            "bash ./scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        ):
            self.assertIn(fragment, self.runtime_gates_note)

        for fragment in (
            "issue `#11`",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "Goal:",
            "Achieved:",
        ):
            self.assertIn(fragment, self.progress_route_note)

    def test_recovery_route_printer_keeps_fallback_commands_and_warning_visible(self) -> None:
        for fragment in (
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--offline-deps-root /path/to/offline-deps",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "normalize_saved_archives_root()",
            'route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_recovery_route_surface.sh"',
            'matching_line_gate_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh"',
            'saved_archive_candidates_script = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"',
            'archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"',
            'readiness_script = repo_root / "scripts" / "check_linux_build_readiness.py"',
            'fallback_restore_script = repo_root / "scripts" / "linux" / "restore_issue3_fallback_zig_toolchain.sh"',
            '"fallback_zig_archive":',
            '"fallback_restore_check":',
            '"fallback_restore":',
            '"matching_line_gate":',
            '"saved_archive_candidate_discovery":',
            '"archive_restore_surface_check":',
            "Treat the attached Zig 0.17 dev bundle as a surfaced fallback only",
            "If the only available archive is the attached Zig 0.17 fallback",
            "Fallback archive staging",
        ):
            self.assertIn(fragment, self.recovery_route_helper)

    def test_fallback_restore_helper_keeps_surface_and_restore_contract_visible(self) -> None:
        for fragment in (
            "--browser-root /path/to/browser-repo",
            "--toolchains-root /path/to/toolchains",
            "--toolchain-root /path/to/toolchains/zig-0.17.0-dev.299+a76ce7710",
            "--archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--check-only",
            "--json",
            "--force",
            'DEFAULT_TOOLCHAIN_DIR_NAME="zig-0.17.0-dev.299+a76ce7710"',
            'DEFAULT_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            '"browser_root":',
            '"toolchains_root":',
            '"toolchain_root":',
            '"archive_path":',
            '"zig_bin":',
            '"check_only":',
            '"force_restore":',
            '"toolchain_exists":',
            'if [[ "${CHECK_ONLY}" == "true" ]]',
            "Fallback Zig restore surface check passed.",
            "Suggested probe after restore:",
            "Working rule:",
            "Stage this fallback only for route discovery and environment checks.",
            "The branch still expects Zig 0.15.x for honest validation.",
            'tar -xJf "${ARCHIVE_PATH}" -C "${TOOLCHAIN_ROOT}" --strip-components=1',
            "Fallback Zig toolchain is ready.",
            "This staged toolchain is the attached Zig 0.17 fallback.",
        ):
            self.assertIn(fragment, self.fallback_restore_helper)

    def test_readiness_helper_keeps_fallback_archive_classification_visible(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "DEFAULT_ZIG_TOOLCHAIN_GLOBS = (",
            '"zig*/zig"',
            '"zig*/bin/zig"',
            "def resolve_default_toolchains_root(repo_root):",
            "def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):",
            "def discover_toolchain_zig_candidates(toolchains_root):",
            "def describe_fallback_zig_archive(minimum_zig, fallback_zig_archive):",
            '"mismatched: expected 0.15.x line"',
        ):
            self.assertIn(fragment, self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
