import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
# Issue #3 Enter-Submit Runtime Revalidation

Target `Page.zig` slice
Target `win32_backend.zig` slice
Focused regression coverage
src/browser/Page.zig
src/display/win32_backend.zig
chrome-google-home-title-probe.ps1
google_home_title_probe.html?google-home-probe=1
""",
    "docs/WINDOWS_FULL_USE.md": """
google-form-controls-enter-order
""",
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": """
docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md
docs/WINDOWS_FULL_USE.md
src/browser/Page.zig
src/display/win32_backend.zig
scripts/windows/HeadedValidationHelpers.ps1
scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1
tmp-browser-smoke/form-controls/enter-submit-probe.ps1
tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1
src/browser/tests/page/google_home_title_probe.html
note_path = "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"
reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"
google_home_title_probe.html?google-home-probe=1
Stale queued suppression entries do not drop real later text_input bytes.
Shared click-first route:
""",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": """
note_path = "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
shared_enter_default = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"
shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"
shared_enter_google = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"
shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"
reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"
google_home_title_probe.html?google-home-probe=1
Stale queued suppression entries do not drop real later text_input bytes.
Shared click-first route:
Use focused_page_tests and focused_win32_tests only when the current checkout already has a branch-compatible Zig toolchain
Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig
Only jump to reduced_google_fixture or live_google after the shared Enter-order ladder and reduced Google probe agree on the same event ordering.
src/browser/Page.zig
src/display/win32_backend.zig
docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md
docs/WINDOWS_FULL_USE.md
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-enter-runtime-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3EnterSubmitRuntimeSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runtime_note = read_text(cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")
        cls.windows_runbook = read_text(cls.repo_root / "docs/WINDOWS_FULL_USE.md")
        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )
        cls.runtime_helper = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )

    def test_runtime_note_keeps_narrow_targets_and_probe_command(self) -> None:
        for snippet in (
            "Target `Page.zig` slice",
            "Target `win32_backend.zig` slice",
            "Focused regression coverage",
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html?google-home-probe=1",
        ):
            self.assertIn(snippet, self.runtime_note)

    def test_windows_runbook_keeps_google_enter_order_route_visible(self) -> None:
        self.assertIn("google-form-controls-enter-order", self.windows_runbook)

    def test_surface_check_keeps_runtime_note_helper_probe_and_fixture_refs(self) -> None:
        for snippet in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
            "docs/WINDOWS_FULL_USE.md",
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
            "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
            "src/browser/tests/page/google_home_title_probe.html",
        ):
            self.assertIn(snippet, self.surface_check)

    def test_runtime_helper_keeps_surface_check_and_enter_order_ladder(self) -> None:
        for snippet in (
            'note_path = "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            'shared_enter_default = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"',
            'shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"',
            'shared_enter_google = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"',
            'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"',
            'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"',
            "google_home_title_probe.html?google-home-probe=1",
            "Shared click-first route:",
            "Stale queued suppression entries do not drop real later text_input bytes.",
        ):
            self.assertIn(snippet, self.runtime_helper)

    def test_runtime_helper_keeps_replay_guidance_and_companion_files(self) -> None:
        for snippet in (
            "branch-compatible Zig toolchain",
            "Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig",
            "Only jump to reduced_google_fixture or live_google after the shared Enter-order ladder and reduced Google probe agree on the same event ordering.",
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
            "docs/WINDOWS_FULL_USE.md",
        ):
            self.assertIn(snippet, self.runtime_helper)


if __name__ == "__main__":
    unittest.main()
