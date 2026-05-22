import unittest
from pathlib import Path


import attached_pages_preflight_report as preflight_module


class AttachedPagesPreflightCommandHintsTests(unittest.TestCase):
    def test_build_route_url_normalizes_relative_routes(self):
        self.assertEqual(
            "http://127.0.0.1:8235/manifest.json",
            preflight_module.build_route_url("127.0.0.1", 8235, "manifest.json"),
        )

    def test_choose_recommended_command_falls_back_to_manifest_for_unknown_step(self):
        command_hints = {
            "sidecar_audit_command": "sidecars",
            "asset_audit_command": "assets",
            "launch_command": "launch",
            "manifest_command": "manifest",
        }

        self.assertEqual(
            "manifest",
            preflight_module.choose_recommended_command("unexpected-step", command_hints),
        )

    def test_strict_commands_preserve_preferred_initial_page_and_inputs(self):
        repo_root = Path("/tmp/lightpanda")
        selected_files = [
            repo_root / "agent_files" / "google-home.html",
            repo_root / "agent_files" / "notes.html",
        ]

        command_hints = preflight_module.build_command_hints(
            repo_root,
            selected_files=selected_files,
            google_style=True,
            preferred_initial_page="notes.html",
            bind="127.0.0.1",
            port=8456,
        )

        self.assertIn("--preferred-initial-page notes.html", command_hints["strict_manifest_command"])
        self.assertIn("--preferred-initial-page notes.html", command_hints["strict_launch_command"])
        self.assertIn("--require-complete-sidecars", command_hints["strict_manifest_command"])
        self.assertIn("--require-complete-assets", command_hints["strict_manifest_command"])
        self.assertIn("--print-manifest", command_hints["strict_manifest_command"])
        self.assertIn("--google-style", command_hints["strict_launch_command"])
        self.assertIn("--bind 127.0.0.1", command_hints["strict_launch_command"])
        self.assertIn("--port 8456", command_hints["strict_launch_command"])
        self.assertIn(str(selected_files[0]), command_hints["strict_launch_command"])
        self.assertIn(str(selected_files[1]), command_hints["strict_launch_command"])


if __name__ == "__main__":
    unittest.main()
