#!/usr/bin/env python3
"""Audit representative image-runtime probe scripts for explicit headed launches."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "image_runtime_base_probe_headed_launch",
        "path": "tmp-browser-smoke/image-smoke/chrome-http-runtime-image-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", $pageUrl, "--screenshot_png", $outPng)',
        "why": "The base image-runtime screenshot probe should keep requesting a headed browser window explicitly.",
    },
    {
        "label": "image_runtime_script_auth_probe_headed_launch",
        "path": "tmp-browser-smoke/image-smoke/chrome-http-runtime-script-auth-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", $pageUrl, "--screenshot_png", $outPng)',
        "why": "The authenticated script probe is meant to validate real headed loading and should not rely on the CLI default.",
    },
    {
        "label": "image_runtime_auth_inherit_probe_headed_launch",
        "path": "tmp-browser-smoke/image-smoke/chrome-http-runtime-image-auth-inherit-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", $pageUrl, "--screenshot_png", $outPng)',
        "why": "Inherited-auth image checks should keep their headed screenshot route explicit.",
    },
    {
        "label": "image_runtime_module_auth_anonymous_probe_headed_launch",
        "path": "tmp-browser-smoke/image-smoke/chrome-http-runtime-module-auth-anonymous-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", $pageUrl, "--screenshot_png", $outPng)',
        "why": "Anonymous module-auth coverage should stay on the explicit headed path while exercising localhost runtime behavior.",
    },
    {
        "label": "image_runtime_policy_probe_headed_launch",
        "path": "tmp-browser-smoke/image-smoke/chrome-http-runtime-image-policy-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/policy-page.html","--screenshot_png",$outPng',
        "why": "Policy-gated image rendering checks should keep the headed launch requirement visible.",
    },
    {
        "label": "image_runtime_redirect_probe_headed_launch",
        "path": "tmp-browser-smoke/image-smoke/chrome-http-runtime-image-redirect-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/redirect-policy-page.html","--screenshot_png",$outPng',
        "why": "Redirected image-runtime probes should stay pinned to an explicit headed screenshot route.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether representative image-runtime probes launch browse "
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
        print(f"[{status}] headed image-runtime probe launch audit")
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
