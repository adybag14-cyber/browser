#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import tempfile
import unittest


REQUIRED_FILES = (
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
    "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
    "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
    "scripts/linux/show_issue3_progress_tracker_route.sh",
    "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh",
    "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh",
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh",
    "scripts/check_issue3_saved_rust_archive_candidates.py",
    "scripts/check_issue3_staged_rust_toolchain_candidates.py",
    "scripts/check_linux_build_readiness.py",
)


def write_file(root: Path, relative_path: str, text: str = "fixture\n") -> None:
    target = root / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")


def make_fixture_repo() -> Path:
    fixture_dir = Path(tempfile.mkdtemp(prefix="issue3_saved_rust_bridge_"))
    repo_root = fixture_dir / "browser"
    repo_root.mkdir()

    note_text = "\n".join(
        [
            "issue `#11`",
            "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        ]
    )
    show_text = "\n".join(
        [
            "check_issue3_progress_tracker_route_surface.sh",
            "show_issue3_progress_tracker_route.sh",
            "check_issue3_saved_rust_archive_candidates_route_surface.sh",
            "show_issue3_saved_rust_archive_candidates_route.sh",
            "check_issue3_saved_rust_archive_candidates.py",
            "check_issue3_staged_rust_toolchain_candidates.py",
            "check_issue3_saved_rust_toolchain_route_surface.sh",
            "show_issue3_saved_rust_toolchain_route.sh",
            "check_issue3_linux_build_readiness_route_surface.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "check_linux_build_readiness.py",
            "Progress-tracker route surface check:",
            "Saved Rust archive-candidate route:",
            "Staged Rust toolchain candidates:",
            "Linux build-readiness route:",
        ]
    )

    for relative_path in REQUIRED_FILES:
        text = "fixture\n"
        if relative_path.endswith("ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md"):
            text = note_text
        elif relative_path.endswith("show_issue3_saved_rust_build_readiness_route.sh"):
            text = show_text
        write_file(repo_root, relative_path, text)

    return repo_root


class SavedRustBuildReadinessRouteTests(unittest.TestCase):
    def test_surface_checker_fixture_passes(self) -> None:
        repo_root = make_fixture_repo()
        script_path = (
            Path(__file__).resolve().parents[2]
            / "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh"
        )
        completed = subprocess.run(
            ["bash", str(script_path), "--repo-root", str(repo_root), "--json"],
            check=True,
            capture_output=True,
            text=True,
        )
        payload = json.loads(completed.stdout)
        self.assertEqual(payload["missing_count"], 0)
        self.assertGreaterEqual(payload["reference_count"], 10)
        self.assertGreaterEqual(payload["content_check_count"], 10)

    def test_route_printer_json_surfaces_bridge_commands(self) -> None:
        repo_root = make_fixture_repo()
        saved_archives_root = repo_root.parent / "memory" / "repo_archives" / "browser" / "dependencies"
        toolchains_root = repo_root.parent / "toolchains"
        saved_archives_root.mkdir(parents=True)
        toolchains_root.mkdir(parents=True)

        script_path = (
            Path(__file__).resolve().parents[2]
            / "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh"
        )
        completed = subprocess.run(
            [
                "bash",
                str(script_path),
                "--repo-root",
                str(repo_root),
                "--saved-archives-root",
                str(saved_archives_root),
                "--toolchains-root",
                str(toolchains_root),
                "--json",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        payload = json.loads(completed.stdout)
        self.assertIn("docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md", payload["read_first"])
        commands = payload["commands"]
        self.assertIn("progress_tracker_route", commands)
        self.assertIn("saved_rust_archive_helper", commands)
        self.assertIn("staged_rust_helper", commands)
        self.assertIn("saved_rust_route", commands)
        self.assertIn("build_readiness_route", commands)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
