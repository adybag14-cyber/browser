#!/usr/bin/env python3
"""Audit websocket smoke probes for explicit headed browse launches."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "tmp-browser-smoke/websocket-smoke/chrome-websocket-echo-probe.ps1",
        "snippet": "'browse','--browser_mode','headed'",
        "purpose": "The websocket echo probe should keep headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/websocket-smoke/chrome-websocket-binary-close-probe.ps1",
        "snippet": "'browse','--browser_mode','headed'",
        "purpose": "The websocket binary-close probe should keep headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/websocket-smoke/chrome-websocket-subprotocol-probe.ps1",
        "snippet": "'browse','--browser_mode','headed'",
        "purpose": "The websocket subprotocol probe should keep headed mode explicit in its browse launch.",
    },
)


def build_missing_summary(results: list[dict[str, object]]) -> list[dict[str, object]]:
    summary: list[dict[str, object]] = []
    for result in results:
        if result["present"]:
            continue
        summary.append(
            {
                "path": result["path"],
                "purpose": result["purpose"],
                "snippet": result["snippet"],
                "reason": "file_missing" if not result["exists"] else "headed_launch_missing",
            }
        )
    return summary


def audit_repo_root(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    for expectation in EXPECTATIONS:
        target = repo_root / expectation["path"]
        exists = target.is_file()
        present = exists and expectation["snippet"] in target.read_text(
            encoding="utf-8", errors="ignore"
        )
        results.append(
            {
                "path": expectation["path"],
                "purpose": expectation["purpose"],
                "snippet": expectation["snippet"],
                "exists": exists,
                "present": present,
            }
        )
    missing = build_missing_summary(results)
    return {
        "profile": "websocket-headed-launches",
        "repo_root": str(repo_root),
        "checked_count": len(results),
        "missing_count": len(missing),
        "missing": missing,
        "results": results,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit websocket localhost probes for explicit headed browse launches."
    )
    parser.add_argument("--repo-root", default=".", help="Repository root to inspect.")
    parser.add_argument("--json", action="store_true", help="Print JSON instead of text.")
    args = parser.parse_args(argv)

    audit = audit_repo_root(Path(args.repo_root).resolve())
    if args.json:
        print(json.dumps(audit, indent=2))
    elif audit["missing_count"]:
        for item in audit["missing"]:
            print(f"FAIL {item['path']}: {item['purpose']} ({item['reason']})")
    else:
        print("Websocket probe headed-launch surface is intact.")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
