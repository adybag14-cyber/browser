from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md": """
    # Issue #3 Saved Memory Inputs Route

    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - issue `#11`
    - `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
    - `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
    """,
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    # Issue #3 Progress Tracker Route

    - issue `#11`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    """,
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh": """
    Read first
    docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    Working rules
    issue #11 progress-update handoff
    """,
    "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh": """
    docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
    issue `#11`
    issue #11 progress-update handoff
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue11-saved-memory-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11SavedMemoryInputsProgressTrackerSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.saved_memory_doc = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md"
        )
        cls.progress_tracker_doc = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_memory_inputs_route.sh"
        )
        cls.route_surface = read_text(
            cls.repo_root / "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh"
        )

    def test_saved_memory_route_keeps_progress_tracker_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "issue `#11`",
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
        ):
            self.assertIn(fragment, self.saved_memory_doc)

    def test_progress_tracker_doc_stays_issue11_focused(self) -> None:
        self.assertIn("issue `#11`", self.progress_tracker_doc)
        self.assertIn("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", self.progress_tracker_doc)

    def test_route_printer_mentions_progress_tracker_handoff(self) -> None:
        self.assertIn("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", self.route_printer)
        self.assertIn("issue #11 progress-update handoff", self.route_printer)

    def test_route_surface_guards_tracker_visibility(self) -> None:
        self.assertIn("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", self.route_surface)
        self.assertIn("issue #11 progress-update handoff", self.route_surface)


if __name__ == "__main__":
    unittest.main()
