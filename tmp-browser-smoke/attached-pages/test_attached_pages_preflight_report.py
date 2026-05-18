import contextlib
import importlib.util
import io
import json
import tempfile
import textwrap
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("attached_pages_preflight_report.py")
SPEC = importlib.util.spec_from_file_location("attached_pages_preflight_report", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"could not load helper module from {MODULE_PATH}")
helper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helper)


class AttachedPagesPreflightReportTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.workspace_root = Path(self.tempdir.name)
        self.repo_root = self.workspace_root / "browser"
        self.repo_root.mkdir()
        (self.repo_root / "build.zig").write_text("// stub build file\n", encoding="utf-8")
        self.attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        self.attached_pages_dir.mkdir(parents=True)
        self.fixture = self.write_html(
            self.workspace_root / "agent_files" / "google-search.html",
            "Google Search Home",
            '<form action="/search"><input name="q" aria-label="search the web"></form>',
        )

    def tearDown(self):
        self.tempdir.cleanup()

    def write_html(self, path: Path, title: str, body: str) -> Path:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            f"""<!doctype html>
<html>
  <head>
    <title>{title}</title>
  </head>
  <body>{body}</body>
</html>
""",
            encoding="utf-8",
        )
        return path

    def write_launcher_stub(self):
        (self.attached_pages_dir / "start_attached_pages_catalog.py").write_text(
            textwrap.dedent(
                """
                import importlib.util
                from pathlib import Path

                def select_attached_html_inputs(repo_root, *, explicit_inputs=None, google_style=False):
                    if explicit_inputs:
                        return [Path(path).expanduser().resolve() for path in explicit_inputs]
                    return [repo_root.parent / "agent_files" / "google-search.html"]

                def load_sidecar_module(repo_root):
                    path = repo_root / "tmp-browser-smoke" / "attached-pages" / "attached_pages_sidecar_audit.py"
                    spec = importlib.util.spec_from_file_location("attached_pages_sidecar_audit", path)
                    module = importlib.util.module_from_spec(spec)
                    spec.loader.exec_module(module)
                    return module

                def load_server_module(repo_root):
                    path = repo_root / "tmp-browser-smoke" / "attached-pages" / "attached_pages_server.py"
                    spec = importlib.util.spec_from_file_location("attached_pages_server", path)
                    module = importlib.util.module_from_spec(spec)
                    spec.loader.exec_module(module)
                    return module

                def find_manifest_entry_for_path(manifest, preferred_path, *, selected_files=None):
                    preferred_name = Path(preferred_path).name
                    for entry in manifest:
                        if entry.get("file") == preferred_name:
                            return entry
                    return manifest[0] if manifest else None

                def describe_fixture_selection(selected_files, *, repo_root, google_style=False):
                    mode = "google-style" if google_style else "plain"
                    return [
                        "Selected fixtures:",
                        f"- {Path(selected_files[0]).name} ({mode})",
                    ]
                """
            ).strip()
            + "\n",
            encoding="utf-8",
        )

    def write_sidecar_stub(self, missing_sidecars: int):
        (self.attached_pages_dir / "attached_pages_sidecar_audit.py").write_text(
            textwrap.dedent(
                f"""
                def build_sidecar_audit(root=None, selected_files=None):
                    return {{
                        "bundle_root": "/bundle",
                        "fixture_count": len(selected_files or []),
                        "fixtures_with_missing_sidecars": {missing_sidecars},
                        "fixtures": [],
                    }}
                """
            ).strip()
            + "\n",
            encoding="utf-8",
        )

    def write_server_stub(self, missing_assets: int, external_assets: int = 0):
        (self.attached_pages_dir / "attached_pages_server.py").write_text(
            textwrap.dedent(
                f"""
                from pathlib import Path

                def build_manifest(root=None, selected_files=None):
                    return [{{
                        "file": Path(selected_files[0]).name,
                        "title": "Google Search Home",
                        "route": "/pages/1",
                        "alias_route": "/pages/1-google-search-home",
                        "slug_route": "/named/google-search-home",
                    }}]

                def build_asset_audit(root=None, selected_files=None):
                    return {{
                        "bundle_root": "/bundle",
                        "fixture_count": len(selected_files or []),
                        "fixtures_with_missing_assets": {missing_assets},
                        "fixtures_with_external_assets": {external_assets},
                        "fixtures": [],
                    }}
                """
            ).strip()
            + "\n",
            encoding="utf-8",
        )

    def build_report(self, *, missing_sidecars: int, missing_assets: int, external_assets: int = 0, google_style: bool = False):
        self.write_launcher_stub()
        self.write_sidecar_stub(missing_sidecars)
        self.write_server_stub(missing_assets, external_assets=external_assets)
        return helper.build_preflight_report(
            self.repo_root,
            explicit_inputs=[str(self.fixture)],
            google_style=google_style,
        )

    def test_sidecar_gap_takes_priority_in_recommended_next_step(self):
        report = self.build_report(missing_sidecars=1, missing_assets=2, external_assets=3, google_style=True)

        self.assertFalse(report["ready_for_launch"])
        self.assertEqual("restore-missing-sidecar-bundles", report["recommended_next_step"])
        self.assertEqual(1, report["missing_sidecar_fixture_count"])
        self.assertEqual(2, report["missing_asset_fixture_count"])
        self.assertEqual(3, report["fixtures_with_external_assets"])
        self.assertEqual("/pages/1", report["preferred_route"])
        self.assertEqual("/named/google-search-home", report["preferred_named_route"])

    def test_asset_gap_becomes_recommended_next_step_after_sidecars_are_complete(self):
        report = self.build_report(missing_sidecars=0, missing_assets=1)

        self.assertFalse(report["ready_for_launch"])
        self.assertEqual("restore-missing-local-assets", report["recommended_next_step"])
        self.assertEqual(0, report["missing_sidecar_fixture_count"])
        self.assertEqual(1, report["missing_asset_fixture_count"])

    def test_ready_bundle_reports_launch_readiness_and_renders_preferred_routes(self):
        report = self.build_report(missing_sidecars=0, missing_assets=0, google_style=True)
        text_report = helper.render_text_report(report)

        self.assertTrue(report["ready_for_launch"])
        self.assertEqual("print-manifest-or-start-server", report["recommended_next_step"])
        self.assertIn("Ready for launch: yes", text_report)
        self.assertIn("Preferred route: /pages/1/", text_report)
        self.assertIn("Preferred alias route: /pages/1-google-search-home/", text_report)
        self.assertIn("Preferred named route: /named/google-search-home/", text_report)
        self.assertIn("Selected fixtures:", text_report)
        self.assertIn("google-search.html (google-style)", text_report)

    def test_exit_code_obeys_allow_missing_flags(self):
        report = self.build_report(missing_sidecars=1, missing_assets=1)

        self.assertEqual(1, helper.exit_code_for_report(report))
        self.assertEqual(1, helper.exit_code_for_report(report, allow_missing_sidecars=True))
        self.assertEqual(1, helper.exit_code_for_report(report, allow_missing_assets=True))
        self.assertEqual(
            0,
            helper.exit_code_for_report(
                report,
                allow_missing_sidecars=True,
                allow_missing_assets=True,
            ),
        )

    def test_main_can_emit_json_and_return_success_when_missing_items_are_allowed(self):
        self.write_launcher_stub()
        self.write_sidecar_stub(1)
        self.write_server_stub(1, external_assets=2)

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--input",
                    str(self.fixture),
                    "--json",
                    "--allow-missing-sidecars",
                    "--allow-missing-assets",
                ]
            )

        self.assertEqual(0, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("restore-missing-sidecar-bundles", payload["recommended_next_step"])
        self.assertEqual(2, payload["fixtures_with_external_assets"])
        self.assertEqual([str(self.fixture)], payload["selected_fixtures"])


if __name__ == "__main__":
    unittest.main()
