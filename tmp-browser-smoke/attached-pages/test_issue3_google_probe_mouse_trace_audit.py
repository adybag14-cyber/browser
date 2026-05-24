from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from issue3_google_probe_mouse_trace_audit import EXPECTATIONS, audit, render_repo, run_self_test


class Issue3GoogleProbeMouseTraceAuditTests(unittest.TestCase):
    def assert_missing_label_is_reported(self, missing_label: str) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            render_repo(repo_root, missing_label=missing_label)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual(missing_label, failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_passes_when_all_expected_markers_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            render_repo(repo_root)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_each_marker_fails_in_isolation(self) -> None:
        for expectation in EXPECTATIONS:
            with self.subTest(label=expectation["label"]):
                self.assert_missing_label_is_reported(expectation["label"])

    def test_self_test_passes(self) -> None:
        stream = io.StringIO()
        with redirect_stdout(stream):
            ok, failures = run_self_test()
        self.assertTrue(ok)
        self.assertEqual([], failures)


if __name__ == "__main__":
    unittest.main()
