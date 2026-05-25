from __future__ import annotations

import contextlib
import io
import json
import sys
import tarfile
import tempfile
import unittest
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))

import check_issue3_saved_zig_archive_candidates as helper


BUILD_ZON = """.{
    .name = .browser,
    .version = \"0.0.0\",
    .minimum_zig_version = \"0.15.2\",
    .dependencies = .{},
    .paths = .{\"\"},
}
"""

FALLBACK_ARCHIVE_NAME = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def create_zip_archive(path: Path, top_level: str) -> None:
    with zipfile.ZipFile(path, "w") as archive:
        archive.writestr(f"{top_level}/zig", "binary")


def create_tar_xz_archive(path: Path, top_level: str) -> None:
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_root = Path(tmpdir)
        binary_path = tmp_root / top_level / "zig"
        binary_path.parent.mkdir(parents=True, exist_ok=True)
        binary_path.write_text("binary", encoding="utf-8")
        with tarfile.open(path, "w:xz") as archive:
            archive.add(binary_path.parent, arcname=top_level)


class Issue3SavedZigArchiveCandidatesHelperTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.workspace_root = Path(self.tempdir.name)
        self.repo_root = self.workspace_root / "browser"
        self.repo_root.mkdir()
        (self.repo_root / "build.zig.zon").write_text(BUILD_ZON, encoding="utf-8")
        self.saved_archives_root = self.workspace_root / "memory" / "repo_archives" / "browser"
        self.saved_archives_root.mkdir(parents=True)
        self.dependencies_root = self.saved_archives_root / "dependencies"
        self.dependencies_root.mkdir()
        self.toolchains_root = self.workspace_root / "toolchains"
        self.toolchains_root.mkdir()
        self.agent_files_root = self.workspace_root / "agent_files"
        self.agent_files_root.mkdir()

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def run_main_json(self) -> tuple[int, dict[str, object]]:
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--saved-archives-root",
                    str(self.saved_archives_root),
                    "--toolchains-root",
                    str(self.toolchains_root),
                    "--json",
                ]
            )
        return exit_code, json.loads(output.getvalue())

    def test_main_json_prefers_exact_match_from_generic_archive_name(self) -> None:
        generic_archive = self.dependencies_root / "saved-zig-toolchain.tar.xz"
        mismatched_archive = self.saved_archives_root / "zig-linux-x86_64-0.17.0-dev.299+a76ce7710.zip"
        create_tar_xz_archive(generic_archive, "zig-linux-x86_64-0.15.2")
        create_zip_archive(mismatched_archive, "zig-linux-x86_64-0.17.0-dev.299+a76ce7710")

        exit_code, report = self.run_main_json()

        self.assertEqual(0, exit_code)
        self.assertEqual("passed", report["status"])
        self.assertEqual(
            [str(self.saved_archives_root.resolve()), str(self.dependencies_root.resolve())],
            report["saved_archives_search_roots"],
        )
        preferred = report["preferred_archive"]
        self.assertIsNotNone(preferred)
        assert isinstance(preferred, dict)
        self.assertEqual(str(generic_archive.resolve()), preferred["path"])
        self.assertEqual("0.15.2", preferred["version"])
        self.assertEqual("matches-expected-line", preferred["status"])
        commands = report["commands"]
        self.assertIn("restore_check", commands)
        self.assertIn("restore", commands)
        self.assertIn("restore_zig_toolchain_archive.sh", commands["restore_check"])
        self.assertIn(str(self.toolchains_root.resolve()), commands["restore_check"])

    def test_main_json_reports_failure_when_only_mismatched_inputs_are_available(self) -> None:
        mismatched_archive = self.dependencies_root / "zig-linux-x86_64-0.17.0-dev.299+a76ce7710.zip"
        fallback_archive = self.agent_files_root / FALLBACK_ARCHIVE_NAME
        create_zip_archive(mismatched_archive, "zig-linux-x86_64-0.17.0-dev.299+a76ce7710")
        create_tar_xz_archive(fallback_archive, "zig-x86_64-linux-0.17.0-dev.299+a76ce7710")

        exit_code, report = self.run_main_json()

        self.assertEqual(1, exit_code)
        self.assertEqual("failed", report["status"])
        self.assertEqual(str(fallback_archive.resolve()), report["fallback_archive"])
        self.assertIsNone(report["preferred_archive"])
        self.assertEqual({}, report["commands"])
        self.assertTrue(report["failures"])
        self.assertIn("expected 0.15.x line", report["failures"][0])
        self.assertIn(str(self.saved_archives_root.resolve()), report["failures"][0])


if __name__ == "__main__":
    unittest.main()
