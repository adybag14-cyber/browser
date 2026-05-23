from __future__ import annotations

import importlib.util
import os
import pathlib
import tempfile
import unittest


FIXTURE_FILES = {
    "tmp-browser-smoke/find/chrome-find-probe.ps1": r'''
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","360","--window_height","420"
''',
    "tmp-browser-smoke/bookmarks/bookmark-close-probe.ps1": r'''
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$Port/index.html","--window_width","320","--window_height","420","--screenshot_png",$readyPng
''',
    "tmp-browser-smoke/settings/chrome-settings-restore-off-probe.ps1": r'''
$browser1 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","960","--window_height","640"
$browser2 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","960","--window_height","640"
''',
    "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1": r'''
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$initialPng
''',
    "tmp-browser-smoke/downloads/chrome-download-probe.ps1": r'''
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$pageUrl,"--window_width","960","--window_height","640","--screenshot_png",$initialPng)
''',
}


def load_audit_module(script_path: pathlib.Path):
    spec = importlib.util.spec_from_file_location(
        "browser_shell_headed_probe_launch_audit", script_path
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-browser-shell-headed-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class BrowserShellHeadedProbeLaunchAuditTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        script_path = pathlib.Path(__file__).resolve().with_name(
            "browser_shell_headed_probe_launch_audit.py"
        )
        cls.audit_module = load_audit_module(script_path)

        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = script_path.parents[2]

        cls.result = cls.audit_module.audit(cls.repo_root)

    def test_audit_passes(self) -> None:
        self.assertTrue(self.result["ok"])
        self.assertEqual(self.result["missing_count"], 0)

    def test_audit_covers_expected_probe_labels(self) -> None:
        labels = {check["label"] for check in self.result["checks"]}
        self.assertEqual(
            labels,
            {
                "find_probe_explicit_headed_launch",
                "bookmark_close_probe_explicit_headed_launch",
                "settings_restore_off_probe_explicit_headed_launches",
                "tabs_probe_explicit_headed_launch",
                "downloads_probe_explicit_headed_launch",
            },
        )

    def test_audit_points_at_browser_shell_probe_paths(self) -> None:
        paths = {check["path"] for check in self.result["checks"]}
        self.assertEqual(
            paths,
            {
                "tmp-browser-smoke/find/chrome-find-probe.ps1",
                "tmp-browser-smoke/bookmarks/bookmark-close-probe.ps1",
                "tmp-browser-smoke/settings/chrome-settings-restore-off-probe.ps1",
                "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1",
                "tmp-browser-smoke/downloads/chrome-download-probe.ps1",
            },
        )


if __name__ == "__main__":
    unittest.main()
