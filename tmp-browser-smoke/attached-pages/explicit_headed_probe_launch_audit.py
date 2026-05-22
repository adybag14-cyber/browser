#!/usr/bin/env python3
"""Audit explicit headed launch wiring across selected smoke probes."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "fetch_credentials_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/fetch-credentials/FetchCredentialsProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed",$StartupUrl,"--window_width","960","--window_height","640")',
        "why": "Fetch credentials probes should keep requesting a real headed browser session instead of relying on a CLI default.",
    },
    {
        "label": "fetch_abort_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/fetch-abort/FetchAbortProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Fetch abort validation should stay pinned to headed mode for localhost interaction coverage.",
    },
    {
        "label": "attachment_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/attachment-downloads/AttachmentProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Attachment probes are meant to exercise headed download behavior, so the launch mode should stay explicit.",
    },
    {
        "label": "cookie_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/cookie-persistence/CookieProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Cookie persistence probes should not drift onto a non-headed startup path.",
    },
    {
        "label": "websocket_echo_probe_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/websocket-smoke/chrome-websocket-echo-probe.ps1",
        "snippet": "Start-Process -FilePath $browserExe -ArgumentList 'browse','--browser_mode','headed',$pageUrl,'--window_width','840','--window_height','560'",
        "why": "The websocket echo probe should continue launching the headed browser explicitly while it waits for a real window title.",
    },
    {
        "label": "websocket_binary_close_probe_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/websocket-smoke/chrome-websocket-binary-close-probe.ps1",
        "snippet": "Start-Process -FilePath $browserExe -ArgumentList 'browse','--browser_mode','headed',$pageUrl,'--window_width','840','--window_height','560'",
        "why": "Binary-close websocket coverage should stay tied to an explicit headed run.",
    },
    {
        "label": "websocket_subprotocol_probe_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/websocket-smoke/chrome-websocket-subprotocol-probe.ps1",
        "snippet": "Start-Process -FilePath $browserExe -ArgumentList 'browse','--browser_mode','headed',$pageUrl,'--window_width','840','--window_height','560'",
        "why": "Subprotocol websocket coverage should stay on the headed launch path that the probe expects.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether selected localhost smoke probes keep requesting "
            "explicit headed browse launches."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=default_repo_root,
        help="Repository root to inspect. Defaults to the current script directory.",
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
        text = target.read_text(encoding="utf-8") if exists else ""
        present = expectation["snippet"] in text
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
        print(f"[{status}] explicit headed probe launch audit")
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