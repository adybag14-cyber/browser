from __future__ import annotations

import copy
import unittest

from google_enter_submit_trace_audit import audit


def make_result() -> dict[str, object]:
    return {
        "focused_worked": True,
        "typed_worked": True,
        "submitted_worked": True,
        "server_saw_submit": False,
        "failure_stage": None,
        "title_after_focus": "FOCUSED|A=INPUT:q::1|Q=1|V=|S=0,0|E=focus",
        "title_after_type": "TYPED:lightpanda|A=INPUT:q::1|Q=1|V=lightpanda|S=10,10|E=input",
        "title_after_keydown": "KEYDOWN:lightpanda:13:13|A=INPUT:q::1|Q=1|V=lightpanda|S=10,10|E=keydown",
        "title_after_keypress": "KEYPRESS:Enter:lightpanda|A=INPUT:q::1|Q=1|V=lightpanda|S=10,10|E=keypress",
        "title_after_submit": "SUBMIT:lightpanda|A=INPUT:q::1|Q=1|V=lightpanda|S=10,10|E=submit",
        "server_ready_at_utc": "2026-05-21T20:20:00Z",
        "screenshot_ready_at_utc": "2026-05-21T20:20:01Z",
        "window_ready_at_utc": "2026-05-21T20:20:02Z",
        "focus_observed_at_utc": "2026-05-21T20:20:03Z",
        "input_sent_at_utc": "2026-05-21T20:20:04Z",
        "typed_observed_at_utc": "2026-05-21T20:20:05Z",
        "enter_sent_at_utc": "2026-05-21T20:20:06Z",
        "keydown_observed_at_utc": "2026-05-21T20:20:07Z",
        "keypress_observed_at_utc": "2026-05-21T20:20:08Z",
        "submit_observed_at_utc": "2026-05-21T20:20:09Z",
        "trace_artifacts": [
            "tmp-browser-smoke/google-investigation-next/runtime-input-backend-123.log",
            "tmp-browser-smoke/google-investigation-next/wndproc-input-123.log",
            "tmp-browser-smoke/google-investigation-next/browse-render.log",
        ],
    }


class GoogleEnterSubmitTraceAuditTests(unittest.TestCase):
    def test_audit_passes_when_probe_result_is_ordered(self) -> None:
        summary = audit(make_result())
        self.assertTrue(summary["ok"])
        self.assertEqual([], summary["failed_checks"])

    def test_audit_fails_when_submit_happens_without_keydown_marker(self) -> None:
        result = make_result()
        result["title_after_keydown"] = "SUBMIT:lightpanda|unexpected"

        summary = audit(result)
        self.assertFalse(summary["ok"])
        labels = {check["label"] for check in summary["failed_checks"]}
        self.assertIn("title_after_keydown_marker", labels)

    def test_audit_fails_when_timestamps_go_backwards(self) -> None:
        result = make_result()
        result["typed_observed_at_utc"] = "2026-05-21T20:20:03Z"

        summary = audit(result)
        self.assertFalse(summary["ok"])
        labels = {check["label"] for check in summary["failed_checks"]}
        self.assertIn("input_sent_at_utc_before_typed_observed_at_utc", labels)

    def test_audit_accepts_server_submit_fallback(self) -> None:
        result = make_result()
        result["submitted_worked"] = False
        result["server_saw_submit"] = True
        result["title_after_submit"] = None
        result["submit_observed_at_utc"] = None

        summary = audit(result)
        self.assertFalse(summary["ok"])
        labels = {check["label"] for check in summary["failed_checks"]}
        self.assertNotIn("submit_evidence", labels)
        self.assertIn("title_after_submit_marker", labels)

    def test_audit_fails_when_trace_artifacts_are_missing(self) -> None:
        result = copy.deepcopy(make_result())
        result["trace_artifacts"] = ["tmp-browser-smoke/google-investigation-next/browse-render.log"]

        summary = audit(result)
        self.assertFalse(summary["ok"])
        labels = {check["label"] for check in summary["failed_checks"]}
        self.assertIn("runtime_input_trace_present", labels)
        self.assertIn("wndproc_trace_present", labels)


if __name__ == "__main__":
    unittest.main()