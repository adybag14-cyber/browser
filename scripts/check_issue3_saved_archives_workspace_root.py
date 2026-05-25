#!/usr/bin/env python3

"""Surface the saved issue #3 archive root from nested or restored checkouts.

This helper gives Linux/WSL re-entry runs one small place to answer:
- where the saved `repo_archives/browser` root is
- whether the `dependencies/` normalization should be applied
- whether the required saved archives are actually present

It is intentionally narrower than the broader build-readiness helper so future
runs can use it as a preflight before rebuilding explicit `--saved-archives-root`
overrides by hand.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import tempfile
import unittest


SAVED_ARCHIVE_GLOBS: dict[str, str] = {
    "rust_toolchain": "01-rust-*.tar.xz",
    "html5ever": "02-litefetch-html5ever-*.zip",
    "boringssl": "03-boringssl-zig-main.zip",
    "browser_deps": "04-zig-browser-depo.tar.zip",
}
SAVED_ARCHIVE_LABELS: dict[str, str] = {
    "rust_toolchain": "saved Rust toolchain archive",
    "html5ever": "saved html5ever dependency archive",
    "boringssl": "saved BoringSSL archive",
    "browser_deps": "saved browser dependency archive",
}
REQUIRED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")
OPTIONAL_ARCHIVE_KEYS = ("html5ever",)


def ancestor_chain(start: pathlib.Path) -> list[pathlib.Path]:
    chain: list[pathlib.Path] = []
    current = start.resolve()
    while True:
        chain.append(current)
        if current.parent == current:
            break
        current = current.parent
    return chain


def locate_first_existing(start: pathlib.Path, relative_path: str) -> pathlib.Path | None:
    for ancestor in ancestor_chain(start):
        candidate = ancestor / relative_path
        if candidate.exists():
            return candidate.resolve()
    return None


def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()


def normalize_saved_archives_root(saved_archives_root: pathlib.Path) -> pathlib.Path:
    dependencies_root = saved_archives_root / "dependencies"
    if dependencies_root.is_dir():
        return dependencies_root.resolve()
    return saved_archives_root.resolve()


def discover_saved_archives(saved_archives_root: pathlib.Path) -> dict[str, pathlib.Path]:
    discovered: dict[str, pathlib.Path] = {}
    for key, pattern in SAVED_ARCHIVE_GLOBS.items():
        matches = sorted(saved_archives_root.glob(pattern))
        if matches:
            discovered[key] = matches[0].resolve()
    return discovered


def check_saved_archives_root(saved_archives_root: pathlib.Path) -> tuple[list[str], dict[str, pathlib.Path]]:
    failures: list[str] = []
    if not saved_archives_root.exists():
        failures.append(f"saved archive root is missing: expected {saved_archives_root}")
        return failures, {}
    if not saved_archives_root.is_dir():
        failures.append(f"saved archive root is not a directory: {saved_archives_root}")
        return failures, {}

    discovered = discover_saved_archives(saved_archives_root)
    for key in REQUIRED_ARCHIVE_KEYS:
        if key in discovered:
            continue
        failures.append(
            f"missing {SAVED_ARCHIVE_LABELS[key]} under {saved_archives_root} "
            f"(expected {SAVED_ARCHIVE_GLOBS[key]})"
        )
    return failures, discovered


def serialize_value(value: object) -> object:
    if isinstance(value, pathlib.Path):
        return str(value)
    if isinstance(value, dict):
        return {str(key): serialize_value(inner) for key, inner in value.items()}
    if isinstance(value, (list, tuple)):
        return [serialize_value(item) for item in value]
    return value


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Discover and validate the saved issue #3 archive root for nested or restored checkouts."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help=(
            "Optional explicit saved archive root. Either repo_archives/browser or "
            "repo_archives/browser/dependencies is accepted."
        ),
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the report as JSON instead of the human-readable summary.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit.",
    )
    return parser


class SavedArchivesWorkspaceRootTests(unittest.TestCase):
    def test_default_root_uses_repo_parent_when_workspace_is_flat(self) -> None:
        repo_root = pathlib.Path("/tmp/workspace/browser")
        expected = pathlib.Path("/tmp/workspace/memory/repo_archives/browser")
        self.assertEqual(resolve_default_saved_archives_root(repo_root), expected)

    def test_default_root_discovers_ancestor_memory_workspace(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = pathlib.Path(tmpdir)
            repo_root = workspace_root / "restored" / "browser-memory-snapshot" / "browser"
            memory_root = workspace_root / "memory" / "repo_archives" / "browser"
            repo_root.mkdir(parents=True)
            memory_root.mkdir(parents=True)
            self.assertEqual(resolve_default_saved_archives_root(repo_root), memory_root.resolve())

    def test_normalization_prefers_dependencies_subdirectory(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir) / "memory" / "repo_archives" / "browser"
            deps = root / "dependencies"
            deps.mkdir(parents=True)
            self.assertEqual(normalize_saved_archives_root(root), deps.resolve())

    def test_check_saved_archives_root_accepts_dependencies_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            deps_root = pathlib.Path(tmpdir) / "repo_archives" / "browser" / "dependencies"
            deps_root.mkdir(parents=True)
            (deps_root / "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz").write_text("rust", encoding="utf-8")
            (deps_root / "03-boringssl-zig-main.zip").write_text("boringssl", encoding="utf-8")
            (deps_root / "04-zig-browser-depo.tar.zip").write_text("browser-deps", encoding="utf-8")

            failures, discovered = check_saved_archives_root(deps_root)

            self.assertEqual(failures, [])
            self.assertIn("rust_toolchain", discovered)
            self.assertIn("boringssl", discovered)
            self.assertIn("browser_deps", discovered)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedArchivesWorkspaceRootTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    requested_root = pathlib.Path(args.saved_archives_root).resolve() if args.saved_archives_root else None
    discovered_root = requested_root if requested_root is not None else resolve_default_saved_archives_root(repo_root)
    normalized_root = normalize_saved_archives_root(discovered_root)
    failures, discovered_archives = check_saved_archives_root(normalized_root)

    next_step = None
    if failures:
        next_step = (
            "Use the surfaced repo_archives/browser root from the nearest workspace memory folder, "
            "or pass --saved-archives-root explicitly if this checkout lives outside the normal workspace layout."
        )

    report = {
        "status": "failed" if failures else "passed",
        "repo_root": repo_root,
        "requested_saved_archives_root": requested_root,
        "discovered_saved_archives_root": discovered_root,
        "normalized_saved_archives_root": normalized_root,
        "saved_archives": discovered_archives,
        "failures": failures,
        "suggested_next_step": next_step,
    }

    if args.json:
        print(json.dumps(serialize_value(report), indent=2))
        return 1 if failures else 0

    print(f"Repo root: {repo_root}")
    if requested_root is not None:
        print(f"Requested saved archive root: {requested_root}")
    print(f"Discovered saved archive root: {discovered_root}")
    print(f"Normalized saved archive root: {normalized_root}")
    for key in (*REQUIRED_ARCHIVE_KEYS, *OPTIONAL_ARCHIVE_KEYS):
        archive_path = discovered_archives.get(key)
        state = (
            "ok"
            if archive_path is not None
            else "optional missing"
            if key in OPTIONAL_ARCHIVE_KEYS
            else "missing"
        )
        location = str(archive_path) if archive_path is not None else SAVED_ARCHIVE_GLOBS[key]
        print(f"  - {SAVED_ARCHIVE_LABELS[key]}: {location} [{state}]")

    if failures:
        print("\nSaved archive discovery failed:")
        for failure in failures:
            print(f"  - {failure}")
        print(f"\nSuggested next step: {next_step}")
        return 1

    print("\nSaved archive discovery passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
