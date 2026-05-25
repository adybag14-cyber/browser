from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Saved Rust Build-Readiness Bridge Route

    - issue `#11`
    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
    - `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
    - `scripts/linux/show_issue3_progress_tracker_route.sh`
    - `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/check_linux_build_readiness.py`
    """,
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    - `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    - `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`
    """,
    "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh": r"""
    Usage:
      bash scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh \
        [--repo-root /path/to/browser-repo] \
        [--json]
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|issue \`#11\`|"
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md|"
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_rust_archive_candidates.py|"
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|scripts/check_issue3_staged_rust_toolchain_candidates.py|"
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|scripts/linux/show_issue3_saved_rust_toolchain_route.sh|"
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|scripts/linux/show_issue3_linux_build_readiness_route.sh|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_progress_tracker_route_surface.sh|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|show_issue3_progress_tracker_route.sh|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_saved_rust_archive_candidates_route_surface.sh|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|show_issue3_saved_rust_archive_candidates_route.sh|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_saved_rust_archive_candidates.py|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_staged_rust_toolchain_candidates.py|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_saved_rust_toolchain_route_surface.sh|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|show_issue3_saved_rust_toolchain_route.sh|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_linux_build_readiness_route_surface.sh|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|show_issue3_linux_build_readiness_route.sh|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_linux_build_readiness.py|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|Progress-tracker route surface check:|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|Saved Rust archive-candidate route:|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|Staged Rust toolchain candidates:|"
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|Linux build-readiness route:|"
    """,
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh": r"""
    Print a compact bridge from the issue #11 progress tracker through the saved
    Rust candidate helpers and back into the broader Linux build-readiness route.
    "issue": "Google issue #3 saved Rust build-readiness bridge route"
    "saved_rust_archive_helper":
    "staged_rust_helper":
    "saved_rust_route":
    "build_readiness_route":
    "build_readiness_helper":
    Progress-tracker route surface check:
    Saved Rust archive-candidate route:
    Staged Rust toolchain candidates:
    Linux build-readiness route:
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-rust-bridge-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedRustBuildReadinessRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.bridge_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md"
        )
        cls.progress_note = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.surface_helper = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh"
        )

    def test_bridge_note_keeps_issue11_and_rust_handoff_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.bridge_note)

    def test_progress_and_build_notes_keep_bridge_visible(self) -> None:
        for note_text in (self.progress_note, self.build_readiness_note):
            self.assertIn("docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md", note_text)

    def test_surface_checker_keeps_bridge_contract_fragments_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
            "--repo-root /path/to/browser-repo",
            "--json",
            r"docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|issue \`#11\`|",
            "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "check_issue3_progress_tracker_route_surface.sh",
            "show_issue3_progress_tracker_route.sh",
            "Progress-tracker route surface check:",
            "Saved Rust archive-candidate route:",
            "Staged Rust toolchain candidates:",
            "Linux build-readiness route:",
        ):
            self.assertIn(fragment, self.surface_helper)

    def test_route_printer_keeps_saved_rust_bridge_handoff_visible(self) -> None:
        for fragment in (
            "saved Rust build-readiness bridge route",
            '"issue": "Google issue #3 saved Rust build-readiness bridge route"',
            '"saved_rust_archive_helper"',
            '"staged_rust_helper"',
            '"saved_rust_route"',
            '"build_readiness_route"',
            '"build_readiness_helper"',
            "Progress-tracker route surface check:",
            "Saved Rust archive-candidate route:",
            "Staged Rust toolchain candidates:",
            "Linux build-readiness route:",
        ):
            self.assertIn(fragment, self.route_helper)


if __name__ == "__main__":
    unittest.main()
