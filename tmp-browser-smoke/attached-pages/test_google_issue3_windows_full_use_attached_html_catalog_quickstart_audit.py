import tempfile
import unittest
from pathlib import Path

import google_issue3_windows_full_use_attached_html_catalog_quickstart_audit as helper


DOC_SNIPPET = """# Issue #3 Windows Full-Use Attached HTML Catalog Quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -AuditSidecars
```
"""

README_SNIPPET = """# Attached Pages

The intended order is sidecars first, broader asset audit second, manifest or server startup last.
"""

HELPER_SNIPPET = """$entrypoint = [ordered]@{
    recommended_next_key = 'attached_pages_sidecar_audit'
    helper_commands = [ordered]@{
        attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand
        attached_pages_google_sidecar_audit = $attachedPagesGoogleSidecarAuditCommand
        attached_pages_asset_audit = $attachedPagesAssetAuditCommand
        attached_pages_print_manifest = $attachedPagesManifestPrintCommand
        attached_pages_strict_launch = $attachedPagesStrictLaunchCommand
    }
}
Write-Host ((\" 10. Sidecar audit:         {0}\") -f $entrypoint.helper_commands.attached_pages_sidecar_audit)
Write-Host ((\" 11. Asset audit:           {0}\") -f $entrypoint.helper_commands.attached_pages_asset_audit)
Write-Host ((\" 12. Print manifest:        {0}\") -f $entrypoint.helper_commands.attached_pages_print_manifest)
Write-Host ((\" 13. Strict launch:         {0}\") -f $entrypoint.helper_commands.attached_pages_strict_launch)
Write-Host ((\" 26. Google sidecars:       {0}\") -f $entrypoint.helper_commands.attached_pages_google_sidecar_audit)
"""


class GoogleIssue3WindowsFullUseAttachedHtmlCatalogQuickstartAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "docs").mkdir()
        (self.root / "scripts" / "windows").mkdir(parents=True)
        (self.root / "tmp-browser-smoke" / "attached-pages").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(
        self,
        *,
        doc_text: str = DOC_SNIPPET,
        readme_text: str = README_SNIPPET,
        helper_text: str = HELPER_SNIPPET,
    ) -> None:
        (self.root / "docs" / "ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md").write_text(
            doc_text, encoding="utf-8"
        )
        (self.root / "tmp-browser-smoke" / "attached-pages" / "README.md").write_text(
            readme_text, encoding="utf-8"
        )
        (self.root / "scripts" / "windows" / "show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1").write_text(
            helper_text, encoding="utf-8"
        )

    def assert_failing_path(self, audit: dict[str, object], path: str) -> None:
        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(path, failing_paths)

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_catalog_quickstart_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_sidecar_audit_in_doc(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars\n",
                "",
            )
        )

        self.assert_failing_path(
            helper.build_catalog_quickstart_audit(self.root),
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
        )

    def test_build_audit_reports_missing_readme_order_note(self) -> None:
        self.write_contract_files(readme_text="# Attached Pages\n")

        self.assert_failing_path(
            helper.build_catalog_quickstart_audit(self.root),
            "tmp-browser-smoke/attached-pages/README.md",
        )

    def test_build_audit_reports_missing_helper_recommended_next_key(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                "    recommended_next_key = 'attached_pages_sidecar_audit'\n",
                "",
            )
        )

        self.assert_failing_path(
            helper.build_catalog_quickstart_audit(self.root),
            "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        )

    def test_build_audit_reports_missing_google_sidecar_output(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                "26. Google sidecars:       {0}",
                "",
            )
        )

        self.assert_failing_path(
            helper.build_catalog_quickstart_audit(self.root),
            "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        )


if __name__ == "__main__":
    unittest.main()
