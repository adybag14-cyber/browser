import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_enter_submit_runtime_revalidation_audit as helper


RUNTIME_NOTE = """# Issue #3 Enter-Submit Runtime Revalidation

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

beginDeferredNativeTextInputEnterSubmit()
pending_text_input_suppressions
later `text_input` remains available when stale suppression bytes do not match

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```
"""


PROBE_HELPER = """[CmdletBinding()]
$probeUrl = "http://127.0.0.1:9582/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"
-ExpectedTypedTitleContains ("TYPED:{0}" -f $InputText)
-ExpectedEnterTitleContains ("SUBMIT:{0}" -f $InputText)
"""


PROBE_HTML = """<script>
function bindQueryInput(q) {
  q.addEventListener('input', function(){ mark('TYPED:' + q.value); });
  q.form.addEventListener('submit', function(e){
    e.preventDefault();
    mark('SUBMIT:' + q.value);
  });
}
</script>
"""


class GoogleIssue3EnterSubmitRuntimeRevalidationAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "docs").mkdir()
        (self.root / "tmp-browser-smoke" / "google-investigation-next").mkdir(parents=True)
        (self.root / "src" / "browser" / "tests" / "page").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(
        self,
        *,
        runtime_note: str = RUNTIME_NOTE,
        windows_doc: str = "# Windows Full Use\n",
        production_guide: str = "# Headed Production Guide\n",
        probe_helper: str = PROBE_HELPER,
        probe_html: str = PROBE_HTML,
    ) -> None:
        (self.root / "docs" / "ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md").write_text(
            runtime_note, encoding="utf-8"
        )
        (self.root / "docs" / "WINDOWS_FULL_USE.md").write_text(windows_doc, encoding="utf-8")
        (self.root / "docs" / "HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md").write_text(
            production_guide, encoding="utf-8"
        )
        (
            self.root
            / "tmp-browser-smoke"
            / "google-investigation-next"
            / "chrome-google-home-title-probe.ps1"
        ).write_text(probe_helper, encoding="utf-8")
        (
            self.root
            / "src"
            / "browser"
            / "tests"
            / "page"
            / "google_home_title_probe.html"
        ).write_text(probe_html, encoding="utf-8")

    def test_build_audit_passes_when_runtime_surface_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_runtime_revalidation_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertEqual(0, audit["missing_path_count"])

    def test_build_audit_reports_missing_runtime_note_command(self) -> None:
        self.write_contract_files(
            runtime_note=RUNTIME_NOTE.replace(
                "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1\n",
                "",
            )
        )

        audit = helper.build_runtime_revalidation_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        grouped = {entry["path"]: entry for entry in audit["missing_paths"]}
        self.assertIn("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", grouped)
        self.assertIn(
            "chrome-google-home-title-probe.ps1",
            grouped["docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"]["first_missing_snippet"],
        )

    def test_build_audit_reports_missing_probe_helper_submit_expectation(self) -> None:
        self.write_contract_files(
            probe_helper=PROBE_HELPER.replace(
                '-ExpectedEnterTitleContains ("SUBMIT:{0}" -f $InputText)\n',
                "",
            )
        )

        audit = helper.build_runtime_revalidation_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        grouped = {entry["path"]: entry for entry in audit["missing_paths"]}
        self.assertIn(
            "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
            grouped,
        )

    def test_build_audit_reports_missing_probe_html_submit_marker(self) -> None:
        self.write_contract_files(
            probe_html=PROBE_HTML.replace("    mark('SUBMIT:' + q.value);\n", "")
        )

        audit = helper.build_runtime_revalidation_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        grouped = {entry["path"]: entry for entry in audit["missing_paths"]}
        self.assertIn("src/browser/tests/page/google_home_title_probe.html", grouped)

    def test_cli_json_output_reports_missing_repo_root_cleanly(self) -> None:
        missing_root = self.root / "missing"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("repo_root_not_found", payload["error_type"])
        self.assertEqual(str(missing_root), payload["repo_root"])

    def test_text_report_includes_missing_path_summary(self) -> None:
        self.write_contract_files(probe_html="# drifted\n")

        audit = helper.build_runtime_revalidation_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Enter-Submit Runtime Revalidation Audit", report)
        self.assertIn("Missing path summary:", report)
        self.assertIn("[FAIL] src/browser/tests/page/google_home_title_probe.html", report)


if __name__ == "__main__":
    unittest.main()
