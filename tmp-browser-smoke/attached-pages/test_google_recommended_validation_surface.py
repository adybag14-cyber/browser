import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
Write-Route -Name "google-recommended" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order",
    "& `"$BrowserExe`" browse --headed `"https://www.google.com/`"",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1"
) -Notes @(
    "Use the shared Enter-submit probe first, then the dedicated Google form-controls Enter-order gate, then verify Google homepage typing, focus retention, and Enter submit manually."
)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-recommended-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleRecommendedValidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.router = read_text(cls.repo_root / "scripts/windows/show_headed_validation_suites.ps1")

    def test_google_recommended_route_keeps_shared_input_google_and_attached_html_ladder(self) -> None:
        route_match = re.search(
            r'Write-Route\s+-Name\s+"google-recommended"\s+-Commands\s+@\((?P<body>.*?)\)\s+-Notes',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(route_match, "router should keep a top-level google-recommended route")
        body = route_match.group("body")

        expected_commands = (
            r'.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input',
            r'.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order',
            r'browse --headed `"https://www.google.com/`"',
            r'.\scripts\windows\show_attached_html_validation_flow.ps1',
            r'.\scripts\windows\show_google_attached_html_validation_flow.ps1',
            r'.\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1',
            r'.\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1',
            r'.\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1',
            r'.\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1',
            r'.\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1',
        )

        for command in expected_commands:
            self.assertIn(command, body)

    def test_google_recommended_notes_keep_the_manual_google_handoff(self) -> None:
        self.assertIn(
            "then verify Google homepage typing, focus retention, and Enter submit manually.",
            self.router,
        )


if __name__ == "__main__":
    unittest.main()
