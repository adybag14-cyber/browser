from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md": """
    # Issue #3 Saved Rust Archive Candidates Route

    - `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - issue `#11`
    - `python scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .`
    - `python scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .`
    """,
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Saved Rust Build-Readiness Bridge Route

    - `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
    - `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    """,
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    # Issue #3 Progress Tracker Route

    - issue `#11`
    - `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    """,
    "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh": """
    docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md
    scripts/check_issue3_saved_rust_archive_candidates.py
    scripts/check_issue3_staged_rust_toolchain_candidates.py
    scripts/linux/show_issue3_saved_rust_toolchain_route.sh
    "status"
    "repo_root"
    "saved_archives_root"
    "toolchains_root"
    "expected_rust"
    "rust_archives"
    "preferred_archive"
    "commands"
    "restore_check"
    "restore"
    """,
    "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh": """
    Google issue #3 saved Rust archive candidates route
    docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    Route surface check:
    Saved archive candidate discovery:
    Staged toolchain candidate discovery:
    Saved Rust toolchain route surface check:
    Saved Rust toolchain route:
    Issue #11 progress-tracker route:
    Broader Linux build-readiness route:
    "surface_check"
    "candidate_discovery"
    "staged_toolchain_candidates"
    "saved_rust_toolchain_route_surface"
    "saved_rust_toolchain_route"
    "progress_tracker_route"
    "linux_build_readiness_route"
    """,
    "scripts/check_issue3_saved_rust_archive_candidates.py": """
    DEFAULT_EXPECTED_RUST = "1.79.0"
    ARCHIVE_RE = re.compile(r"01-rust-(\\d+\\.\\d+\\.\\d+)-([^.]+(?:\\.[^.]+)*)\\.tar\\.xz$")
    def normalize_saved_archives_root(saved_archives_root: pathlib.Path) -> pathlib.Path:
    def build_saved_archive_search_roots(saved_archives_root: pathlib.Path) -> list[pathlib.Path]:
    def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:
    def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:
    def discover_rust_archives(search_roots: list[pathlib.Path]) -> list[pathlib.Path]:
    def infer_archive_metadata(path: pathlib.Path) -> tuple[str | None, str]:
    def describe_archive(expected: str, path: pathlib.Path) -> dict[str, str]:
    def choose_preferred_archive(expected: str, archive_reports: list[dict[str, str]]) -> dict[str, str] | None:
    def build_restore_command(
    "restore_check"
    "restore"
    "matches-expected-line"
    "older-than-expected"
    "mismatched-line"
    "no saved Rust archive under"
    """,
    "scripts/check_issue3_staged_rust_toolchain_candidates.py": """
    EXPECTED_RUST_VERSION = "1.79.0"
    "preferred_candidate"
    "matching_candidates"
    "path_export"
    "cargo_export"
    "rustc_export"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-saved-rust-archive-route-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedRustArchiveCandidatesRouteSurfaceTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md"
        )
        cls.bridge_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md"
        )
        cls.progress_note = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root
            / "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh"
        )
        cls.archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_rust_archive_candidates.py"
        )
        cls.staged_helper = read_text(
            cls.repo_root / "scripts/check_issue3_staged_rust_toolchain_candidates.py"
        )

    def test_route_note_keeps_issue11_and_helper_ladder_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "issue `#11`",
            "python scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .",
            "python scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .",
        ):
            self.assertIn(fragment, self.route_note)

    def test_neighbor_notes_keep_route_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
            "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
        ):
            self.assertIn(fragment, self.bridge_note)

        for fragment in (
            "issue `#11`",
            "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
        ):
            self.assertIn(fragment, self.progress_note)

    def test_surface_checker_keeps_json_contract_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            '"status"',
            '"repo_root"',
            '"saved_archives_root"',
            '"toolchains_root"',
            '"expected_rust"',
            '"rust_archives"',
            '"preferred_archive"',
            '"commands"',
            '"restore_check"',
            '"restore"',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_printer_keeps_followup_order_visible(self) -> None:
        for fragment in (
            "saved Rust archive candidates route",
            "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "Route surface check:",
            "Saved archive candidate discovery:",
            "Staged toolchain candidate discovery:",
            "Saved Rust toolchain route surface check:",
            "Saved Rust toolchain route:",
            "Issue #11 progress-tracker route:",
            "Broader Linux build-readiness route:",
            '"surface_check"',
            '"candidate_discovery"',
            '"staged_toolchain_candidates"',
            '"saved_rust_toolchain_route_surface"',
            '"saved_rust_toolchain_route"',
            '"progress_tracker_route"',
            '"linux_build_readiness_route"',
        ):
            self.assertIn(fragment, self.route_printer)

        surface_index = self.route_printer.index("Route surface check:")
        archive_index = self.route_printer.index("Saved archive candidate discovery:")
        staged_index = self.route_printer.index("Staged toolchain candidate discovery:")
        restore_surface_index = self.route_printer.index(
            "Saved Rust toolchain route surface check:"
        )
        restore_index = self.route_printer.index("Saved Rust toolchain route:")
        progress_index = self.route_printer.index("Issue #11 progress-tracker route:")
        build_index = self.route_printer.index("Broader Linux build-readiness route:")
        self.assertLess(surface_index, archive_index)
        self.assertLess(archive_index, staged_index)
        self.assertLess(staged_index, restore_surface_index)
        self.assertLess(restore_surface_index, restore_index)
        self.assertLess(restore_index, progress_index)
        self.assertLess(progress_index, build_index)

    def test_archive_helper_keeps_selection_contract_visible(self) -> None:
        for fragment in (
            'DEFAULT_EXPECTED_RUST = "1.79.0"',
            'ARCHIVE_RE = re.compile(r"01-rust-(\\d+\\.\\d+\\.\\d+)-([^.]+(?:\\.[^.]+)*)\\.tar\\.xz$")',
            "def normalize_saved_archives_root(saved_archives_root: pathlib.Path) -> pathlib.Path:",
            "def build_saved_archive_search_roots(saved_archives_root: pathlib.Path) -> list[pathlib.Path]:",
            "def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:",
            "def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:",
            "def discover_rust_archives(search_roots: list[pathlib.Path]) -> list[pathlib.Path]:",
            "def infer_archive_metadata(path: pathlib.Path) -> tuple[str | None, str]:",
            "def describe_archive(expected: str, path: pathlib.Path) -> dict[str, str]:",
            "def choose_preferred_archive(expected: str, archive_reports: list[dict[str, str]]) -> dict[str, str] | None:",
            "def build_restore_command(",
            '"restore_check"',
            '"restore"',
            '"matches-expected-line"',
            '"older-than-expected"',
            '"mismatched-line"',
            '"no saved Rust archive under',
        ):
            self.assertIn(fragment, self.archive_helper)

    def test_staged_helper_keeps_reuse_surface_visible(self) -> None:
        for fragment in (
            'EXPECTED_RUST_VERSION = "1.79.0"',
            '"preferred_candidate"',
            '"matching_candidates"',
            '"path_export"',
            '"cargo_export"',
            '"rustc_export"',
        ):
            self.assertIn(fragment, self.staged_helper)


if __name__ == "__main__":
    unittest.main()
