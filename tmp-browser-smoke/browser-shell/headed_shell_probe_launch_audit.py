#!/usr/bin/env python3
"""Audit representative browser-shell probe scripts for explicit headed launches."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "tabs_primary_probe_headed_launch",
        "path": "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$initialPng',
        "why": "The main tabs probe should explicitly request headed mode while exercising browser shell tab behavior.",
    },
    {
        "label": "tabs_reopen_closed_headed_launch",
        "path": "tmp-browser-smoke/tabs/chrome-reopen-closed-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$initialPng',
        "why": "Reopen-closed-tab coverage should stay on an explicit headed browser path.",
    },
    {
        "label": "tabs_session_restore_run1_headed_launch",
        "path": "tmp-browser-smoke/tabs/chrome-session-restore-probe.ps1",
        "snippet": '$browser1 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$run1Png',
        "why": "Session-restore setup should pin the first shell run to headed mode explicitly.",
    },
    {
        "label": "tabs_session_restore_run2_headed_launch",
        "path": "tmp-browser-smoke/tabs/chrome-session-restore-probe.ps1",
        "snippet": '$browser2 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$run2Png',
        "why": "Session-restore replay should keep the headed launch explicit on the restart pass too.",
    },
    {
        "label": "bookmark_persist_run1_headed_launch",
        "path": "tmp-browser-smoke/bookmarks/bookmark-persist-probe.ps1",
        "snippet": '$browser1 = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$indexUrl,"--window_width","320","--window_height","420","--screenshot_png",$browser1ReadyPng)',
        "why": "Bookmark persistence checks should keep their first browser-shell launch on the explicit headed route.",
    },
    {
        "label": "bookmark_persist_run2_headed_launch",
        "path": "tmp-browser-smoke/bookmarks/bookmark-persist-probe.ps1",
        "snippet": '$browser2 = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$nextUrl,"--window_width","320","--window_height","420","--screenshot_png",$browser2ReadyPng)',
        "why": "Bookmark persistence replay should stay headed after the first shell session exits.",
    },
    {
        "label": "download_probe_headed_launch",
        "path": "tmp-browser-smoke/downloads/chrome-download-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$pageUrl,"--window_width","960","--window_height","640","--screenshot_png",$initialPng)',
        "why": "Download validation should not rely on a CLI default to open the headed browser shell.",
    },
    {
        "label": "download_delete_probe_headed_launch",
        "path": "tmp-browser-smoke/downloads/chrome-download-delete-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","browser://downloads","--window_width","960","--window_height","640","--screenshot_png",$initialPng)',
        "why": "Browser downloads UI coverage should keep using an explicit headed launch for the shell surface.",
    },
    {
        "label": "popup_anchor_probe_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/anchor-index.html")',
        "why": "Popup anchor probes are checking headed tab creation behavior and should request that mode directly.",
    },
    {
        "label": "wrapped_link_overlay_probe_headed_launch",
        "path": "tmp-browser-smoke/wrapped-link/chrome-history-overlay-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","240","--window_height","480","--screenshot_png",$beforePng',
        "why": "History-overlay shell checks should stay on an explicit headed validation route.",
    },
    {
        "label": "zoom_probe_headed_launch",
        "path": "tmp-browser-smoke/zoom/chrome-zoom-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$pageUrl,"--window_width","320","--window_height","420","--screenshot_png",$beforePng)',
        "why": "Zoom validation is browser-shell behavior and should keep its headed launch contract explicit.",
    },
    {
        "label": "bare_metal_download_headed_launch",
        "path": "tmp-browser-smoke/bare-metal-release/chrome-bare-metal-download-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $bootBinary -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","960","--window_height","640","--screenshot_png",$initialPng',
        "why": "The packaged bare-metal browser probe should still request headed mode directly.",
    },
    {
        "label": "bare_metal_policy_headed_launch",
        "path": "tmp-browser-smoke/bare-metal-release/chrome-bare-metal-policy-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse", "--browser_mode", "headed", "http://127.0.0.1:$port/policy-page.html", "--screenshot_png", $policyScreenshot',
        "why": "Bare-metal policy coverage should keep the shell launch explicit even when it runs against the packaged binary.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether representative browser-shell validation probes "
            "launch browse with an explicit headed request."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=default_repo_root,
        help="Repository root to inspect. Defaults to the current script's repo.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the full audit summary as JSON.",
    )
    return parser.parse_args()


def audit(repo_root: Path) -> dict[str, object]:
    checks: list[dict[str, object]] = []
    missing = 0

    for expectation in EXPECTATIONS:
        target = repo_root / expectation["path"]
        exists = target.is_file()
        if exists:
            text = target.read_text(encoding="utf-8")
            present = expectation["snippet"] in text
        else:
            present = False
        if not present:
            missing += 1
        checks.append(
            {
                **expectation,
                "exists": exists,
                "present": present,
            }
        )

    return {
        "repo_root": str(repo_root),
        "expectation_count": len(EXPECTATIONS),
        "missing_count": missing,
        "ok": missing == 0,
        "checks": checks,
    }


def main() -> int:
    args = parse_args()
    result = audit(args.repo_root.resolve())

    if args.json:
        json.dump(result, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        status = "PASS" if result["ok"] else "FAIL"
        print(f"[{status}] headed shell probe launch audit")
        print(f"Repo root: {result['repo_root']}")
        print(
            f"Matched {result['expectation_count'] - result['missing_count']} of "
            f"{result['expectation_count']} expectations."
        )
        for check in result["checks"]:
            marker = "ok" if check["present"] else "missing"
            print(f"- {marker}: {check['label']} ({check['path']})")
            if not check["present"]:
                print(f"  Why: {check['why']}")

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
