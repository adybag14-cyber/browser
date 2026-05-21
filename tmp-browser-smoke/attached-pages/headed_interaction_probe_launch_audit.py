#!/usr/bin/env python3
"""Audit interaction-heavy probe scripts for explicit headed launches."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "file_upload_common_headed_launch",
        "path": "tmp-browser-smoke/file-upload/FileUploadProbeCommon.ps1",
        "snippet": "return Start-Process -FilePath $script:BrowserExe -ArgumentList @('browse', '--browser_mode', 'headed', '--window_width', '960', '--window_height', '640', $StartupUrl)",
        "why": "File-upload probes should request a headed browser window explicitly before opening the native picker.",
    },
    {
        "label": "enter_submit_probe_headed_launch",
        "path": "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)',
        "why": "Enter-submit validation should stay on an explicit headed route while exercising real keyboard delivery.",
    },
    {
        "label": "label_click_probe_headed_launch",
        "path": "tmp-browser-smoke/form-controls/label-click-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)',
        "why": "Label-click interaction probes should keep a real headed window request instead of relying on CLI defaults.",
    },
    {
        "label": "popup_background_timer_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-background-timer-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/script-popup-background-timer.html")',
        "why": "Popup background-timer validation is about real headed window behavior and should keep that contract explicit.",
    },
    {
        "label": "popup_form_enter_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-form-enter-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/form-index.html")',
        "why": "Popup form Enter probes should pin headed mode directly while checking tab-opening submit behavior.",
    },
    {
        "label": "popup_form_post_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-form-post-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/form-post-index.html")',
        "why": "Popup POST probes should keep explicit headed launches while verifying real form submission flow.",
    },
    {
        "label": "inline_flow_probe_headed_launch",
        "path": "tmp-browser-smoke/inline-flow/probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--screenshot_png",$outPng',
        "why": "Inline-flow screenshot probes should keep the headed render path explicit for local layout validation.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether interaction-heavy validation probes launch "
            "browse with an explicit headed request."
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
        print(f"[{status}] headed interaction probe launch audit")
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
