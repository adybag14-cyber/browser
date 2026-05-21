#!/usr/bin/env python3
"""Audit whether key headed smoke probes keep explicit headed launches."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "browser_pages_common_explicit_headed_launch",
        "path": "tmp-browser-smoke/browser-pages/BrowserPagesProbeCommon.ps1",
        "snippet": '@("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Shared browser-pages helpers should always force headed mode for shell validation.",
    },
    {
        "label": "attachment_common_explicit_headed_launch",
        "path": "tmp-browser-smoke/attachment-downloads/AttachmentProbeCommon.ps1",
        "snippet": '@("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Attached-page download probes should stay on the real headed runtime.",
    },
    {
        "label": "storage_common_explicit_headed_launch",
        "path": "tmp-browser-smoke/localstorage-persistence/StorageProbeCommon.ps1",
        "snippet": '@("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Storage persistence probes should not drift back to the CLI default mode.",
    },
    {
        "label": "download_delete_internal_page_explicit_headed_launch",
        "path": "tmp-browser-smoke/downloads/chrome-download-delete-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed","browser://downloads","--window_width","960","--window_height","640","--screenshot_png",$initialPng)',
        "why": "The downloads internal-page probe should force headed mode before checking destructive download actions.",
    },
    {
        "label": "stylesheet_auth_explicit_headed_launch",
        "path": "tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1",
        "snippet": '@("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "640", $pageUrl)',
        "why": "Stylesheet auth headed coverage should keep using the native window path explicitly.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether key headed smoke helpers and representative probes "
            "still request headed mode explicitly."
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



def emit_text(summary: dict[str, object]) -> None:
    status = "ok" if summary["ok"] else "missing"
    print(
        f"[headed-probe-launch-explicitness] status={status} "
        f"missing={summary['missing_count']}/{summary['expectation_count']}"
    )
    for check in summary["checks"]:
        check_status = "present" if check["present"] else ("missing_file" if not check["exists"] else "missing_snippet")
        print(
            f"- {check['label']}: {check_status} "
            f"({check['path']})"
        )
        if check_status != "present":
            print(f"  why: {check['why']}")



def main() -> int:
    args = parse_args()
    summary = audit(args.repo_root.resolve())
    if args.json:
        json.dump(summary, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        emit_text(summary)
    return 0 if summary["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
