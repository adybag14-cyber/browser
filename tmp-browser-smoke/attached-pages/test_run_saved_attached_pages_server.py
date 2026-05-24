#!/usr/bin/env python3

from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path

from run_saved_attached_pages_server import discover_html_inputs, find_default_source_dir


class RunSavedAttachedPagesServerTests(unittest.TestCase):
    def test_find_default_source_dir_prefers_env_override(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "sample.html").write_text("<html>ok</html>", encoding="utf-8")
            env_name = "LIGHTPANDA_ATTACHED_PAGES_DIR"
            old = os.environ.get(env_name)
            os.environ[env_name] = str(root)
            try:
                self.assertEqual(find_default_source_dir(), root)
            finally:
                if old is None:
                    del os.environ[env_name]
                else:
                    os.environ[env_name] = old

    def test_discover_html_inputs_sorts_and_filters_exports(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "b page.htm").write_text("<html>b</html>", encoding="utf-8")
            (root / "a page.html").write_text("<html>a</html>", encoding="utf-8")
            (root / "notes.txt").write_text("ignore", encoding="utf-8")

            discovered = discover_html_inputs(root)
            self.assertEqual(
                [path.name for path in discovered],
                ["a page.html", "b page.htm"],
            )


if __name__ == "__main__":
    unittest.main()
