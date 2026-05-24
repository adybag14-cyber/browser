#!/usr/bin/env python3
"""Audit explicit headed launches in shared storage probe helpers."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "indexeddb_headed_launch",
        "path": "tmp-browser-smoke/indexeddb-persistence/IndexedDbProbeCommon.ps1",
        "snippet": (
            'return Start-Process -FilePath $script:BrowserExe -ArgumentList '
            '@("browse","--browser_mode","headed","--window_width","960",'
            '"--window_height","640",$StartupUrl) -WorkingDirectory '
            '$script:Repo -PassThru -RedirectStandardOutput $Stdout '
            '-RedirectStandardError $Stderr'
        ),
        "why": (
            "The shared IndexedDB helper should request a real headed browse "
            "session instead of depending on CLI defaults."
        ),
    },
    {
        "label": "sessionstorage_headed_launch",
        "path": "tmp-browser-smoke/sessionstorage-scope/SessionStorageProbeCommon.ps1",
        "snippet": (
            'return Start-Process -FilePath $script:BrowserExe -ArgumentList '
            '@("browse","--browser_mode","headed","--window_width","960",'
            '"--window_height","640",$StartupUrl) -WorkingDirectory '
            '$script:Repo -PassThru -RedirectStandardOutput $Stdout '
            '-RedirectStandardError $Stderr'
        ),
        "why": (
            "The shared sessionStorage helper should keep headed launches "
            "explicit so localhost storage probes stay on the native windowed path."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[1] if len(script_path.parents) > 1 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether the shared IndexedDB and sessionStorage probe helpers "
            "still launch browse with an explicit headed browser mode."
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
        print(f"[{status}] headed storage common launch audit")
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