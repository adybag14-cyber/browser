import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("check_issue3_attached_html_target_bundle.py")
EXPECTED = [
    "Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html",
    "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html",
    "Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html",
]


def run_checker(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        check=False,
        capture_output=True,
        text=True,
    )


class AttachedHtmlTargetBundleTests(unittest.TestCase):
    def test_self_test_passes(self) -> None:
        result = run_checker("--self-test")
        self.assertEqual(result.returncode, 0)
        self.assertIn("self-test: ok", result.stdout)

    def test_exact_bundle_matches(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            for name in EXPECTED:
                (tmp_path / name).write_text("<html></html>", encoding="utf-8")

            result = run_checker("--input", str(tmp_path), "--json")
            self.assertEqual(result.returncode, 0)
            payload = json.loads(result.stdout)
            self.assertTrue(payload["exact_bundle_match"])
            self.assertEqual(payload["missing_expected_files"], [])
            self.assertEqual(payload["unexpected_html_files"], [])

    def test_missing_bundle_member_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            for name in EXPECTED[:2]:
                (tmp_path / name).write_text("<html></html>", encoding="utf-8")

            result = run_checker("--input", str(tmp_path), "--json")
            self.assertEqual(result.returncode, 1)
            payload = json.loads(result.stdout)
            self.assertIn(EXPECTED[2], payload["missing_expected_files"])

    def test_extra_html_requires_opt_in(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            for name in EXPECTED:
                (tmp_path / name).write_text("<html></html>", encoding="utf-8")
            (tmp_path / "extra.html").write_text("<html></html>", encoding="utf-8")

            result = run_checker("--input", str(tmp_path), "--json")
            self.assertEqual(result.returncode, 1)
            payload = json.loads(result.stdout)
            self.assertEqual(payload["unexpected_html_files"], ["extra.html"])

            allowed = run_checker("--input", str(tmp_path), "--json", "--allow-extra-files")
            self.assertEqual(allowed.returncode, 0)


if __name__ == "__main__":
    unittest.main()
