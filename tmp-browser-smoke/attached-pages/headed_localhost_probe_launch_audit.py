#!/usr/bin/env python3
"""Audit representative localhost probe scripts for explicit headed launches."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "attachment_downloads_common_headed_launch",
        "path": "tmp-browser-smoke/attachment-downloads/AttachmentProbeCommon.ps1",
        "snippet": 'return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Attachment download probes should request headed browse mode explicitly instead of relying on the CLI default.",
    },
    {
        "label": "browser_pages_common_headed_launch",
        "path": "tmp-browser-smoke/browser-pages/BrowserPagesProbeCommon.ps1",
        "snippet": 'return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Browser pages probes should pin headed launches even when they thread extra shell-log plumbing.",
    },
    {
        "label": "sessionstorage_common_headed_launch",
        "path": "tmp-browser-smoke/sessionstorage-scope/SessionStorageProbeCommon.ps1",
        "snippet": 'return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Session storage probes are meant to exercise a real headed browser window on localhost pages.",
    },
    {
        "label": "cookie_common_headed_launch",
        "path": "tmp-browser-smoke/cookie-persistence/CookieProbeCommon.ps1",
        "snippet": 'return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Cookie persistence checks should stay on an explicit headed validation route.",
    },
    {
        "label": "websocket_echo_headed_launch",
        "path": "tmp-browser-smoke/websocket-smoke/chrome-websocket-echo-probe.ps1",
        "snippet": "$browser = Start-Process -FilePath $browserExe -ArgumentList 'browse','--browser_mode','headed',$pageUrl,'--window_width','840','--window_height','560'",
        "why": "WebSocket localhost probes should not drift back to an implicit browser-mode launch.",
    },
    {
        "label": "popup_anchor_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/anchor-index.html")',
        "why": "Popup probes are validating headed window behavior and should keep that request explicit.",
    },
    {
        "label": "stylesheet_auth_headed_launch",
        "path": "tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "640", $pageUrl)',
        "why": "Authenticated stylesheet smokes should keep using a headed browser window explicitly.",
    },
    {
        "label": "flow_layout_headed_launch",
        "path": "tmp-browser-smoke/flow-layout/probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","--screenshot_png",$outPng,$pageUrl)',
        "why": "Flow-layout screenshot checks should pin the headed render path directly.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether representative localhost validation probes launch "
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
        print(f"[{status}] headed localhost probe launch audit")
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