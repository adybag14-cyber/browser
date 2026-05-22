#!/usr/bin/env python3
"""Audit startup target classification coverage in src/main.zig."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "internal_helper_exists",
        "path": "src/main.zig",
        "snippet": "fn browseTargetInternal(url: []const u8, scheme: []const u8) ?BrowseTargetInfo {",
        "why": "Browser shell pages should keep a dedicated internal-target classifier.",
    },
    {
        "label": "bare_local_html_helper_exists",
        "path": "src/main.zig",
        "snippet": "fn looksLikeBareLocalHtmlPath(url: []const u8) bool {",
        "why": "Bare attached-page filenames should keep their dedicated local-path guard.",
    },
    {
        "label": "implicit_loopback_helper_exists",
        "path": "src/main.zig",
        "snippet": "fn browseTargetImplicitLoopback(url: []const u8) ?BrowseTargetInfo {",
        "why": "Scheme-less localhost targets should keep a dedicated loopback classifier.",
    },
    {
        "label": "browse_target_internal_branch_order",
        "path": "src/main.zig",
        "snippet": "    if (browseTargetInternal(url, scheme)) |internal| {\n        return internal;\n    }\n    if (browseTargetAbout(url)) |about| {\n        return about;\n    }\n",
        "why": "Internal browser pages should stay classified before the generic authority fallback.",
    },
    {
        "label": "browse_target_loopback_branch_order",
        "path": "src/main.zig",
        "snippet": "        if (browseTargetImplicitLoopback(url)) |implicit_loopback| {\n            return implicit_loopback;\n        }\n        if (looksLikeBareLocalHtmlPath(url)) {\n            return .{\n                .scheme = \"path\",\n                .scope = \"local_path\",\n",
        "why": "Scheme-less loopback targets should stay ahead of bare local HTML classification.",
    },
    {
        "label": "browser_downloads_internal_test",
        "path": "src/main.zig",
        "snippet": "test \"browse target info classifies browser downloads pages as internal\" {",
        "why": "Startup diagnostics should keep browser downloads pages on the internal route.",
    },
    {
        "label": "browser_settings_internal_test",
        "path": "src/main.zig",
        "snippet": "test \"browse target info keeps browser settings routes on the internal path\" {",
        "why": "Browser settings pages should keep their internal classification coverage.",
    },
    {
        "label": "about_blank_internal_test",
        "path": "src/main.zig",
        "snippet": "test \"browse target info classifies about blank pages as internal\" {",
        "why": "About pages should keep their internal startup classification coverage.",
    },
    {
        "label": "dotted_bare_local_html_test",
        "path": "src/main.zig",
        "snippet": "test \"browse target info keeps dotted bare local html files on the local path route\" {",
        "why": "Dotted attached-page filenames should keep local-path coverage instead of drifting toward remote-host classification.",
    },
    {
        "label": "scheme_less_localhost_test",
        "path": "src/main.zig",
        "snippet": "test \"browse target info classifies scheme-less localhost pages as loopback\" {",
        "why": "Localhost startup diagnostics should keep loopback coverage for bare attached-page URLs.",
    },
    {
        "label": "scheme_less_remote_test",
        "path": "src/main.zig",
        "snippet": "test \"browse target info classifies scheme-less remote hosts as implicit http\" {",
        "why": "Remote scheme-less hosts should stay distinct from localhost and local-path targets.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/main.zig still carries the startup-target "
            "classification helpers and focused tests used by headed-mode "
            "attached-page and localhost diagnostics."
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
        print(f"[{status}] headed startup target classification audit")
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