#!/usr/bin/env python3
"""Audit headed startup target routing expectations in src/main.zig."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


MAIN_PATH = Path("src/main.zig")

REQUIRED_SNIPPETS = (
    {
        "label": "implicit_loopback_helper",
        "snippet": "fn browseTargetImplicitLoopback(url: []const u8) ?BrowseTargetInfo {",
        "purpose": "Scheme-less localhost targets should keep a dedicated loopback helper.",
    },
    {
        "label": "implicit_remote_helper",
        "snippet": "fn browseTargetImplicitRemote(url: []const u8) ?BrowseTargetInfo {",
        "purpose": "Scheme-less remote-host routing should stay explicit in startup diagnostics.",
    },
    {
        "label": "local_html_suffix_branch",
        "snippet": 'std.ascii.endsWithIgnoreCase(local_path_candidate, ".xhtml")',
        "purpose": "Bare local HTML and XHTML targets should keep a dedicated local-path fallback branch.",
    },
    {
        "label": "attached_html_filename_test",
        "snippet": 'test "browse target info classifies attached html filenames as local paths" {',
        "purpose": "The runtime should keep a direct test for bare local HTML filenames.",
    },
    {
        "label": "attached_html_query_test",
        "snippet": 'test "browse target info keeps attached html queries on the local path route" {',
        "purpose": "Bare local HTML targets with queries should stay on the local-path route.",
    },
    {
        "label": "attached_xhtml_fragment_test",
        "snippet": 'test "browse target info keeps attached xhtml fragments on the local path route" {',
        "purpose": "Bare local XHTML targets with fragments should stay on the local-path route.",
    },
    {
        "label": "loopback_localhost_test",
        "snippet": 'test "browse target info classifies scheme-less localhost pages as loopback" {',
        "purpose": "Scheme-less localhost launches should stay on the implicit loopback route.",
    },
    {
        "label": "loopback_ipv6_test",
        "snippet": 'test "browse target info keeps ipv6 loopback hosts on the implicit http route" {',
        "purpose": "IPv6 loopback launches should stay on the implicit loopback route.",
    },
)

LOCAL_HTML_BRANCH_PARTS = (
    'std.ascii.endsWithIgnoreCase(local_path_candidate, ".xhtml")',
    'std.ascii.endsWithIgnoreCase(local_path_candidate, ".html")',
    'std.ascii.endsWithIgnoreCase(local_path_candidate, ".htm")',
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_repo_root_error_audit(root: str | None, message: str) -> dict[str, object]:
    repo_root = str(Path.cwd()) if root is None else str(Path(root).expanduser())
    return {
        "repo_root": repo_root,
        "path": str(MAIN_PATH),
        "expectation_count": len(REQUIRED_SNIPPETS),
        "missing_count": None,
        "bug_present": None,
        "ok": False,
        "results": [],
        "bug_details": [],
        "error_type": "repo_root_not_found",
        "error": message,
    }


def implicit_remote_preempts_local_html(text: str) -> tuple[bool, list[str]]:
    details: list[str] = []
    loopback_marker = "if (browseTargetImplicitLoopback(url)) |implicit_loopback| {"
    remote_marker = "if (browseTargetImplicitRemote(url)) |implicit_remote| {"
    local_marker = 'std.ascii.endsWithIgnoreCase(local_path_candidate, ".xhtml")'

    loopback_index = text.find(loopback_marker)
    remote_index = text.find(remote_marker)
    local_index = text.find(local_marker)

    if remote_index == -1 or local_index == -1:
        details.append("Could not locate the implicit remote branch and local HTML fallback branch together.")
        return False, details

    if loopback_index != -1 and remote_index < loopback_index:
        details.append("The implicit remote branch appears before the implicit loopback branch.")

    if remote_index < local_index:
        details.append(
            "The implicit remote branch still appears before the bare local HTML fallback, so dotted filenames like attached-page.html can still classify as implicit remote hosts."
        )
        return True, details

    return False, details


def build_startup_target_route_audit(repo_root: Path) -> dict[str, object]:
    main_path = repo_root / MAIN_PATH
    if not main_path.is_file():
        return {
            "repo_root": str(repo_root),
            "path": str(MAIN_PATH),
            "expectation_count": len(REQUIRED_SNIPPETS),
            "missing_count": len(REQUIRED_SNIPPETS),
            "bug_present": None,
            "ok": False,
            "results": [
                {
                    **expectation,
                    "present": False,
                }
                for expectation in REQUIRED_SNIPPETS
            ],
            "bug_details": [f"Missing required file: {MAIN_PATH}"],
        }

    text = main_path.read_text(encoding="utf-8", errors="ignore")
    results = []
    missing_count = 0
    for expectation in REQUIRED_SNIPPETS:
        if expectation["label"] == "local_html_suffix_branch":
            present = all(part in text for part in LOCAL_HTML_BRANCH_PARTS)
        else:
            present = expectation["snippet"] in text
        if not present:
            missing_count += 1
        results.append({**expectation, "present": present})

    bug_present, bug_details = implicit_remote_preempts_local_html(text)
    ok = missing_count == 0 and not bug_present

    return {
        "repo_root": str(repo_root),
        "path": str(MAIN_PATH),
        "expectation_count": len(REQUIRED_SNIPPETS),
        "missing_count": missing_count,
        "bug_present": bug_present,
        "ok": ok,
        "results": results,
        "bug_details": bug_details,
    }


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Headed Startup Target Route Audit",
        "",
        f"Repo root: {audit['repo_root']}",
        f"Path: {audit['path']}",
    ]

    if audit.get("error_type"):
        lines.extend(
            [
                f"Error: {audit['error']}",
                "",
            ]
        )
        return "\n".join(lines).rstrip() + "\n"

    status = "PASS" if audit["ok"] else "FAIL"
    lines.extend(
        [
            f"Status: {status}",
            f"Expectations checked: {audit['expectation_count']}",
            f"Missing expectations: {audit['missing_count']}",
            f"Implicit-remote preemption bug present: {audit['bug_present']}",
            "",
        ]
    )

    for result in audit["results"]:
        marker = "ok" if result["present"] else "missing"
        lines.append(f"- {marker}: {result['label']}")
        if not result["present"]:
            lines.append(f"  Why: {result['purpose']}")

    if audit["bug_details"]:
        lines.append("")
        lines.append("Diagnostic details:")
        for detail in audit["bug_details"]:
            lines.append(f"- {detail}")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit whether headed startup target routing keeps local HTML targets on the local-path route."
    )
    parser.add_argument("--repo-root", help="Repository root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    try:
        repo_root = resolve_repo_root(args.repo_root)
        audit = build_startup_target_route_audit(repo_root)
    except FileNotFoundError as exc:
        audit = build_repo_root_error_audit(args.repo_root, str(exc))

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 0 if audit.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())