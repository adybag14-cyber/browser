import importlib.util
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("start_attached_pages_catalog.py")
SPEC = importlib.util.spec_from_file_location("start_attached_pages_catalog", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"could not load helper module from {MODULE_PATH}")
helper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helper)


class NestedCheckoutDiscoveryTests(unittest.TestCase):
    def test_discovery_finds_workspace_agent_files_from_nested_checkout(self):
        with tempfile.TemporaryDirectory() as tempdir:
            workspace_root = Path(tempdir)
            nested_repo_root = workspace_root / "work" / "browser"
            nested_repo_root.mkdir(parents=True)
            (nested_repo_root / "build.zig").write_text("// stub build file\n", encoding="utf-8")

            expected = workspace_root / "agent_files" / "workspace-fixture.html"
            expected.parent.mkdir(parents=True)
            expected.write_text(
                """<!doctype html>
<html>
  <head>
    <title>Workspace Fixture</title>
  </head>
  <body>fixture</body>
</html>
""",
                encoding="utf-8",
            )

            discovered = helper.discover_attached_html_candidates(
                nested_repo_root,
                cwd=nested_repo_root / "tmp-browser-smoke",
            )

            self.assertEqual([expected.resolve()], discovered)


if __name__ == "__main__":
    unittest.main()
