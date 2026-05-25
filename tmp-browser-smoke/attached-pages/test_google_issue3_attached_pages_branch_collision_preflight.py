import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import google_issue3_attached_pages_branch_collision_preflight as helper


class GoogleIssue3AttachedPagesBranchCollisionPreflightTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "build.zig").write_text("// build root marker\n", encoding="utf-8")

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def test_normalize_candidate_paths_deduplicates_and_normalizes(self) -> None:
        normalized = helper.normalize_candidate_paths(
            [
                "./scripts/windows/helper.ps1",
                "scripts\\windows\\helper.ps1",
                " ",
                "docs/example.md",
            ]
        )

        self.assertEqual(
            [
                "scripts/windows/helper.ps1",
                "docs/example.md",
            ],
            normalized,
        )

    def test_inspect_candidate_paths_reports_known_surface_collision(self) -> None:
        path = "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1"
        target = self.root / path
        target.parent.mkdir(parents=True)
        target.write_text("# present\n", encoding="utf-8")

        with mock.patch.object(
            helper,
            "load_known_surfaces",
            return_value=(
                {
                    "group": "launcher-companion",
                    "kind": "file",
                    "path": path,
                    "purpose": "Launcher companion helper.",
                },
            ),
        ):
            result = helper.inspect_candidate_paths(self.root, [path, "docs/missing.md"])

        self.assertEqual(2, result["candidate_count"])
        self.assertEqual(1, result["collision_count"])
        collision = result["collisions"][0]
        self.assertEqual(path, collision["path"])
        self.assertTrue(collision["exists"])
        self.assertTrue(collision["is_known_surface"])
        self.assertEqual("launcher-companion", collision["group"])
        self.assertIn("launcher companion", collision["purpose"].lower())

    def test_inspect_candidate_paths_reports_unknown_existing_path(self) -> None:
        path = "tmp-browser-smoke/attached-pages/custom-note.md"
        target = self.root / path
        target.parent.mkdir(parents=True)
        target.write_text("present\n", encoding="utf-8")

        result = helper.inspect_candidate_paths(self.root, [path])

        self.assertEqual(1, result["collision_count"])
        collision = result["collisions"][0]
        self.assertEqual(path, collision["path"])
        self.assertFalse(collision["is_known_surface"])
        self.assertIsNone(collision["group"])
        self.assertIsNone(collision["purpose"])

    def test_render_text_report_warns_when_collisions_exist(self) -> None:
        report = helper.render_text_report(
            {
                "repo_root": str(self.root),
                "candidate_count": 1,
                "collision_count": 1,
                "collisions": [
                    {
                        "path": "docs/example.md",
                        "kind": "file",
                        "group": "proof-route",
                        "purpose": "Pinned proof-route note.",
                    }
                ],
            }
        )

        self.assertIn("Collisions: 1", report)
        self.assertIn("Known surface group: proof-route", report)
        self.assertIn("Use an existing-file diff", report)

    def test_main_returns_zero_when_no_collisions(self) -> None:
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.root),
                    "--path",
                    "tmp-browser-smoke/attached-pages/new-helper.py",
                ]
            )

        self.assertEqual(0, exit_code)
        self.assertIn("Collisions: 0", output.getvalue())

    def test_main_returns_one_when_collision_exists(self) -> None:
        path = "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md"
        target = self.root / path
        target.parent.mkdir(parents=True)
        target.write_text("present\n", encoding="utf-8")

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.root),
                    "--path",
                    path,
                    "--json",
                ]
            )

        self.assertEqual(1, exit_code)
        self.assertIn('"collision_count": 1', output.getvalue())


if __name__ == "__main__":
    unittest.main()
