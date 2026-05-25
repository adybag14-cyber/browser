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
    - `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - issue `#11`
    - `python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .`
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md": """
    # Issue #3 Zig Toolchain Archive Restore Route

    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
    """,
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    # Issue #3 Progress Tracker Route

    - issue `#11`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    """,
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh": """
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh
    scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh
    scripts/check_issue3_saved_zig_archive_candidates.py
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|check_issue3_saved_zig_archive_candidates_route_surface.sh
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|show_issue3_saved_zig_archive_candidates_route.sh
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|check_issue3_saved_zig_archive_candidates.py
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|issue `#11`
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|check_issue3_saved_zig_archive_candidates.py
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_zig_archive_candidates.py
    scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|saved Zig archive candidates route
    scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|check_issue3_saved_zig_archive_candidates.py
    scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|check_issue3_zig_toolchain_archive_restore_route_surface.sh
    scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|show_issue3_zig_toolchain_recovery_route.sh
    """,
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh": """
    Google issue #3 saved Zig archive candidates route
    docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
    check_issue3_saved_zig_archive_candidates_route_surface.sh
    check_issue3_saved_zig_archive_candidates.py
    check_issue3_zig_toolchain_archive_restore_route_surface.sh
    show_issue3_zig_toolchain_recovery_route.sh
    issue #11
    "surface_check"
    "candidate_discovery"
    "archive_restore_surface_check"
    "zig_recovery_route"
    Route surface check:
    Saved archive candidate discovery:
    Archive restore surface check:
    Broader Zig recovery route:
    Prefer an exact 0.15.2 archive
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": """
    MINIMUM_ZIG_RE = "minimum"
    ARCHIVE_PATTERNS = ("zig*.tar", "zig*.tar.gz", "zig*.tgz", "zig*.tar.xz", "zig*.zip")
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    def normalize_saved_archives_root(saved_archives_root): ...
    def resolve_default_saved_archives_root(repo_root): ...
    def resolve_default_toolchains_root(repo_root): ...
    def resolve_default_fallback_archive(repo_root): ...
    def discover_zig_archives(root): ...
    def infer_archive_version(path): ...
    def describe_archive(expected, path): ...
    def choose_preferred_archive(expected, archive_reports): ...
    def build_restore_command(repo_root, toolchains_root, archive_path, *, check_only): ...
    def build_report(*, repo_root, saved_archives_root, toolchains_root, minimum_zig, archive_reports, preferred_archive, fallback_archive): ...
    "restore_check"
    "restore"
    "matches-expected-line"
    "mismatched-line"
    "older-than-minimum"
    "no saved Zig archive under"
    "use the fallback archive only as a surfaced stopgap"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-saved-zig-archive-candidates-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedZigArchiveCandidatesRouteSurfaceTest(unittest.TestCase):
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
        cls.recovery_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.archive_restore_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.progress_note = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root
            / "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh"
        )
        cls.candidate_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )

    def test_route_note_keeps_issue11_and_followups_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "issue `#11`",
            "python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
        ):
            self.assertIn(fragment, self.route_note)

    def test_neighbor_notes_keep_saved_archive_discovery_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
        ):
            self.assertIn(fragment, self.recovery_note)

        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
        ):
            self.assertIn(fragment, self.archive_restore_note)

        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
        ):
            self.assertIn(fragment, self.build_readiness_note)

        for fragment in (
            "issue `#11`",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        ):
            self.assertIn(fragment, self.progress_note)

    def test_surface_checker_keeps_route_contract_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|show_issue3_saved_zig_archive_candidates_route.sh",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|check_issue3_saved_zig_archive_candidates.py",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|issue `#11`",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|check_issue3_saved_zig_archive_candidates.py",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|saved Zig archive candidates route",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|show_issue3_zig_toolchain_recovery_route.sh",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_printer_keeps_commands_and_rule_order_visible(self) -> None:
        for fragment in (
            "Google issue #3 saved Zig archive candidates route",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "check_issue3_saved_zig_archive_candidates.py",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "issue #11",
            '"surface_check"',
            '"candidate_discovery"',
            '"archive_restore_surface_check"',
            '"zig_recovery_route"',
            "Route surface check:",
            "Saved archive candidate discovery:",
            "Archive restore surface check:",
            "Broader Zig recovery route:",
            "Prefer an exact 0.15.2 archive",
        ):
            self.assertIn(fragment, self.route_printer)

        route_surface_index = self.route_printer.index("Route surface check:")
        discovery_index = self.route_printer.index("Saved archive candidate discovery:")
        restore_surface_index = self.route_printer.index("Archive restore surface check:")
        recovery_index = self.route_printer.index("Broader Zig recovery route:")
        self.assertLess(route_surface_index, discovery_index)
        self.assertLess(discovery_index, restore_surface_index)
        self.assertLess(restore_surface_index, recovery_index)

    def test_candidate_helper_keeps_archive_selection_contract_visible(self) -> None:
        for fragment in (
            "ARCHIVE_PATTERNS =",
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "def normalize_saved_archives_root(saved_archives_root):",
            "def resolve_default_saved_archives_root(repo_root):",
            "def resolve_default_toolchains_root(repo_root):",
            "def resolve_default_fallback_archive(repo_root):",
            "def discover_zig_archives(root):",
            "def infer_archive_version(path):",
            "def describe_archive(expected, path):",
            "def choose_preferred_archive(expected, archive_reports):",
            "def build_restore_command(repo_root, toolchains_root, archive_path, *, check_only):",
            '"restore_check"',
            '"restore"',
            '"matches-expected-line"',
            '"mismatched-line"',
            '"older-than-minimum"',
            '"no saved Zig archive under',
            "use the fallback archive only as a surfaced stopgap",
        ):
            self.assertIn(fragment, self.candidate_helper)


if __name__ == "__main__":
    unittest.main()