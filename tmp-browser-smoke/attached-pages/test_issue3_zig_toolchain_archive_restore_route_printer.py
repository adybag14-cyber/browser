import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

DEFAULT_SOURCE_SCRIPT = (
    Path(__file__).resolve().parents[2]
    / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
)


class ZigArchiveRestoreRoutePrinterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.repo_root = self.root / "browser"
        self.repo_root.mkdir()
        (self.repo_root / "build.zig.zon").write_text(".{ .minimum_zig_version = \"0.15.1\" }\n", encoding="utf-8")

        for relative_path in [
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
        ]:
            target = self.repo_root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("placeholder\n", encoding="utf-8")

        script_target = self.repo_root / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        script_target.parent.mkdir(parents=True, exist_ok=True)
        source_script = Path(
            os.environ.get(
                "LIGHTPANDA_ROUTE_HELPER_SOURCE",
                str(DEFAULT_SOURCE_SCRIPT),
            )
        )
        shutil.copyfile(source_script, script_target)
        os.chmod(script_target, 0o755)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def run_script(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(self.repo_root / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"), "--repo-root", str(self.repo_root), *args],
            check=True,
            capture_output=True,
            text=True,
        )

    def test_text_output_surfaces_live_route_sections(self) -> None:
        completed = self.run_script()
        output = completed.stdout
        self.assertIn("Google issue #3 Zig toolchain archive restore route", output)
        self.assertIn("Surface check", output)
        self.assertIn("Archive restore commands", output)
        self.assertIn("show_issue3_zig_toolchain_recovery_route.sh", output)
        self.assertIn("provide --archive /path/to/zig-0.15.2.tar.xz", output)

    def test_json_output_reports_compact_route_when_no_archive_is_selected(self) -> None:
        completed = self.run_script("--json")
        payload = json.loads(completed.stdout)
        self.assertEqual(payload["issue"], "Google issue #3 Zig toolchain archive restore route")
        self.assertEqual(payload["archive_path"], "")
        self.assertIn("surface_check", payload["commands"])
        self.assertIn("recovery_route", payload["commands"])
        self.assertNotIn("restore_check_only", payload["commands"])

    def test_json_output_reports_restore_and_readiness_when_archive_is_selected(self) -> None:
        archive = self.root / "zig-0.15.2.tar.xz"
        archive.write_text("placeholder archive path\n", encoding="utf-8")
        completed = self.run_script("--archive", str(archive), "--json")
        payload = json.loads(completed.stdout)
        self.assertEqual(payload["archive_path"], str(archive))
        self.assertTrue(payload["destination"].endswith("zig-0.15.2"))
        self.assertIn("restore_check_only", payload["commands"])
        self.assertIn("restore", payload["commands"])
        self.assertIn("full_readiness", payload["commands"])


if __name__ == "__main__":
    unittest.main()
