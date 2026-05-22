from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from headed_stateful_probe_launch_audit import (
    EXPECTED_LAUNCH_SNIPPETS,
    audit_summary,
    collect_headed_launch_gaps,
)


class HeadedStatefulProbeLaunchAuditTests(unittest.TestCase):
    def test_seeded_live_shape_has_no_gaps(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            (repo_root / "build.zig").write_text("", encoding="utf-8")
            for relative_path, snippets in EXPECTED_LAUNCH_SNIPPETS.items():
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("\n".join(snippets), encoding="utf-8")

            summary = audit_summary(repo_root)
            self.assertEqual(summary["expected_file_count"], len(EXPECTED_LAUNCH_SNIPPETS))
            self.assertEqual(summary["gaps"], [])

    def test_missing_marker_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            (repo_root / "build.zig").write_text("", encoding="utf-8")
            for relative_path, snippets in EXPECTED_LAUNCH_SNIPPETS.items():
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("\n".join(snippets), encoding="utf-8")

            broken_path = "tmp-browser-smoke/settings/chrome-settings-home-probe.ps1"
            broken_target = repo_root / broken_path
            broken_target.write_text('"browse"\n"--browser_mode"\n', encoding="utf-8")

            gaps = collect_headed_launch_gaps(repo_root)
            self.assertEqual(
                gaps,
                [
                    {
                        "path": broken_path,
                        "missing_file": False,
                        "missing_snippets": ['"headed"'],
                    }
                ],
            )


if __name__ == "__main__":
    unittest.main()
