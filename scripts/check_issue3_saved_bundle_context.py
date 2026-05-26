#!/usr/bin/env python3

"""Surface the saved issue #3 bundle context used by the Linux/WSL re-entry lane."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shlex
import sys
import tempfile
import unittest


BUNDLE_FILE_NAMES: dict[str, tuple[str, str]] = {
    "repo_snapshot": ("01-browser-fork-headed-mode-foundation.zip", "saved browser repo snapshot"),
    "readme": ("README.md", "saved browser README"),
    "blocker_intelligence": ("blocker_intelligence.yaml", "blocker intelligence record"),
    "session_register": ("session_entry_register.yaml", "session entry register"),
}

DEPENDENCY_ARCHIVE_PATTERNS: dict[str, tuple[str, str]] = {
    "rust_toolchain": ("01-rust-*.tar.xz", "saved Rust toolchain archive"),
    "html5ever": ("02-litefetch-html5ever-*.zip", "saved html5ever dependency archive"),
    "boringssl": ("03-boringssl-zig-main.zip", "saved BoringSSL archive"),
    "browser_deps": ("04-zig-browser-depo.tar.zip", "saved browser dependency archive"),
}

REQUIRED_BUNDLE_KEYS = tuple(BUNDLE_FILE_NAMES.keys())
REQUIRED_DEPENDENCY_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")


def ancestor_chain(start: Path) -> list[Path]:
    chain: list[Path] = []
    current = start.resolve()
    while True:
        chain.append(current)
        if current.parent == current:
            break
        current = current.parent
    return chain


def locate_first_existing(start: Path, relative_path: str) -> Path | None:
    for ancestor in ancestor_chain(start):
        candidate = ancestor / relative_path
        if candidate.exists():
            return candidate.resolve()
    return None


def normalize_saved_bundle_root(saved_bundle_root: Path) -> Path:
    resolved = saved_bundle_root.resolve()
    if resolved.name == "dependencies" and resolved.parent.is_dir():
        return resolved.parent
    return resolved


def resolve_default_saved_bundle_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        return normalize_saved_bundle_root(located)
    return normalize_saved_bundle_root(repo_root.parent / "memory" / "repo_archives" / "browser")


def discover_bundle_files(saved_bundle_root: Path) -> dict[str, Path]:
    discovered: dict[str, Path] = {}
    for key, (filename, _) in BUNDLE_FILE_NAMES.items():
        candidate = saved_bundle_root / filename
        if candidate.is_file():
            discovered[key] = candidate.resolve()
    return discovered


def discover_dependency_archives(dependencies_root: Path) -> dict[str, Path]:
    discovered: dict[str, Path] = {}
    if not dependencies_root.is_dir():
        return discovered
    for key, (pattern, _) in DEPENDENCY_ARCHIVE_PATTERNS.items():
        matches = sorted(dependencies_root.glob(pattern))
        if matches:
            discovered[key] = matches[0].resolve()
    return discovered


def format_shell_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def collect_saved_bundle_context(
    repo_root: Path,
    saved_bundle_root: Path,
) -> dict[str, object]:
    failures: list[str] = []

    if not saved_bundle_root.exists():
        failures.append(f"saved bundle root is missing: expected {saved_bundle_root}")
        return {
            "status": "failed",
            "repo_root": repo_root,
            "saved_bundle_root": saved_bundle_root,
            "dependencies_root": saved_bundle_root / "dependencies",
            "bundle_files": {},
            "dependency_archives": {},
            "failures": failures,
            "suggested_build_readiness_command": None,
        }
    if not saved_bundle_root.is_dir():
        failures.append(f"saved bundle root is not a directory: {saved_bundle_root}")
        return {
            "status": "failed",
            "repo_root": repo_root,
            "saved_bundle_root": saved_bundle_root,
            "dependencies_root": saved_bundle_root / "dependencies",
            "bundle_files": {},
            "dependency_archives": {},
            "failures": failures,
            "suggested_build_readiness_command": None,
        }

    dependencies_root = (saved_bundle_root / "dependencies").resolve()
    if not dependencies_root.is_dir():
        failures.append(f"dependency archive root is missing: expected {dependencies_root}")

    bundle_files = discover_bundle_files(saved_bundle_root)
    for key in REQUIRED_BUNDLE_KEYS:
        if key not in bundle_files:
            filename, label = BUNDLE_FILE_NAMES[key]
            failures.append(f"missing {label} under {saved_bundle_root} (expected {filename})")

    dependency_archives = discover_dependency_archives(dependencies_root)
    for key in REQUIRED_DEPENDENCY_ARCHIVE_KEYS:
        if key not in dependency_archives:
            pattern, label = DEPENDENCY_ARCHIVE_PATTERNS[key]
            failures.append(f"missing {label} under {dependencies_root} (expected {pattern})")

    suggested_build_readiness_command = [
        "python",
        "scripts/check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
        "--expect-saved-archives",
        "--saved-archives-root",
        str(saved_bundle_root),
    ]

    return {
        "status": "failed" if failures else "passed",
        "repo_root": repo_root,
        "saved_bundle_root": saved_bundle_root,
        "dependencies_root": dependencies_root,
        "bundle_files": bundle_files,
        "dependency_archives": dependency_archives,
        "failures": failures,
        "suggested_build_readiness_command": suggested_build_readiness_command,
    }


def serialize(value: object) -> object:
    if isinstance(value, Path):
        return str(value)
    if isinstance(value, dict):
        return {str(key): serialize(inner) for key, inner in value.items()}
    if isinstance(value, list):
        return [serialize(item) for item in value]
    return value


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Surface the saved repo snapshot, companion Memory records, and dependency "
            "bundle roots used by the issue #11 Linux/WSL re-entry lane."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--saved-bundle-root",
        default=None,
        help=(
            "Path to memory/repo_archives/browser or its dependencies subdirectory "
            "(default: nearest ancestor memory/repo_archives/browser root)"
        ),
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class SavedBundleContextTests(unittest.TestCase):
    def test_normalize_saved_bundle_root_accepts_dependencies_subdir(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            bundle_root = Path(tmpdir) / "memory" / "repo_archives" / "browser"
            dependencies_root = bundle_root / "dependencies"
            dependencies_root.mkdir(parents=True)

            self.assertEqual(
                normalize_saved_bundle_root(dependencies_root),
                bundle_root.resolve(),
            )

    def test_collect_context_reports_required_bundle_and_dependency_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            bundle_root = root / "memory" / "repo_archives" / "browser"
            dependencies_root = bundle_root / "dependencies"
            dependencies_root.mkdir(parents=True)

            for filename, _ in BUNDLE_FILE_NAMES.values():
                (bundle_root / filename).write_text(filename, encoding="utf-8")
            (dependencies_root / "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz").write_text("rust", encoding="utf-8")
            (dependencies_root / "02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip").write_text(
                "html5ever",
                encoding="utf-8",
            )
            (dependencies_root / "03-boringssl-zig-main.zip").write_text("boringssl", encoding="utf-8")
            (dependencies_root / "04-zig-browser-depo.tar.zip").write_text("browser-deps", encoding="utf-8")

            result = collect_saved_bundle_context(repo_root.resolve(), bundle_root.resolve())

            self.assertEqual(result["status"], "passed")
            self.assertEqual(result["failures"], [])
            self.assertIn("repo_snapshot", result["bundle_files"])
            self.assertIn("browser_deps", result["dependency_archives"])

    def test_collect_context_flags_missing_readme_and_blocker(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            bundle_root = root / "memory" / "repo_archives" / "browser"
            dependencies_root = bundle_root / "dependencies"
            dependencies_root.mkdir(parents=True)

            (bundle_root / "01-browser-fork-headed-mode-foundation.zip").write_text("zip", encoding="utf-8")
            (bundle_root / "session_entry_register.yaml").write_text("run_entries: []\n", encoding="utf-8")
            (dependencies_root / "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz").write_text("rust", encoding="utf-8")
            (dependencies_root / "03-boringssl-zig-main.zip").write_text("boringssl", encoding="utf-8")
            (dependencies_root / "04-zig-browser-depo.tar.zip").write_text("browser-deps", encoding="utf-8")

            result = collect_saved_bundle_context(repo_root.resolve(), bundle_root.resolve())

            self.assertEqual(result["status"], "failed")
            failures = result["failures"]
            self.assertTrue(any("saved browser README" in failure for failure in failures))
            self.assertTrue(any("blocker intelligence record" in failure for failure in failures))


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedBundleContextTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    saved_bundle_root = (
        normalize_saved_bundle_root(Path(args.saved_bundle_root))
        if args.saved_bundle_root
        else resolve_default_saved_bundle_root(repo_root)
    )
    report = collect_saved_bundle_context(repo_root, saved_bundle_root)

    if args.json:
        print(json.dumps(serialize(report), indent=2))
        return 1 if report["failures"] else 0

    print(f"Repo root: {repo_root}")
    print(f"Saved bundle root: {report['saved_bundle_root']}")
    print(f"Dependency archive root: {report['dependencies_root']}")

    print("Bundle files:")
    bundle_files = report["bundle_files"]
    for key in REQUIRED_BUNDLE_KEYS:
        filename, label = BUNDLE_FILE_NAMES[key]
        path = bundle_files.get(key)
        state = "ok" if path is not None else "missing"
        location = str(path) if path is not None else filename
        print(f"  - {label}: {location} [{state}]")

    print("Dependency archives:")
    dependency_archives = report["dependency_archives"]
    for key, (_, label) in DEPENDENCY_ARCHIVE_PATTERNS.items():
        path = dependency_archives.get(key)
        state = "ok" if path is not None else "optional missing" if key == "html5ever" else "missing"
        location = str(path) if path is not None else DEPENDENCY_ARCHIVE_PATTERNS[key][0]
        print(f"  - {label}: {location} [{state}]")

    suggested_command = report["suggested_build_readiness_command"]
    if suggested_command is not None:
        print("Suggested build-readiness command:")
        print(f"  {format_shell_command(suggested_command)}")

    failures = report["failures"]
    if failures:
        print("\nSaved bundle context check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print("\nSaved bundle context check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())