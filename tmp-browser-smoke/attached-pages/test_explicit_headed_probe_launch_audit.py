from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


SPEC = importlib.util.spec_from_file_location(
    "explicit_headed_probe_launch_audit",
    Path(__file__).with_name("explicit_headed_probe_launch_audit.py"),
)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class ExplicitHeadedProbeLaunchAuditTests(unittest.TestCase):
    def write_fixture_repo(self, repo_root: Path, drop_index: int | None = None) -> None:
        for index, expectation in enumerate(MODULE.EXPECTATIONS):
            if drop_index is not None and index == drop_index:
                continue
            target = repo_root / expectation["path"]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(expectation["snippet"], encoding="utf-8")

    def test_repo_root_from_finds_build_zig(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            nested = repo_root / "tmp-browser-smoke" / "attached-pages"
            nested.mkdir(parents=True)
            (repo_root / "build.zig").write_text("// sentinel\n", encoding="utf-8")

            self.assertEqual(MODULE.repo_root_from(nested), repo_root)

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_fixture_repo(repo_root)

            result = MODULE.audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_when_one_file_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_fixture_repo(repo_root, drop_index=0)

            result = MODULE.audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_reports_missing_snippet_for_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_fixture_repo(repo_root)
            first_target = repo_root / MODULE.EXPECTATIONS[0]["path"]
            first_target.write_text('Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse",$StartupUrl)', encoding="utf-8")

            result = MODULE.audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertTrue(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_covers_common_and_direct_probe_surfaces(self) -> None:
        covered_paths = {expectation["path"] for expectation in MODULE.EXPECTATIONS}
        self.assertTrue(
            {
                "tmp-browser-smoke/browser-pages/BrowserPagesProbeCommon.ps1",
                "tmp-browser-smoke/localstorage-persistence/StorageProbeCommon.ps1",
                "tmp-browser-smoke/sessionstorage-scope/SessionStorageProbeCommon.ps1",
                "tmp-browser-smoke/indexeddb-persistence/IndexedDbProbeCommon.ps1",
                "tmp-browser-smoke/file-upload/FileUploadProbeCommon.ps1",
                "tmp-browser-smoke/popup/chrome-popup-form-enter-probe.ps1",
                "tmp-browser-smoke/popup/chrome-popup-form-post-probe.ps1",
                "tmp-browser-smoke/popup/chrome-popup-script-policy-block-probe.ps1",
                "tmp-browser-smoke/zoom/chrome-zoom-probe.ps1",
            }.issubset(covered_paths)
        )


if __name__ == "__main__":
    unittest.main()
