#!/usr/bin/env python3
"""Audit inline-flow probe scripts for explicit headed browse launches."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "inline_checkbox_link_headed_launch",
        "path": "tmp-browser-smoke/inline-flow/chrome-inline-checkbox-link-probe.ps1",
        "snippet": 'Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/checkbox-link.html"',
        "why": "Checkbox link probes should request headed browse mode explicitly for localhost flow validation.",
    },
    {
        "label": "inline_radio_button_link_headed_launch",
        "path": "tmp-browser-smoke/inline-flow/chrome-inline-radio-button-link-probe.ps1",
        "snippet": 'Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/radio-button-link.html"',
        "why": "Radio-button link probes are exercising headed interaction and should not rely on the CLI default.",
    },
    {
        "label": "inline_wrap_button_space_headed_launch",
        "path": "tmp-browser-smoke/inline-flow/chrome-inline-wrap-button-space-probe.ps1",
        "snippet": 'Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/button-keyboard.html"',
        "why": "Keyboard-triggered wrap-button probes should pin the headed route explicitly.",
    },
    {
        "label": "inline_long_wrap_link_headed_launch",
        "path": "tmp-browser-smoke/inline-flow/chrome-inline-long-wrap-link-click-probe.ps1",
        "snippet": 'Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/wrapped-long.html"',
        "why": "Long-wrap inline link probes should keep using an explicit headed launch for regression coverage.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether representative inline-flow validation probes launch "
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
        print(f"[{status}] inline-flow headed launch audit")
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