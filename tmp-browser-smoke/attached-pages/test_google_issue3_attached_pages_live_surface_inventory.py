import contextlib
import io
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import google_issue3_attached_pages_live_surface_inventory as helper


class GoogleIssue3AttachedPagesLiveSurfaceInventoryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "build.zig").write_text("// build root marker\n", encoding="utf-8")

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def test_resolve_repo_root_uses_explicit_checkout(self) -> None:
        resolved = helper.resolve_repo_root(self.root / "tmp-browser-smoke", str(self.root))

        self.assertEqual(self.root.resolve(), resolved)

    def test_resolve_repo_root_prefers_environment_override(self) -> None:
        nested = self.root / "tmp-browser-smoke" / "attached-pages"
        nested.mkdir(parents=True)
        with mock.patch.dict(os.environ, {"LIGHTPANDA_REPO_ROOT": str(self.root)}):
            resolved = helper.resolve_repo_root(nested, None)

        self.assertEqual(self.root.resolve(), resolved)

    def test_resolve_repo_root_rejects_non_checkout_path(self) -> None:
        missing_root = self.root / "not-a-checkout"
        missing_root.mkdir()

        with self.assertRaises(FileNotFoundError) as ctx:
            helper.resolve_repo_root(self.root, str(missing_root))

        self.assertIn("does not look like a Lightpanda checkout", str(ctx.exception))

    def test_build_inventory_honors_group_filter(self) -> None:
        launcher_helper = (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_attached_pages_launcher_companion.ps1"
        )
        launcher_helper.parent.mkdir(parents=True)
        launcher_helper.write_text("# present\n", encoding="utf-8")

        inventory = helper.build_inventory(self.root, {"launcher-companion"})

        self.assertTrue(inventory)
        self.assertTrue(all(row["group"] == "launcher-companion" for row in inventory))
        self.assertIn(
            "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
            [row["path"] for row in inventory],
        )
        present_rows = [row for row in inventory if row["exists"]]
        self.assertEqual(
            ["scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1"],
            [row["path"] for row in present_rows],
        )

    def test_render_text_report_prints_missing_only_guidance(self) -> None:
        inventory = [
            {
                "group": "launcher-companion",
                "kind": "file",
                "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
                "purpose": "Launcher companion helper.",
                "exists": False,
            }
        ]

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.render_text_report(self.root, inventory, missing_only=True)

        report = output.getvalue()
        self.assertEqual(0, exit_code)
        self.assertIn("Missing: 1/1", report)
        self.assertIn("[MISS] scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1", report)
        self.assertIn("Use the missing paths above as the honest create-only candidates.", report)

    def test_render_text_report_prints_clean_lane_warning(self) -> None:
        inventory = [
            {
                "group": "proof-route",
                "kind": "file",
                "path": "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
                "purpose": "Pinned proof-route note.",
                "exists": True,
            }
        ]

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.render_text_report(self.root, inventory, missing_only=False)

        report = output.getvalue()
        self.assertEqual(0, exit_code)
        self.assertIn("Present: 1/1", report)
        self.assertIn("[PASS] docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md", report)
        self.assertIn("Prefer an existing-file diff or a different lane", report)

    def test_render_text_report_returns_one_when_missing_only_hides_all_rows(self) -> None:
        inventory = [
            {
                "group": "replay-route",
                "kind": "file",
                "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
                "purpose": "Replay quickstart note.",
                "exists": True,
            }
        ]

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.render_text_report(self.root, inventory, missing_only=True)

        self.assertEqual(1, exit_code)
        self.assertIn("Missing: 0/1", output.getvalue())


if __name__ == "__main__":
    unittest.main()