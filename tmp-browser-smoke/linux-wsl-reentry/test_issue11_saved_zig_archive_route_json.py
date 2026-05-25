#!/usr/bin/env python3

from __future__ import annotations

import json
import pathlib
import subprocess
import sys
import tarfile
import tempfile
import unittest
import zipfile


class SavedZigArchiveRouteJsonTests(unittest.TestCase):
    def setUp(self) -> None:
        self.repo_root = pathlib.Path(__file__).resolve().parents[2]
        self.helper_path = self.repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
        self.route_surface_path = (
            self.repo_root / "scripts" / "linux" / "check_issue3_saved_zig_archive_candidates_route_surface.sh"
        )
        self.route_show_path = (
            self.repo_root / "scripts" / "linux" / "show_issue3_saved_zig_archive_candidates_route.sh"
        )

    def create_zip_archive(self, path: pathlib.Path, top_level: str) -> None:
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr(f"{top_level}/zig", "binary")

    def create_tar_archive(self, path: pathlib.Path, top_level: str) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            zig_path = root / top_level / "zig"
            zig_path.parent.mkdir(parents=True)
            zig_path.write_text("binary", encoding="utf-8")
            with tarfile.open(path, "w:xz") as archive:
                archive.add(zig_path.parent, arcname=top_level)

    def run_json_command(self, *command: str) -> dict[str, object]:
        completed = subprocess.run(command, check=True, capture_output=True, text=True)
        return json.loads(completed.stdout)

    def test_saved_archive_helper_prefers_exact_0152_and_emits_restore_commands(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_root = pathlib.Path(tmpdir)
            saved_root = temp_root / "repo_archives" / "browser" / "dependencies"
            toolchains_root = temp_root / "toolchains"
            saved_root.mkdir(parents=True)
            toolchains_root.mkdir(parents=True)

            exact_archive = saved_root / "zig-linux-x86_64-0.15.2.zip"
            newer_same_line = saved_root / "zig-linux-x86_64-0.15.7.zip"
            fallback_archive = temp_root / "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
            self.create_zip_archive(exact_archive, "zig-linux-x86_64-0.15.2")
            self.create_zip_archive(newer_same_line, "zig-linux-x86_64-0.15.7")
            self.create_tar_archive(fallback_archive, "zig-x86_64-linux-0.17.0-dev.299+a76ce7710")

            report = self.run_json_command(
                sys.executable,
                str(self.helper_path),
                "--repo-root",
                str(self.repo_root),
                "--saved-archives-root",
                str(saved_root.parent),
                "--toolchains-root",
                str(toolchains_root),
                "--fallback-zig-archive",
                str(fallback_archive),
                "--json",
            )

            self.assertEqual(report["status"], "passed")
            preferred_archive = report["preferred_archive"]
            self.assertIsInstance(preferred_archive, dict)
            assert isinstance(preferred_archive, dict)
            self.assertEqual(preferred_archive["version"], "0.15.2")
            self.assertEqual(pathlib.Path(preferred_archive["path"]), exact_archive.resolve())
            commands = report["commands"]
            self.assertIsInstance(commands, dict)
            assert isinstance(commands, dict)
            self.assertIn("--check-only", commands["restore_check"])
            self.assertIn(str(exact_archive.resolve()), commands["restore_check"])
            self.assertIn(str(exact_archive.resolve()), commands["restore"])

    def test_route_surface_json_passes_with_matching_saved_archive(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_root = pathlib.Path(tmpdir)
            saved_root = temp_root / "repo_archives" / "browser" / "dependencies"
            toolchains_root = temp_root / "toolchains"
            saved_root.mkdir(parents=True)
            toolchains_root.mkdir(parents=True)
            self.create_zip_archive(saved_root / "zig-linux-x86_64-0.15.2.zip", "zig-linux-x86_64-0.15.2")

            report = self.run_json_command(
                "bash",
                str(self.route_surface_path),
                "--repo-root",
                str(self.repo_root),
                "--saved-archives-root",
                str(saved_root.parent),
                "--toolchains-root",
                str(toolchains_root),
                "--json",
            )

            self.assertEqual(report["status"], "passed")
            self.assertEqual(pathlib.Path(report["helper_path"]), self.helper_path)
            self.assertEqual(
                pathlib.Path(report["doc_path"]),
                self.repo_root / "docs" / "ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            )
            self.assertTrue(str(report["minimum_zig"]).startswith("0.15."))
            self.assertEqual(report["failures"], [])

    def test_route_show_json_surfaces_issue11_follow_up_commands(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_root = pathlib.Path(tmpdir)
            saved_root = temp_root / "repo_archives" / "browser" / "dependencies"
            toolchains_root = temp_root / "toolchains"
            saved_root.mkdir(parents=True)
            toolchains_root.mkdir(parents=True)
            fallback_archive = temp_root / "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
            self.create_zip_archive(saved_root / "zig-linux-x86_64-0.15.2.zip", "zig-linux-x86_64-0.15.2")
            self.create_tar_archive(fallback_archive, "zig-x86_64-linux-0.17.0-dev.299+a76ce7710")

            report = self.run_json_command(
                "bash",
                str(self.route_show_path),
                "--repo-root",
                str(self.repo_root),
                "--saved-archives-root",
                str(saved_root.parent),
                "--toolchains-root",
                str(toolchains_root),
                "--fallback-zig-archive",
                str(fallback_archive),
                "--json",
            )

            self.assertEqual(report["issue"], "Google issue #3 saved Zig archive candidates route")
            self.assertEqual(
                pathlib.Path(report["progress_tracker_route_path"]),
                self.repo_root / "docs" / "ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            )
            commands = report["commands"]
            self.assertIsInstance(commands, dict)
            assert isinstance(commands, dict)
            for key in (
                "surface_check",
                "candidate_discovery",
                "matching_line_gate",
                "archive_restore_surface_check",
                "progress_tracker_route",
                "zig_recovery_route",
            ):
                self.assertIn(key, commands)
            self.assertIn("issue #11", "\n".join(report["notes"]))


if __name__ == "__main__":
    unittest.main()
