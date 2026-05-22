from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import headed_probe_mode_inventory_audit as audit


def write_probe(repo_root: Path, relative_path: str, content: str) -> None:
    path = repo_root / relative_path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


class HeadedProbeModeInventoryAuditTests(unittest.TestCase):
    def make_repo(self) -> Path:
        tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(tempdir.cleanup)
        repo_root = Path(tempdir.name)
        (repo_root / "build.zig").write_text("// stub\n", encoding="utf-8")
        return repo_root

    def test_detects_missing_explicit_headed_launch(self) -> None:
        repo_root = self.make_repo()
        write_probe(
            repo_root,
            "tmp-browser-smoke/family/missing.ps1",
            """
            $browser = Start-Process -FilePath $browserExe -ArgumentList \"browse\",\"http://127.0.0.1:8000/index.html\" -WorkingDirectory $repo -PassThru
            """,
        )

        result = audit.audit_probe_launches(repo_root)

        self.assertEqual(1, result["browser_launch_count"])
        self.assertEqual(1, len(result["missing_explicit_headed"]))
        self.assertIn("missing.ps1", result["missing_explicit_headed"][0]["relative_path"])

    def test_accepts_browser_mode_headed_and_headed_shortcut(self) -> None:
        repo_root = self.make_repo()
        write_probe(
            repo_root,
            "tmp-browser-smoke/family/explicit.ps1",
            """
            $browser = Start-Process -FilePath $browserExe -ArgumentList @(\"browse\",\"--browser_mode\",\"headed\",\"http://127.0.0.1:8000/index.html\") -WorkingDirectory $repo -PassThru
            """,
        )
        write_probe(
            repo_root,
            "tmp-browser-smoke/family/shortcut.ps1",
            """
            $browser = Start-Process -FilePath $browserExe -ArgumentList \"browse\",\"--headed\",\"http://127.0.0.1:8000/index.html\" -WorkingDirectory $repo -PassThru
            """,
        )

        result = audit.audit_probe_launches(repo_root)

        self.assertEqual(2, result["browser_launch_count"])
        self.assertEqual([], result["missing_explicit_headed"])

    def test_ignores_non_browser_process_launches(self) -> None:
        repo_root = self.make_repo()
        write_probe(
            repo_root,
            "tmp-browser-smoke/family/server.ps1",
            """
            $server = Start-Process -FilePath \"python\" -ArgumentList \"-m\",\"http.server\",\"8000\" -WorkingDirectory $root -PassThru
            """,
        )

        result = audit.audit_probe_launches(repo_root)

        self.assertEqual(0, result["browser_launch_count"])
        self.assertEqual([], result["missing_explicit_headed"])

    def test_main_returns_nonzero_when_missing(self) -> None:
        repo_root = self.make_repo()
        write_probe(
            repo_root,
            "tmp-browser-smoke/family/missing.ps1",
            """
            $browser = Start-Process -FilePath $browserExe -ArgumentList \"browse\",\"http://127.0.0.1:8000/index.html\" -WorkingDirectory $repo -PassThru
            """,
        )

        self.assertEqual(1, audit.main([str(repo_root)]))


if __name__ == "__main__":
    unittest.main()
