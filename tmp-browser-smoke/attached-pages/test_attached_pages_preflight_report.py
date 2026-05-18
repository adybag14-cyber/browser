import contextlib
import io
import json
import tempfile
import types
import unittest
from pathlib import Path

import attached_pages_preflight_report as report_module


class AttachedPagesPreflightReportTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def write_html(self, relative_path: str, content: str) -> Path:
        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def make_fake_modules(
        self,
        *,
        manifest: list[dict[str, str]] | None = None,
        missing_sidecars: int = 0,
        missing_assets: int = 0,
        external_assets: int = 0,
    ) -> tuple[types.SimpleNamespace, types.SimpleNamespace, types.SimpleNamespace]:
        launcher_module = types.SimpleNamespace(
            find_manifest_entry_for_path=lambda manifest_entries, preferred_path, selected_files=None: manifest_entries[0],
            describe_fixture_selection=lambda selected_files, repo_root, google_style=False: [
                "Selected fixtures:",
                *[f"- {Path(path).name}" for path in selected_files],
            ],
        )
        sidecar_module = types.SimpleNamespace(
            build_sidecar_audit=lambda selected_files=None: {
                "fixtures_with_missing_sidecars": missing_sidecars,
                "fixture_count": len(selected_files or []),
                "fixtures": [],
            }
        )
        server_module = types.SimpleNamespace(
            build_manifest=lambda selected_files=None: manifest
            or [
                {
                    "route": "/pages/1",
                    "alias_route": "/pages/1-google-search",
                    "slug_route": "/named/google-search",
                }
            ],
            build_asset_audit=lambda selected_files=None: {
                "fixtures_with_missing_assets": missing_assets,
                "fixtures_with_external_assets": external_assets,
                "fixture_count": len(selected_files or []),
                "fixtures": [],
            },
        )
        return launcher_module, sidecar_module, server_module

    def test_complete_bundle_reports_ready_for_launch(self):
        fixture = self.write_html("bundle/google-search.html", "<html><title>Google Search</title></html>")
        launcher_module, sidecar_module, server_module = self.make_fake_modules()

        report = report_module.assemble_preflight_report(
            self.root,
            selected_files=[fixture],
            google_style=False,
            launcher_module=launcher_module,
            sidecar_module=sidecar_module,
            server_module=server_module,
        )

        self.assertTrue(report["ready_for_launch"])
        self.assertEqual("print-manifest-or-start-server", report["recommended_next_step"])
        self.assertIsNone(report["preferred_route"])

    def test_google_style_report_surfaces_preferred_route_and_sidecar_blocker(self):
        fixture = self.write_html("bundle/google-search.html", "<html><title>Google Search</title></html>")
        launcher_module, sidecar_module, server_module = self.make_fake_modules(
            missing_sidecars=1,
            missing_assets=0,
        )

        report = report_module.assemble_preflight_report(
            self.root,
            selected_files=[fixture],
            google_style=True,
            launcher_module=launcher_module,
            sidecar_module=sidecar_module,
            server_module=server_module,
        )

        self.assertFalse(report["ready_for_launch"])
        self.assertEqual("restore-missing-sidecar-bundles", report["recommended_next_step"])
        self.assertEqual("/pages/1", report["preferred_route"])
        text_report = report_module.render_text_report(report)
        self.assertIn("Preferred route: /pages/1/", text_report)
        self.assertIn("Ready for launch: no", text_report)

    def test_json_output_and_allow_flags_can_downgrade_failures(self):
        sample_report = {
            "repo_root": str(self.root),
            "google_style": False,
            "input_count": 1,
            "fixture_count": 1,
            "missing_sidecar_fixture_count": 1,
            "missing_asset_fixture_count": 1,
            "fixtures_with_external_assets": 0,
            "ready_for_launch": False,
            "recommended_next_step": "restore-missing-sidecar-bundles",
            "preferred_route": None,
            "preferred_alias_route": None,
            "preferred_named_route": None,
            "selected_fixture_lines": ["Selected fixtures:", "- sample.html"],
            "selected_fixtures": [str(self.root / "sample.html")],
            "sidecar_audit": {"fixtures_with_missing_sidecars": 1},
            "asset_audit": {"fixtures_with_missing_assets": 1},
            "manifest": [{"route": "/pages/1"}],
        }

        self.assertEqual(1, report_module.exit_code_for_report(sample_report))
        self.assertEqual(
            0,
            report_module.exit_code_for_report(
                sample_report,
                allow_missing_sidecars=True,
                allow_missing_assets=True,
            ),
        )

        original_builder = report_module.build_preflight_report
        try:
            report_module.build_preflight_report = lambda repo_root, explicit_inputs=None, google_style=False: sample_report
            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                exit_code = report_module.main(
                    [
                        "--repo-root",
                        str(self.root),
                        "--json",
                        "--allow-missing-sidecars",
                        "--allow-missing-assets",
                    ]
                )
        finally:
            report_module.build_preflight_report = original_builder

        self.assertEqual(0, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual(1, payload["missing_sidecar_fixture_count"])
        self.assertEqual(1, payload["missing_asset_fixture_count"])


if __name__ == "__main__":
    unittest.main()