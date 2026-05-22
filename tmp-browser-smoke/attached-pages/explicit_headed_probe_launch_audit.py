#!/usr/bin/env python3
"""Audit explicit headed launch wiring across selected smoke probes."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "browser_pages_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/browser-pages/BrowserPagesProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Browser shell page probes should keep requesting a real headed browser session instead of relying on a CLI default.",
    },
    {
        "label": "attachment_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/attachment-downloads/AttachmentProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Attachment probes are meant to exercise headed download behavior, so the launch mode should stay explicit.",
    },
    {
        "label": "fetch_abort_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/fetch-abort/FetchAbortProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Fetch abort validation should stay pinned to headed mode for localhost interaction coverage.",
    },
    {
        "label": "storage_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/localstorage-persistence/StorageProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Local storage persistence coverage should keep using an explicit headed launch.",
    },
    {
        "label": "session_storage_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/sessionstorage-scope/SessionStorageProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Session storage scope checks should stay on the real headed path they expect.",
    },
    {
        "label": "indexeddb_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/indexeddb-persistence/IndexedDbProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "IndexedDB persistence probes should keep requesting headed mode explicitly.",
    },
    {
        "label": "file_upload_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/file-upload/FileUploadProbeCommon.ps1",
        "snippet": "Start-Process -FilePath $script:BrowserExe -ArgumentList @('browse', '--browser_mode', 'headed', '--window_width', '960', '--window_height', '640', $StartupUrl)",
        "why": "File upload coverage depends on a real headed window and chooser flow.",
    },
    {
        "label": "fetch_credentials_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/fetch-credentials/FetchCredentialsProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed",$StartupUrl,"--window_width","960","--window_height","640")',
        "why": "Fetch credentials probes should keep requesting a real headed browser session instead of relying on a CLI default.",
    },
    {
        "label": "cookie_common_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/cookie-persistence/CookieProbeCommon.ps1",
        "snippet": 'Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Cookie persistence probes should not drift onto a non-headed startup path.",
    },
    {
        "label": "popup_form_enter_probe_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-form-enter-probe.ps1",
        "snippet": 'Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/form-index.html")',
        "why": "Popup form enter coverage should keep forcing a headed window for localhost interaction.",
    },
    {
        "label": "popup_form_post_probe_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-form-post-probe.ps1",
        "snippet": 'Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/form-post-index.html")',
        "why": "Popup form post coverage should keep using an explicit headed launch path.",
    },
    {
        "label": "popup_script_policy_block_probe_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/popup/chrome-popup-script-policy-block-probe.ps1",
        "snippet": 'Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/script-popup-blank-index.html")',
        "why": "Popup policy blocking checks should stay tied to the headed browser surface they validate.",
    },
    {
        "label": "websocket_echo_probe_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/websocket-smoke/chrome-websocket-echo-probe.ps1",
        "snippet": "Start-Process -FilePath $browserExe -ArgumentList 'browse','--browser_mode','headed',$pageUrl,'--window_width','840','--window_height','560'",
        "why": "The websocket echo probe should continue launching the headed browser explicitly while it waits for a real window title.",
    },
    {
        "label": "zoom_probe_keeps_explicit_headed_launch",
        "path": "tmp-browser-smoke/zoom/chrome-zoom-probe.ps1",
        "snippet": 'Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$pageUrl,"--window_width","320","--window_height","420","--screenshot_png",$beforePng)',
        "why": "The zoom probe should stay on an explicit headed launch path before exercising Ctrl+wheel input.",
    },
)


def repo_root_from(start: Path) -> Path:
    current = start.resolve()
    for candidate in (current, *current.parents):
        if (candidate / "build.zig").exists():
            return candidate
    raise FileNotFoundError(f"Could not resolve repo root from {start}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether selected localhost smoke probes keep requesting "
            "explicit headed browse launches."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=None,
        help="Repository root to inspect. Defaults to the current repo that contains this script.",
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
    repo_root = args.repo_root.resolve() if args.repo_root else repo_root_from(Path(__file__).resolve().parent)
    result = audit(repo_root)

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
