import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import google_issue3_enter_submit_runtime_revalidation_audit as helper


RUNTIME_NOTE_TEXT = """# Issue #3 Enter-Submit Runtime Revalidation

## Goal

- keep the narrowed runtime slice visible

## Current runtime gap

- `_defer_native_text_input_enter_submit: bool`
- `_pending_native_enter_submit: ?*Element.Html.Input`
- `std.ArrayListUnmanaged(TextInputEvent)`
- `src/browser/tests/page/google_home_title_probe.html`
- `zig build -Dtarget=x86_64-windows-msvc --summary all`
- `powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1`
- `.\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1`
- `runtime-input-backend-*.log`
- `wndproc-input-*.log`
- `src/browser/Page.zig`
- `src/display/win32_backend.zig`
"""


class GoogleIssue3EnterSubmitRuntimeRevalidationAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "docs").mkdir()

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_runtime_note(self, text: str = RUNTIME_NOTE_TEXT) -> None:
        (self.root / "docs" / "ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md").write_text(
            text,
            encoding="utf-8",
        )

    def test_build_audit_passes_when_runtime_note_matches_contract(self) -> None:
        self.write_runtime_note()

        audit = helper.build_runtime_revalidation_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertEqual(0, audit["missing_path_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_replay_command(self) -> None:
        self.write_runtime_note(
            RUNTIME_NOTE_TEXT.replace(
                "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1",
                "",
            )
        )

        audit = helper.build_runtime_revalidation_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1",
            failing_snippets,
        )

    def test_missing_path_summary_groups_multiple_missing_contract_points(self) -> None:
        self.write_runtime_note("# drifted\n")

        audit = helper.build_runtime_revalidation_audit(self.root)

        self.assertEqual(1, audit["missing_path_count"])
        summary = audit["missing_paths"][0]
        self.assertEqual("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", summary["path"])
        self.assertGreater(summary["missing_expectation_count"], 1)
        self.assertEqual("Runtime note keeps the headed slice goal visible", summary["first_missing_purpose"])
        self.assertIn("## Goal", summary["missing_snippets"])

    def test_text_report_surfaces_missing_path_summary(self) -> None:
        self.write_runtime_note("# drifted\n")

        audit = helper.build_runtime_revalidation_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Enter-Submit Runtime Revalidation Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("Missing path summary:", report)
        self.assertIn("[FAIL] docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", report)

    def test_cli_json_output_returns_nonzero_when_note_drifts(self) -> None:
        self.write_runtime_note("# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)
        self.assertEqual(1, payload["missing_path_count"])

    def test_cli_reports_missing_repo_root_cleanly(self) -> None:
        missing_root = self.root / "missing-root"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("repo_root_not_found", payload["error_type"])
        self.assertEqual(str(missing_root), payload["repo_root"])


if __name__ == "__main__":
    unittest.main()
