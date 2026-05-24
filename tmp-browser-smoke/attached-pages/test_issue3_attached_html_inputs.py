from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/check_issue3_attached_html_inputs.py": """
    DEFAULT_MIN_COUNT = 3
    parser.add_argument("--agent-files-root")
    parser.add_argument("--page", action="append")
    parser.add_argument("--require-name-substring", action="append")
    parser.add_argument("--min-count", type=int, default=DEFAULT_MIN_COUNT)
    def resolve_default_agent_files_root(repo_root):
        return (repo_root.parent / "agent_files").resolve()
    def discover_pages(agent_files_root):
        return sorted(path.resolve() for path in agent_files_root.iterdir() if path.is_file() and path.suffix.lower() == ".html")
    "page_mode": "explicit" if page_args else "auto-discovery",
    "profile": "issue3-attached-html-inputs"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-attached-html-inputs-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3AttachedHtmlInputsSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.helper = read_text(cls.repo_root / "scripts/check_issue3_attached_html_inputs.py")

    def test_helper_keeps_agent_files_defaults_and_page_selection_surface_visible(self) -> None:
        for fragment in (
            "DEFAULT_MIN_COUNT = 3",
            'HTML_SUFFIX = ".html"',
            "--agent-files-root",
            "--page",
            "--require-name-substring",
            "--min-count",
            'return (repo_root.parent / "agent_files").resolve()',
            "path.suffix.lower() == HTML_SUFFIX",
            '"page_mode": "explicit" if page_args else "auto-discovery"',
            '"profile": "issue3-attached-html-inputs"',
        ):
            self.assertIn(fragment, self.helper)


if __name__ == "__main__":
    unittest.main()
