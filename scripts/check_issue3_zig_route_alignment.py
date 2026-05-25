#!/usr/bin/env python3

"""Check that the issue #3 Zig recovery route still points at its key helpers."""

from __future__ import annotations

import argparse
import json
import pathlib
import tempfile
import unittest


REFERENCE_PATHS = (
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "Linux/WSL route note that should point runs toward the Zig recovery chain.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "Zig recovery route note that should keep the saved-archive and fallback helpers visible.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
        "Archive-restore note that should stay paired with the broader Zig recovery route.",
    ),
    (
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "Saved Zig archive discovery helper that picks the preferred 0.15.x restore candidate.",
    ),
    (
        "scripts/linux/check_issue3_zig_toolchain_match.sh",
        "Fail-fast matching-line gate that should prove a staged 0.15.x candidate exists.",
    ),
    (
        "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        "Surface checker that should fail fast before a real Zig archive is staged under ../toolchains.",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
        "Route printer that should keep the archive-restore chain on one compact surface.",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        "Route printer that should hand the run through saved-candidate discovery, archive restore, and matching-line checks.",
    ),
    (
        "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
        "Fallback restore helper that should surface the attached Zig 0.17 bundle without treating it as honest validation evidence.",
    ),
    (
        "scripts/linux/restore_zig_toolchain_archive.sh",
        "Archive restore helper that stages a real Zig archive under ../toolchains.",
    ),
)

CONTENT_EXPECTATIONS = (
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "scripts/linux/check_issue3_zig_toolchain_match.sh",
        "The Linux/WSL note keeps the dedicated matching-line gate visible.",
    ),
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        "The Linux/WSL note keeps the archive-restore surface checker visible before a restore is trusted.",
    ),
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
        "The Linux/WSL note keeps the archive-restore route note in the read-first chain.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "The Zig recovery note keeps the saved-archive candidate helper visible.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "scripts/linux/check_issue3_zig_toolchain_match.sh",
        "The Zig recovery note keeps the dedicated matching-line gate visible.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        "The Zig recovery note keeps the archive-restore surface checker visible.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
        "The Zig recovery note keeps the fallback restore helper visible.",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        "check_issue3_saved_zig_archive_candidates.py",
        "The Zig recovery route printer keeps the saved-archive candidate helper in the surfaced command set.",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        "The Zig recovery route printer keeps the archive-restore surface checker visible.",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        "restore_issue3_fallback_zig_toolchain.sh",
        "The Zig recovery route printer keeps the fallback restore helper visible.",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
        "show_issue3_zig_toolchain_recovery_route.sh",
        "The archive-restore route printer keeps the follow-up recovery route visible.",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
        "restore_zig_toolchain_archive.sh",
        "The archive-restore route printer keeps the concrete restore helper visible.",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check that the issue #3 Zig recovery route still points at its key helpers."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of plain text")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


def run_checks(repo_root: pathlib.Path) -> dict[str, object]:
    missing_references: list[dict[str, str]] = []
    missing_content: list[dict[str, str]] = []

    for relative_path, purpose in REFERENCE_PATHS:
        full_path = repo_root / relative_path
        if not full_path.is_file():
            missing_references.append({"path": relative_path, "purpose": purpose})

    for relative_path, snippet, purpose in CONTENT_EXPECTATIONS:
        full_path = repo_root / relative_path
        if not full_path.is_file():
            missing_content.append({"path": relative_path, "snippet": snippet, "purpose": purpose})
            continue
        text = full_path.read_text(encoding="utf-8")
        if snippet not in text:
            missing_content.append({"path": relative_path, "snippet": snippet, "purpose": purpose})

    failures: list[str] = []
    if missing_references:
        failures.append("missing route helper files")
    if missing_content:
        failures.append("missing route helper snippets")

    return {
        "status": "failed" if failures else "passed",
        "repo_root": str(repo_root),
        "reference_count": len(REFERENCE_PATHS),
        "content_check_count": len(CONTENT_EXPECTATIONS),
        "missing_references": missing_references,
        "missing_content": missing_content,
        "failures": failures,
    }


class ZigRouteAlignmentTests(unittest.TestCase):
    def test_passes_when_all_files_and_snippets_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = pathlib.Path(tmpdir)
            for relative_path, _purpose in REFERENCE_PATHS:
                full_path = repo_root / relative_path
                full_path.parent.mkdir(parents=True, exist_ok=True)
                full_path.write_text("", encoding="utf-8")

            for relative_path, snippet, _purpose in CONTENT_EXPECTATIONS:
                full_path = repo_root / relative_path
                existing = full_path.read_text(encoding="utf-8")
                full_path.write_text(existing + snippet + "\n", encoding="utf-8")

            report = run_checks(repo_root)
            self.assertEqual(report["status"], "passed")
            self.assertEqual(report["missing_references"], [])
            self.assertEqual(report["missing_content"], [])

    def test_reports_missing_reference(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = pathlib.Path(tmpdir)
            report = run_checks(repo_root)
            self.assertEqual(report["status"], "failed")
            self.assertTrue(report["missing_references"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ZigRouteAlignmentTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    report = run_checks(repo_root)

    if args.json:
        print(json.dumps(report, indent=2))
        return 1 if report["failures"] else 0

    print("Issue #3 Zig route alignment check")
    print()
    print(f"Repo root: {repo_root}")
    print(f"Reference paths checked: {report['reference_count']}")
    print(f"Content expectations checked: {report['content_check_count']}")

    if report["missing_references"]:
        print()
        print("Missing helper files:")
        for row in report["missing_references"]:
            print(f"  - {row['path']}: {row['purpose']}")

    if report["missing_content"]:
        print()
        print("Missing helper snippets:")
        for row in report["missing_content"]:
            print(f"  - {row['path']}: {row['snippet']}")

    if report["failures"]:
        print()
        print("Zig route alignment check failed.", flush=True)
        return 1

    print()
    print("Zig route alignment check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
