#!/usr/bin/env python3

"""Check whether the saved Memory inputs for issue #3 are present.

This helper gives the issue #3 runtime and Linux build-readiness routes one
small preflight for the saved Memory artifacts that scheduled runs depend on:
the repo snapshot, README, blocker intelligence, dependency archives, the
optional attached fallback Zig bundle, and the attached-page validation helper
surface that later replay helpers expect to find after restore.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
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

RESTORE_HELPER_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
EXPECTED_REPO_SNAPSHOT_PREFIX = "browser-fork-headed-mode-foundation/"
REQUIRED_REPO_ROOT_FILE = "build.zig.zon"

BASE_REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry guide"),
    ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "Enter-submit runtime revalidation guide"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved-browser-snapshot restore guide"),
    ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry guide"),
    ("docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md", "restored-helper-surface sync guide"),
    ("docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md", "saved-archive integrity guide"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md", "saved-browser-snapshot archive-surface guide"),
    ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 progress-tracker route guide"),
    ("docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md", "workspace-context route guide"),
    ("docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md", "saved-memory inputs route guide"),
    ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness guide"),
    ("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "Zig toolchain recovery guide"),
    ("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", "Zig toolchain archive restore guide"),
    ("docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md", "saved Zig archive candidate guide"),
    ("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "offline build inputs guide"),
    ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain guide"),
    ("docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md", "saved Rust build-readiness guide"),
    ("docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md", "saved Rust archive candidates guide"),
    ("docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md", "Google-shaped attached-page validation flow guide"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
    ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
    ("scripts/check_issue3_saved_rust_archive_candidates.py", "saved Rust archive candidate helper"),
    ("scripts/check_issue3_staged_rust_toolchain_candidates.py", "staged Rust toolchain candidate helper"),
    ("scripts/check_issue3_saved_browser_snapshot_archive_surface.py", "saved-browser-snapshot archive-surface helper"),
    ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
    ("scripts/check_issue3_restored_helper_surface_sync.py", "restored-helper-surface sync helper"),
    ("scripts/check_issue3_workspace_context.py", "workspace-context helper"),
    ("scripts/check_issue3_saved_zig_archive_candidates.py", "saved Zig archive candidate helper"),
    ("scripts/check_issue3_staged_zig_toolchain_candidates.py", "staged Zig toolchain candidate helper"),
    ("scripts/check_issue3_build_readiness_rerun.py", "build-readiness rerun helper"),
    ("scripts/check_issue11_saved_memory_helper_contract.py", "issue #11 saved-memory helper contract checker"),
    ("scripts/check_issue11_reentry_inventory_consistency.py", "issue #11 re-entry inventory checker"),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness helper"),
    ("scripts/windows/HeadedValidationHelpers.ps1", "Windows headed validation helper"),
    (
        "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "Windows runtime re-entry surface checker",
    ),
    (
        "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
        "Windows runtime re-entry route helper",
    ),
    (
        "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "Windows attached-page replay surface checker",
    ),
    (
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Windows attached-page replay route helper",
    ),
    ("scripts/windows/start_attached_pages_catalog.ps1", "Windows attached-pages catalog launcher"),
    ("tmp-browser-smoke/attached-pages/README.md", "attached-pages launcher runbook"),
    ("tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py", "attached-pages catalog launcher"),
    ("scripts/linux/check_issue3_progress_tracker_route_surface.sh", "issue #11 progress-tracker route surface checker"),
    ("scripts/linux/show_issue3_progress_tracker_route.sh", "issue #11 progress-tracker route helper"),
    (
        "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
        "saved Zig archive candidate route surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
        "saved Zig archive candidate route helper",
    ),
    ("scripts/linux/check_issue3_workspace_context_route_surface.sh", "workspace-context route surface checker"),
    ("scripts/linux/show_issue3_workspace_context_route.sh", "workspace-context route helper"),
    (
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "saved-browser-snapshot route surface checker",
    ),
    (RESTORE_HELPER_PATH, "saved-browser-snapshot restore helper"),
    ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved-browser-snapshot route helper"),
    (
        "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
        "restored-checkout re-entry route surface checker",
    ),
    ("scripts/linux/show_issue3_restored_checkout_reentry_route.sh", "restored-checkout re-entry route helper"),
    (
        "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
        "restored-helper-surface sync route surface checker",
    ),
    ("scripts/linux/show_issue3_restored_helper_surface_sync_route.sh", "restored-helper-surface sync route helper"),
    (
        "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
        "saved-archive integrity route surface checker",
    ),
    ("scripts/linux/show_issue3_saved_archive_integrity_route.sh", "saved-archive integrity route helper"),
    (
        "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
        "saved-memory inputs route surface checker",
    ),
    ("scripts/linux/show_issue3_saved_memory_inputs_route.sh", "saved-memory inputs route helper"),
    (
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "Linux build-readiness surface checker",
    ),
    ("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux build-readiness route helper"),
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
    ("scripts/linux/check_issue3_zig_toolchain_match.sh", "Zig toolchain matching-line checker"),
    (
        "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        "Zig toolchain archive restore surface checker",
    ),
    ("scripts/linux/show_issue3_zig_toolchain_recovery_route.sh", "Zig toolchain recovery route helper"),
    ("scripts/linux/restore_issue3_fallback_zig_toolchain.sh", "fallback Zig restore helper"),
    ("scripts/linux/restore_zig_toolchain_archive.sh", "saved Zig archive restore helper"),
    (
        "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
        "saved Rust build-readiness surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
        "saved Rust build-readiness route helper",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh",
        "saved Rust archive candidates route surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh",
        "saved Rust archive candidates route helper",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        "saved Rust toolchain surface checker",
    ),
    ("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "saved Rust toolchain route helper"),
    ("scripts/linux/restore_saved_rust_toolchain.sh", "saved Rust toolchain restore helper"),
    (
        "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
        "offline build inputs route surface checker",
    ),
    ("scripts/linux/show_issue3_offline_build_inputs_route.sh", "offline build inputs route helper"),
    ("scripts/linux/prepare_offline_build_inputs.sh", "offline build inputs preparation helper"),
    (
        "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh",
        "Windows runtime handoff surface checker",
    ),
    ("scripts/linux/show_issue3_windows_runtime_handoff_route.sh", "Windows runtime handoff route helper"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the saved Memory artifacts for the blocked issue #3 "
            "runtime route are present before build-readiness or re-entry work."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser checkout root (default: current directory)")
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Path to the live helper checkout that should stay in sync with the "
            "restored checkout helper surface (default: repo root, or the "
            "current working tree when checking a restored snapshot from a "
            "live helper checkout)"
        ),
    )
    parser.add_argument("--memory-root", default=None, help="Path to the workspace memory root (default: ../memory beside the repo workspace)")
    parser.add_argument("--agent-files-root", default=None, help="Path to the builder-attached files root (default: ../agent_files beside the repo workspace)")
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help=(
            "Optional path to the reusable restored checkout to probe "
            "(default: ../browser-memory-snapshot beside the repo workspace)"
        ),
    )
    parser.add_argument("--fallback-zig-archive", default=None, help="Optional explicit path to the fallback Zig archive to check instead of auto-discovery")
    parser.add_argument("--skip-archive-integrity-check", action="store_true", help="Skip lightweight readability checks for the saved snapshot and dependency archives")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON instead of line-oriented text")
    parser.add_argument("--self-test", action="store_true", help="Run focused helper tests and exit")
    return parser


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


def resolve_default_memory_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "memory")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "memory").resolve()


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "agent_files")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "agent_files").resolve()


def resolve_default_restored_checkout_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, DEFAULT_RESTORED_CHECKOUT_NAME)
    if located is not None and located.is_dir():
        return located
    if (repo_root / REQUIRED_REPO_ROOT_FILE).is_file():
        return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()
    return (repo_root / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()


def extract_restore_helper_paths(script_text: str) -> list[str]:
    marker = "declare -a HELPER_SURFACE_PATHS=("
    in_block = False
    paths: list[str] = []

    for line in script_text.splitlines():
        stripped = line.strip()
        if not in_block:
            if stripped == marker:
                in_block = True
            continue

        if stripped == ")":
            break

        if stripped.startswith('"') and stripped.endswith('"'):
            paths.append(stripped.strip('"'))

    if not in_block:
        raise ValueError(f"Could not find HELPER_SURFACE_PATHS in {RESTORE_HELPER_PATH}")
    if not paths:
        raise ValueError(f"HELPER_SURFACE_PATHS in {RESTORE_HELPER_PATH} is empty")
    return paths


def load_required_restored_helper_files(helper_root: Path) -> list[tuple[str, str]]:
    required = list(BASE_REQUIRED_RESTORED_HELPER_FILES)
    known_paths = {path for path, _label in required}
    restore_helper = helper_root / RESTORE_HELPER_PATH
    if not restore_helper.is_file():
        return required

    helper_paths = extract_restore_helper_paths(restore_helper.read_text(encoding="utf-8"))
    for helper_path in helper_paths:
        if helper_path in known_paths:
            continue
        required.append(
            (
                helper_path,
                "Current helper-surface path mirrored from "
                f"{RESTORE_HELPER_PATH}.",
            )
        )
        known_paths.add(helper_path)
    return required


def path_has_live_helper_surface(path: Path) -> bool:
    return (
        path.is_dir()
        and (path / REQUIRED_REPO_ROOT_FILE).is_file()
        and all((path / relative_path).is_file() for relative_path, _label in load_required_restored_helper_files(path))
    )


def resolve_default_helper_root(repo_root: Path) -> Path:
    repo_root = repo_root.resolve()
    restored_checkout_root = resolve_default_restored_checkout_root(repo_root)
    cwd = Path.cwd().resolve()
    if cwd != repo_root and path_has_live_helper_surface(cwd):
        if repo_root == restored_checkout_root or restored_checkout_root in repo_root.parents:
            return cwd
    if path_has_live_helper_surface(repo_root):
        return repo_root
    return repo_root


def collect_repo_root_result(repo_root: Path) -> dict[str, object]:
    exists = repo_root.is_dir()
    required_file_path = repo_root / REQUIRED_REPO_ROOT_FILE
    has_required_file = required_file_path.is_file()
    if not exists:
        status = "missing"
    elif has_required_file:
        status = "ready"
    else:
        status = "missing-build-manifest"
    return {
        "path": str(repo_root),
        "exists": exists,
        "required_file": REQUIRED_REPO_ROOT_FILE,
        "required_file_path": str(required_file_path),
        "has_required_file": has_required_file,
        "status": status,
    }


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
    return {"label": label, "path": str(path), "exists": path.is_file()}


def collect_restored_checkout_result(restored_checkout_root: Path, helper_root: Path | None = None) -> dict[str, object]:
    exists = restored_checkout_root.is_dir()
    build_manifest = restored_checkout_root / REQUIRED_REPO_ROOT_FILE
    reference_root = helper_root if helper_root is not None else restored_checkout_root
    helper_requirements = load_required_restored_helper_files(reference_root)

    helper_surface_files = [
        {
            "label": label,
            "path": str(restored_checkout_root / relative_path),
            "relative_path": relative_path,
            "exists": (restored_checkout_root / relative_path).is_file(),
        }
        for relative_path, label in helper_requirements
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

    for relative_path, label in load_required_restored_helper_files(helper_root):
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
    repo_root_result = collect_repo_root_result(repo_root)
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
        fallback_path = agent_files_root / DEFAULT_FALLBACK_ZIG
    fallback_result = check_file(
        fallback_path,
        "fallback Zig archive",
        check_archive_integrity=check_archive_integrity,
    )

    missing_required = [entry for entry in required_files if not entry["exists"]]
    unreadable_required = [
        entry for entry in required_files if entry.get("exists") and "archive_readable" in entry and not entry["archive_readable"]
    ]
    helper_surface_sync = collect_helper_surface_sync_result(helper_root, restored_checkout_root)
    ok = (
        repo_root_result["exists"]
        and repo_root_result["has_required_file"]
        and not missing_required
        and not unreadable_required
        and helper_surface_sync["ok"]
    )

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "repo_root_result": repo_root_result,
        "helper_root": str(helper_root),
        "memory_root": str(memory_root),
        "agent_files_root": str(agent_files_root),
        "restored_checkout": collect_restored_checkout_result(restored_checkout_root, helper_root),
        "helper_surface_sync": helper_surface_sync,
        "archive_integrity_checked": check_archive_integrity,
        "required_files": required_files,
        "optional_files": optional_files,
        "fallback_zig_archive": fallback_result,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    repo_root_result = result["repo_root_result"]
    repo_root_status = {"ready": "PASS", "missing": "FAIL", "missing-build-manifest": "FAIL"}[repo_root_result["status"]]
    print(f"Browser checkout root: [{repo_root_status}] {repo_root_result['path']}")
    if repo_root_result["status"] == "missing":
        print("         status: missing; point --repo-root at a live or restored browser checkout before trusting this preflight")
    elif repo_root_result["status"] == "missing-build-manifest":
        print("         status: invalid checkout root; expected " f"{repo_root_result['required_file_path']}")
    print(f"Helper root: {result['helper_root']}")
    print(f"Memory root: {result['memory_root']}")
    print(f"Agent files root: {result['agent_files_root']}")

    restored_checkout = result["restored_checkout"]
    checkout_status = {"ready": "PASS", "incomplete-helper-surface": "WARN", "incomplete": "WARN", "missing": "WARN"}[restored_checkout["status"]]
    print(f"Reusable restored checkout: [{checkout_status}] {restored_checkout['path']}")
    if restored_checkout["exists"]:
        print(
            "         "
            f"build.zig.zon={'yes' if restored_checkout['has_build_manifest'] else 'no'}, "
            f"helper surface={'yes' if restored_checkout['has_helper_surface'] else 'no'}"
        )
        if restored_checkout["status"] == "incomplete-helper-surface":
            print("         status: restore looks usable, but sync the helper surface before follow-up route commands run from this checkout")
        if restored_checkout["missing_helper_surface_files"]:
            print("         missing helper files: " + ", ".join(restored_checkout["missing_helper_surface_files"]))
    else:
        print("         status: missing; restore the saved browser snapshot route before Linux or WSL replay")

    helper_surface_sync = result["helper_surface_sync"]
    helper_sync_status = {"synced": "PASS", "out-of-sync": "FAIL", "helper-root-missing": "FAIL", "restored-checkout-missing": "WARN"}[helper_surface_sync["status"]]
    print(f"Live/restored helper-surface sync: [{helper_sync_status}] {helper_surface_sync['status']}")
    if helper_surface_sync["drifted_files"]:
        print("         drifted files: " + ", ".join(helper_surface_sync["drifted_files"]))
    if helper_surface_sync["missing_in_helper_root"]:
        print("         missing in helper root: " + ", ".join(helper_surface_sync["missing_in_helper_root"]))
    if helper_surface_sync["missing_in_restored_checkout"]:
        print("         missing in restored checkout: " + ", ".join(helper_surface_sync["missing_in_restored_checkout"]))

    print("Required Memory inputs:")
    for entry in result["required_files"]:
        if not entry["exists"]:
            status = "FAIL"
        elif "archive_readable" in entry and not entry["archive_readable"]:
            status = "FAIL"
        else:
            status = "PASS"
        print(f"  [{status}] {entry['path']}: {entry['label']}")
        if entry.get("archive_summary"):
            print(f"         archive: {entry['archive_summary']}")
        if entry.get("archive_error"):
            print(f"         error: {entry['archive_error']}")

    print("Optional Memory inputs:")
    for entry in result["optional_files"]:
        status = "PASS" if entry["exists"] else "WARN"
        print(f"  [{status}] {entry['path']}: {entry['label']}")

    fallback = result["fallback_zig_archive"]
    if not fallback["exists"]:
        status = "WARN"
    elif "archive_readable" in fallback and not fallback["archive_readable"]:
        status = "FAIL"
    else:
        status = "PASS"
    print(f"Fallback Zig archive: [{status}] {fallback['path']}")
    if fallback.get("archive_summary"):
        print(f"         archive: {fallback['archive_summary']}")
    if fallback.get("archive_error"):
        print(f"         error: {fallback['archive_error']}")

    if result["ok"]:
        print("Saved Memory input check passed.")
        return

    print("Saved Memory input check failed.", file=sys.stderr)
    missing_required = [entry for entry in result["required_files"] if not entry["exists"]]
    unreadable_required = [entry for entry in result["required_files"] if entry.get("exists") and "archive_readable" in entry and not entry["archive_readable"]]
    if not repo_root_result["exists"] or not repo_root_result["has_required_file"]:
        print("Suggested next step: point --repo-root at a valid browser checkout before reopening the issue #3 saved-input route.", file=sys.stderr)
        return
    if restored_checkout["status"] == "missing":
        print("Suggested next step: run scripts/linux/restore_saved_browser_snapshot.sh before using the restored-checkout helper chain.", file=sys.stderr)
        return
    if restored_checkout["status"] == "incomplete-helper-surface":
        print("Suggested next step: rerun restore_saved_browser_snapshot.sh with --sync-helper-surface or refresh the existing destination with --sync-only so the restored checkout carries the current helper surface.", file=sys.stderr)
        return
    if helper_surface_sync["status"] == "out-of-sync":
        print("Suggested next step: refresh the restored checkout helper surface with restore_saved_browser_snapshot.sh --sync-only so the saved-input route and later follow-up commands agree on the same helper files.", file=sys.stderr)
        return
    if missing_required or unreadable_required:
        print("Suggested next step: repair the missing or unreadable Memory artifacts before reopening restore, build-readiness, or runtime re-entry work.", file=sys.stderr)
        return
    if not fallback["exists"]:
        print("Suggested next step: stage the fallback Zig archive in agent_files or pass --fallback-zig-archive explicitly before treating fallback Zig as surfaced input.", file=sys.stderr)
        return
    print("Suggested next step: inspect the saved-input route surface helpers because one of the expected follow-up surfaces is still out of contract.", file=sys.stderr)


def write_archive_placeholder(target: Path, root: Path) -> None:
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


def make_restore_helper_script(*helper_surface_paths: str) -> str:
    lines = ["#!/usr/bin/env bash", "", "declare -a HELPER_SURFACE_PATHS=("]
    lines.extend(f'    "{path}"' for path in helper_surface_paths)
    lines.append(")")
    lines.append("")
    return "\n".join(lines)


class SavedMemoryInputsTests(unittest.TestCase):
    def test_extract_restore_helper_paths(self) -> None:
        script = make_restore_helper_script("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "scripts/check_issue3_workspace_context.py")
        self.assertEqual(
            extract_restore_helper_paths(script),
            ["docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "scripts/check_issue3_workspace_context.py"],
        )

    def test_load_required_restored_helper_files_includes_dynamic_restore_entries(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir)
            restore_helper = helper_root / RESTORE_HELPER_PATH
            restore_helper.parent.mkdir(parents=True, exist_ok=True)
            restore_helper.write_text(
                make_restore_helper_script(
                    "scripts/check_issue11_saved_memory_helper_contract.py",
                    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
                ),
                encoding="utf-8",
            )
            paths = {path for path, _label in load_required_restored_helper_files(helper_root)}
            self.assertIn("scripts/check_issue11_saved_memory_helper_contract.py", paths)
            self.assertIn("scripts/linux/show_issue3_saved_rust_build_readiness_route.sh", paths)

    def test_collect_results_passes_with_required_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            restored_checkout_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            agent_files_root.mkdir()
            restored_checkout_root.mkdir()
            (restored_checkout_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            restore_helper_text = make_restore_helper_script(*[path for path, _label in BASE_REQUIRED_RESTORED_HELPER_FILES])
            for base in (repo_root, restored_checkout_root):
                for relative_path, _label in BASE_REQUIRED_RESTORED_HELPER_FILES:
                    target = base / relative_path
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text(restore_helper_text if relative_path == RESTORE_HELPER_PATH else "pass", encoding="utf-8")
            for relative_path, _label in REQUIRED_MEMORY_FILES + OPTIONAL_MEMORY_FILES:
                write_archive_placeholder(memory_root / relative_path, root)
            with tarfile.open(agent_files_root / DEFAULT_FALLBACK_ZIG, "w:xz") as archive:
                payload = root / "zig.txt"
                payload.write_text("zig", encoding="utf-8")
                archive.add(payload, arcname="zig.txt")

            result = collect_results(
                repo_root=repo_root,
                helper_root=repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
                restored_checkout_root=restored_checkout_root,
                fallback_zig_archive=None,
                check_archive_integrity=True,
            )

            self.assertTrue(result["ok"])
            self.assertEqual(result["restored_checkout"]["status"], "ready")
            self.assertEqual(result["helper_surface_sync"]["status"], "synced")

    def test_collect_results_fails_when_repo_root_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            missing_repo_root = root / "missing-browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            agent_files_root.mkdir()
            for relative_path, _label in REQUIRED_MEMORY_FILES:
                write_archive_placeholder(memory_root / relative_path, root)

            result = collect_results(
                repo_root=missing_repo_root,
                helper_root=missing_repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
                restored_checkout_root=resolve_default_restored_checkout_root(missing_repo_root),
                fallback_zig_archive=None,
                check_archive_integrity=True,
            )

            self.assertFalse(result["ok"])
            self.assertEqual(result["repo_root_result"]["status"], "missing")

    def test_collect_results_fails_when_repo_root_lacks_build_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()
            for relative_path, _label in REQUIRED_MEMORY_FILES:
                write_archive_placeholder(memory_root / relative_path, root)

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
            self.assertEqual(result["repo_root_result"]["status"], "missing-build-manifest")

    def test_collect_results_fails_when_required_archive_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            agent_files_root.mkdir()
            for relative_path, _label in REQUIRED_MEMORY_FILES[1:]:
                (memory_root / relative_path).parent.mkdir(parents=True, exist_ok=True)
                (memory_root / relative_path).write_text("x", encoding="utf-8")

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
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            agent_files_root.mkdir()

            for relative_path, _label in REQUIRED_MEMORY_FILES[1:]:
                write_archive_placeholder(memory_root / relative_path, root)

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

    def test_restored_checkout_helper_surface_requires_dynamic_restore_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            restored_checkout_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            restored_checkout_root.mkdir()
            (helper_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            (restored_checkout_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")

            dynamic_path = "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh"
            restore_helper_text = make_restore_helper_script(dynamic_path)
            helper_restore = helper_root / RESTORE_HELPER_PATH
            helper_restore.parent.mkdir(parents=True, exist_ok=True)
            helper_restore.write_text(restore_helper_text, encoding="utf-8")
            (helper_root / dynamic_path).parent.mkdir(parents=True, exist_ok=True)
            (helper_root / dynamic_path).write_text("live", encoding="utf-8")

            result = collect_restored_checkout_result(restored_checkout_root, helper_root)

            self.assertEqual(result["status"], "incomplete-helper-surface")
            self.assertIn(dynamic_path, result["missing_helper_surface_files"])

    def test_helper_surface_sync_detects_drift_and_missing_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            restored_checkout_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            restored_checkout_root.mkdir()
            (helper_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            (restored_checkout_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")

            dynamic_path = "scripts/check_issue11_saved_memory_helper_contract.py"
            restore_helper_text = make_restore_helper_script(dynamic_path, "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md")
            for base in (helper_root, restored_checkout_root):
                restore_target = base / RESTORE_HELPER_PATH
                restore_target.parent.mkdir(parents=True, exist_ok=True)
                restore_target.write_text(restore_helper_text, encoding="utf-8")
            (helper_root / dynamic_path).parent.mkdir(parents=True, exist_ok=True)
            (helper_root / dynamic_path).write_text("live", encoding="utf-8")
            drifted = "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md"
            for base, text in ((helper_root, "live"), (restored_checkout_root, "restored")):
                target = base / drifted
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(text, encoding="utf-8")

            report = collect_helper_surface_sync_result(helper_root, restored_checkout_root)

            self.assertEqual(report["status"], "out-of-sync")
            self.assertIn(dynamic_path, report["missing_in_restored_checkout"])
            self.assertIn(drifted, report["drifted_files"])

    def test_helper_surface_sync_skips_missing_restored_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir) / "browser"
            helper_root.mkdir()
            (helper_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            restore_helper = helper_root / RESTORE_HELPER_PATH
            restore_helper.parent.mkdir(parents=True, exist_ok=True)
            restore_helper.write_text(make_restore_helper_script(), encoding="utf-8")

            result = collect_helper_surface_sync_result(helper_root, Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME)

            self.assertEqual(result["status"], "restored-checkout-missing")
            self.assertTrue(result["ok"])

    def test_default_helper_root_prefers_live_helper_cwd_for_restored_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            live_root = root / "browser"
            restored_checkout_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            live_root.mkdir()
            restored_checkout_root.mkdir()
            (live_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            (restored_checkout_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            restore_helper_text = make_restore_helper_script(*[path for path, _label in BASE_REQUIRED_RESTORED_HELPER_FILES])
            for relative_path, _label in BASE_REQUIRED_RESTORED_HELPER_FILES:
                target = live_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(restore_helper_text if relative_path == RESTORE_HELPER_PATH else "live", encoding="utf-8")

            original_cwd = Path.cwd()
            try:
                os.chdir(live_root)
                self.assertEqual(resolve_default_helper_root(restored_checkout_root), live_root.resolve())
            finally:
                os.chdir(original_cwd)

    def test_default_helper_root_stays_on_repo_root_without_live_helper_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            live_root = root / "browser"
            restored_checkout_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            live_root.mkdir()
            restored_checkout_root.mkdir()
            (live_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            (restored_checkout_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")

            original_cwd = Path.cwd()
            try:
                os.chdir(live_root)
                self.assertEqual(resolve_default_helper_root(restored_checkout_root), restored_checkout_root.resolve())
            finally:
                os.chdir(original_cwd)

    def test_default_roots_rediscover_nested_workspace_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir) / "workspace"
            repo_root = workspace_root / "runs" / "current" / "browser"
            memory_root = workspace_root / "memory"
            agent_files_root = workspace_root / "agent_files"
            restored_checkout_root = workspace_root / DEFAULT_RESTORED_CHECKOUT_NAME

            repo_root.mkdir(parents=True)
            memory_root.mkdir()
            agent_files_root.mkdir()
            restored_checkout_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")

            self.assertEqual(resolve_default_memory_root(repo_root), memory_root.resolve())
            self.assertEqual(resolve_default_agent_files_root(repo_root), agent_files_root.resolve())
            self.assertEqual(resolve_default_restored_checkout_root(repo_root), restored_checkout_root.resolve())

    def test_default_roots_follow_workspace_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            self.assertEqual(resolve_default_helper_root(repo_root), repo_root)
            self.assertEqual(resolve_default_memory_root(repo_root), Path(tmpdir) / "memory")
            self.assertEqual(resolve_default_agent_files_root(repo_root), Path(tmpdir) / "agent_files")
            self.assertEqual(resolve_default_restored_checkout_root(repo_root), Path(tmpdir) / "browser-memory-snapshot")

        workspace_root = Path("/tmp/workspace")
        self.assertEqual(resolve_default_memory_root(workspace_root), Path("/tmp/memory"))
        self.assertEqual(resolve_default_agent_files_root(workspace_root), Path("/tmp/agent_files"))
        self.assertEqual(resolve_default_restored_checkout_root(workspace_root), Path("/tmp/workspace/browser-memory-snapshot"))


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedMemoryInputsTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else resolve_default_helper_root(repo_root)
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    agent_files_root = Path(args.agent_files_root).resolve() if args.agent_files_root else resolve_default_agent_files_root(repo_root)
    restored_checkout_root = Path(args.restored_checkout_root).resolve() if args.restored_checkout_root else resolve_default_restored_checkout_root(repo_root)
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