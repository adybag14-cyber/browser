from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1": """
    $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$initialPng
    """,
    "tmp-browser-smoke/tabs/chrome-duplicate-tab-probe.ps1": """
    $config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-duplicate"
    $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/duplicate-one.html","--window_width","960","--window_height","640"
    """,
    "tmp-browser-smoke/tabs/chrome-session-restore-probe.ps1": """
    $config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-restore"
    $browser1 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$run1Png
    $browser2 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$run2Png
    """,
    "tmp-browser-smoke/tabs/chrome-reopen-closed-probe.ps1": """
    $config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-reopen"
    $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$initialPng
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-tabs-headed-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class TabsHeadedLaunchSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.chrome_tabs = read_text(
            cls.repo_root / "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1"
        )
        cls.duplicate_tab = read_text(
            cls.repo_root / "tmp-browser-smoke/tabs/chrome-duplicate-tab-probe.ps1"
        )
        cls.session_restore = read_text(
            cls.repo_root / "tmp-browser-smoke/tabs/chrome-session-restore-probe.ps1"
        )
        cls.reopen_closed = read_text(
            cls.repo_root / "tmp-browser-smoke/tabs/chrome-reopen-closed-probe.ps1"
        )

    def test_every_guarded_tabs_probe_keeps_an_explicit_headed_launch(self) -> None:
        launch_snippet = '"browse","--browser_mode","headed"'
        for content in (
            self.chrome_tabs,
            self.duplicate_tab,
            self.session_restore,
            self.reopen_closed,
        ):
            self.assertIn(launch_snippet, content)

    def test_primary_tabs_probe_keeps_screenshot_and_window_surface(self) -> None:
        for fragment in (
            '"browse","--browser_mode","headed","http://$Host`:$Port/index.html"',
            '"--window_width","960","--window_height","640"',
            '"--screenshot_png",$initialPng',
        ):
            self.assertIn(fragment, self.chrome_tabs)

    def test_duplicate_and_restore_probes_keep_profile_bound_routes(self) -> None:
        self.assertIn('-ProfileName "profile-duplicate"', self.duplicate_tab)
        self.assertIn('-ProfileName "profile-restore"', self.session_restore)
        self.assertIn('-ProfileName "profile-reopen"', self.reopen_closed)

    def test_session_restore_keeps_two_explicit_headed_relaunches(self) -> None:
        self.assertEqual(
            2, self.session_restore.count('"browse","--browser_mode","headed"')
        )
        for fragment in ('"--screenshot_png",$run1Png', '"--screenshot_png",$run2Png'):
            self.assertIn(fragment, self.session_restore)


if __name__ == "__main__":
    unittest.main()
