#!/usr/bin/env python3

from __future__ import annotations

import os
from pathlib import Path
import tempfile
import unittest


REQUIRED_FILES: tuple[tuple[str, str], ...] = (
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "Zig recovery note for the Linux or WSL re-entry lane.",
    ),
    (
        "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
        "Fail-fast route surface checker for the Zig recovery lane.",
    ),
    (
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "Saved Zig archive candidate selector.",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates.sh",
        "Wrapper that surfaces saved Zig archive candidates with repo-local defaults.",
    ),
)

SNIPPET_EXPECTATIONS: tuple[tuple[str, str, str], ...] = (
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "The recovery note keeps the saved Zig archive selector visible.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "0.15.2",
        "The recovery note keeps the expected branch-compatible Zig line visible.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        "The recovery note still names the attached fallback Zig archive.",
    ),
    (
        "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "The route surface checker keeps the saved Zig archive selector visible.",
    ),
    (
        "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
        "--saved-archives-root",
        "The route surface checker keeps the saved-archives override visible.",
    ),
    (
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "--saved-archives-root",
        "The saved Zig archive selector still supports an explicit saved-archives root.",
    ),
    (
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "normalize_saved_archives_root",
        "The saved Zig archive selector still normalizes repo_archives/browser to dependencies.",
    ),
    (
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "Preferred restore commands:",
        "The saved Zig archive selector still prints preferred restore commands.",
    ),
    (
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "use the fallback archive only as a surfaced stopgap",
        "The saved Zig archive selector still warns about fallback-only use.",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates.sh",
        "--saved-archives-root",
        "The wrapper still accepts an explicit saved-archives root override.",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates.sh",
        "normalize_saved_archives_root",
        "The wrapper still normalizes repo_archives/browser to dependencies.",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates.sh",
        "check_issue3_saved_zig_archive_candidates.py",
        "The wrapper still delegates to the saved Zig archive selector.",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates.sh",
        "--fallback-zig-archive",
        "The wrapper still accepts an explicit fallback Zig archive override.",
    ),
)


def collect_surface_state(repo_root: Path) -> dict[str, object]:
    missing_files: list[str] = []
    missing_snippets: list[dict[str, str]] = []

    for relative_path, _purpose in REQUIRED_FILES:
        if not (repo_root / relative_path).is_file():
            missing_files.append(relative_path)

    for relative_path, snippet, purpose in SNIPPET_EXPECTATIONS:
        target = repo_root / relative_path
        if not target.is_file() or snippet not in target.read_text(encoding="utf-8"):
            missing_snippets.append(
                {
                    "path": relative_path,
                    "snippet": snippet,
                    "purpose": purpose,
                }
            )

    return {
        "repo_root": str(repo_root),
        "missing_files": missing_files,
        "missing_snippets": missing_snippets,
    }


def build_fixture_repo(root: Path) -> None:
    file_snippets: dict[str, list[str]] = {}
    for relative_path, _purpose in REQUIRED_FILES:
        file_snippets.setdefault(relative_path, [])
    for relative_path, snippet, _purpose in SNIPPET_EXPECTATIONS:
        file_snippets.setdefault(relative_path, []).append(snippet)

    for relative_path, snippets in file_snippets.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("\n".join(["fixture"] + snippets), encoding="utf-8")


class SavedZigArchiveCandidatesSurfaceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._tmpdir: tempfile.TemporaryDirectory[str] | None = None
        if os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls._tmpdir = tempfile.TemporaryDirectory()
            cls.repo_root = Path(cls._tmpdir.name)
            build_fixture_repo(cls.repo_root)
        else:
            cls.repo_root = Path(__file__).resolve().parents[2]

    @classmethod
    def tearDownClass(cls) -> None:
        if cls._tmpdir is not None:
            cls._tmpdir.cleanup()

    def test_surface_files_and_snippets_are_present(self) -> None:
        result = collect_surface_state(self.repo_root)
        self.assertEqual(result["missing_files"], [])
        self.assertEqual(result["missing_snippets"], [])

    def test_missing_wrapper_script_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            build_fixture_repo(repo_root)
            (repo_root / "scripts/linux/show_issue3_saved_zig_archive_candidates.sh").unlink()

            result = collect_surface_state(repo_root)

            self.assertIn(
                "scripts/linux/show_issue3_saved_zig_archive_candidates.sh",
                result["missing_files"],
            )

    def test_missing_saved_archives_override_snippet_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            build_fixture_repo(repo_root)
            target = repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
            target.write_text("fixture\nnormalize_saved_archives_root\n", encoding="utf-8")

            result = collect_surface_state(repo_root)

            missing = {
                (entry["path"], entry["snippet"])
                for entry in result["missing_snippets"]
            }
            self.assertIn(
                (
                    "scripts/check_issue3_saved_zig_archive_candidates.py",
                    "--saved-archives-root",
                ),
                missing,
            )


if __name__ == "__main__":
    unittest.main()
