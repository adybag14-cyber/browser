from __future__ import annotations

import os
from pathlib import Path
import tempfile
import textwrap
import unittest

SCRIPT_RELATIVE_PATH = Path("scripts/check_issue3_linux_build_readiness_reentry.py")
REQUIRED_SNIPPETS = (
    "choose_combined_next_step(",
    "matching_zig_candidates",
    "restore_check",
    "restore",
    "combined_next_step",
    "scripts/check_linux_build_readiness.py",
    "scripts/check_issue3_saved_zig_archive_candidates.py",
    "--expect-saved-archives",
    "--expect-offline-deps",
    "--require-prebuilt-v8",
    "Combined next step:",
)


def resolve_repo_root() -> Path:
    fixture_root = os.environ.get("LIGHTPANDA_FIXTURE_REPO")
    if fixture_root:
        return Path(fixture_root).resolve()
    return Path(__file__).resolve().parents[2]


def load_helper(repo_root: Path) -> str:
    return (repo_root / SCRIPT_RELATIVE_PATH).read_text(encoding="utf-8")


class LinuxBuildReadinessReentryHelperContractTests(unittest.TestCase):
    def test_fixture_helper_contains_required_bridge_logic(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            helper_path = repo_root / SCRIPT_RELATIVE_PATH
            helper_path.parent.mkdir(parents=True, exist_ok=True)
            helper_path.write_text(
                textwrap.dedent(
                    """\
                    def choose_combined_next_step(readiness_report, saved_zig_report):
                        matching_zig_candidates = readiness_report.get(\"matching_zig_candidates\") or []
                        restore_check = (saved_zig_report.get(\"commands\") or {}).get(\"restore_check\")
                        restore = (saved_zig_report.get(\"commands\") or {}).get(\"restore\")
                        return \"combined_next_step\"

                    \"scripts/check_linux_build_readiness.py\"
                    \"scripts/check_issue3_saved_zig_archive_candidates.py\"
                    \"--expect-saved-archives\"
                    \"--expect-offline-deps\"
                    \"--require-prebuilt-v8\"
                    \"Combined next step:\"
                    """
                ),
                encoding="utf-8",
            )

            helper_text = load_helper(repo_root)
            for snippet in REQUIRED_SNIPPETS:
                self.assertIn(snippet, helper_text)

    def test_live_helper_contains_required_bridge_logic(self) -> None:
        repo_root = resolve_repo_root()
        helper_text = load_helper(repo_root)
        for snippet in REQUIRED_SNIPPETS:
            self.assertIn(snippet, helper_text)


if __name__ == "__main__":
    unittest.main()
