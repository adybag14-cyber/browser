#!/usr/bin/env python3

"""Check attached-pages fixture selection before localhost replay.

This helper keeps the attached-pages localhost route honest when multiple saved
HTML exports share the same leaf filename. It discovers the same repo/workspace
attachment roots used by other validation helpers, ranks Google-like fixtures
when requested, and surfaces exact preferred-page selectors that future runs
can pass safely.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path


HTML_EXPORT_EXTENSIONS = {".html", ".htm"}


def resolve_repo_root(start_path: Path, explicit_root: Path | None = None) -> Path:
    if explicit_root is not None:
        repo_root = explicit_root.expanduser().resolve()
        if (repo_root / "build.zig").is_file():
            return repo_root
        raise FileNotFoundError(
            f"explicit repo root does not look like a Lightpanda checkout: {repo_root}"
        )

    override = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
    if override:
        return Path(override).expanduser().resolve()

    cursor = start_path.expanduser().resolve()
    if cursor.is_file():
        cursor = cursor.parent

    while True:
        if (cursor / "build.zig").is_file():
            return cursor
        parent = cursor.parent
        if parent == cursor:
            raise FileNotFoundError(f"could not resolve the Lightpanda repo root from {start_path}")
        cursor = parent


def dedupe_paths(paths: list[Path]) -> list[Path]:
    unique: list[Path] = []
    seen: set[Path] = set()
    for path in paths:
        resolved = path.expanduser().resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        unique.append(resolved)
    return unique


def append_search_context_roots(roots: list[Path], start: Path) -> None:
    cursor = start.expanduser().resolve()
    if cursor.is_file():
        cursor = cursor.parent

    while True:
        roots.extend([cursor / "user_files", cursor / "agent_files"])
        parent = cursor.parent
        if parent == cursor:
            break
        cursor = parent


def get_attached_html_search_roots(repo_root: Path, *, cwd: Path | None = None) -> list[Path]:
    roots: list[Path] = []
    append_search_context_roots(roots, repo_root)
    append_search_context_roots(roots, (cwd or Path.cwd()).expanduser().resolve())
    return [path for path in dedupe_paths(roots) if path.is_dir()]


def collect_html_files_from_root(root: Path) -> list[Path]:
    return sorted(
        path for path in root.rglob("*") if path.is_file() and path.suffix.lower() in HTML_EXPORT_EXTENSIONS
    )


def normalize_explicit_input_paths(input_paths: list[str]) -> list[Path]:
    selected: list[Path] = []
    for raw_path in input_paths:
        path = Path(raw_path).expanduser().resolve()
        if path.is_dir():
            selected.extend(collect_html_files_from_root(path))
            continue
        if not path.is_file():
            raise FileNotFoundError(f"attached HTML input path not found: {path}")
        if path.suffix.lower() not in HTML_EXPORT_EXTENSIONS:
            raise ValueError(f"attached HTML input is not an .html or .htm file: {path}")
        selected.append(path)
    return dedupe_paths(selected)


def discover_attached_html_candidates(repo_root: Path, *, cwd: Path | None = None) -> list[Path]:
    candidates: list[Path] = []
    for root in get_attached_html_search_roots(repo_root, cwd=cwd):
        candidates.extend(collect_html_files_from_root(root))
    return dedupe_paths(candidates)


def google_style_fixture_summary(path: Path) -> dict[str, object]:
    score = 0
    reasons: list[str] = []
    lowered_path = str(path).lower()

    has_query_input = False
    has_search_form = False
    has_google_search_title = False

    if re.search(r"google[-_ ]?(home|search|input|query|submit|probe)", lowered_path):
        score += 6
        reasons.append("google-search path")
    elif re.search(r"search[-_ ]?(home|input|query|submit|probe|results)", lowered_path):
        score += 4
        reasons.append("search path")
    elif re.search(r"\bgoogle\b", lowered_path):
        score += 2
        reasons.append("google path")

    if re.search(r"(safety|privacy|policy|account|support)", lowered_path):
        score -= 4
        reasons.append("marketing path penalty")

    try:
        raw_text = path.read_text(encoding="utf-8", errors="ignore").lower()
    except OSError:
        return {
            "score": score,
            "reasons": reasons,
            "has_query_input": has_query_input,
            "has_search_form": has_search_form,
            "has_google_search_title": has_google_search_title,
        }

    if re.search(r"<title[^>]*>[^<]*google[^<]*(search|home)", raw_text):
        has_google_search_title = True
        score += 6
        reasons.append("google search/home title")
    elif re.search(r"<title[^>]*>[^<]*google[^<]*</title>", raw_text):
        score += 2
        reasons.append("google title")

    if re.search(r"name\s*=\s*['\"]q['\"]", raw_text):
        has_query_input = True
        score += 8
        reasons.append("query input")
    if re.search(r"aria-label\s*=\s*['\"][^'\"]*search[^'\"]*['\"]", raw_text):
        score += 2
        reasons.append("search aria")
    if re.search(r"<form[^>]+action\s*=\s*['\"][^'\"]*/search", raw_text) or re.search(
        r"\b(btnk|apjfqb|glfyf|gsfi)\b", raw_text
    ):
        has_search_form = True
        score += 6
        reasons.append("search form markers")

    if re.search(r"(google safety|safety centre|privacy policy|cookie policy)", raw_text):
        score -= 6
        reasons.append("marketing content penalty")

    return {
        "score": score,
        "reasons": reasons,
        "has_query_input": has_query_input,
        "has_search_form": has_search_form,
        "has_google_search_title": has_google_search_title,
    }


def is_google_style_fixture(path: Path) -> bool:
    summary = google_style_fixture_summary(path)
    return bool(
        summary["score"] > 5
        and (
            summary["has_query_input"]
            or summary["has_search_form"]
            or summary["has_google_search_title"]
        )
    )


def select_attached_html_inputs(
    repo_root: Path, *, explicit_inputs: list[str] | None = None, google_style: bool = False
) -> list[Path]:
    if explicit_inputs:
        selected = normalize_explicit_input_paths(explicit_inputs)
    else:
        selected = discover_attached_html_candidates(repo_root)

    if not selected:
        raise FileNotFoundError("no attached HTML files were found for the selection helper")

    if google_style:
        google_candidates = [path for path in selected if is_google_style_fixture(path)]
        if google_candidates:
            selected = google_candidates
        selected = sorted(
            selected,
            key=lambda path: (-int(google_style_fixture_summary(path)["score"]), str(path)),
        )

    return selected


def build_common_root(paths: list[Path]) -> Path:
    if len(paths) == 1:
        return paths[0].parent
    return Path(os.path.commonpath([str(path.parent) for path in paths]))


def selector_for_path(path: Path, *, common_root: Path) -> str:
    try:
        return path.relative_to(common_root).as_posix()
    except ValueError:
        return path.name


def normalize_selector(selector: str) -> str:
    normalized = selector.replace("\\", "/").strip()
    while normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized.lstrip("/")


def detect_duplicate_leaf_names(paths: list[Path], *, common_root: Path) -> dict[str, list[str]]:
    grouped: dict[str, list[Path]] = {}
    for path in paths:
        grouped.setdefault(path.name, []).append(path)

    duplicates: dict[str, list[str]] = {}
    for leaf, members in grouped.items():
        if len(members) < 2:
            continue
        duplicates[leaf] = [selector_for_path(path, common_root=common_root) for path in members]
    return duplicates


def resolve_preferred_page(paths: list[Path], selector: str, *, common_root: Path) -> Path:
    preferred_candidate = Path(selector).expanduser()
    if preferred_candidate.exists():
        resolved = preferred_candidate.resolve()
        matches = [path for path in paths if path == resolved]
    else:
        normalized_selector = normalize_selector(selector)
        matches = []
        for path in paths:
            relative_selector = normalize_selector(selector_for_path(path, common_root=common_root))
            absolute_selector = normalize_selector(str(path))
            if (
                path.name.casefold() == normalized_selector.casefold()
                or relative_selector.casefold() == normalized_selector.casefold()
                or relative_selector.casefold().endswith("/" + normalized_selector.casefold())
                or absolute_selector.casefold().endswith("/" + normalized_selector.casefold())
            ):
                matches.append(path)

    if not matches:
        available = ", ".join(selector_for_path(path, common_root=common_root) for path in paths)
        raise ValueError(
            f"preferred initial page '{selector}' did not match any selected attached HTML file. "
            f"Available selectors: {available}"
        )
    if len(matches) > 1:
        suggestions = ", ".join(selector_for_path(path, common_root=common_root) for path in matches)
        raise ValueError(
            f"preferred initial page '{selector}' is ambiguous across selected attached HTML files. "
            f"Use one of: {suggestions}"
        )
    return matches[0]


def build_report(
    paths: list[Path], *, repo_root: Path, google_style: bool, preferred_selector: str | None
) -> dict[str, object]:
    common_root = build_common_root(paths)
    duplicate_leaf_names = detect_duplicate_leaf_names(paths, common_root=common_root)
    selected_entries = []
    for path in paths:
        entry = {
            "path": str(path),
            "selector": selector_for_path(path, common_root=common_root),
            "leaf_name": path.name,
        }
        if google_style:
            summary = google_style_fixture_summary(path)
            entry["google_style_score"] = summary["score"]
            entry["google_style_reasons"] = summary["reasons"]
        selected_entries.append(entry)

    resolved_preferred_path = None
    resolved_preferred_selector = None
    if preferred_selector:
        preferred_path = resolve_preferred_page(paths, preferred_selector, common_root=common_root)
        resolved_preferred_path = str(preferred_path)
        resolved_preferred_selector = selector_for_path(preferred_path, common_root=common_root)

    return {
        "repo_root": str(repo_root),
        "fixture_count": len(paths),
        "google_style": google_style,
        "common_root": str(common_root),
        "duplicate_leaf_names": duplicate_leaf_names,
        "preferred_selector": preferred_selector,
        "resolved_preferred_selector": resolved_preferred_selector,
        "resolved_preferred_path": resolved_preferred_path,
        "fixtures": selected_entries,
    }


def render_text_report(report: dict[str, object]) -> str:
    lines = [
        "Attached Pages Selection Check",
        "",
        f"Repo root: {report['repo_root']}",
        f"Fixtures selected: {report['fixture_count']}",
        f"Common selector root: {report['common_root']}",
        f"Google-style ranking: {'enabled' if report['google_style'] else 'disabled'}",
    ]

    if report["preferred_selector"]:
        lines.append(f"Requested preferred selector: {report['preferred_selector']}")
        lines.append(
            "Resolved preferred selector: "
            + str(report["resolved_preferred_selector"])
        )

    duplicate_leaf_names = report["duplicate_leaf_names"]
    if duplicate_leaf_names:
        lines.extend(["", "Duplicate leaf-name collisions:"])
        for leaf_name, selectors in sorted(duplicate_leaf_names.items()):
            lines.append(f"- {leaf_name}")
            for selector in selectors:
                lines.append(f"  selector: {selector}")
    else:
        lines.extend(["", "Duplicate leaf-name collisions: none"])

    lines.extend(["", "Selected fixtures:"])
    for entry in report["fixtures"]:
        fixture_line = f"- {entry['selector']}"
        if report["google_style"]:
            reasons = ", ".join(entry["google_style_reasons"]) or "no matched hints"
            fixture_line += f" (score {entry['google_style_score']}: {reasons})"
        lines.append(fixture_line)

    return "\n".join(lines) + "\n"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check the selected attached HTML fixtures and surface safe selectors "
            "before starting the localhost attached-pages catalog."
        )
    )
    parser.add_argument("--input", action="append", dest="explicit_inputs")
    parser.add_argument("--repo-root", help="Override the Lightpanda repo root.")
    parser.add_argument(
        "--google-style",
        action="store_true",
        help="Prefer the strongest Google-like attached page first when auto-discovering fixtures.",
    )
    parser.add_argument(
        "--preferred-initial-page",
        help="Leaf name, relative selector, or absolute path to resolve before replay.",
    )
    parser.add_argument(
        "--allow-duplicate-leafs",
        action="store_true",
        help="Return success even when multiple selected fixtures share the same leaf filename.",
    )
    parser.add_argument("--json", action="store_true", help="Emit structured JSON.")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    explicit_repo_root = Path(args.repo_root) if args.repo_root else None
    repo_root = resolve_repo_root(Path(__file__), explicit_root=explicit_repo_root)
    selected = select_attached_html_inputs(
        repo_root,
        explicit_inputs=args.explicit_inputs,
        google_style=args.google_style,
    )
    report = build_report(
        selected,
        repo_root=repo_root,
        google_style=args.google_style,
        preferred_selector=args.preferred_initial_page,
    )

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(render_text_report(report), end="")

    if report["duplicate_leaf_names"] and not args.allow_duplicate_leafs:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
