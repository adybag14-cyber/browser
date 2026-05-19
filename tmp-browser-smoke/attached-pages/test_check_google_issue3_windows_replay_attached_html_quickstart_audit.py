from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name(
    "check_google_issue3_windows_replay_attached_html_quickstart_audit.py"
)
SPEC = importlib.util.spec_from_file_location("replay_attached_html_audit", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def write_file(repo_root: Path, relative_path: str, contents: str) -> None:
    target = repo_root / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(contents, encoding="utf-8")


def build_passing_repo(repo_root: Path) -> None:
    write_file(repo_root, "build.zig", "exe = true;\n")

    for reference in MODULE.REFERENCE_CHECKS:
        write_file(repo_root, reference.path, f"# placeholder for {reference.path}\n")

    content_by_path: dict[str, list[str]] = {}
    for check in MODULE.CONTENT_CHECKS:
        content_by_path.setdefault(check.path, []).append(check.snippet)

    for path, snippets in content_by_path.items():
        body = "\n".join(snippets) + "\n"
        write_file(repo_root, path, body)


class ReplayAttachedHtmlAuditTests(unittest.TestCase):
    def test_passes_when_expected_surfaces_exist(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo_root = Path(temp_dir)
            build_passing_repo(repo_root)

            report = MODULE.run_audit(repo_root)

            self.assertEqual(report["missing_count"], 0)
            self.assertIn(
                "surface is intact",
                MODULE.format_text_report(report),
            )

    def test_fails_when_launcher_surface_snippet_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo_root = Path(temp_dir)
            build_passing_repo(repo_root)

            helper_path = repo_root / "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
            helper_text = helper_path.read_text(encoding="utf-8")
            broken_text = helper_text.replace(
                'Write-Host (("  Launcher surface check:   {0}") -f $helper.commands.attached_pages_launcher_companion_surface_check)\n',
                "",
            )
            helper_path.write_text(broken_text, encoding="utf-8")

            report = MODULE.run_audit(repo_root)

            self.assertEqual(report["missing_count"], 1)
            missing_paths = {
                result["path"]
                for result in report["content_checks"]
                if not result["exists"]
            }
            self.assertEqual(
                missing_paths,
                {"scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"},
            )


if __name__ == "__main__":
    unittest.main()
