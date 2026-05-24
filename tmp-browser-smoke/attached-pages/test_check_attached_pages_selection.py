import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("check_attached_pages_selection.py")
SPEC = importlib.util.spec_from_file_location("check_attached_pages_selection", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"could not load helper module from {MODULE_PATH}")
helper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helper)


class CheckAttachedPagesSelectionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.workspace_root = Path(self.tempdir.name)
        self.repo_root = self.workspace_root / "browser"
        self.repo_root.mkdir()
        (self.repo_root / "build.zig").write_text("// stub build file\n", encoding="utf-8")

    def tearDown(self) -> None:
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

    def test_discovery_finds_workspace_sibling_agent_files(self) -> None:
        fixture = self.write_html(
            self.workspace_root / "agent_files" / "fixture.html",
            "Fixture",
            "fixture",
        )

        discovered = helper.discover_attached_html_candidates(
            self.repo_root, cwd=self.repo_root / "tools"
        )

        self.assertEqual([fixture.resolve()], discovered)

    def test_google_style_selection_prefers_search_fixture(self) -> None:
        agent_files = self.workspace_root / "agent_files"
        self.write_html(
            agent_files / "google-safety.html",
            "Google Safety Centre",
            "google safety marketing content",
        )
        search_path = self.write_html(
            agent_files / "google-search.html",
            "Google Search Home",
            '<form action="/search"><input name="q" aria-label="search the web"></form>',
        )

        selected = helper.select_attached_html_inputs(self.repo_root, google_style=True)

        self.assertEqual([search_path.resolve()], selected)

    def test_duplicate_leaf_names_report_exact_selectors(self) -> None:
        first = self.write_html(
            self.workspace_root / "agent_files" / "one" / "google-home.html",
            "First",
            "first",
        )
        second = self.write_html(
            self.workspace_root / "agent_files" / "two" / "google-home.html",
            "Second",
            "second",
        )
        report = helper.build_report(
            [first.resolve(), second.resolve()],
            repo_root=self.repo_root,
            google_style=False,
            preferred_selector=None,
        )

        self.assertEqual(
            {
                "google-home.html": [
                    "one/google-home.html",
                    "two/google-home.html",
                ]
            },
            report["duplicate_leaf_names"],
        )

    def test_preferred_selector_uses_exact_relative_path_when_leafs_collide(self) -> None:
        first = self.write_html(
            self.workspace_root / "agent_files" / "one" / "google-home.html",
            "First",
            "first",
        )
        second = self.write_html(
            self.workspace_root / "agent_files" / "two" / "google-home.html",
            "Second",
            "second",
        )
        common_root = helper.build_common_root([first.resolve(), second.resolve()])

        resolved = helper.resolve_preferred_page(
            [first.resolve(), second.resolve()],
            "two/google-home.html",
            common_root=common_root,
        )

        self.assertEqual(second.resolve(), resolved)

    def test_preferred_selector_rejects_ambiguous_leaf_name(self) -> None:
        first = self.write_html(
            self.workspace_root / "agent_files" / "one" / "google-home.html",
            "First",
            "first",
        )
        second = self.write_html(
            self.workspace_root / "agent_files" / "two" / "google-home.html",
            "Second",
            "second",
        )
        common_root = helper.build_common_root([first.resolve(), second.resolve()])

        with self.assertRaises(ValueError) as raised:
            helper.resolve_preferred_page(
                [first.resolve(), second.resolve()],
                "google-home.html",
                common_root=common_root,
            )

        self.assertIn("ambiguous", str(raised.exception))
        self.assertIn("one/google-home.html", str(raised.exception))
        self.assertIn("two/google-home.html", str(raised.exception))

    def test_main_returns_nonzero_for_duplicate_leafs_without_override(self) -> None:
        self.write_html(
            self.workspace_root / "agent_files" / "one" / "google-home.html",
            "First",
            "first",
        )
        self.write_html(
            self.workspace_root / "agent_files" / "two" / "google-home.html",
            "Second",
            "second",
        )

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.repo_root)])

        self.assertEqual(1, exit_code)
        self.assertIn("Duplicate leaf-name collisions", stdout.getvalue())

    def test_main_json_reports_resolved_preferred_selector(self) -> None:
        fixture = self.write_html(
            self.workspace_root / "agent_files" / "nested" / "fixture.html",
            "Fixture",
            "fixture",
        )

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--input",
                    str(fixture),
                    "--preferred-initial-page",
                    "nested/fixture.html",
                    "--json",
                ]
            )

        self.assertEqual(0, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("fixture.html", payload["resolved_preferred_selector"])
        self.assertEqual(str(fixture.resolve()), payload["resolved_preferred_path"])


if __name__ == "__main__":
    unittest.main()
