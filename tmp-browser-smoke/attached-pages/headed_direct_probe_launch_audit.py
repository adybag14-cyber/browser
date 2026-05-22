#!/usr/bin/env python3
"""Audit direct smoke probes for explicit headed browse launches."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "popup_script_blank_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-script-blank-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/script-popup-blank-index.html")',
        "why": "Script-opened popup probes should keep their headed browser request explicit.",
    },
    {
        "label": "popup_query_load_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-query-load-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$pageUrl)',
        "why": "Direct query-load popup probes should stay on the explicit headed route.",
    },
    {
        "label": "popup_form_enter_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-form-enter-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/form-index.html")',
        "why": "Popup form enter probes validate real headed interaction and should not rely on defaults.",
    },
    {
        "label": "downloads_probe_headed_launch",
        "path": "tmp-browser-smoke/downloads/chrome-download-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$pageUrl,"--window_width","960","--window_height","640","--screenshot_png",$initialPng)',
        "why": "Download probes need an explicit headed window request for realistic local validation.",
    },
    {
        "label": "stop_input_probe_headed_launch",
        "path": "tmp-browser-smoke/stop-loading/chrome-stop-input-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "260", "--window_height", "520", "--screenshot_png", $beforePng, $inputUrl)',
        "why": "Stop-and-restore input probes should pin the headed startup contract directly.",
    },
    {
        "label": "wrapped_link_reload_headed_launch",
        "path": "tmp-browser-smoke/wrapped-link/chrome-reload-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","240","--window_height","480","--screenshot_png",$png,"http://$Host`:$Port/index.html")',
        "why": "Reload probes exercise visible chrome behavior and should keep the headed launch explicit.",
    },
    {
        "label": "duplicate_tab_headed_launch",
        "path": "tmp-browser-smoke/tabs/chrome-duplicate-tab-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/duplicate-one.html","--window_width","960","--window_height","640"',
        "why": "Duplicate-tab probes should keep their direct headed launch explicit.",
    },
    {
        "label": "canvas_render_headed_launch",
        "path": "tmp-browser-smoke/canvas-smoke/chrome-canvas-render-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","420","--window_height","360","--screenshot_png",$outPng',
        "why": "Canvas render probes depend on the real headed presentation surface and should keep that request explicit.",
    },
    {
        "label": "find_probe_headed_launch",
        "path": "tmp-browser-smoke/find/chrome-find-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","360","--window_height","420","--screenshot_png",$readyPng',
        "why": "Find-in-page probes should keep their direct headed launch explicit.",
    },
    {
        "label": "settings_restore_off_headed_launch",
        "path": "tmp-browser-smoke/settings/chrome-settings-restore-off-probe.ps1",
        "snippet": '$browser1 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","960","--window_height","640"',
        "why": "Settings restore-off probes should keep the first headed browser launch explicit.",
    },
    {
        "label": "settings_restore_off_restart_headed_launch",
        "path": "tmp-browser-smoke/settings/chrome-settings-restore-off-probe.ps1",
        "snippet": '$browser2 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","960","--window_height","640"',
        "why": "Settings restore-off probes should keep the restart headed browser launch explicit.",
    },
    {
        "label": "bookmark_close_headed_launch",
        "path": "tmp-browser-smoke/bookmarks/bookmark-close-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$Port/index.html","--window_width","320","--window_height","420","--screenshot_png",$readyPng',
        "why": "Bookmark close probes validate visible chrome behavior and should keep the headed launch explicit.",
    },
    {
        "label": "layout_flex_order_headed_launch",
        "path": "tmp-browser-smoke/layout-smoke/chrome-layout-flex-order-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","480","--window_height","240","--screenshot_png",$outPng',
        "why": "Flex-order layout probes should keep their headed screenshot launch explicit.",
    },
    {
        "label": "layout_background_size_headed_launch",
        "path": "tmp-browser-smoke/layout-smoke/chrome-layout-background-size-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","640","--window_height","860","--screenshot_png",$outPng',
        "why": "Background-size layout probes should keep their headed screenshot launch explicit.",
    },
    {
        "label": "layout_screenshot_load_complete_headed_launch",
        "path": "tmp-browser-smoke/layout-smoke/chrome-screenshot-load-complete-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","420","--window_height","320","--screenshot_png",$outPng',
        "why": "Load-complete screenshot probes should keep their headed screenshot launch explicit.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether direct smoke probes launch browse with an explicit "
            "headed request."
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
        print(f"[{status}] headed direct probe launch audit")
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