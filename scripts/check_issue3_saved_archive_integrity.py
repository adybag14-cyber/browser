#!/usr/bin/env python3

"""Verify the saved issue #3 Memory archives by SHA-256.

This helper complements the existing presence-only saved-Memory preflight.
Use it before restore or Linux build-readiness work when the run needs to know
that the saved repo snapshot and dependency bundles are the exact expected
artifacts rather than merely present at the right paths.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest


EXPECTED_MEMORY_ARCHIVES: tuple[tuple[str, str, str], ...] = (
    (
        "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
        "saved repo snapshot",
        "d1ce047d2f9dd5a9dd7c5a661f3f0caeeac0ff51a19bcdb3c9f3104c081babf0",
    ),
    (
        "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
        "saved Rust toolchain archive",
        "ce552d6bf22a2544ea78647d98cb405d5089af58dbcaa4efea711bf8becd71c5",
    ),
    (
        "repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
        "saved html5ever dependency archive",
        "701e646bd43917993a20cd155472c1d122d0ac38d1ee908396beff44add74cea",
    ),
    (
        "repo_archives/browser/dependencies/03-boringssl-zig-main.zip",
        "saved BoringSSL archive",
        "db924bb0a15f31f3a6ff9848f357585ea09b20e80b584cccbd45ab69ffeda564",
    ),
    (
        "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
        "saved browser dependency archive",
        "e4905ad079f421dfc9c116172ab873666afab4eae8afdeed0d00dc8a4c4368f9",
    ),
)

DEFAULT_FALLBACK_ZIG_NAME = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_FALLBACK_ZIG_SHA256 = "f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Verify the exact SHA-256 fingerprints of the saved repo snapshot, "
            "dependency archives, and optional fallback Zig archive used by "
            "the issue #3 restore and build-readiness routes."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Path to the workspace memory root (default: ../memory beside the repo workspace)",
    )
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help="Path to the builder-attached files root (default: ../agent_files beside the repo workspace)",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the fallback Zig archive to verify",
    )
    parser.add_argument(
        "--require-fallback-zig",
        action="store_true",
        help="Fail when the fallback Zig archive is missing or has the wrong checksum",
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


def resolve_default_memory_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory").resolve()


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    return (repo_root.parent / "agent_files").resolve()


def sha256_for_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_entry(path: Path, label: str, expected_sha256: str) -> dict[str, object]:
    exists = path.is_file()
    actual_sha256 = sha256_for_file(path) if exists else None
    matches = exists and actual_sha256 == expected_sha256
    return {
        "label": label,
        "path": str(path),
        "exists": exists,
        "expected_sha256": expected_sha256,
        "actual_sha256": actual_sha256,
        "matches": matches,
    }


def collect_results(
    *,
    repo_root: Path,
    memory_root: Path,
    agent_files_root: Path,
    fallback_zig_archive: Path | None,
    require_fallback_zig: bool,
) -> dict[str, object]:
    archive_entries = [
        build_entry(memory_root / relative_path, label, expected_sha256)
        for relative_path, label, expected_sha256 in EXPECTED_MEMORY_ARCHIVES
    ]
    bad_required = [entry for entry in archive_entries if not entry["matches"]]

    fallback_path = fallback_zig_archive
    if fallback_path is None:
        fallback_path = agent_files_root / DEFAULT_FALLBACK_ZIG_NAME
    fallback_entry = build_entry(
        fallback_path,
        "fallback Zig archive",
        DEFAULT_FALLBACK_ZIG_SHA256,
    )

    fallback_ok = fallback_entry["matches"] or (
        not require_fallback_zig and not fallback_entry["exists"]
    )
    ok = not bad_required and fallback_ok

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "memory_root": str(memory_root),
        "agent_files_root": str(agent_files_root),
        "require_fallback_zig": require_fallback_zig,
        "archive_entries": archive_entries,
        "fallback_zig_archive": fallback_entry,
    }


def status_for(entry: dict[str, object], *, missing_is_warn: bool = False) -> str:
    if entry["matches"]:
        return "PASS"
    if missing_is_warn and not entry["exists"]:
        return "WARN"
    return "FAIL"


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Memory root: {result['memory_root']}")
    print(f"Agent files root: {result['agent_files_root']}")
    print("Saved archive integrity:")
    for entry in result["archive_entries"]:
        status = status_for(entry)
        print(f"  [{status}] {entry['label']}: {entry['path']}")
        print(f"         expected {entry['expected_sha256']}")
        print(f"         actual   {entry['actual_sha256'] or 'missing'}")
    fallback = result["fallback_zig_archive"]
    fallback_status = status_for(
        fallback,
        missing_is_warn=not result["require_fallback_zig"],
    )
    print(f"Fallback Zig archive: [{fallback_status}] {fallback['path']}")
    print(f"         expected {fallback['expected_sha256']}")
    print(f"         actual   {fallback['actual_sha256'] or 'missing'}")
    if result["ok"]:
        print("\nSaved archive integrity check passed.")
    else:
        print("\nSaved archive integrity check failed.", file=sys.stderr)
        print(
            "Suggested next step: refresh the mismatched archive from the saved Memory source before trusting restore, Linux build-readiness, or issue #3 runtime re-entry work.",
            file=sys.stderr,
        )


class SavedArchiveIntegrityTests(unittest.TestCase):
    def test_collect_results_passes_with_matching_archives(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()

            for relative_path, _label, expected_sha256 in EXPECTED_MEMORY_ARCHIVES:
                target = memory_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(expected_sha256, encoding="utf-8")

            fallback_archive = agent_files_root / DEFAULT_FALLBACK_ZIG_NAME
            fallback_archive.write_text(DEFAULT_FALLBACK_ZIG_SHA256, encoding="utf-8")

            original_sha256 = globals()["sha256_for_file"]
            try:
                globals()["sha256_for_file"] = lambda path: path.read_text(encoding="utf-8")
                result = collect_results(
                    repo_root=repo_root,
                    memory_root=memory_root,
                    agent_files_root=agent_files_root,
                    fallback_zig_archive=None,
                    require_fallback_zig=True,
                )
            finally:
                globals()["sha256_for_file"] = original_sha256

            self.assertTrue(result["ok"])

    def test_collect_results_fails_on_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()

            for index, (relative_path, _label, expected_sha256) in enumerate(EXPECTED_MEMORY_ARCHIVES):
                target = memory_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(
                    "bad" if index == 0 else expected_sha256,
                    encoding="utf-8",
                )

            original_sha256 = globals()["sha256_for_file"]
            try:
                globals()["sha256_for_file"] = lambda path: path.read_text(encoding="utf-8")
                result = collect_results(
                    repo_root=repo_root,
                    memory_root=memory_root,
                    agent_files_root=agent_files_root,
                    fallback_zig_archive=None,
                    require_fallback_zig=False,
                )
            finally:
                globals()["sha256_for_file"] = original_sha256

            self.assertFalse(result["ok"])
            self.assertFalse(result["archive_entries"][0]["matches"])

    def test_optional_fallback_zig_can_warn_without_failing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()

            for relative_path, _label, expected_sha256 in EXPECTED_MEMORY_ARCHIVES:
                target = memory_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(expected_sha256, encoding="utf-8")

            original_sha256 = globals()["sha256_for_file"]
            try:
                globals()["sha256_for_file"] = lambda path: path.read_text(encoding="utf-8")
                result = collect_results(
                    repo_root=repo_root,
                    memory_root=memory_root,
                    agent_files_root=agent_files_root,
                    fallback_zig_archive=None,
                    require_fallback_zig=False,
                )
            finally:
                globals()["sha256_for_file"] = original_sha256

            self.assertTrue(result["ok"])
            self.assertFalse(result["fallback_zig_archive"]["exists"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedArchiveIntegrityTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    agent_files_root = (
        Path(args.agent_files_root).resolve() if args.agent_files_root else resolve_default_agent_files_root(repo_root)
    )
    fallback_zig_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None

    result = collect_results(
        repo_root=repo_root,
        memory_root=memory_root,
        agent_files_root=agent_files_root,
        fallback_zig_archive=fallback_zig_archive,
        require_fallback_zig=args.require_fallback_zig,
    )
    if args.json:
        print(json.dumps({"profile": "issue3-saved-archive-integrity", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())