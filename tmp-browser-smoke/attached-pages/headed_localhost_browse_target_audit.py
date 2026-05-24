#!/usr/bin/env python3
"""Audit headed localhost browse-target normalization and classification paths."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "normalize_loopback_http_branch",
        "path": "src/lightpanda.zig",
        "snippet": (
            "    if (looksLikeLoopbackBrowseTarget(trimmed)) {\n"
            '        return try std.fmt.allocPrintSentinel(allocator, "http://{s}", .{trimmed}, 0);\n'
            "    }\n"
        ),
        "why": "Scheme-less localhost launches should stay on http for attached-page validation targets.",
    },
    {
        "label": "normalize_loopback_host_set",
        "path": "src/lightpanda.zig",
        "snippet": (
            'fn looksLikeLoopbackBrowseTarget(raw: []const u8) bool {\n'
            '    return hasHostPrefix(raw, "localhost") or\n'
            '        hasHostPrefix(raw, "127.0.0.1") or\n'
            '        hasHostPrefix(raw, "[::1]");\n'
            "}\n"
        ),
        "why": "Loopback normalization should keep localhost, IPv4 loopback, and IPv6 loopback in scope together.",
    },
    {
        "label": "normalize_loopback_regression_test",
        "path": "src/lightpanda.zig",
        "snippet": (
            'test "normalizeBrowseUrl keeps loopback targets on http" {\n'
            "    const allocator = std.testing.allocator;\n"
            "\n"
            '    const localhost = try normalizeBrowseUrl(allocator, "localhost:8123/status");\n'
            "    defer allocator.free(localhost.?);\n"
            '    try std.testing.expectEqualStrings("http://localhost:8123/status", localhost.?);\n'
        ),
        "why": "The source-level normalizeBrowseUrl tests should keep proving the localhost http route explicitly.",
    },
    {
        "label": "implicit_loopback_helper",
        "path": "src/main.zig",
        "snippet": (
            "fn browseTargetImplicitLoopback(url: []const u8) ?BrowseTargetInfo {\n"
            "    const authority = browseTargetImplicitAuthority(url) orelse return null;\n"
            "    const host = browseTargetHost(authority);\n"
            "    if (!isLoopbackBrowseHost(host)) {\n"
            "        return null;\n"
            "    }\n"
            "    return .{\n"
            '        .scheme = "implicit_http",\n'
            '        .scope = "loopback",\n'
        ),
        "why": "Headed browse target diagnostics should keep treating scheme-less localhost targets as loopback http inputs.",
    },
    {
        "label": "attached_html_local_path_test",
        "path": "src/main.zig",
        "snippet": (
            'test "browse target info classifies attached html filenames as local paths" {\n'
            '    const info = browseTargetInfo("attached-page.html");\n'
            "\n"
            '    try std.testing.expectEqualStrings("path", info.scheme);\n'
            '    try std.testing.expectEqualStrings("local_path", info.scope);\n'
        ),
        "why": "Bare attached HTML files should keep staying on the local-path route for direct headed testing.",
    },
    {
        "label": "schemeless_localhost_loopback_test",
        "path": "src/main.zig",
        "snippet": (
            'test "browse target info classifies scheme-less localhost pages as loopback" {\n'
            '    const info = browseTargetInfo("localhost:8123/attached-page.html");\n'
            "\n"
            '    try std.testing.expectEqualStrings("implicit_http", info.scheme);\n'
            '    try std.testing.expectEqualStrings("loopback", info.scope);\n'
        ),
        "why": "Attached localhost pages should keep classifying as loopback even without an explicit scheme.",
    },
    {
        "label": "fqdn_localhost_loopback_test",
        "path": "src/main.zig",
        "snippet": (
            'test "browse target info keeps fully qualified localhost hosts on the implicit http route" {\n'
            '    const info = browseTargetInfo("localhost.:8123/attached-page.html");\n'
            "\n"
            '    try std.testing.expectEqualStrings("implicit_http", info.scheme);\n'
            '    try std.testing.expectEqualStrings("loopback", info.scope);\n'
        ),
        "why": "Fully qualified localhost hostnames should stay loopback-safe for local server variants.",
    },
    {
        "label": "ipv6_loopback_route_test",
        "path": "src/main.zig",
        "snippet": (
            'test "browse target info keeps ipv6 loopback hosts on the implicit http route" {\n'
            '    const info = browseTargetInfo("[::1]:8123/replay.xhtml?case=1");\n'
            "\n"
            '    try std.testing.expectEqualStrings("implicit_http", info.scheme);\n'
            '    try std.testing.expectEqualStrings("loopback", info.scope);\n'
        ),
        "why": "IPv6 loopback attached pages should keep the same headed localhost route as IPv4 and localhost names.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/lightpanda.zig and src/main.zig still preserve "
            "headed localhost browse-target normalization and attached-page classification."
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
        print(f"[{status}] headed localhost browse target audit")
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