#!/usr/bin/env python3

from __future__ import annotations

import os
from pathlib import Path
import tempfile
import unittest


REQUIRED_FILES: tuple[tuple[str, str], ...] = (
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "Linux or WSL build-readiness note for the blocked issue #3 runtime lane.",
    ),
    (
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "Fail-fast surface checker for the Linux build-readiness route.",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "Compact route printer for the saved-archive-first Linux build-readiness path.",
    ),
)

SNIPPET_EXPECTATIONS: tuple[tuple[str, str, str], ...] = (
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "scripts/linux/check_issue3_zig_toolchain_match.sh",
        "The Linux build-readiness note keeps the dedicated Zig matching-line gate visible.",
    ),
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "--saved-archives-root /path/to/memory/repo_archives/browser",
        "The Linux build-readiness note keeps the saved-archives override visible in its explicit helper example.",
    ),
    (
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "scripts/linux/check_issue3_zig_toolchain_match.sh",
        "The surface checker keeps the Zig matching-line gate in its guarded helper surface.",
    ),
    (
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "TOOLCHAIN_MATCH_COMMAND",
        "The surface checker requires the route printer to keep a dedicated Zig matching-line command.",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "TOOLCHAIN_MATCH_COMMAND=",
        "The route printer still defines a dedicated Zig matching-line command.",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "--saved-archives-root $(format_shell_arg \"${SAVED_ARCHIVES_ROOT}\")",
        "The route printer threads the normalized saved-archives root into the Zig matching-line handoff.",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "\"zig_toolchain_match\": ${TOOLCHAIN_MATCH_COMMAND@Q}",
        "The route printer keeps the Zig matching-line handoff in its JSON output.",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "Zig matching-line gate:",
        "The route printer keeps the Zig matching-line step visible in its human-readable output.",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "A caller-provided Rust toolchain dir now also defines the derived toolchains root used by the Zig recovery route and matching-line gate",
        "The route printer keeps the saved-archives and toolchains handoff rule visible in its working notes.",
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


class LinuxBuildReadinessSavedArchivesHandoffTests(unittest.TestCase):
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

    def test_missing_route_printer_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            build_fixture_repo(repo_root)
            (repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh").unlink()

            result = collect_surface_state(repo_root)

            self.assertIn(
                "scripts/linux/show_issue3_linux_build_readiness_route.sh",
                result["missing_files"],
            )

    def test_missing_saved_archives_handoff_snippet_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            build_fixture_repo(repo_root)
            target = repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
            target.write_text(
                "\n".join(
                    [
                        "fixture",
                        "TOOLCHAIN_MATCH_COMMAND=",
                        "\"zig_toolchain_match\": ${TOOLCHAIN_MATCH_COMMAND@Q}",
                        "Zig matching-line gate:",
                    ]
                ),
                encoding="utf-8",
            )

            result = collect_surface_state(repo_root)

            missing = {
                (entry["path"], entry["snippet"])
                for entry in result["missing_snippets"]
            }
            self.assertIn(
                (
                    "scripts/linux/show_issue3_linux_build_readiness_route.sh",
                    "--saved-archives-root $(format_shell_arg \"${SAVED_ARCHIVES_ROOT}\")",
                ),
                missing,
            )


if __name__ == "__main__":
    unittest.main()
