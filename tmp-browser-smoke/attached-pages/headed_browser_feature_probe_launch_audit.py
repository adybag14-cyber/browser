#!/usr/bin/env python3
"""Audit browser-feature probe scripts for explicit headed launches."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


SOURCE_ROOT = Path("tmp-browser-smoke")

EXPECTATIONS = (
    {
        "label": "browser_pages_common_headed_launch",
        "path": "tmp-browser-smoke/browser-pages/BrowserPagesProbeCommon.ps1",
        "snippet": 'return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Browser pages probes should keep using an explicit headed browser window for shell and settings validation.",
    },
    {
        "label": "bookmark_toggle_headed_launch",
        "path": "tmp-browser-smoke/bookmarks/bookmark-toggle-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$url,"--window_width","320","--window_height","420","--screenshot_png",$readyPng)',
        "why": "Bookmark toggle validation should stay on an explicit headed launch instead of depending on the CLI default.",
    },
    {
        "label": "bookmark_keyboard_headed_launch",
        "path": "tmp-browser-smoke/bookmarks/bookmark-keyboard-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","$origin/next.html","--window_width","320","--window_height","420","--screenshot_png",$readyPng)',
        "why": "Bookmark keyboard overlay checks should keep a real headed window request pinned.",
    },
    {
        "label": "bookmark_persist_run1_headed_launch",
        "path": "tmp-browser-smoke/bookmarks/bookmark-persist-probe.ps1",
        "snippet": '$browser1 = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$indexUrl,"--window_width","320","--window_height","420","--screenshot_png",$browser1ReadyPng)',
        "why": "Bookmark persistence validation should keep the first run on an explicit headed launch.",
    },
    {
        "label": "bookmark_close_headed_launch",
        "path": "tmp-browser-smoke/bookmarks/bookmark-close-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$Port/index.html","--window_width","320","--window_height","420","--screenshot_png",$readyPng',
        "why": "Bookmark close validation should keep explicit headed navigation before the overlay close action.",
    },
    {
        "label": "download_probe_headed_launch",
        "path": "tmp-browser-smoke/downloads/chrome-download-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$pageUrl,"--window_width","960","--window_height","640","--screenshot_png",$initialPng)',
        "why": "Download probes should keep requesting headed mode explicitly while exercising the browser downloads surface.",
    },
    {
        "label": "download_delete_probe_headed_launch",
        "path": "tmp-browser-smoke/downloads/chrome-download-delete-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","browser://downloads","--window_width","960","--window_height","640","--screenshot_png",$initialPng)',
        "why": "Downloads delete validation should keep browser://downloads on an explicit headed launch path.",
    },
    {
        "label": "find_probe_headed_launch",
        "path": "tmp-browser-smoke/find/chrome-find-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","360","--window_height","420","--screenshot_png",$readyPng',
        "why": "Find-in-page validation should keep using an explicit headed window before Ctrl+F interaction starts.",
    },
    {
        "label": "zoom_probe_headed_launch",
        "path": "tmp-browser-smoke/zoom/chrome-zoom-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$pageUrl,"--window_width","320","--window_height","420","--screenshot_png",$beforePng)',
        "why": "Zoom validation should keep the headed launch contract explicit before Ctrl+wheel interaction.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether representative browser-feature probes launch browse "
            "with an explicit headed request."
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
        "source_root": str(SOURCE_ROOT),
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
        print(f"[{status}] headed browser-feature probe launch audit")
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
