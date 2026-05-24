#!/usr/bin/env python3

"""Verify the saved issue #3 Memory archives by SHA-256 and archive layout.

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
import tarfile
import tempfile
import unittest
import zipfile


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

EXPECTED_REPO_SNAPSHOT_PREFIX = "browser-fork-headed-mode-foundation/"
EXPECTED_BROWSER_DEPENDENCY_ZIP_ENTRIES: tuple[str, ...] = (
    "zig-v8-fork-0.3.1.tar.gz",
    "curl-8.18.0.tar.gz",
    "nghttp2-1.68.0.tar.gz",
    "zlib-1.3.2.tar.gz",
    "brotli-028fb5a23661f123017c060daa546b55cf4bde29.tar.gz",
    "libc_v8_14.0.365.4_linux_x86_64 (1).a",
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


def inspect_archive_layout(path: Path, label: str) -> tuple[bool, str | None, str | None]:
    try:
        suffixes = path.suffixes
        if suffixes[-2:] in ([".tar", ".xz"], [".tar", ".gz"]):
            with tarfile.open(path, mode="r:*") as archive:
                members = archive.getmembers()
                if not members:
                    raise ValueError("archive has no members")
                return True, f"tar entries={len(members)}", None

        if suffixes[-2:] == [".tar", ".zip"]:
            with zipfile.ZipFile(path) as archive:
                bad_member = archive.testzip()
                if bad_member is not None:
                    raise zipfile.BadZipFile(f"CRC failure in {bad_member}")
                names = archive.namelist()
                if not names:
                    raise ValueError("archive has no members")
                missing_entries = sorted(
                    set(EXPECTED_BROWSER_DEPENDENCY_ZIP_ENTRIES).difference(names)
                )
                if missing_entries:
                    raise ValueError(
                        "missing expected entries: " + ", ".join(missing_entries)
                    )
                return (
                    True,
                    f"zip entries={len(names)}; expected payloads present={len(EXPECTED_BROWSER_DEPENDENCY_ZIP_ENTRIES)}",
                    None,
                )

        if path.suffix == ".zip":
            with zipfile.ZipFile(path) as archive:
                bad_member = archive.testzip()
                if bad_member is not None:
                    raise zipfile.BadZipFile(f"CRC failure in {bad_member}")
                names = archive.namelist()
                if not names:
                    raise ValueError("archive has no members")
                if label == "saved repo snapshot" and not any(
                    name.startswith(EXPECTED_REPO_SNAPSHOT_PREFIX) for name in names
                ):
                    raise ValueError(
                        f"missing expected top-level folder {EXPECTED_REPO_SNAPSHOT_PREFIX!r}"
                    )
                summary = f"zip entries={len(names)}"
                if label == "saved repo snapshot":
                    summary += (
                        f"; top-level={EXPECTED_REPO_SNAPSHOT_PREFIX.rstrip('/')}"
                    )
                return True, summary, None

        return True, "layout check not defined for this file type", None
    except (tarfile.TarError, zipfile.BadZipFile, ValueError, OSError) as exc:
        return False, None, str(exc)


def build_entry(path: Path, label: str, expected_sha256: str) -> dict[str, object]:
    exists = path.is_file()
    actual_sha256 = sha256_for_file(path) if exists else None
    matches = exists and actual_sha256 == expected_sha256
    layout_ok = False
    layout_summary = None
    layout_error = None
    if exists:
        layout_ok, layout_summary, layout_error = inspect_archive_layout(path, label)
    return {
        "label": label,
        "path": str(path),
        "exists": exists,
        "expected_sha256": expected_sha256,
        "actual_sha256": actual_sha256,
        "matches": matches,
        "layout_ok": layout_ok,
        "layout_summary": layout_summary,
        "layout_error": layout_error,
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
    bad_required = [
        entry
        for entry in archive_entries
        if not entry["matches"] or not entry["layout_ok"]
    ]

    fallback_path = fallback_zig_archive
    if fallback_path is None:
        fallback_path = agent_files_root / DEFAULT_FALLBACK_ZIG_NAME
    fallback_entry = build_entry(
        fallback_path,
        "fallback Zig archive",
        DEFAULT_FALLBACK_ZIG_SHA256,
    )

    fallback_ok = (
        fallback_entry["matches"] and fallback_entry["layout_ok"]
    ) or (not require_fallback_zig and not fallback_entry["exists"])
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
    if entry["matches"] and entry["layout_ok"]:
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
        if entry["layout_summary"]:
            print(f"         layout   {entry['layout_summary']}")
        if entry["layout_error"]:
            print(f"         layout   {entry['layout_error']}")
    fallback = result["fallback_zig_archive"]
    fallback_status = status_for(
        fallback,
        missing_is_warn=not result["require_fallback_zig"],
    )
    print(f"Fallback Zig archive: [{fallback_status}] {fallback['path']}")
    print(f"         expected {fallback['expected_sha256']}")
    print(f"         actual   {fallback['actual_sha256'] or 'missing'}")
    if fallback["layout_summary"]:
        print(f"         layout   {fallback['layout_summary']}")
    if fallback["layout_error"]:
        print(f"         layout   {fallback['layout_error']}")
    if result["ok"]:
        print("\nSaved archive integrity check passed.")
    else:
        print("\nSaved archive integrity check failed.", file=sys.stderr)
        print(
            "Suggested next step: refresh the mismatched archive from the saved Memory source before trusting restore, Linux build-readiness, or issue #3 runtime re-entry work.",
            file=sys.stderr,
        )


def write_tar_xz(path: Path, members: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_root = Path(tmpdir)
        with tarfile.open(path, "w:xz") as archive:
            for name, content in members.items():
                member_path = tmp_root / name
                member_path.parent.mkdir(parents=True, exist_ok=True)
                member_path.write_text(content, encoding="utf-8")
                archive.add(member_path, arcname=name)


def write_zip(path: Path, members: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w") as archive:
        for name, content in members.items():
            archive.writestr(name, content)


class SavedArchiveIntegrityTests(unittest.TestCase):
    def build_valid_archives(
        self, memory_root: Path, agent_files_root: Path
    ) -> dict[Path, str]:
        expected_sha_by_path: dict[Path, str] = {}

        repo_snapshot = (
            memory_root
            / "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
        )
        write_zip(
            repo_snapshot,
            {
                "browser-fork-headed-mode-foundation/README.md": "repo",
                "browser-fork-headed-mode-foundation/build.zig": "build",
            },
        )
        expected_sha_by_path[repo_snapshot] = EXPECTED_MEMORY_ARCHIVES[0][2]

        rust_archive = (
            memory_root
            / "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz"
        )
        write_tar_xz(rust_archive, {"rust/bin/rustc": "rust"})
        expected_sha_by_path[rust_archive] = EXPECTED_MEMORY_ARCHIVES[1][2]

        html5ever_archive = (
            memory_root
            / "repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
        )
        write_zip(html5ever_archive, {"deps/libhtml5ever.a": "html5ever"})
        expected_sha_by_path[html5ever_archive] = EXPECTED_MEMORY_ARCHIVES[2][2]

        boringssl_archive = (
            memory_root
            / "repo_archives/browser/dependencies/03-boringssl-zig-main.zip"
        )
        write_zip(boringssl_archive, {"boringssl-zig-main/README.md": "boring"})
        expected_sha_by_path[boringssl_archive] = EXPECTED_MEMORY_ARCHIVES[3][2]

        browser_dep_archive = (
            memory_root
            / "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip"
        )
        write_zip(
            browser_dep_archive,
            {name: name for name in EXPECTED_BROWSER_DEPENDENCY_ZIP_ENTRIES},
        )
        expected_sha_by_path[browser_dep_archive] = EXPECTED_MEMORY_ARCHIVES[4][2]

        fallback_archive = agent_files_root / DEFAULT_FALLBACK_ZIG_NAME
        write_tar_xz(fallback_archive, {"zig/zig": "zig"})
        expected_sha_by_path[fallback_archive] = DEFAULT_FALLBACK_ZIG_SHA256

        return expected_sha_by_path

    def test_collect_results_passes_with_matching_archives(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()

            expected_sha_by_path = self.build_valid_archives(
                memory_root, agent_files_root
            )

            original_sha256 = globals()["sha256_for_file"]
            try:
                globals()["sha256_for_file"] = (
                    lambda path: expected_sha_by_path[path]
                )
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
            self.assertTrue(
                all(entry["layout_ok"] for entry in result["archive_entries"])
            )

    def test_collect_results_fails_on_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()

            expected_sha_by_path = self.build_valid_archives(
                memory_root, agent_files_root
            )

            bad_path = (
                memory_root
                / "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
            )

            original_sha256 = globals()["sha256_for_file"]
            try:
                globals()["sha256_for_file"] = (
                    lambda path: "bad"
                    if path == bad_path
                    else expected_sha_by_path[path]
                )
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
            self.assertTrue(result["archive_entries"][0]["layout_ok"])

    def test_optional_fallback_zig_can_warn_without_failing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()

            expected_sha_by_path = self.build_valid_archives(
                memory_root, agent_files_root
            )
            fallback_archive = agent_files_root / DEFAULT_FALLBACK_ZIG_NAME
            fallback_archive.unlink()
            expected_sha_by_path.pop(fallback_archive, None)

            original_sha256 = globals()["sha256_for_file"]
            try:
                globals()["sha256_for_file"] = (
                    lambda path: expected_sha_by_path[path]
                )
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

    def test_collect_results_fails_on_archive_layout_problem(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()

            expected_sha_by_path = self.build_valid_archives(
                memory_root, agent_files_root
            )

            browser_dep_archive = (
                memory_root
                / "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip"
            )
            write_zip(
                browser_dep_archive,
                {
                    name: name
                    for name in EXPECTED_BROWSER_DEPENDENCY_ZIP_ENTRIES[:-1]
                },
            )

            original_sha256 = globals()["sha256_for_file"]
            try:
                globals()["sha256_for_file"] = (
                    lambda path: expected_sha_by_path[path]
                )
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
            broken_entry = result["archive_entries"][-1]
            self.assertTrue(broken_entry["matches"])
            self.assertFalse(broken_entry["layout_ok"])
            self.assertIn("missing expected entries", broken_entry["layout_error"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedArchiveIntegrityTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = (
        Path(args.memory_root).resolve()
        if args.memory_root
        else resolve_default_memory_root(repo_root)
    )
    agent_files_root = (
        Path(args.agent_files_root).resolve()
        if args.agent_files_root
        else resolve_default_agent_files_root(repo_root)
    )
    fallback_zig_archive = (
        Path(args.fallback_zig_archive).resolve()
        if args.fallback_zig_archive
        else None
    )

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