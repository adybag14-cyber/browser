#!/usr/bin/env python3

"""Focused surface guard for the issue #3 workspace re-entry route helper."""

from __future__ import annotations

import os
from pathlib import Path
import unittest


def resolve_repo_root() -> Path:
    fixture_repo = os.environ.get("LIGHTPANDA_FIXTURE_REPO")
    if fixture_repo:
        return Path(fixture_repo).resolve()
    return Path("/workspace").resolve()


class WorkspaceReentryRoutesSurfaceTests(unittest.TestCase):
    def test_helper_references_saved_memory_and_restored_checkout_routes(self) -> None:
        helper_path = resolve_repo_root() / "scripts" / "check_issue3_workspace_reentry_routes.py"
        text = helper_path.read_text(encoding="utf-8")

        for needle in (
            "check_issue3_saved_memory_inputs_route_surface.sh",
            "show_issue3_saved_memory_inputs_route.sh",
            "check_issue3_restored_checkout_reentry_route_surface.sh",
            "show_issue3_restored_checkout_reentry_route.sh",
            "show_issue3_progress_tracker_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "--memory-root",
            "--restored-checkout-root",
            "--saved-archives-root",
            "--toolchains-root",
            "--offline-deps-root",
        ):
            self.assertIn(needle, text)


if __name__ == "__main__":
    unittest.main()