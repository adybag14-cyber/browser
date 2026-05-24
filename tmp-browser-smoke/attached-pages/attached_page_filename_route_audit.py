#!/usr/bin/env python3
"""Audit local attached-page filename coverage for headed startup target routing."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


SOURCE_PATH = "src/main.zig"

REAL_ATTACHED_PAGE_FILENAMES = (
    "Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html",
    "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html",
    "Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html",
)

SOURCE_EXPECTATIONS = (
    {
        "label": "local_path_candidate_helper",
        "snippet": "fn browseTargetLocalPathCandidate(url: []const u8) []const u8 {",
        "why": "The startup classifier should keep trimming query and fragment suffixes before local-path checks.",
    },
    {
        "label": "bare_local_html_helper",
        "snippet": "fn looksLikeBareLocalHtmlPath(url: []const u8) bool {",
        "why": "Bare attached HTML filenames should stay on the dedicated local-path helper route.",
    },
    {
        "label": "local_path_suffix_html",
        "snippet": 'std.ascii.endsWithIgnoreCase(candidate, ".html") or',
        "why": "Plain `.html` attached filenames should remain classified as local paths.",
    },
    {
        "label": "local_path_suffix_xhtml",
        "snippet": 'std.ascii.endsWithIgnoreCase(candidate, ".xhtml") or',
        "why": "Saved `.xhtml` attached pages should remain classified as local paths.",
    },
    {
        "label": "slash_local_path_branch",
        "snippet": "std.mem.indexOfScalar(u8, local_path_candidate, '/') != null or",
        "why": "Relative attached-page launches under nested folders should keep their local-path branch.",
    },
    {
        "label": "backslash_local_path_branch",
        "snippet": "std.mem.indexOfScalar(u8, local_path_candidate, '\\\\') != null or",
        "why": "Windows attached-page launches should keep their explicit backslash-aware local-path branch.",
    },
    {
        "label": "local_path_scope_result",
        "snippet": '.scope = "local_path",',
        "why": "The browse-target classifier should keep surfacing attached pages as `local_path` targets.",
    },
    {
        "label": "attached_html_example_test",
        "snippet": 'const info = browseTargetInfo("attached-page.html?case=1");',
        "why": "Focused source tests should continue covering attached-page launches directly.",
    },
)


def trim_query_and_fragment(url: str) -> str:
    suffix_start = len(url)
    for marker in ("?", "#"):
        index = url.find(marker)
        if index != -1:
            suffix_start = min(suffix_start, index)
    return url[:suffix_start]


def classify_target(url: str) -> dict[str, str]:
    if "://" in url:
        return {
            "scheme": "other",
            "scope": "non_local",
            "host": "(n/a)",
            "port": "(n/a)",
        }

    candidate = trim_query_and_fragment(url)
    is_local_path = (
        "/" in candidate
        or "\\" in candidate
        or candidate.lower().endswith((".html", ".xhtml", ".htm"))
    )
    return {
        "scheme": "path" if is_local_path else "unknown",
        "scope": "local_path" if is_local_path else "unknown",
        "host": "(none)",
        "port": "(none)",
    }


def build_target_examples() -> tuple[dict[str, str], ...]:
    examples: list[dict[str, str]] = []
    for filename in REAL_ATTACHED_PAGE_FILENAMES:
        examples.append(
            {
                "label": f"bare::{filename}",
                "target": filename,
                "expected_scheme": "path",
                "expected_scope": "local_path",
            }
        )
        examples.append(
            {
                "label": f"relative::{filename}",
                "target": f"agent_files/{filename}",
                "expected_scheme": "path",
                "expected_scope": "local_path",
            }
        )
        examples.append(
            {
                "label": f"windows::{filename}",
                "target": f"agent_files\\{filename}",
                "expected_scheme": "path",
                "expected_scope": "local_path",
            }
        )
    return tuple(examples)


TARGET_EXAMPLES = build_target_examples()


def audit(repo_root: Path) -> dict[str, object]:
    target = repo_root / SOURCE_PATH
    exists = target.is_file()
    text = target.read_text(encoding="utf-8") if exists else ""

    source_checks: list[dict[str, object]] = []
    missing_source = 0
    for expectation in SOURCE_EXPECTATIONS:
        present = expectation["snippet"] in text
        if not present:
            missing_source += 1
        source_checks.append(
            {
                **expectation,
                "path": SOURCE_PATH,
                "exists": exists,
                "present": present,
            }
        )

    target_checks: list[dict[str, object]] = []
    misclassified_targets = 0
    for example in TARGET_EXAMPLES:
        classification = classify_target(example["target"])
        matches = (
            classification["scheme"] == example["expected_scheme"]
            and classification["scope"] == example["expected_scope"]
        )
        if not matches:
            misclassified_targets += 1
        target_checks.append(
            {
                **example,
                "classification": classification,
                "matches": matches,
            }
        )

    return {
        "repo_root": str(repo_root),
        "source_path": SOURCE_PATH,
        "source_expectation_count": len(SOURCE_EXPECTATIONS),
        "missing_source_count": missing_source,
        "target_example_count": len(TARGET_EXAMPLES),
        "misclassified_target_count": misclassified_targets,
        "ok": exists and missing_source == 0 and misclassified_targets == 0,
        "source_checks": source_checks,
        "target_checks": target_checks,
    }


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check that src/main.zig keeps the local-path startup routing hooks "
            "needed for the real attached HTML page filenames used in headed validation."
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


def main() -> int:
    args = parse_args()
    result = audit(args.repo_root.resolve())

    if args.json:
        json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
        sys.stdout.write("\n")
    else:
        status = "PASS" if result["ok"] else "FAIL"
        print(f"[{status}] attached page filename route audit")
        print(f"Repo root: {result['repo_root']}")
        print(f"Source path: {result['source_path']}")
        print(
            f"Matched {result['source_expectation_count'] - result['missing_source_count']} of "
            f"{result['source_expectation_count']} source expectations."
        )
        print(
            f"Matched {result['target_example_count'] - result['misclassified_target_count']} of "
            f"{result['target_example_count']} real attached-page target examples."
        )
        for check in result["source_checks"]:
            marker = "ok" if check["present"] else "missing"
            print(f"- {marker}: {check['label']} ({check['path']})")
            if not check["present"]:
                print(f"  Why: {check['why']}")
        for check in result["target_checks"]:
            marker = "ok" if check["matches"] else "mismatch"
            print(f"- {marker}: {check['label']} -> {check['classification']['scope']}")

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())