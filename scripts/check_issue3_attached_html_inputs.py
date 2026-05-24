#!/usr/bin/env python3

"""Check the attached HTML validation inputs for the headed issue #3 route.

This helper gives scheduled and manual runs a quick preflight before trying to
serve or replay the attached compatibility pages. It verifies that the expected
HTML inputs are present beside the workspace, reports their sizes and digests,
and fails early when the attached-page set is incomplete.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest


DEFAULT_MIN_COUNT = 3
HTML_SUFFIX = ".html"
REQUIRED_REPO_ROOT_FILE = "build.zig.zon"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the attached HTML pages used for headed issue #3 "
            "compatibility replay are present before local validation work."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help="Path to the attached builder file directory (default: ../agent_files beside the repo root)",
    )
    parser.add_argument(
        "--page",
        action="append",
        default=[],
        help=(
            "Specific attached HTML filename or path to require. May be passed "
            "multiple times. When omitted, all .html files under agent_files "
            "are discovered automatically."
        ),
    )
    parser.add_argument(
        "--require-name-substring",
        action="append",
        default=[],
        help=(
            "Require at least one discovered page name to contain this "
            "substring. May be passed multiple times."
        ),
    )
    parser.add_argument(
        "--min-count",
        type=int,
        default=DEFAULT_MIN_COUNT,
        help=f"Minimum number of attached HTML files required (default: {DEFAULT_MIN_COUNT})",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    return (repo_root.parent / "agent_files").resolve()


def file_digest(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def resolve_page_argument(raw_value: str, agent_files_root: Path) -> Path:
    candidate = Path(raw_value)
    if candidate.is_absolute():
        return candidate
    if candidate.exists():
        return candidate.resolve()
    return (agent_files_root / raw_value).resolve()


def collect_page_entry(path: Path) -> dict[str, object]:
    exists = path.is_file()
    return {
        "name": path.name,
        "path": str(path),
        "exists": exists,
        "size_bytes": path.stat().st_size if exists else None,
        "sha256": file_digest(path) if exists else None,
    }


def discover_pages(agent_files_root: Path) -> list[Path]:
    if not agent_files_root.is_dir():
        return []
    return sorted(
        path.resolve()
        for path in agent_files_root.iterdir()
        if path.is_file() and path.suffix.lower() == HTML_SUFFIX
    )


def collect_results(
    *,
    repo_root: Path,
    agent_files_root: Path,
    page_args: list[str],
    required_name_substrings: list[str],
    min_count: int,
) -> dict[str, object]:
    repo_root_exists = repo_root.is_dir()
    repo_root_manifest = repo_root / REQUIRED_REPO_ROOT_FILE
    repo_root_ready = repo_root_exists and repo_root_manifest.is_file()

    discovered_paths = (
        [resolve_page_argument(value, agent_files_root) for value in page_args]
        if page_args
        else discover_pages(agent_files_root)
    )
    pages = [collect_page_entry(path) for path in discovered_paths]
    missing_pages = [entry["path"] for entry in pages if not entry["exists"]]

    discovered_names = [entry["name"] for entry in pages if entry["exists"]]
    substring_matches = []
    missing_substrings = []
    for substring in required_name_substrings:
        matches = [name for name in discovered_names if substring in name]
        substring_matches.append({"substring": substring, "matches": matches})
        if not matches:
            missing_substrings.append(substring)

    found_count = sum(1 for entry in pages if entry["exists"])
    meets_min_count = found_count >= min_count
    ok = (
        repo_root_ready
        and agent_files_root.is_dir()
        and not missing_pages
        and meets_min_count
        and not missing_substrings
    )

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "repo_root_ready": repo_root_ready,
        "repo_root_manifest": str(repo_root_manifest),
        "agent_files_root": str(agent_files_root),
        "agent_files_root_exists": agent_files_root.is_dir(),
        "page_mode": "explicit" if page_args else "auto-discovery",
        "min_count": min_count,
        "found_count": found_count,
        "meets_min_count": meets_min_count,
        "pages": pages,
        "missing_pages": missing_pages,
        "required_name_substrings": required_name_substrings,
        "substring_matches": substring_matches,
        "missing_substrings": missing_substrings,
    }


def emit_text(result: dict[str, object]) -> None:
    repo_status = "PASS" if result["repo_root_ready"] else "FAIL"
    agent_files_status = "PASS" if result["agent_files_root_exists"] else "FAIL"
    count_status = "PASS" if result["meets_min_count"] else "FAIL"
    print(f"Browser checkout root: [{repo_status}] {result['repo_root']}")
    if not result["repo_root_ready"]:
        print(f"         expected manifest: {result['repo_root_manifest']}")
    print(f"Attached files root:   [{agent_files_status}] {result['agent_files_root']}")
    print(f"Discovery mode:        {result['page_mode']}")
    print(
        f"Attached HTML count:   [{count_status}] "
        f"{result['found_count']} found; need at least {result['min_count']}"
    )
    print("Attached HTML files:")
    for entry in result["pages"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['name']}: {entry['path']}")
        if entry["exists"]:
            print(
                f"         size={entry['size_bytes']} sha256={entry['sha256']}"
            )
    if result["required_name_substrings"]:
        print("Required name substrings:")
        for entry in result["substring_matches"]:
            status = "PASS" if entry["matches"] else "FAIL"
            matches = ", ".join(entry["matches"]) if entry["matches"] else "none"
            print(f"  [{status}] {entry['substring']}: {matches}")
    if result["ok"]:
        print("\nAttached HTML input check passed.")
    else:
        print("\nAttached HTML input check failed.", file=sys.stderr)
        print(
            "Suggested next step: remount or restore the attached HTML pages "
            "under agent_files, then rerun this helper before local headed replay.",
            file=sys.stderr,
        )


class AttachedHtmlInputsTests(unittest.TestCase):
    def build_fixture(self) -> tuple[Path, Path]:
        root = Path(tempfile.mkdtemp(prefix="lightpanda-attached-html-inputs-"))
        repo_root = root / "browser"
        agent_files_root = root / "agent_files"
        repo_root.mkdir()
        agent_files_root.mkdir()
        (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
        return repo_root, agent_files_root

    def test_auto_discovery_passes_with_three_html_files(self) -> None:
        repo_root, agent_files_root = self.build_fixture()
        for name in ("alpha.html", "beta.html", "gamma.html"):
            (agent_files_root / name).write_text(f"<html>{name}</html>", encoding="utf-8")

        result = collect_results(
            repo_root=repo_root,
            agent_files_root=agent_files_root,
            page_args=[],
            required_name_substrings=[],
            min_count=3,
        )

        self.assertTrue(result["ok"])
        self.assertEqual(result["page_mode"], "auto-discovery")
        self.assertEqual(result["found_count"], 3)

    def test_explicit_page_mode_fails_when_a_page_is_missing(self) -> None:
        repo_root, agent_files_root = self.build_fixture()
        (agent_files_root / "present.html").write_text("<html>present</html>", encoding="utf-8")

        result = collect_results(
            repo_root=repo_root,
            agent_files_root=agent_files_root,
            page_args=["present.html", "missing.html"],
            required_name_substrings=[],
            min_count=2,
        )

        self.assertFalse(result["ok"])
        self.assertEqual(result["page_mode"], "explicit")
        self.assertEqual(len(result["missing_pages"]), 1)
        self.assertTrue(result["missing_pages"][0].endswith("missing.html"))

    def test_required_name_substrings_must_match_discovered_files(self) -> None:
        repo_root, agent_files_root = self.build_fixture()
        for name in (
            "Control your online safety and privacy.html",
            "Job Application.html",
            "Presidential Unsealing.html",
        ):
            (agent_files_root / name).write_text(f"<html>{name}</html>", encoding="utf-8")

        result = collect_results(
            repo_root=repo_root,
            agent_files_root=agent_files_root,
            page_args=[],
            required_name_substrings=["privacy", "Application", "Missing"],
            min_count=3,
        )

        self.assertFalse(result["ok"])
        self.assertEqual(result["missing_substrings"], ["Missing"])
        self.assertEqual(len(result["substring_matches"]), 3)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(AttachedHtmlInputsTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    agent_files_root = (
        Path(args.agent_files_root).resolve()
        if args.agent_files_root
        else resolve_default_agent_files_root(repo_root)
    )
    result = collect_results(
        repo_root=repo_root,
        agent_files_root=agent_files_root,
        page_args=args.page,
        required_name_substrings=args.require_name_substring,
        min_count=args.min_count,
    )
    if args.json:
        print(json.dumps({"profile": "issue3-attached-html-inputs", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())