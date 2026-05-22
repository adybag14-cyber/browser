#!/usr/bin/env python3
"""Audit popup and file-upload probe scripts for explicit headed launches."""

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
        "why": "File upload probes exercise the real headed shell and should keep their launch mode explicit.",
    },
    {
        "label": "popup_form_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-form-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/form-index.html")',
        "why": "Form-driven popup probes should not rely on the CLI default browser mode.",
    },
    {
        "label": "popup_form_enter_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-form-enter-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/form-index.html")',
        "why": "Enter-submit popup probes validate real headed keyboard delivery and should keep that route explicit.",
    },
    {
        "label": "popup_form_post_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-form-post-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/form-post-index.html")',
        "why": "POST-driven popup probes should stay pinned to the headed browser path.",
    },
    {
        "label": "popup_query_load_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-query-load-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$pageUrl)',
        "why": "Query-string popup loads are part of localhost headed validation and should keep the mode explicit.",
    },
    {
        "label": "popup_named_anchor_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-named-anchor-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","--screenshot_png",$screenshotPath,"$origin/named-target-index.html")',
        "why": "Named-target popup probes should continue to request a headed window directly.",
    },
    {
        "label": "popup_script_blank_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-script-blank-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/script-popup-blank-index.html")',
        "why": "Script-opened blank popups validate headed tab behavior and should stay explicit.",
    },
    {
        "label": "popup_script_named_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-script-named-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/script-popup-named-index.html")',
        "why": "Named script popup probes should keep their headed launch path explicit.",
    },
    {
        "label": "popup_script_policy_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-script-policy-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/script-popup-policy-index.html")',
        "why": "Popup policy probes validate a headed settings workflow and should not fall back to an implicit mode.",
    },
    {
        "label": "popup_background_timer_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-background-timer-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/script-popup-background-timer.html")',
        "why": "Background-timer popup probes exercise headed popup lifecycle behavior and should keep their mode explicit.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether popup and file-upload localhost validation probes "
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
        print(f"[{status}] headed popup probe launch audit")
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