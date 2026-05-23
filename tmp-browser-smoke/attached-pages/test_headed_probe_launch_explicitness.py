from __future__ import annotations

import os
from pathlib import Path
import re
import unittest


TARGET_PROBE_PATHS: tuple[str, ...] = (
    "tmp-browser-smoke/bookmarks/bookmark-close-probe.ps1",
    "tmp-browser-smoke/bookmarks/bookmark-delete-probe.ps1",
    "tmp-browser-smoke/bookmarks/bookmark-persist-probe.ps1",
    "tmp-browser-smoke/find/chrome-find-probe.ps1",
    "tmp-browser-smoke/settings/chrome-settings-restore-off-probe.ps1",
    "tmp-browser-smoke/flow-layout/probe.ps1",
)


def normalize_script(text: str) -> str:
    return re.sub(r"\s+", "", text).lower()


def has_explicit_headed_browse_launch(text: str) -> bool:
    normalized = normalize_script(text)
    if "start-process" not in normalized:
        return False
    explicit_tokens = (
        '"browse","--browser_mode","headed"',
        "'browse','--browser_mode','headed'",
        '"browse","--headed"',
        "'browse','--headed'",
    )
    return any(token in normalized for token in explicit_tokens)


def resolve_repo_root() -> Path:
    override = os.environ.get("LIGHTPANDA_HEADED_PROBE_REPO_ROOT")
    if override:
        return Path(override).resolve()
    return Path(__file__).resolve().parents[2]


class HeadedProbeLaunchHelpersTests(unittest.TestCase):
    def test_accepts_browser_mode_headed_launch(self) -> None:
        script = 'Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", $pageUrl)'
        self.assertTrue(has_explicit_headed_browse_launch(script))

    def test_accepts_headed_flag_launch(self) -> None:
        script = "Start-Process -FilePath $browserExe -ArgumentList 'browse', '--headed', $pageUrl"
        self.assertTrue(has_explicit_headed_browse_launch(script))

    def test_rejects_default_mode_browse_launch(self) -> None:
        script = 'Start-Process -FilePath $browserExe -ArgumentList "browse", $pageUrl, "--window_width", "420"'
        self.assertFalse(has_explicit_headed_browse_launch(script))


class HeadedProbeLaunchSurfaceTests(unittest.TestCase):
    def test_key_localhost_probes_keep_explicit_headed_launches(self) -> None:
        repo_root = resolve_repo_root()
        missing_paths: list[str] = []
        non_explicit_paths: list[str] = []

        for relative_path in TARGET_PROBE_PATHS:
            target = repo_root / relative_path
            if not target.is_file():
                missing_paths.append(relative_path)
                continue
            if not has_explicit_headed_browse_launch(target.read_text(encoding="utf-8")):
                non_explicit_paths.append(relative_path)

        self.assertEqual(missing_paths, [], f"missing probe scripts: {missing_paths}")
        self.assertEqual(
            non_explicit_paths,
            [],
            f"probe scripts missing explicit headed browse launch: {non_explicit_paths}",
        )


if __name__ == "__main__":
    unittest.main()
