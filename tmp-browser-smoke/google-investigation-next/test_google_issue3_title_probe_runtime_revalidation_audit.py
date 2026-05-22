import tempfile
import unittest
from pathlib import Path

import google_issue3_title_probe_runtime_revalidation_audit as helper


RUNTIME_NOTE = """# Runtime Revalidation

- src/browser/Page.zig
- src/display/win32_backend.zig
- beginDeferredNativeTextInputEnterSubmit()
- std.ArrayListUnmanaged(TextInputEvent)
- runtime-input-backend-*.log
- wndproc-input-*.log
"""


PROBE_HTML = """<!doctype html>
<script>
window.__lpEarlyEvents=[];
window.__lpPostMessages=[];
document.addEventListener('keydown', function () {});
document.addEventListener('keypress', function () {});
document.addEventListener('beforeinput', function () {});
document.addEventListener('input', function () {});
</script>
"""


PROBE_PS1 = """$helper = Join-Path $RepoRoot \"scripts\\windows\\watch_headed_probe.ps1\"
& $helper `
    -ExpectedTitleContainsAny @(\"A=INPUT:q::1\", \"FOCUSED|\") `
    -ExpectedTypedTitleContains (\"TYPED:{0}\" -f $InputText) `
    -ExpectedEnterTitleContains (\"SUBMIT:{0}\" -f $InputText)
\"runtime-input-backend-*.log\"
\"wndproc-input-*.log\"
"""


class GoogleIssue3TitleProbeRuntimeRevalidationAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "docs").mkdir()
        (self.root / "src" / "browser" / "tests" / "page").mkdir(parents=True)
        (self.root / "tmp-browser-smoke" / "google-investigation-next").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(
        self,
        *,
        runtime_note_text: str = RUNTIME_NOTE,
        probe_html_text: str = PROBE_HTML,
        probe_ps1_text: str = PROBE_PS1,
    ) -> None:
        (self.root / "docs" / "ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md").write_text(
            runtime_note_text, encoding="utf-8"
        )
        (self.root / "src" / "browser" / "tests" / "page" / "google_home_title_probe.html").write_text(
            probe_html_text, encoding="utf-8"
        )
        (
            self.root
            / "tmp-browser-smoke"
            / "google-investigation-next"
            / "chrome-google-home-title-probe.ps1"
        ).write_text(probe_ps1_text, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_runtime_trace_reference(self) -> None:
        self.write_contract_files(
            runtime_note_text=RUNTIME_NOTE.replace("- runtime-input-backend-*.log\n", "")
        )

        audit = helper.build_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn("runtime-input-backend-*.log", failing_snippets)

    def test_build_audit_reports_missing_keypress_probe_listener(self) -> None:
        self.write_contract_files(
            probe_html_text=PROBE_HTML.replace("document.addEventListener('keypress', function () {});\n", "")
        )

        audit = helper.build_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn("document.addEventListener('keypress'", failing_snippets)

    def test_build_audit_reports_missing_enter_title_marker(self) -> None:
        self.write_contract_files(
            probe_ps1_text=PROBE_PS1.replace(
                '    -ExpectedEnterTitleContains (\"SUBMIT:{0}\" -f $InputText)\n', ""
            )
        )

        audit = helper.build_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn('-ExpectedEnterTitleContains (\"SUBMIT:{0}\" -f $InputText)', failing_snippets)


if __name__ == "__main__":
    unittest.main()
