from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md": """
    ## Restored-Checkout-Only Follow-ups

    Treat those commands as post-restore follow-ups, not as the first step in a
    fresh workspace.

    If `../browser-memory-snapshot` or the chosen `--restored-checkout-root`
    does not exist yet, go to the saved-browser-snapshot route first:

    ```bash
    bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
    ```

    After that restore succeeds, rerun the nested-workspace saved-memory
    preflight or the restored-checkout preflight before trusting the issue `#11`
    helper-contract and re-entry inventory commands from the restored tree.
    """,
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh": """
      Saved-Memory preflight when a restored checkout already exists:
        ${RESTORED_SAVED_INPUT_COMMAND}

      Restored helper-surface sync route:
        ${RESTORED_HELPER_SURFACE_SYNC_ROUTE_COMMAND}

      Live-helper preflight from the restored checkout itself:
        ${LIVE_HELPER_RESTORED_CHECKOUT_COMMAND}

      Restore route when no reusable checkout exists yet:
        ${SNAPSHOT_ROUTE_COMMAND}

      - Use saved_browser_snapshot_route when the saved inputs are green but
        there is still no restored checkout.
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-saved-memory-restored-followups-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedMemoryRestoredCheckoutFollowupsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        else:
            candidate_root = pathlib.Path(__file__).resolve().parents[2]
            if (candidate_root / "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md").is_file():
                cls.repo_root = candidate_root
            else:
                cls.repo_root = build_fixture_repo()

        cls.saved_memory_route_text = (
            cls.repo_root / "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md"
        ).read_text(encoding="utf-8")
        cls.saved_memory_route_printer_text = (
            cls.repo_root / "scripts/linux/show_issue3_saved_memory_inputs_route.sh"
        ).read_text(encoding="utf-8")

    def test_saved_memory_route_keeps_restore_first_handoff_visible(self) -> None:
        for fragment in (
            "## Restored-Checkout-Only Follow-ups",
            "Treat those commands as post-restore follow-ups, not as the first step",
            "fresh workspace.",
            "go to the saved-browser-snapshot route first:",
            "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        ):
            self.assertIn(fragment, self.saved_memory_route_text)

    def test_saved_memory_route_keeps_post_restore_recheck_guidance_visible(self) -> None:
        for fragment in (
            "After that restore succeeds, rerun the nested-workspace saved-memory",
            "preflight or the restored-checkout preflight before trusting the issue `#11`",
            "helper-contract and re-entry inventory commands from the restored tree.",
        ):
            self.assertIn(fragment, self.saved_memory_route_text)

    def test_route_printer_keeps_restore_and_restored_checkout_steps_ordered(self) -> None:
        for fragment in (
            "Saved-Memory preflight when a restored checkout already exists:",
            "Restored helper-surface sync route:",
            "Live-helper preflight from the restored checkout itself:",
            "Restore route when no reusable checkout exists yet:",
            "Use saved_browser_snapshot_route when the saved inputs are green but",
            "there is still no restored checkout.",
        ):
            self.assertIn(fragment, self.saved_memory_route_printer_text)


if __name__ == "__main__":
    unittest.main()
