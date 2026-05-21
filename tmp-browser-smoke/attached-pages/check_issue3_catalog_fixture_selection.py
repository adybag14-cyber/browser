#!/usr/bin/env python3
"""Regression checks for attached-pages catalog fixture selection."""

from __future__ import annotations

import argparse
import importlib.util
import os
import tempfile
from pathlib import Path
from types import ModuleType


PASS_MARKER = "ISSUE3_ATTACHED_PAGES_CATALOG_FIXTURE_SELECTION_SELF_TEST=pass"
COUNT_MARKER = "ISSUE3_ATTACHED_PAGES_CATALOG_FIXTURE_SELECTION_CASE_COUNT={count}"


def resolve_repo_root(start_path: Path, explicit_root: Path | None = None) -> Path:
    if explicit_root is not None:
        root = explicit_root.expanduser().resolve()
        if (root / "build.zig").is_file():
            return root
        raise FileNotFoundError(
            f"explicit repo root does not look like a Lightpanda checkout: {root}"
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
            raise FileNotFoundError(
                f"could not resolve the Lightpanda repo root from {start_path}"
            )
        cursor = parent


def load_catalog_module(repo_root: Path) -> ModuleType:
    module_path = repo_root / "tmp-browser-smoke" / "attached-pages" / "start_attached_pages_catalog.py"
    if not module_path.is_file():
        raise FileNotFoundError(f"attached pages catalog helper not found: {module_path}")

    spec = importlib.util.spec_from_file_location("start_attached_pages_catalog", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"could not load module from {module_path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def write_html(path: Path, title: str, body: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        f"<html><head><title>{title}</title></head><body>{body}</body></html>",
        encoding="utf-8",
    )
    return path


def assert_equal(actual, expected, message: str) -> None:
    if actual != expected:
        raise AssertionError(f"{message}: expected {expected!r}, got {actual!r}")


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def test_google_style_prefers_search_fixture(module: ModuleType) -> None:
    with tempfile.TemporaryDirectory(prefix="issue3-catalog-google-style-") as tmpdir:
        repo_root = Path(tmpdir) / "repo"
        repo_root.mkdir(parents=True, exist_ok=True)
        (repo_root / "build.zig").write_text("", encoding="utf-8")

        inputs = repo_root / "user_files" / "bundle"
        search = write_html(
            inputs / "Google Search Home.html",
            "Google Search",
            "<form action='/search'><input name='q' aria-label='Search'></form>",
        )
        marketing = write_html(
            inputs / "Google Safety Centre.html",
            "Google Safety Centre",
            "<p>Google Safety Centre privacy policy</p>",
        )
        other = write_html(
            inputs / "Anthropic Role.html",
            "Anthropic Role",
            "<main>job application</main>",
        )

        selected = module.select_attached_html_inputs(
            repo_root,
            google_style=True,
            cwd=repo_root,
        )

        assert_equal(selected[0], search.resolve(), "google-style should prefer search-like export first")
        assert_true(marketing.resolve() not in selected, "google-style should filter out marketing-like exports when a search page exists")
        assert_true(other.resolve() not in selected, "google-style should stay on Google-like exports when a search page exists")


def test_preferred_initial_page_reorders_explicit_inputs(module: ModuleType) -> None:
    with tempfile.TemporaryDirectory(prefix="issue3-catalog-preferred-page-") as tmpdir:
        repo_root = Path(tmpdir) / "repo"
        repo_root.mkdir(parents=True, exist_ok=True)
        (repo_root / "build.zig").write_text("", encoding="utf-8")

        bundle = repo_root / "user_files" / "bundle"
        first = write_html(bundle / "alpha.html", "Alpha", "<p>alpha</p>")
        preferred = write_html(bundle / "preferred.html", "Preferred", "<p>preferred</p>")
        write_html(bundle / "zeta.html", "Zeta", "<p>zeta</p>")

        selected = module.select_attached_html_inputs(
            repo_root,
            explicit_inputs=[str(bundle)],
            preferred_initial_page="preferred.html",
            cwd=repo_root,
        )

        assert_equal(selected[0], preferred.resolve(), "preferred page should be moved to the front")
        assert_true(first.resolve() in selected, "explicit bundle should still include the non-preferred page")


def test_explicit_inputs_dedupe_directory_and_file(module: ModuleType) -> None:
    with tempfile.TemporaryDirectory(prefix="issue3-catalog-dedupe-") as tmpdir:
        repo_root = Path(tmpdir) / "repo"
        repo_root.mkdir(parents=True, exist_ok=True)
        (repo_root / "build.zig").write_text("", encoding="utf-8")

        bundle = repo_root / "user_files" / "bundle"
        first = write_html(bundle / "alpha.html", "Alpha", "<p>alpha</p>")
        second = write_html(bundle / "beta.html", "Beta", "<p>beta</p>")

        selected = module.select_attached_html_inputs(
            repo_root,
            explicit_inputs=[str(bundle), str(first), str(second)],
            cwd=repo_root,
        )

        assert_equal(len(selected), 2, "explicit inputs should dedupe overlapping directory and file entries")
        assert_equal(selected[0], first.resolve(), "deduped selection should preserve sorted bundle order")
        assert_equal(selected[1], second.resolve(), "deduped selection should keep the second unique file")


def test_discovery_sees_repo_and_workspace_attachment_roots(module: ModuleType) -> None:
    with tempfile.TemporaryDirectory(prefix="issue3-catalog-discovery-") as tmpdir:
        workspace_root = Path(tmpdir) / "workspace"
        repo_root = workspace_root / "repo"
        repo_root.mkdir(parents=True, exist_ok=True)
        (repo_root / "build.zig").write_text("", encoding="utf-8")

        repo_user = write_html(repo_root / "user_files" / "repo-user.html", "Repo User", "<p>repo-user</p>")
        repo_agent = write_html(repo_root / "agent_files" / "repo-agent.html", "Repo Agent", "<p>repo-agent</p>")
        workspace_user = write_html(workspace_root / "user_files" / "workspace-user.html", "Workspace User", "<p>workspace-user</p>")
        workspace_agent = write_html(workspace_root / "agent_files" / "workspace-agent.html", "Workspace Agent", "<p>workspace-agent</p>")

        selected = module.select_attached_html_inputs(
            repo_root,
            cwd=workspace_root,
        )

        selected_set = {path.resolve() for path in selected}
        expected = {
            repo_user.resolve(),
            repo_agent.resolve(),
            workspace_user.resolve(),
            workspace_agent.resolve(),
        }
        assert_true(expected.issubset(selected_set), "discovery should include repo and workspace attachment roots")


def run_self_test(repo_root: Path) -> int:
    module = load_catalog_module(repo_root)
    cases = [
        test_google_style_prefers_search_fixture,
        test_preferred_initial_page_reorders_explicit_inputs,
        test_explicit_inputs_dedupe_directory_and_file,
        test_discovery_sees_repo_and_workspace_attachment_roots,
    ]
    for case in cases:
        case(module)

    print(PASS_MARKER)
    print(COUNT_MARKER.format(count=len(cases)))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Regression checks for issue #3 attached-pages catalog fixture selection."
    )
    parser.add_argument(
        "--repo-root",
        default="",
        help="Path to the Lightpanda repo root. Defaults to auto-discovery.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run the standalone regression self-test suite.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    repo_root = resolve_repo_root(
        Path(__file__),
        Path(args.repo_root) if args.repo_root else None,
    )

    if args.self_test:
        return run_self_test(repo_root)

    parser.error("choose --self-test")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
