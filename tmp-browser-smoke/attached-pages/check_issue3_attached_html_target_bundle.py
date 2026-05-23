import argparse
import json
import os
from pathlib import Path


EXPECTED_BUNDLE_FILES = (
    "Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html",
    "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html",
    "Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html",
)
HTML_EXTENSIONS = {".html", ".htm"}


def resolve_repo_root(start_path: Path, explicit_root: Path | None = None) -> Path:
    if explicit_root is not None:
        return explicit_root.expanduser().resolve()

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
            return start_path.expanduser().resolve()
        cursor = parent


def collect_html_files(root: Path) -> list[Path]:
    if root.is_file():
        return [root] if root.suffix.lower() in HTML_EXTENSIONS else []
    if not root.is_dir():
        return []
    return sorted(
        path for path in root.rglob("*") if path.is_file() and path.suffix.lower() in HTML_EXTENSIONS
    )


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


def append_context_roots(roots: list[Path], start: Path) -> None:
    cursor = start.expanduser().resolve()
    if cursor.is_file():
        cursor = cursor.parent

    while True:
        roots.append(cursor / "agent_files")
        roots.append(cursor / "user_files")
        parent = cursor.parent
        if parent == cursor:
            break
        cursor = parent


def discover_candidate_roots(repo_root: Path, cwd: Path | None = None) -> list[Path]:
    roots: list[Path] = []
    append_context_roots(roots, repo_root)
    append_context_roots(roots, (cwd or Path.cwd()).resolve())
    unique = dedupe_paths(roots)
    return [path for path in unique if path.is_dir()]


def build_bundle_report(html_files: list[Path], bundle_root: Path, preferred_initial_page: str | None) -> dict[str, object]:
    expected = set(EXPECTED_BUNDLE_FILES)
    detected_names = sorted(path.name for path in html_files)
    detected_set = set(detected_names)
    missing = sorted(expected - detected_set)
    unexpected = sorted(detected_set - expected)

    preferred_present = None
    if preferred_initial_page:
        preferred_present = preferred_initial_page in detected_set

    return {
        "bundle_root": str(bundle_root),
        "fixture_count": len(html_files),
        "expected_file_names": list(EXPECTED_BUNDLE_FILES),
        "detected_file_names": detected_names,
        "missing_expected_files": missing,
        "unexpected_html_files": unexpected,
        "preferred_initial_page": preferred_initial_page,
        "preferred_initial_page_present": preferred_present,
        "exact_bundle_match": not missing and not unexpected,
    }


def select_best_candidate_root(candidate_roots: list[Path]) -> tuple[Path, list[Path]]:
    ranked: list[tuple[int, int, str, Path, list[Path]]] = []
    expected = set(EXPECTED_BUNDLE_FILES)
    for root in candidate_roots:
        html_files = collect_html_files(root)
        if not html_files:
            continue
        names = {path.name for path in html_files}
        matched = len(names & expected)
        extras = len(names - expected)
        ranked.append((-matched, extras, str(root), root, html_files))

    if not ranked:
        raise FileNotFoundError("could not find any attached HTML candidate roots")

    ranked.sort()
    _, _, _, root, html_files = ranked[0]
    return root, html_files


def run_self_test() -> None:
    expected = set(EXPECTED_BUNDLE_FILES)
    assert len(expected) == 3
    assert any("Google Safety Centre" in name for name in expected)
    assert any("Anthropic" in name for name in expected)
    assert any("UAP Encounters" in name for name in expected)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check whether the pinned issue #3 attached HTML target bundle is present."
    )
    parser.add_argument("--repo-root", type=Path, default=None)
    parser.add_argument("--input", action="append", default=[])
    parser.add_argument("--preferred-initial-page", default=EXPECTED_BUNDLE_FILES[0])
    parser.add_argument("--allow-extra-files", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        run_self_test()
        if not args.json:
            print("self-test: ok")
        return 0

    repo_root = resolve_repo_root(Path(__file__), args.repo_root)

    if args.input:
        input_paths = dedupe_paths([Path(value) for value in args.input])
        html_files: list[Path] = []
        bundle_root = input_paths[0] if len(input_paths) == 1 else Path(os.path.commonpath([str(p) for p in input_paths]))
        for path in input_paths:
            html_files.extend(collect_html_files(path))
        html_files = dedupe_paths(html_files)
        if not html_files:
            raise FileNotFoundError("explicit inputs did not resolve to any attached HTML files")
    else:
        bundle_root, html_files = select_best_candidate_root(discover_candidate_roots(repo_root))

    report = build_bundle_report(html_files, bundle_root, args.preferred_initial_page)
    success = not report["missing_expected_files"] and (
        args.allow_extra_files or not report["unexpected_html_files"]
    )

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print("Issue #3 attached HTML target bundle check")
        print(f"Bundle root: {report['bundle_root']}")
        print(f"Fixture count: {report['fixture_count']}")
        print("Expected files:")
        for name in report["expected_file_names"]:
            print(f"  - {name}")
        if report["missing_expected_files"]:
            print("Missing expected files:")
            for name in report["missing_expected_files"]:
                print(f"  - {name}")
        if report["unexpected_html_files"]:
            print("Unexpected HTML files:")
            for name in report["unexpected_html_files"]:
                print(f"  - {name}")
        if report["preferred_initial_page"]:
            status = "present" if report["preferred_initial_page_present"] else "missing"
            print(f"Preferred initial page: {report['preferred_initial_page']} ({status})")
        if success:
            print("Result: pinned compatibility bundle is ready.")
        else:
            print("Result: pinned compatibility bundle is incomplete.")

    return 0 if success else 1


if __name__ == "__main__":
    raise SystemExit(main())
