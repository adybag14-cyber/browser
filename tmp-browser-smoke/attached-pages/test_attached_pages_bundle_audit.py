import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path


def load_helper(helper_path: Path):
    helper_dir = str(helper_path.parent)
    added_to_path = False
    if helper_dir not in sys.path:
        sys.path.insert(0, helper_dir)
        added_to_path = True
    sys.modules.pop("attached_pages_server", None)
    sys.modules.pop("attached_pages_sidecar_audit", None)
    sys.modules.pop("attached_pages_bundle_audit", None)
    spec = importlib.util.spec_from_file_location("attached_pages_bundle_audit", helper_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load helper from {helper_path}")
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
        return module
    finally:
        if added_to_path:
            sys.path.pop(0)


class AttachedPagesBundleAuditTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.helper_dir = self.root / "attached-pages"
        self.helper_dir.mkdir()
        self.helper_path = self.helper_dir / "attached_pages_bundle_audit.py"
        self.helper_path.write_text(
            Path(
                "/workspace/work/browser-fork-headed-mode-foundation/tmp-browser-smoke/attached-pages/attached_pages_bundle_audit.py"
            ).read_text(encoding="utf-8"),
            encoding="utf-8",
        )

    def tearDown(self):
        self.tempdir.cleanup()

    def write_stub_modules(self, *, sidecar_missing: int, asset_missing: int, asset_external: int = 0):
        (self.helper_dir / "attached_pages_sidecar_audit.py").write_text(
            f"""def build_sidecar_audit(root=None, selected_files=None):
    return {{
        "bundle_root": str(root if root is not None else selected_files[0]),
        "fixture_count": 1,
        "fixtures_with_missing_sidecars": {sidecar_missing},
        "fixtures": [{{"display_path": "fixture.html"}}],
    }}

def render_text_report(audit):
    return "Attached Pages Sidecar Audit\\n\\nFixtures with missing sidecars: {{0}}\\n".format(
        audit["fixtures_with_missing_sidecars"]
    )
""",
            encoding="utf-8",
        )
        (self.helper_dir / "attached_pages_server.py").write_text(
            f"""def build_asset_audit(root=None, selected_files=None):
    return {{
        "bundle_root": str(root if root is not None else selected_files[0]),
        "fixture_count": 1,
        "fixtures_with_missing_assets": {asset_missing},
        "fixtures_with_external_assets": {asset_external},
        "fixtures": [{{"display_path": "fixture.html"}}],
    }}

def render_asset_audit_text(audit):
    return (
        "Attached Pages Asset Audit\\n\\n"
        "Fixtures with missing assets: {{0}}\\n"
        "Fixtures with external assets: {{1}}\\n"
    ).format(
        audit["fixtures_with_missing_assets"],
        audit["fixtures_with_external_assets"],
    )
""",
            encoding="utf-8",
        )

    def run_main(self, argv: list[str]) -> tuple[int, str]:
        helper = load_helper(self.helper_path)
        original_argv = sys.argv[:]
        stdout = io.StringIO()
        try:
            sys.argv = [str(self.helper_path), *argv]
            with contextlib.redirect_stdout(stdout):
                exit_code = helper.main()
        finally:
            sys.argv = original_argv
        return exit_code, stdout.getvalue()

    def test_text_report_combines_sidecar_and_asset_sections(self):
        self.write_stub_modules(sidecar_missing=1, asset_missing=0, asset_external=2)

        exit_code, output = self.run_main(["--root", str(self.root / "bundle")])

        self.assertEqual(1, exit_code)
        self.assertIn("Attached Pages Bundle Audit", output)
        self.assertIn("Attached Pages Sidecar Audit", output)
        self.assertIn("Fixtures with missing sidecars: 1", output)
        self.assertIn("Attached Pages Asset Audit", output)
        self.assertIn("Fixtures with external assets: 2", output)

    def test_json_output_wraps_sidecar_and_asset_payloads(self):
        self.write_stub_modules(sidecar_missing=0, asset_missing=1)

        exit_code, output = self.run_main(["--root", str(self.root / "bundle"), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(output)
        self.assertEqual(0, payload["sidecars"]["fixtures_with_missing_sidecars"])
        self.assertEqual(1, payload["assets"]["fixtures_with_missing_assets"])

    def test_allow_flags_independently_control_exit_code(self):
        self.write_stub_modules(sidecar_missing=1, asset_missing=1)

        exit_code, _ = self.run_main(["--root", str(self.root / "bundle")])
        self.assertEqual(1, exit_code)

        exit_code, _ = self.run_main(
            [
                "--root",
                str(self.root / "bundle"),
                "--allow-missing-sidecars",
            ]
        )
        self.assertEqual(1, exit_code)

        exit_code, _ = self.run_main(
            [
                "--root",
                str(self.root / "bundle"),
                "--allow-missing-assets",
            ]
        )
        self.assertEqual(1, exit_code)

        exit_code, _ = self.run_main(
            [
                "--root",
                str(self.root / "bundle"),
                "--allow-missing-sidecars",
                "--allow-missing-assets",
            ]
        )
        self.assertEqual(0, exit_code)

    def test_input_mode_passes_selected_files_to_stub_modules(self):
        self.write_stub_modules(sidecar_missing=0, asset_missing=0)
        fixture = self.root / "fixture.html"
        fixture.write_text("<!doctype html><body>fixture</body>", encoding="utf-8")

        exit_code, output = self.run_main(["--input", str(fixture), "--json"])

        self.assertEqual(0, exit_code)
        payload = json.loads(output)
        self.assertEqual(str(fixture), payload["sidecars"]["bundle_root"])
        self.assertEqual(str(fixture), payload["assets"]["bundle_root"])


if __name__ == "__main__":
    unittest.main()
