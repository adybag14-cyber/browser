import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import config_mode_inference_audit as helper


CONFIG_SNIPPETS = "\n".join(expectation["snippet"] for expectation in helper.EXPECTATIONS) + "\n"


class ConfigModeInferenceAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "src").mkdir()

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_config(self, content: str = CONFIG_SNIPPETS) -> None:
        (self.root / "src" / "Config.zig").write_text(content, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_config()

        audit = helper.build_mode_inference_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_remote_host_helper(self) -> None:
        self.write_config(CONFIG_SNIPPETS.replace(helper.EXPECTATIONS[0]["snippet"] + "\n", ""))

        audit = helper.build_mode_inference_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        missing = [result for result in audit["results"] if not result["exists"]]
        self.assertEqual(helper.EXPECTATIONS[0]["snippet"], missing[0]["snippet"])

    def test_build_audit_reports_missing_scheme_less_remote_fetch_guard(self) -> None:
        self.write_config(CONFIG_SNIPPETS.replace(helper.EXPECTATIONS[2]["snippet"] + "\n", ""))

        audit = helper.build_mode_inference_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        missing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(helper.EXPECTATIONS[2]["snippet"], missing_snippets)

    def test_build_audit_reports_missing_loopback_browse_guard(self) -> None:
        self.write_config(CONFIG_SNIPPETS.replace(helper.EXPECTATIONS[4]["snippet"] + "\n", ""))

        audit = helper.build_mode_inference_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        missing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(helper.EXPECTATIONS[4]["snippet"], missing_snippets)

    def test_main_outputs_json_when_contract_drifts(self) -> None:
        self.write_config("# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual(len(helper.EXPECTATIONS), payload["missing_count"])

    def test_main_reports_missing_repo_root_in_text(self) -> None:
        missing_root = self.root / "missing-repo-root"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root)])

        self.assertEqual(1, exit_code)
        text = stdout.getvalue()
        self.assertIn("Config Mode Inference Audit", text)
        self.assertIn(f"Repo root: {missing_root}", text)
        self.assertIn("Error: repo root does not exist:", text)


if __name__ == "__main__":
    unittest.main()