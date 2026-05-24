#!/usr/bin/env python3

"""Check whether the saved Memory inputs for issue #3 are present.

This helper gives the issue #3 runtime and Linux build-readiness routes one
small preflight for the saved Memory artifacts that scheduled runs depend on:
the repo snapshot, README, blocker intelligence, dependency archives, and the
optional attached fallback Zig bundle.
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


REQUIRED_MEMORY_FILES: tuple[tuple[str, str], ...] = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/README.md", "saved repo notes"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    (
        "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
        "saved Rust toolchain archive",
    ),
    (
        "repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
        "saved html5ever dependency archive",
    ),
    (
        "repo_archives/browser/dependencies/03-boringssl-zig-main.zip",
        "saved BoringSSL archive",
    ),
    (
        "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
        "saved browser dependency archive",
    ),
)

OPTIONAL_MEMORY_FILES: tuple[tuple[str, str], ...] = (
    ("repo_archives/browser/session_entry_register.yaml", "session entry register"),
)

REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry guide"),
    ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "Enter-submit runtime revalidation guide"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved-browser-snapshot restore guide"),
    ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness guide"),
    ("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "Zig toolchain recovery guide"),
    ("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "offline build inputs guide"),
    ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain guide"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
    (
        "scripts/check_issue3_saved_archive_integrity.py",
        "saved-archive integrity helper",
    ),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness helper"),
    (
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "saved-browser-snapshot route surface checker",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "saved-browser-snapshot restore helper",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "saved-browser-snapshot route helper",
    ),
    (
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "Linux build-readiness surface checker",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "Linux build-readiness route helper",
    ),
    (
        "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
        "runtime re-entry surface checker",
    ),
    (
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        "runtime re-entry route helper",
    ),
    (
        "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
        "Zig toolchain recovery surface checker",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        "Zig toolchain recovery route helper",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        "saved Rust toolchain surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "saved Rust toolchain route helper",
    ),
    (
        "scripts/linux/restore_saved_rust_toolchain.sh",
        "saved Rust toolchain restore helper",
    ),
    (
        "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
        "offline build inputs surface checker",
    ),
    (
        "scripts/linux/show_issue3_offline_build_inputs_route.sh",
        "offline build inputs route helper",
    ),
    (
        "scripts/linux/prepare_offline_build_inputs.sh",
        "offline build inputs preparation helper",
    ),
)

DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
EXPECTED_REPO_SNAPSHOT_PREFIX = "browser-fork-headed-mode-foundation/"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the saved Memory artifacts for the blocked issue #3 "
            "runtime route are present before build-readiness or re-entry work."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Path to the live helper checkout that should stay in sync with the "
            "restored checkout helper surface (default: repo root)"
        ),
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
        "--restored-checkout-root",
        default=None,
        help=(
            "Optional path to the reusable restored checkout to probe "
            "(default: ../browser-memory-snapshot beside the repo workspace)"
        ),
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the fallback Zig archive to check instead of auto-discovery",
    )
    parser.add_argument(
        "--skip-archive-integrity-check",
        action="store_true",
        help="Skip lightweight readability checks for the saved snapshot and dependency archives",
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


def resolve_default_helper_root(repo_root: Path) -> Path:
    return repo_root.resolve()


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    return (repo_root.parent / "agent_files").resolve()


def resolve_default_restored_checkout_root(repo_root: Path) -> Path:
    if (repo_root / "build.zig.zon").is_file():
        return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()
    return (repo_root / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()


def archive_integrity_result(path: Path, label: str) -> dict[str, object]:
    result: dict[str, object] = {
        "label": label,
        "path": str(path),
        "exists": path.is_file(),
        "archive_readable": False,
        "archive_summary": None,
        "archive_error": None,
    }
    if not result["exists"]:
        return result

    try:
        suffixes = path.suffixes
        if path.suffix == ".zip":
            with zipfile.ZipFile(path) as archive:
                names = archive.namelist()
                bad_member = archive.testzip()
                if bad_member is not None:
                    raise zipfile.BadZipFile(f"CRC failure in {bad_member}")
                summary = f"zip entries={len(names)}"
                if label == "saved repo snapshot":
                    if not any(name.startswith(EXPECTED_REPO_SNAPSHOT_PREFIX) for name in names):
                        raise ValueError(
                            "missing expected top-level folder "
                            f"{EXPECTED_REPO_SNAPSHOT_PREFIX!r}"
                        )
                    summary += f"; top-level={EXPECTED_REPO_SNAPSHOT_PREFIX.rstrip('/')}"
                result["archive_summary"] = summary
        elif suffixes[-2:] == [".tar", ".xz"] or suffixes[-2:] == [".tar", ".gz"]:
            with tarfile.open(path, mode="r:*") as archive:
                members = archive.getmembers()
                if not members:
                    raise ValueError("archive has no members")
                result["archive_summary"] = f"tar entries={len(members)}"
        else:
            result["archive_summary"] = "integrity check not defined for this file type"
        result["archive_readable"] = True
        return result
    except (tarfile.TarError, zipfile.BadZipFile, ValueError, OSError) as exc:
        result["archive_error"] = str(exc)
        return result


def check_file(path: Path, label: str, *, check_archive_integrity: bool) -> dict[str, object]:
    if check_archive_integrity and (
        path.suffix == ".zip" or path.suffixes[-2:] == [".tar", ".xz"] or path.suffixes[-2:] == [".tar", ".gz"]
    ):
        return archive_integrity_result(path, label)
    exists = path.is_file()
    return {
        "label": label,
        "path": str(path),
        "exists": exists,
    }


def collect_restored_checkout_result(restored_checkout_root: Path) -> dict[str, object]:
    exists = restored_checkout_root.is_dir()
    build_manifest = restored_checkout_root / "build.zig.zon"

    helper_surface_files = [
        {
            "label": label,
            "path": str(restored_checkout_root / relative_path),
            "relative_path": relative_path,
            "exists": (restored_checkout_root / relative_path).is_file(),
        }
        for relative_path, label in REQUIRED_RESTORED_HELPER_FILES
    ]
    missing_helper_surface_files = [
        entry["relative_path"] for entry in helper_surface_files if not entry["exists"]
    ]

    has_build_manifest = build_manifest.is_file()
    has_helper_surface = exists and not missing_helper_surface_files

    if not exists:
        status = "missing"
    elif has_build_manifest and has_helper_surface:
        status = "ready"
    elif has_build_manifest:
        status = "incomplete-helper-surface"
    else:
        status = "incomplete"

    return {
        "path": str(restored_checkout_root),
        "exists": exists,
        "has_build_manifest": has_build_manifest,
        "has_helper_surface": has_helper_surface,
        "helper_surface_files": helper_surface_files,
        "missing_helper_surface_files": missing_helper_surface_files,
        "status": status,
    }


def file_digest(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collect_helper_surface_sync_result(helper_root: Path, restored_checkout_root: Path) -> dict[str, object]:
    if not helper_root.is_dir():
        return {
            "status": "helper-root-missing",
            "helper_root": str(helper_root),
            "restored_checkout_root": str(restored_checkout_root),
            "checked_files": [],
            "drifted_files": [],
            "missing_in_helper_root": [],
            "missing_in_restored_checkout": [],
            "ok": False,
        }

    if not restored_checkout_root.is_dir():
        return {
            "status": "restored-checkout-missing",
            "helper_root": str(helper_root),
            "restored_checkout_root": str(restored_checkout_root),
            "checked_files": [],
            "drifted_files": [],
            "missing_in_helper_root": [],
            "missing_in_restored_checkout": [],
            "ok": True,
        }

    checked_files: list[dict[str, object]] = []
    drifted_files: list[str] = []
    missing_in_helper_root: list[str] = []
    missing_in_restored_checkout: list[str] = []

    for relative_path, label in REQUIRED_RESTORED_HELPER_FILES:
        helper_path = helper_root / relative_path
        restored_path = restored_checkout_root / relative_path
        helper_exists = helper_path.is_file()
        restored_exists = restored_path.is_file()
        same_content = False
        if helper_exists and restored_exists:
            same_content = file_digest(helper_path) == file_digest(restored_path)
        if not helper_exists:
            missing_in_helper_root.append(relative_path)
        if not restored_exists:
            missing_in_restored_checkout.append(relative_path)
        if helper_exists and restored_exists and not same_content:
            drifted_files.append(relative_path)
        checked_files.append(
            {
                "label": label,
                "relative_path": relative_path,
                "helper_path": str(helper_path),
                "restored_path": str(restored_path),
                "helper_exists": helper_exists,
                "restored_exists": restored_exists,
                "same_content": same_content if helper_exists and restored_exists else None,
            }
        )

    ok = not drifted_files and not missing_in_helper_root and not missing_in_restored_checkout
    status = "synced" if ok else "out-of-sync"
    return {
        "status": status,
        "helper_root": str(helper_root),
        "restored_checkout_root": str(restored_checkout_root),
        "checked_files": checked_files,
        "drifted_files": drifted_files,
        "missing_in_helper_root": missing_in_helper_root,
        "missing_in_restored_checkout": missing_in_restored_checkout,
        "ok": ok,
    }


def collect_results(
    *,
    repo_root: Path,
    helper_root: Path,
    memory_root: Path,
    agent_files_root: Path,
    restored_checkout_root: Path,
    fallback_zig_archive: Path | None,
    check_archive_integrity: bool,
) -> dict[str, object]:
    required_files = [
        check_file(memory_root / relative_path, label, check_archive_integrity=check_archive_integrity)
        for relative_path, label in REQUIRED_MEMORY_FILES
    ]
    optional_files = [
        check_file(memory_root / relative_path, label, check_archive_integrity=check_archive_integrity)
        for relative_path, label in OPTIONAL_MEMORY_FILES
    ]

    fallback_path = fallback_zig_archive
    if fallback_path is None:
        candidate = agent_files_root / DEFAULT_FALLBACK_ZIG
        fallback_path = candidate if candidate.exists() else candidate
    fallback_result = check_file(
        fallback_path,
        "fallback Zig archive",
        check_archive_integrity=check_archive_integrity,
    )

    missing_required = [entry for entry in required_files if not entry["exists"]]
    unreadable_required = [
        entry
        for entry in required_files
        if entry.get("exists") and "archive_readable" in entry and not entry["archive_readable"]
    ]
    helper_surface_sync = collect_helper_surface_sync_result(helper_root, restored_checkout_root)
    ok = not missing_required and not unreadable_required and helper_surface_sync["ok"]

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "helper_root": str(helper_root),
        "memory_root": str(memory_root),
        "agent_files_root": str(agent_files_root),
        "restored_checkout": collect_restored_checkout_result(restored_checkout_root),
        "helper_surface_sync": helper_surface_sync,
        "archive_integrity_checked": check_archive_integrity,
        "required_files": required_files,
        "optional_files": optional_files,
        "fallback_zig_archive": fallback_result,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Helper root: {result['helper_root']}")
    print(f"Memory root: {result['memory_root']}")
    print(f"Agent files root: {result['agent_files_root']}")
    restored_checkout = result["restored_checkout"]
    checkout_status = {
        "ready": "PASS",
        "incomplete-helper-surface": "WARN",
        "incomplete": "WARN",
        "missing": "WARN",
    }[restored_checkout["status"]]
    print(
        f"Reusable restored checkout: [{checkout_status}] "
        f"{restored_checkout['path']}"
    )
    if restored_checkout["exists"]:
        print(
            "         "
            f"build.zig.zon={'yes' if restored_checkout['has_build_manifest'] else 'no'}, "
            f"helper surface={'yes' if restored_checkout['has_helper_surface'] else 'no'}"
        )
        if restored_checkout["status"] == "incomplete-helper-surface":
            print("         status: restore looks usable, but sync the helper surface before follow-up route commands run from this checkout")
        if restored_checkout["missing_helper_surface_files"]:
            joined = ", ".join(restored_checkout["missing_helper_surface_files"])
            print(f"         missing helper files: {joined}")
    else:
        print("         status: missing; restore the saved browser snapshot route before Linux or WSL replay")
    helper_surface_sync = result["helper_surface_sync"]
    helper_sync_status = {
        "synced": "PASS",
        "out-of-sync": "FAIL",
        "restored-checkout-missing": "WARN",
        "helper-root-missing": "FAIL",
    }[helper_surface_sync["status"]]
    print(
        f"Helper surface sync: [{helper_sync_status}] "
        f"{helper_surface_sync['helper_root']} -> {helper_surface_sync['restored_checkout_root']}"
    )
    if helper_surface_sync["status"] == "out-of-sync":
        if helper_surface_sync["drifted_files"]:
            print(
                "         drifted files: "
                + ", ".join(helper_surface_sync["drifted_files"])
            )
        if helper_surface_sync["missing_in_restored_checkout"]:
            print(
                "         missing in restored checkout: "
                + ", ".join(helper_surface_sync["missing_in_restored_checkout"])
            )
        if helper_surface_sync["missing_in_helper_root"]:
            print(
                "         missing in helper root: "
                + ", ".join(helper_surface_sync["missing_in_helper_root"])
            )
        print("         suggested next step: re-run the saved-browser restore with --sync-helper-surface before Linux or WSL follow-up work")
    print("Required Memory inputs:")
    for entry in result["required_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        if entry.get("exists") and "archive_readable" in entry and not entry["archive_readable"]:
            status = "FAIL"
        print(f"  [{status}] {entry['label']}: {entry['path']}")
        if entry.get("archive_summary"):
            print(f"         summary: {entry['archive_summary']}")
        if entry.get("archive_error"):
            print(f"         archive error: {entry['archive_error']}")
    print("Optional Memory inputs:")
    for entry in result["optional_files"]:
        status = "PASS" if entry["exists"] else "WARN"
        if entry.get("exists") and "archive_readable" in entry and not entry["archive_readable"]:
            status = "WARN"
        print(f"  [{status}] {entry['label']}: {entry['path']}")
        if entry.get("archive_summary"):
            print(f"         summary: {entry['archive_summary']}")
        if entry.get("archive_error"):
            print(f"         archive error: {entry['archive_error']}")
    fallback = result["fallback_zig_archive"]
    fallback_status = "PASS" if fallback["exists"] else "WARN"
    if fallback.get("exists") and "archive_readable" in fallback and not fallback["archive_readable"]:
        fallback_status = "WARN"
    print(f"Fallback Zig archive: [{fallback_status}] {fallback['path']}")
    if fallback.get("archive_summary"):
        print(f"         summary: {fallback['archive_summary']}")
    if fallback.get("archive_error"):
        print(f"         archive error: {fallback['archive_error']}")
    if result["ok"]:
        print("\nSaved Memory input check passed.")
    else:
        print("\nSaved Memory input check failed.", file=sys.stderr)
        print(
            "Suggested next step: restore or remount readable saved repo and dependency archives before reopening the issue #3 runtime route.",
            file=sys.stderr,
        )


class SavedMemoryInputsTests(unittest.TestCase):
    def test_collect_results_passes_with_required_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            restored_checkout_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            repo_root.mkdir()
            agent_files_root.mkdir()
            restored_checkout_root.mkdir()
            (restored_checkout_root / "build.zig.zon").write_text("{}", encoding="utf-8")
            for relative_path, _label in REQUIRED_RESTORED_HELPER_FILES:
                target = restored_checkout_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("pass", encoding="utf-8")
            for relative_path, _label in REQUIRED_MEMORY_FILES + OPTIONAL_MEMORY_FILES:
                target = memory_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                if target.suffix == ".zip":
                    with zipfile.ZipFile(target, "w") as archive:
                        member = "browser-fork-headed-mode-foundation/README.md" if "fork-headed-mode-foundation" in target.name else "placeholder.txt"
                        archive.writestr(member, "x")
                elif target.suffixes[-2:] == [".tar", ".xz"]:
                    with tarfile.open(target, "w:xz") as archive:
                        payload = root / "payload.txt"
                        payload.write_text("x", encoding="utf-8")
                        archive.add(payload, arcname="payload.txt")
                else:
                    target.write_text("x", encoding="utf-8")
            with tarfile.open(agent_files_root / DEFAULT_FALLBACK_ZIG, "w:xz") as archive:
                payload = root / "zig.txt"
                payload.write_text("zig", encoding="utf-8")
                archive.add(payload, arcname="zig.txt")

            result = collect_results(
                repo_root=repo_root,
                helper_root=restored_checkout_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
                restored_checkout_root=restored_checkout_root,
                fallback_zig_archive=None,
                check_archive_integrity=True,
            )

            self.assertTrue(result["ok"])
            self.assertTrue(result["fallback_zig_archive"]["exists"])
            self.assertTrue(result["required_files"][0]["archive_readable"])
            self.assertEqual(result["restored_checkout"]["status"], "ready")
            self.assertTrue(result["restored_checkout"]["has_helper_surface"])
            self.assertEqual(result["restored_checkout"]["missing_helper_surface_files"], [])
            self.assertEqual(result["helper_surface_sync"]["status"], "synced")

    def test_collect_results_fails_when_required_archive_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()
            for relative_path, _label in REQUIRED_MEMORY_FILES[1:]:
                target = memory_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                helper_root=repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
                restored_checkout_root=resolve_default_restored_checkout_root(repo_root),
                fallback_zig_archive=None,
                check_archive_integrity=False,
            )

            self.assertFalse(result["ok"])
            self.assertFalse(result["required_files"][0]["exists"])

    def test_collect_results_fails_when_repo_snapshot_is_unreadable(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()

            for relative_path, _label in REQUIRED_MEMORY_FILES[1:]:
                target = memory_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                if target.suffix == ".zip":
                    with zipfile.ZipFile(target, "w") as archive:
                        archive.writestr("placeholder.txt", "x")
                elif target.suffixes[-2:] == [".tar", ".xz"]:
                    with tarfile.open(target, "w:xz") as archive:
                        payload = root / "payload.txt"
                        payload.write_text("x", encoding="utf-8")
                        archive.add(payload, arcname="payload.txt")
                else:
                    target.write_text("x", encoding="utf-8")

            broken_repo_snapshot = memory_root / REQUIRED_MEMORY_FILES[0][0]
            broken_repo_snapshot.parent.mkdir(parents=True, exist_ok=True)
            broken_repo_snapshot.write_text("not-a-zip", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                helper_root=repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
                restored_checkout_root=resolve_default_restored_checkout_root(repo_root),
                fallback_zig_archive=None,
                check_archive_integrity=True,
            )

            self.assertFalse(result["ok"])
            self.assertTrue(result["required_files"][0]["exists"])
            self.assertFalse(result["required_files"][0]["archive_readable"])

    def test_restored_checkout_detection_handles_missing_and_incomplete_states(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            missing = collect_restored_checkout_result(root / DEFAULT_RESTORED_CHECKOUT_NAME)
            self.assertEqual(missing["status"], "missing")

            incomplete_root = root / "partial-checkout"
            incomplete_root.mkdir()
            incomplete = collect_restored_checkout_result(incomplete_root)
            self.assertEqual(incomplete["status"], "incomplete")
            self.assertFalse(incomplete["has_build_manifest"])
            self.assertFalse(incomplete["has_helper_surface"])
            self.assertEqual(
                incomplete["missing_helper_surface_files"],
                [relative_path for relative_path, _label in REQUIRED_RESTORED_HELPER_FILES],
            )

    def test_restored_checkout_helper_surface_requires_current_helper_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            restored_checkout_root = Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME
            restored_checkout_root.mkdir()
            (restored_checkout_root / "build.zig.zon").write_text("{}", encoding="utf-8")
            legacy_helper_paths = {
                "scripts/check_issue3_saved_memory_inputs.py",
                "scripts/linux/show_issue3_linux_build_readiness_route.sh",
                "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            }
            for relative_path in legacy_helper_paths:
                target = restored_checkout_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("pass", encoding="utf-8")

            result = collect_restored_checkout_result(restored_checkout_root)

            self.assertEqual(result["status"], "incomplete-helper-surface")
            self.assertTrue(result["has_build_manifest"])
            self.assertFalse(result["has_helper_surface"])
            self.assertIn(
                "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
                result["missing_helper_surface_files"],
            )
            self.assertIn(
                "scripts/check_issue3_saved_archive_integrity.py",
                result["missing_helper_surface_files"],
            )
            self.assertIn(
                "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
                result["missing_helper_surface_files"],
            )
            self.assertIn(
                "scripts/check_linux_build_readiness.py",
                result["missing_helper_surface_files"],
            )
            self.assertIn(
                "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
                result["missing_helper_surface_files"],
            )
            self.assertIn(
                "scripts/linux/prepare_offline_build_inputs.sh",
                result["missing_helper_surface_files"],
            )

    def test_helper_surface_sync_detects_drift_and_missing_restored_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            restored_checkout_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            restored_checkout_root.mkdir()

            for relative_path, _label in REQUIRED_RESTORED_HELPER_FILES:
                helper_target = helper_root / relative_path
                helper_target.parent.mkdir(parents=True, exist_ok=True)
                helper_target.write_text("live", encoding="utf-8")

                if relative_path == "scripts/check_issue3_saved_memory_inputs.py":
                    continue

                restored_target = restored_checkout_root / relative_path
                restored_target.parent.mkdir(parents=True, exist_ok=True)
                restored_target.write_text(
                    "restored drift" if relative_path == "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" else "live",
                    encoding="utf-8",
                )

            result = collect_helper_surface_sync_result(helper_root, restored_checkout_root)

            self.assertEqual(result["status"], "out-of-sync")
            self.assertIn(
                "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
                result["drifted_files"],
            )
            self.assertIn(
                "scripts/check_issue3_saved_memory_inputs.py",
                result["missing_in_restored_checkout"],
            )

    def test_helper_surface_sync_skips_missing_restored_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir) / "browser"
            helper_root.mkdir()

            result = collect_helper_surface_sync_result(
                helper_root, Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME
            )

            self.assertEqual(result["status"], "restored-checkout-missing")
            self.assertTrue(result["ok"])

    def test_default_roots_follow_workspace_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text("{}", encoding="utf-8")
            self.assertEqual(resolve_default_helper_root(repo_root), repo_root)
            self.assertEqual(resolve_default_memory_root(repo_root), Path(tmpdir) / "memory")
            self.assertEqual(resolve_default_agent_files_root(repo_root), Path(tmpdir) / "agent_files")
            self.assertEqual(
                resolve_default_restored_checkout_root(repo_root),
                Path(tmpdir) / "browser-memory-snapshot",
            )

        workspace_root = Path("/tmp/workspace")
        self.assertEqual(resolve_default_memory_root(workspace_root), Path("/tmp/memory"))
        self.assertEqual(resolve_default_agent_files_root(workspace_root), Path("/tmp/agent_files"))
        self.assertEqual(
            resolve_default_restored_checkout_root(workspace_root),
            Path("/tmp/workspace/browser-memory-snapshot"),
        )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedMemoryInputsTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else resolve_default_helper_root(repo_root)
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    agent_files_root = (
        Path(args.agent_files_root).resolve() if args.agent_files_root else resolve_default_agent_files_root(repo_root)
    )
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root
        else resolve_default_restored_checkout_root(repo_root)
    )
    fallback_zig_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None

    result = collect_results(
        repo_root=repo_root,
        helper_root=helper_root,
        memory_root=memory_root,
        agent_files_root=agent_files_root,
        restored_checkout_root=restored_checkout_root,
        fallback_zig_archive=fallback_zig_archive,
        check_archive_integrity=not args.skip_archive_integrity_check,
    )
    if args.json:
        print(json.dumps({"profile": "issue3-saved-memory-inputs", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
