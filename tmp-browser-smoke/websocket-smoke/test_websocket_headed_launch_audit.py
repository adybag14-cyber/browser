from __future__ import annotations

import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import websocket_headed_launch_audit as helper


class WebsocketHeadedLaunchAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(self) -> None:
        for expectation in helper.EXPECTATIONS:
            target = self.root / expectation["path"]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(
                f"$browser = Start-Process -ArgumentList {expectation['snippet']},$pageUrl\n",
                encoding="utf-8",
            )

    def test_audit_passes_when_all_websocket_probes_keep_headed_launch(self) -> None:
        self.write_contract_files()
        audit = helper.audit_repo_root(self.root)
        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["present"] for result in audit["results"]))

    def test_audit_reports_existing_file_when_headed_launch_snippet_drifts(self) -> None:
        self.write_contract_files()
        target = self.root / helper.EXPECTATIONS[0]["path"]
        target.write_text(
            "$browser = Start-Process -ArgumentList 'browse',$pageUrl,'--window_width','840'\n",
            encoding="utf-8",
        )
        audit = helper.audit_repo_root(self.root)
        self.assertEqual(1, audit["missing_count"])
        self.assertTrue(audit["results"][0]["exists"])
        self.assertFalse(audit["results"][0]["present"])
        self.assertEqual("headed_launch_missing", audit["missing"][0]["reason"])

    def test_audit_reports_missing_probe_file(self) -> None:
        self.write_contract_files()
        target = self.root / helper.EXPECTATIONS[-1]["path"]
        target.unlink()
        audit = helper.audit_repo_root(self.root)
        self.assertEqual(1, audit["missing_count"])
        self.assertFalse(audit["results"][-1]["exists"])
        self.assertFalse(audit["results"][-1]["present"])
        self.assertEqual("file_missing", audit["missing"][0]["reason"])

    def test_main_outputs_json_and_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files()
        target = self.root / helper.EXPECTATIONS[1]["path"]
        target.write_text("# drifted\n", encoding="utf-8")
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])
        self.assertEqual(1, exit_code)
        payload = json.loads(output.getvalue())
        self.assertEqual("websocket-headed-launches", payload["profile"])
        self.assertEqual(1, payload["missing_count"])


if __name__ == "__main__":
    unittest.main()
