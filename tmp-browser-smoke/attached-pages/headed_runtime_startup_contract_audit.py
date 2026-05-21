#!/usr/bin/env python3
"""Audit headed startup-route contracts across main.zig and Config.zig."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "main_bare_local_html_helper",
        "path": "src/main.zig",
        "snippet": "fn looksLikeBareLocalHtmlPath(url: []const u8) bool {",
        "why": "Headed startup diagnostics should keep a dedicated helper for bare local HTML targets before remote-host inference.",
    },
    {
        "label": "main_bare_local_html_precedes_implicit_remote",
        "path": "src/main.zig",
        "snippet": "        if (looksLikeBareLocalHtmlPath(url)) {\n            return .{\n                .scheme = \"path\",\n                .scope = \"local_path\",\n                .host = \"(none)\",\n                .port = \"(none)\",\n            };\n        }\n        if (browseTargetImplicitRemote(url)) |implicit_remote| {",
        "why": "Bare attached-page HTML files should stay on the local-path route before scheme-less remote-host classification runs.",
    },
    {
        "label": "main_loopback_localhost_test",
        "path": "src/main.zig",
        "snippet": 'test "browse target info classifies scheme-less localhost pages as loopback" {',
        "why": "The startup classifier should keep scheme-less localhost replay URLs on the loopback route.",
    },
    {
        "label": "main_loopback_any_bind_test",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps any-bind loopback hosts on the implicit http route" {',
        "why": "The startup classifier should keep any-bind localhost targets on the loopback route used during local headed validation.",
    },
    {
        "label": "main_loopback_ipv6_test",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps ipv6 loopback hosts on the implicit http route" {',
        "why": "IPv6 loopback startup targets should stay covered for headed localhost validation.",
    },
    {
        "label": "config_local_target_helper",
        "path": "src/Config.zig",
        "snippet": "fn inferLocalBrowseTarget(token: []const u8) bool {",
        "why": "Command-mode inference should keep a dedicated helper for local attached-page targets.",
    },
    {
        "label": "config_file_url_browse_support",
        "path": "src/Config.zig",
        "snippet": '    if (std.ascii.startsWithIgnoreCase(token, "file://")) {\n        return true;\n    }',
        "why": "File URLs should continue to select browse mode for local headed validation.",
    },
    {
        "label": "config_bare_html_browse_test",
        "path": "src/Config.zig",
        "snippet": 'test "infer mode treats bare html filename as browse" {',
        "why": "Bare attached-page filenames should keep selecting browse mode automatically.",
    },
    {
        "label": "config_remote_html_fetch_test",
        "path": "src/Config.zig",
        "snippet": 'test "infer mode keeps fetch for remote html url without browse hint" {',
        "why": "Remote HTML URLs should stay on fetch unless a browse-specific hint is present.",
    },
    {
        "label": "config_headed_remote_html_browse_test",
        "path": "src/Config.zig",
        "snippet": 'test "infer mode keeps browse for remote html url after headed shortcut" {',
        "why": "An explicit headed request should still push remote HTML URLs onto browse mode.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether headed startup-route contracts remain present in "
            "main.zig and Config.zig."
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
        print(f"[{status}] headed runtime startup contract audit")
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