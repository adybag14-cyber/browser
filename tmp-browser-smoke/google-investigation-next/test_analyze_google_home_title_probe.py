from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("analyze_google_home_title_probe.py")
SPEC = importlib.util.spec_from_file_location("analyze_google_home_title_probe", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC is not None and SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class AnalyzeGoogleHomeTitleProbeTests(unittest.TestCase):
    def _base_result(self) -> dict:
        return {
            "helper_outcome": "completed",
            "helper_ready_active_element": "INPUT",
            "helper_ready_query_element": "INPUT:q",
            "helper_ready_marker": "FOCUSED",
            "helper_typed_marker": "TYPED",
            "helper_enter_marker": "SUBMIT",
            "helper_last_marker": "SUBMIT",
            "helper_typed_query_value": "n",
            "helper_enter_query_value": "n",
            "helper_last_query_value": "n",
            "helper_typed_title": "TYPED:n|q",
            "helper_enter_title": "SUBMIT:n|q",
            "helper_last_title": "SUBMIT:n|q",
            "backend_trace_tails": [],
            "wndproc_trace_tails": [],
            "backend_trace_files": [],
            "wndproc_trace_files": [],
        }

    def test_classify_healthy_submit_path(self) -> None:
        summary = MODULE.summarize_probe(self._base_result())
        self.assertEqual("healthy-submit-path", summary["classification"])

    def test_classify_focus_drift(self) -> None:
        result = self._base_result()
        result["helper_ready_active_element"] = "BODY"
        result["helper_ready_query_element"] = ""
        summary = MODULE.summarize_probe(result)
        self.assertEqual("focus-drift", summary["classification"])

    def test_classify_text_suppression_or_drop(self) -> None:
        result = self._base_result()
        result["helper_typed_query_value"] = ""
        result["helper_enter_query_value"] = ""
        result["helper_last_query_value"] = ""
        result["helper_typed_title"] = "KEYDOWN:|q"
        result["helper_enter_title"] = "KEYDOWN:|q"
        result["helper_last_title"] = "KEYDOWN:|q"
        result["backend_trace_tails"] = [
            {"tail": "key_down_end|allow_text_input=True|value_after="},
        ]
        result["wndproc_trace_tails"] = [
            {"tail": "dispatch_text_begin|text=n|value_before="},
        ]
        summary = MODULE.summarize_probe(result)
        self.assertEqual("likely-text-suppression-or-drop", summary["classification"])

    def test_classify_enter_submit_not_reached(self) -> None:
        result = self._base_result()
        result["helper_enter_title"] = "KEYDOWN:n|q"
        result["helper_last_title"] = "KEYDOWN:n|q"
        summary = MODULE.summarize_probe(result)
        self.assertEqual("enter-submit-not-reached", summary["classification"])

    def test_cli_json_output(self) -> None:
        result = self._base_result()
        with tempfile.TemporaryDirectory() as tmp_dir:
            probe_path = Path(tmp_dir) / "probe.json"
            probe_path.write_text(MODULE.json.dumps(result), encoding="utf-8")
            rc = MODULE.main([str(probe_path), "--json"])
        self.assertEqual(0, rc)


if __name__ == "__main__":
    unittest.main()
