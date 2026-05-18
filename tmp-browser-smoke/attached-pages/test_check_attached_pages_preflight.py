import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("check_attached_pages_preflight.py")
SPEC = importlib.util.spec_from_file_location("check_attached_pages_preflight", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"could not load helper module from {MODULE_PATH}")
helper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helper)


def write_launcher_module(path: Path) -> None:
    path.write_text(
        """import importlib.util
from pathlib import Path


def _load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f\"could not load {path}\")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def select_attached_html_inputs(repo_root, explicit_inputs=None, google_style=False):
    if explicit_inputs:
        return [Path(explicit_inputs[0]).expanduser().resolve()]
    return sorted((repo_root / \"agent_files\").glob(\"*.html\"))


def load_sidecar_module(repo_root):
    return _load_module(
        \"attached_pages_sidecar_audit\",
        repo_root / \"tmp-browser-smoke\" / \"attached-pages\" / \"attached_pages_sidecar_audit.py\",
    )


def load_server_module(repo_root):
    return _load_module(
        \"attached_pages_server\",
        repo_root / \"tmp-browser-smoke\" / \"attached-pages\" / \"attached_pages_server.py\",
    )


def describe_fixture_selection(selected_files, *, repo_root, google_style=False):
    lines = [\"Selected fixtures:\"]
    for path in selected_files:
        display = Path(path).resolve().relative_to(repo_root.resolve()).as_posix()
        suffix = \" (google-style)\" if google_style else \"\"
        lines.append(f\"- {display}{suffix}\")
    return lines
""",
        encoding="utf-8",
    )


def write_sidecar_module(path: Path, missing_count: int) -> None:
    path.write_text(
        f"""def build_sidecar_audit(root=None, selected_files=None):
    return {{
        \"bundle_root\": \"/tmp/bundle\",
        \"fixture_count\": 1,
        \"fixtures_with_missing_sidecars\": {missing_count},
        \"fixtures\": [{{\"display_path\": \"agent_files/fixture.html\"}}],
    }}


def render_text_report(audit):
    return \"Attached Pages Sidecar Audit\\n\\nFixtures with missing sidecars: {{}}\\n\".format(
        audit[\"fixtures_with_missing_sidecars\"]
    )
""",
        encoding="utf-8",
    )


def write_server_module(path: Path, missing_count: int) -> None:
    path.write_text(
        f"""def build_asset_audit(root=None, selected_files=None):
    return {{
        \"fixture_count\": 1,
        \"fixtures_with_missing_assets\": {missing_count},
        \"fixtures\": [{{\"display_path\": \"agent_files/fixture.html\"}}],
    }}


def render_asset_audit_text(audit):
    return \"Attached Pages Asset Audit\\n\\nFixtures with missing assets: {{}}\\n\".format(
        audit[\"fixtures_with_missing_assets\"]
    )
""",
        encoding="utf-8",
    )


class CheckAttachedPagesPreflightTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.repo_root = Path(self.tempdir.name) / "browser"
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        attached_pages_dir.mkdir(parents=True)
        (self.repo_root / "build.zig").write_text("// stub build file\n", encoding="utf-8")
        fixture_dir = self.repo_root / "agent_files"
        fixture_dir.mkdir()
        (fixture_dir / "fixture.html").write_text(
            "<!doctype html><title>Fixture</title><body>fixture</body>",
            encoding="utf-8",
        )
        write_launcher_module(attached_pages_dir / "start_attached_pages_catalog.py")

    def tearDown(self):
        self.tempdir.cleanup()

    def test_json_output_reports_ready_bundle(self):
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        write_sidecar_module(attached_pages_dir / "attached_pages_sidecar_audit.py", missing_count=0)
        write_server_module(attached_pages_dir / "attached_pages_server.py", missing_count=0)

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--google-style",
                    "--json",
                ]
            )

        payload = json.loads(stdout.getvalue())
        self.assertEqual(0, exit_code)
        self.assertTrue(payload["ready_for_replay"])
        self.assertEqual([], payload["blocking_reasons"])
        self.assertEqual(1, payload["selected_fixture_count"])

    def test_text_output_blocks_when_sidecars_and_assets_are_missing(self):
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        write_sidecar_module(attached_pages_dir / "attached_pages_sidecar_audit.py", missing_count=1)
        write_server_module(attached_pages_dir / "attached_pages_server.py", missing_count=1)

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--input",
                    str(self.repo_root / "agent_files" / "fixture.html"),
                ]
            )

        output = stdout.getvalue()
        self.assertEqual(1, exit_code)
        self.assertIn("Selected fixtures:", output)
        self.assertIn("Sidecar audit:", output)
        self.assertIn("Asset audit:", output)
        self.assertIn("Replay readiness: blocked", output)
        self.assertIn("missing sidecar bundles, missing local assets", output)

    def test_allow_flags_permit_nonzero_audits_to_continue(self):
        attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        write_sidecar_module(attached_pages_dir / "attached_pages_sidecar_audit.py", missing_count=1)
        write_server_module(attached_pages_dir / "attached_pages_server.py", missing_count=1)

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--allow-missing-sidecars",
                    "--allow-missing-assets",
                    "--json",
                ]
            )

        payload = json.loads(stdout.getvalue())
        self.assertEqual(0, exit_code)
        self.assertEqual([], payload["blocking_reasons"])
        self.assertTrue(payload["ready_for_replay"])


if __name__ == "__main__":
    unittest.main()
