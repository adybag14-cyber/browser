#!/usr/bin/env python3

from __future__ import annotations

import os
from pathlib import Path
import tempfile
import textwrap
import unittest

DOC_RELATIVE_PATH = Path("docs/ISSUE3_LINUX_BUILD_READINESS_REENTRY_BRIDGE.md")
REQUIRED_SNIPPETS = (
    "Issue #3 Linux Build-Readiness Re-entry Bridge",
    "scripts/check_issue3_linux_build_readiness_reentry.py",
    "scripts/check_linux_build_readiness.py",
    "scripts/check_issue3_saved_zig_archive_candidates.py",
    "issue `#11`",
    "combined_next_step",
    "--fallback-zig-archive",
)


def resolve_repo_root() -> Path:
    fixture_root = os.environ.get("LIGHTPANDA_FIXTURE_REPO")
    if fixture_root:
        return Path(fixture_root).resolve()
    return Path(__file__).resolve().parents[2]


def load_bridge_note(repo_root: Path) -> str:
    return (repo_root / DOC_RELATIVE_PATH).read_text(encoding="utf-8")


class LinuxBuildReadinessReentryBridgeNoteTests(unittest.TestCase):
    def test_fixture_note_contains_required_bridge_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            note_path = repo_root / DOC_RELATIVE_PATH
            note_path.parent.mkdir(parents=True, exist_ok=True)
            note_path.write_text(
                textwrap.dedent(
                    """\
                    # Issue #3 Linux Build-Readiness Re-entry Bridge

                    issue `#11`
                    scripts/check_issue3_linux_build_readiness_reentry.py
                    scripts/check_linux_build_readiness.py
                    scripts/check_issue3_saved_zig_archive_candidates.py
                    combined_next_step
                    --fallback-zig-archive
                    """
                ),
                encoding="utf-8",
            )

            note_text = load_bridge_note(repo_root)
            for snippet in REQUIRED_SNIPPETS:
                self.assertIn(snippet, note_text)

    def test_live_note_contains_required_bridge_surface(self) -> None:
        repo_root = resolve_repo_root()
        note_text = load_bridge_note(repo_root)
        for snippet in REQUIRED_SNIPPETS:
            self.assertIn(snippet, note_text)


if __name__ == "__main__":
    unittest.main()
