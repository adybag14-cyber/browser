#!/usr/bin/env python3
"""Audit direct product-surface smoke probes for explicit headed launches."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "find_probe_headed_launch",
        "path": "tmp-browser-smoke/find/chrome-find-probe.ps1",
        "snippets": (
            '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","360","--window_height","420","--screenshot_png",$readyPng',
        ),
        "why": "Find-in-page headed validation should keep requesting headed mode explicitly.",
    },
    {
        "label": "settings_restore_off_headed_launches",
        "path": "tmp-browser-smoke/settings/chrome-settings-restore-off-probe.ps1",
        "snippets": (
            '$browser1 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","960","--window_height","640"',
            '$browser2 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","960","--window_height","640"',
        ),
        "why": "The restore-off smoke probe should pin headed mode on both launches so session validation stays on the real browser path.",
    },
    {
        "label": "bookmark_close_headed_launch",
        "path": "tmp-browser-smoke/bookmarks/bookmark-close-probe.ps1",
        "snippets": (
            '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$Port/index.html","--window_width","320","--window_height","420","--screenshot_png",$readyPng',
        ),
        "why": "Bookmark product-surface checks should keep using an explicit headed browse launch.",
    },
    {
        "label": "download_delete_headed_launch",
        "path": "tmp-browser-smoke/downloads/chrome-download-delete-probe.ps1",
        "snippets": (
            '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","browser://downloads","--window_width","960","--window_height","640","--screenshot_png",$initialPng)',
        ),
        "why": "Browser downloads UI validation should stay on the explicit headed shell route.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether representative direct product-surface smoke probes "
            "request headed browse mode explicitly."
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
            missing_snippets = [
                snippet for snippet in expectation["snippets"] if snippet not in text
            ]
        else:
            missing_snippets = list(expectation["snippets"])

        present = not missing_snippets
        if not present:
            missing += 1

        checks.append(
            {
                **expectation,
                "exists": exists,
                "present": present,
                "missing_snippets": missing_snippets,
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
        print(f"[{status}] headed product-surface probe launch audit")
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