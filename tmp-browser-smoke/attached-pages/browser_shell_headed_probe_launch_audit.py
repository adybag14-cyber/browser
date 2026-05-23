#!/usr/bin/env python3
"""Audit explicit headed launches in key browser-shell smoke probes."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "tmp-browser-smoke/find/chrome-find-probe.ps1",
        "label": "find_probe_explicit_headed_launch",
        "snippets": (
            'Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed"',
        ),
        "why": "The find-in-page probe should always validate the native headed shell instead of relying on a mutable CLI default.",
    },
    {
        "path": "tmp-browser-smoke/bookmarks/bookmark-close-probe.ps1",
        "label": "bookmark_close_probe_explicit_headed_launch",
        "snippets": (
            'Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed"',
        ),
        "why": "Bookmark-close coverage is only trustworthy when the probe requests a real headed browse session directly.",
    },
    {
        "path": "tmp-browser-smoke/settings/chrome-settings-restore-off-probe.ps1",
        "label": "settings_restore_off_probe_explicit_headed_launches",
        "snippets": (
            '$browser1 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed"',
            '$browser2 = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed"',
        ),
        "why": "The restore-off settings flow should keep both launches on the headed path so restart behavior is measured on the real shell.",
    },
    {
        "path": "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1",
        "label": "tabs_probe_explicit_headed_launch",
        "snippets": (
            'Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed"',
        ),
        "why": "Tab-strip probes should not drift onto an implicit default mode while validating headed window behavior.",
    },
    {
        "path": "tmp-browser-smoke/downloads/chrome-download-probe.ps1",
        "label": "downloads_probe_explicit_headed_launch",
        "snippets": (
            'Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$pageUrl',
        ),
        "why": "The downloads shell probe should pin its browse launch to headed mode before checking file and metadata behavior.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2]

    parser = argparse.ArgumentParser(
        description=(
            "Check whether selected browser-shell smoke probes keep explicit "
            "headed browse launches."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=default_repo_root,
        help="Repository root to inspect. Defaults to the parent repo root.",
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
        missing_snippets = [
            snippet for snippet in expectation["snippets"] if snippet not in text
        ]
        present = exists and not missing_snippets
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
        print(f"[{status}] browser-shell headed probe launch audit")
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
                for snippet in check["missing_snippets"]:
                    print(f"  Missing snippet: {snippet}")

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
