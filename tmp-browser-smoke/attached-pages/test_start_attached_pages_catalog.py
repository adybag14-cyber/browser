import contextlib
import importlib.util
import io
import os
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("start_attached_pages_catalog.py")
SPEC = importlib.util.spec_from_file_location("start_attached_pages_catalog", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"could not load helper module from {MODULE_PATH}")
helper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helper)


class StartAttachedPagesCatalogTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.workspace_root = Path(self.tempdir.name)
        self.repo_root = self.workspace_root / "browser"
        self.repo_root.mkdir()
        (self.repo_root / "build.zig").write_text("// stub build file\n", encoding="utf-8")

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

    def test_resolve_repo_root_climbs_to_build_zig(self):
        nested = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        nested.mkdir(parents=True)
        self.assertEqual(self.repo_root, helper.resolve_repo_root(nested))

    def test_discovery_finds_workspace_sibling_agent_files(self):
        sibling_agent_files = self.workspace_root / "agent_files"
        expected = self.write_html(sibling_agent_files / "sample.html", "Sample Fixture", "sample")

        discovered = helper.discover_attached_html_candidates(
            self.repo_root, cwd=self.repo_root / "tools"
        )

        self.assertEqual([expected.resolve()], discovered)

    def test_google_style_selection_prefers_search_fixture(self):
        agent_files = self.workspace_root / "agent_files"
        self.write_html(
            agent_files / "google-safety.html",
            "Google Safety Centre",
            "google safety marketing content",
        )
        search_path = agent_files / "google-search.html"
        search_path.parent.mkdir(parents=True, exist_ok=True)
        search_path.write_text(
            """<!doctype html>
<html>
  <head>
    <title>Google Search Home</title>
  </head>
  <body>
    <form action="/search">
      <input name="q" aria-label="search the web">
    </form>
  </body>
</html>
""",
            encoding="utf-8",
        )

        selected = helper.select_attached_html_inputs(
            self.repo_root,
            google_style=True,
            cwd=self.repo_root / "scripts",
        )

        self.assertEqual([search_path.resolve()], selected)

    def test_explicit_input_paths_accept_directories_and_files(self):
        fixture_dir = self.workspace_root / "bundle"
        first = self.write_html(fixture_dir / "first.html", "First", "first")
        second = self.write_html(fixture_dir / "nested" / "second.htm", "Second", "second")

        selected = helper.select_attached_html_inputs(
            self.repo_root,
            explicit_inputs=[str(fixture_dir), str(first)],
        )

        self.assertEqual([first.resolve(), second.resolve()], selected)

    def test_load_server_module_reads_repo_copy(self):
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        attached_pages_dir.mkdir(parents=True)
        (attached_pages_dir / "attached_pages_server.py").write_text(
            "VALUE = 7\n",
            encoding="utf-8",
        )

        module = helper.load_server_module(self.repo_root)

        self.assertEqual(7, module.VALUE)

    def test_load_sidecar_module_reads_repo_copy(self):
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        attached_pages_dir.mkdir(parents=True)
        (attached_pages_dir / "attached_pages_sidecar_audit.py").write_text(
            "VALUE = 11\n",
            encoding="utf-8",
        )

        module = helper.load_sidecar_module(self.repo_root)

        self.assertEqual(11, module.VALUE)

    def test_find_manifest_entry_for_path_matches_leaf_name(self):
        manifest = [
            {
                "file": "nested/google-home.html",
                "route": "/pages/1",
                "alias_route": "/pages/1-google-home",
                "slug_route": "/named/google-home",
            }
        ]

        entry = helper.find_manifest_entry_for_path(
            manifest,
            Path("/tmp/bundle/google-home.html"),
        )

        self.assertIsNotNone(entry)
        self.assertEqual("/pages/1", entry["route"])

    def test_main_print_manifest_uses_repo_server_module(self):
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        attached_pages_dir.mkdir(parents=True)
        fixture = self.write_html(self.workspace_root / "agent_files" / "fixture.html", "Fixture", "fixture")
        (attached_pages_dir / "attached_pages_server.py").write_text(
            """import json
from pathlib import Path

def build_manifest(root=None, selected_files=None):
    return [{"file": Path(selected_files[0]).name, "route": "/pages/1"}]

def build_asset_audit(root=None, selected_files=None):
    return {"fixtures_with_missing_assets": 0}

def render_asset_audit_text(audit):
    return "audit\\n"

def create_server(root=None, bind="127.0.0.1", port=8235, selected_files=None):
    raise AssertionError("server launch should not happen during --print-manifest")
""",
            encoding="utf-8",
        )

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--input",
                    str(fixture),
                    "--print-manifest",
                ]
            )

        self.assertEqual(0, exit_code)
        self.assertIn('"route": "/pages/1"', stdout.getvalue())

    def test_main_print_manifest_can_require_complete_sidecars(self):
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        attached_pages_dir.mkdir(parents=True)
        fixture = self.write_html(self.workspace_root / "agent_files" / "fixture.html", "Fixture", "fixture")
        (attached_pages_dir / "attached_pages_sidecar_audit.py").write_text(
            """def build_sidecar_audit(root=None, selected_files=None):
    return {
        "fixture_count": 1,
        "fixtures_with_missing_sidecars": 1,
        "fixtures": [],
    }

def render_text_report(audit):
    return "Attached Pages Sidecar Audit\\n\\nFixtures with missing sidecars: 1\\n"
""",
            encoding="utf-8",
        )

        stdout = io.StringIO()
        stderr = io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--input",
                    str(fixture),
                    "--print-manifest",
                    "--require-complete-sidecars",
                ]
            )

        self.assertEqual(1, exit_code)
        self.assertEqual("", stdout.getvalue())
        self.assertIn("Attached Pages Sidecar Audit", stderr.getvalue())
        self.assertIn("Refusing to continue", stderr.getvalue())

    def test_main_audit_sidecars_json_uses_repo_sidecar_module(self):
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        attached_pages_dir.mkdir(parents=True)
        fixture = self.write_html(self.workspace_root / "agent_files" / "fixture.html", "Fixture", "fixture")
        (attached_pages_dir / "attached_pages_sidecar_audit.py").write_text(
            """from pathlib import Path

def build_sidecar_audit(root=None, selected_files=None):
    return {
        "fixture_count": 1,
        "fixtures_with_missing_sidecars": 0,
        "fixtures": [{"path": str(Path(selected_files[0]))}],
    }

def render_text_report(audit):
    return "sidecars\\n"
""",
            encoding="utf-8",
        )

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--input",
                    str(fixture),
                    "--audit-sidecars",
                    "--audit-sidecars-json",
                ]
            )

        self.assertEqual(0, exit_code)
        self.assertIn('"fixtures_with_missing_sidecars": 0', stdout.getvalue())

    def test_main_audit_sidecars_missing_returns_nonzero_unless_allowed(self):
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        attached_pages_dir.mkdir(parents=True)
        fixture = self.write_html(self.workspace_root / "agent_files" / "fixture.html", "Fixture", "fixture")
        (attached_pages_dir / "attached_pages_sidecar_audit.py").write_text(
            """def build_sidecar_audit(root=None, selected_files=None):
    return {
        "fixture_count": 1,
        "fixtures_with_missing_sidecars": 1,
        "fixtures": [],
    }

def render_text_report(audit):
    return "sidecars\\n"
""",
            encoding="utf-8",
        )

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--input",
                    str(fixture),
                    "--audit-sidecars",
                ]
            )
        self.assertEqual(1, exit_code)

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--input",
                    str(fixture),
                    "--audit-sidecars",
                    "--allow-missing-sidecars",
                ]
            )
        self.assertEqual(0, exit_code)

    def test_main_server_mode_can_require_complete_sidecars(self):
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        attached_pages_dir.mkdir(parents=True)
        fixture = self.write_html(self.workspace_root / "agent_files" / "fixture.html", "Fixture", "fixture")
        (attached_pages_dir / "attached_pages_sidecar_audit.py").write_text(
            """def build_sidecar_audit(root=None, selected_files=None):
    return {
        "fixture_count": 1,
        "fixtures_with_missing_sidecars": 1,
        "fixtures": [],
    }

def render_text_report(audit):
    return "Attached Pages Sidecar Audit\\n\\nFixtures with missing sidecars: 1\\n"
""",
            encoding="utf-8",
        )

        stdout = io.StringIO()
        stderr = io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--input",
                    str(fixture),
                    "--require-complete-sidecars",
                ]
            )

        self.assertEqual(1, exit_code)
        self.assertEqual("", stdout.getvalue())
        self.assertIn("Attached Pages Sidecar Audit", stderr.getvalue())
        self.assertIn("Refusing to continue", stderr.getvalue())

    def test_main_server_mode_prints_preferred_routes_and_strict_gate(self):
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        attached_pages_dir.mkdir(parents=True)
        fixture = self.write_html(
            self.workspace_root / "agent_files" / "google-search.html",
            "Google Search Home",
            '<form action="/search"><input name="q" aria-label="search the web"></form>',
        )
        (attached_pages_dir / "attached_pages_sidecar_audit.py").write_text(
            """def build_sidecar_audit(root=None, selected_files=None):
    return {
        "fixture_count": 1,
        "fixtures_with_missing_sidecars": 0,
        "fixtures": [],
    }

def render_text_report(audit):
    return "Attached Pages Sidecar Audit\\n"
""",
            encoding="utf-8",
        )
        (attached_pages_dir / "attached_pages_server.py").write_text(
            """from pathlib import Path

def build_manifest(root=None, selected_files=None):
    return [{
        "file": Path(selected_files[0]).name,
        "route": "/pages/1",
        "alias_route": "/pages/1-google-search-home",
        "slug_route": "/named/google-search-home",
    }]

def build_asset_audit(root=None, selected_files=None):
    return {
        "fixtures_with_missing_assets": 0,
    }

def render_asset_audit_text(audit):
    return "audit\\n"

class FakeServer:
    server_address = ("127.0.0.1", 8235)

    def serve_forever(self):
        raise KeyboardInterrupt()

    def server_close(self):
        return None

def create_server(root=None, bind="127.0.0.1", port=8235, selected_files=None):
    return FakeServer(), build_manifest(root=root, selected_files=selected_files)
""",
            encoding="utf-8",
        )

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--input",
                    str(fixture),
                    "--google-style",
                    "--require-complete-sidecars",
                ]
            )

        output = stdout.getvalue()
        self.assertEqual(0, exit_code)
        self.assertIn("Strict sidecar gate: enabled", output)
        self.assertIn("Preferred Google-style page:", output)
        self.assertIn("Preferred route: http://127.0.0.1:8235/pages/1/", output)
        self.assertIn(
            "Preferred alias route: http://127.0.0.1:8235/pages/1-google-search-home/",
            output,
        )
        self.assertIn(
            "Preferred named route: http://127.0.0.1:8235/named/google-search-home/",
            output,
        )

    def test_repo_override_takes_precedence_over_environment(self):
        other_repo = self.workspace_root / "other-browser"
        other_repo.mkdir()
        (other_repo / "build.zig").write_text("// other\n", encoding="utf-8")

        original = os.environ.get("LIGHTPANDA_REPO_ROOT")
        os.environ["LIGHTPANDA_REPO_ROOT"] = str(other_repo)
        try:
            resolved = helper.resolve_repo_root(self.repo_root / "tmp-browser-smoke")
        finally:
            if original is None:
                os.environ.pop("LIGHTPANDA_REPO_ROOT", None)
            else:
                os.environ["LIGHTPANDA_REPO_ROOT"] = original

        self.assertEqual(other_repo.resolve(), resolved)


if __name__ == "__main__":
    unittest.main()
