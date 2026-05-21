#!/usr/bin/env python3
"""Audit popup smoke probes for explicit headed launch arguments."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "popup_anchor_launches_headed_explicitly",
        "path": "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1",
        "snippet": (
            '$browser = Start-Process -FilePath $browserExe -ArgumentList '
            '@("browse","--browser_mode","headed","--window_width","960",'
            '"--window_height","640","$origin/anchor-index.html")'
        ),
        "why": (
            "The popup anchor smoke path should stay on an explicit headed "
            "browse launch instead of relying on CLI defaults."
        ),
    },
    {
        "label": "popup_script_blank_launches_headed_explicitly",
        "path": "tmp-browser-smoke/popup/chrome-popup-script-blank-probe.ps1",
        "snippet": (
            '$browser = Start-Process -FilePath $browserExe -ArgumentList '
            '@("browse","--browser_mode","headed","--window_width","960",'
            '"--window_height","640","$origin/script-popup-blank-index.html")'
        ),
        "why": (
            "The script-blank popup probe should pin headed mode explicitly so "
            "local popup validation cannot drift onto a different browser mode."
        ),
    },
    {
        "label": "popup_script_policy_launches_headed_explicitly",
        "path": "tmp-browser-smoke/popup/chrome-popup-script-policy-probe.ps1",
        "snippet": (
            '$browser = Start-Process -FilePath $browserExe -ArgumentList '
            '@("browse","--browser_mode","headed","--window_width","960",'
            '"--window_height","640","$origin/script-popup-policy-index.html")'
        ),
        "why": (
            "The popup script-policy probe should keep explicit headed launch "
            "arguments while it exercises popup policy settings."
        ),
    },
    {
        "label": "popup_named_anchor_launches_headed_explicitly",
        "path": "tmp-browser-smoke/popup/chrome-popup-named-anchor-probe.ps1",
        "snippet": (
            '$browser = Start-Process -FilePath $browserExe -ArgumentList '
            '@("browse","--browser_mode","headed","--window_width","960",'
            '"--window_height","640","--screenshot_png",$screenshotPath,'
            '"$origin/named-target-index.html")'
        ),
        "why": (
            "The named-anchor popup probe should keep its explicit headed "
            "launch while it verifies popup tab reuse and screenshot flow."
        ),
    },
    {
        "label": "popup_form_enter_launches_headed_explicitly",
        "path": "tmp-browser-smoke/popup/chrome-popup-form-enter-probe.ps1",
        "snippet": (
            '$browser = Start-Process -FilePath $browserExe -ArgumentList '
            '@("browse","--browser_mode","headed","--window_width","960",'
            '"--window_height","640","$origin/form-index.html")'
        ),
        "why": (
            "The popup form-enter probe should keep explicit headed launch "
            "arguments while it verifies Enter-driven popup navigation."
        ),
    },
    {
        "label": "popup_form_post_launches_headed_explicitly",
        "path": "tmp-browser-smoke/popup/chrome-popup-form-post-probe.ps1",
        "snippet": (
            '$browser = Start-Process -FilePath $browserExe -ArgumentList '
            '@("browse","--browser_mode","headed","--window_width","960",'
            '"--window_height","640","$origin/form-post-index.html")'
        ),
        "why": (
            "The popup form-post probe should keep explicit headed launch "
            "arguments while it verifies POST-backed popup navigation."
        ),
    },
    {
        "label": "popup_query_load_launches_headed_explicitly",
        "path": "tmp-browser-smoke/popup/chrome-query-load-probe.ps1",
        "snippet": (
            '$browser = Start-Process -FilePath $browserExe -ArgumentList '
            '@("browse","--browser_mode","headed","--window_width","960",'
            '"--window_height","640",$pageUrl)'
        ),
        "why": (
            "The popup query-load probe should keep explicit headed launch "
            "arguments while it verifies direct popup result loads."
        ),
    },
    {
        "label": "popup_script_policy_block_launches_headed_explicitly",
        "path": "tmp-browser-smoke/popup/chrome-popup-script-policy-block-probe.ps1",
        "snippet": (
            '$browser = Start-Process -FilePath $browserExe -ArgumentList '
            '@("browse","--browser_mode","headed","--window_width","960",'
            '"--window_height","640","$origin/script-popup-blank-index.html")'
        ),
        "why": (
            "The popup script-policy-block probe should keep explicit headed "
            "launch arguments while it verifies blocked popup policy behavior."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = (
        script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent
    )

    parser = argparse.ArgumentParser(
        description=(
            "Check whether representative popup smoke probes keep explicit "
            "headed browse launches."
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
        checks.append({**expectation, "exists": exists, "present": present})

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