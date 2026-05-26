#!/usr/bin/env python3

"""Check that restored issue #3 helper surfaces include the newer re-entry routes.

This helper focuses on the smaller set of late-added Linux/WSL re-entry route
files that older restored snapshots can miss while still looking mostly usable.
It is meant to fail fast before a run trusts a restored checkout for issue #11
or reopens the narrowed issue #3 runtime lane.
"""

from __future__ import annotations

import argparse
from contextlib import redirect_stdout
import hashlib
import io
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest


ISSUE_LABEL = "Issue #11 Linux/WSL restored helper-surface sync route for issue #3 re-entry"
JSON_PROFILE = "issue11-restored-helper-surface-sync"
RESTORE_HELPER_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"
HELPER_SURFACE_LINE_RE = re.compile(r'^\s*"([^"]+)"\s*$')

BASE_REQUIRED_REENTRY_ROUTE_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 tracker route"),
    (
        "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
        "restored helper-surface sync route note",
    ),
    (
        "scripts/check_issue3_restored_helper_surface_sync.py",
        "restored helper-surface sync helper",
    ),
    ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
    (
        "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
        "restored helper-surface sync route surface checker",
    ),
    (
        "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
        "restored helper-surface sync route helper",
    ),
    (
        RESTORE_HELPER_PATH,
        "saved snapshot restore helper that defines the current helper-surface copy set",
    ),
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def extract_helper_surface_paths(script_text: str) -> list[str]:
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

        match = HELPER_SURFACE_LINE_RE.match(line)
        if match is not None:
            paths.append(match.group(1))

    if not in_block:
        raise ValueError(
            f"Could not find HELPER_SURFACE_PATHS in {RESTORE_HELPER_PATH}"
        )
    if not paths:
        raise ValueError(f"HELPER_SURFACE_PATHS in {RESTORE_HELPER_PATH} is empty")
    return paths


def load_required_reentry_route_files(helper_root: Path) -> list[tuple[str, str]]:
    required = list(BASE_REQUIRED_REENTRY_ROUTE_FILES)
    known_paths = {path for path, _label in required}
    restore_helper = helper_root / RESTORE_HELPER_PATH
    if not restore_helper.is_file():
        return required

    helper_paths = extract_helper_surface_paths(restore_helper.read_text(encoding="utf-8"))
    for helper_path in helper_paths:
        if helper_path in known_paths:
            continue
        required.append(
            (
                helper_path,
                "Current helper-surface path mirrored from "
                f"{RESTORE_HELPER_PATH} so the narrower sync check cannot "
                "silently miss a newer follow-up helper.",
            )
        )
        known_paths.add(helper_path)

    return required


def collect_file_state(root: Path, relative_path: str, label: str) -> dict[str, object]:
    path = root / relative_path
    exists = path.is_file()
    return {
        "label": label,
        "relative_path": relative_path,
        "path": str(path),
        "exists": exists,
        "sha256": sha256(path) if exists else None,
    }


def compare_helper_surfaces(helper_root: Path, restored_root: Path) -> dict[str, object]:
    required_files = load_required_reentry_route_files(helper_root)
    helper_rows: list[dict[str, object]] = []
    restored_rows: list[dict[str, object]] = []
    drifted: list[str] = []
    missing_in_helper: list[str] = []
    missing_in_restored: list[str] = []

    for relative_path, label in required_files:
        helper_row = collect_file_state(helper_root, relative_path, label)
        restored_row = collect_file_state(restored_root, relative_path, label)
        helper_rows.append(helper_row)
        restored_rows.append(restored_row)

        helper_exists = bool(helper_row["exists"])
        restored_exists = bool(restored_row["exists"])
        if not helper_exists:
            missing_in_helper.append(relative_path)
        if not restored_exists:
            missing_in_restored.append(relative_path)
        if helper_exists and restored_exists and helper_row["sha256"] != restored_row["sha256"]:
            drifted.append(relative_path)

    ok = not missing_in_helper and not missing_in_restored and not drifted
    return {
        "ok": ok,
        "helper_root": str(helper_root),
        "restored_root": str(restored_root),
        "required_path_count": len(required_files),
        "helper_files": helper_rows,
        "restored_files": restored_rows,
        "missing_in_helper": missing_in_helper,
        "missing_in_restored": missing_in_restored,
        "drifted_files": drifted,
    }


def serialize_report(report: dict[str, object]) -> dict[str, object]:
    return {"profile": JSON_PROFILE, "issue": ISSUE_LABEL, **report}


def emit_text(report: dict[str, object]) -> None:
    print(ISSUE_LABEL)
    print()
    print(f"Helper root:   {report['helper_root']}")
    print(f"Restored root: {report['restored_root']}")
    print()

    for relative_path in report["missing_in_helper"]:
        print(f"[FAIL] helper root missing {relative_path}")
    for relative_path in report["missing_in_restored"]:
        print(f"[FAIL] restored checkout missing {relative_path}")
    for relative_path in report["drifted_files"]:
        print(f"[FAIL] restored checkout drifted at {relative_path}")

    if report["ok"]:
        print("Restored helper surface sync passed.")
        return

    print()
    print("Suggested next step:")
    print(
        "  Refresh the restored checkout helper surface from the live branch-local "
        "helper root before trusting Linux/WSL re-entry commands."
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a restored checkout still carries the issue #11 "
            "Linux/WSL helper surface that supports issue #3 runtime re-entry."
        )
    )
    parser.add_argument(
        "--helper-root",
        default=".",
        help="Path to the live helper checkout root (default: current directory)",
    )
    parser.add_argument(
        "--restored-root",
        required=False,
        default="../browser-memory-snapshot",
        help="Path to the restored checkout root to compare",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of the human-readable summary",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    return parser


def make_restore_helper_script(*helper_surface_paths: str) -> str:
    lines = ["#!/usr/bin/env bash", "", "declare -a HELPER_SURFACE_PATHS=("]
    lines.extend(f'    "{path}"' for path in helper_surface_paths)
    lines.append(")")
    lines.append("")
    return "\n".join(lines)


def write_required_files(
    helper_root: Path,
    restored_root: Path,
    required_files: list[tuple[str, str]],
    restore_helper_text: str,
) -> None:
    for relative_path, _label in required_files:
        for base in (helper_root, restored_root):
            target = base / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            if relative_path == RESTORE_HELPER_PATH:
                target.write_text(restore_helper_text, encoding="utf-8")
            else:
                target.write_text(relative_path, encoding="utf-8")


class RestoredHelperSurfaceSyncTests(unittest.TestCase):
    def test_extract_helper_surface_paths_parses_restore_helper_array(self) -> None:
        script_text = make_restore_helper_script(
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "scripts/check_issue3_workspace_context.py",
        )

        self.assertEqual(
            extract_helper_surface_paths(script_text),
            [
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/check_issue3_workspace_context.py",
            ],
        )

    def test_load_required_reentry_route_files_includes_dynamic_restore_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir)
            restore_helper = helper_root / RESTORE_HELPER_PATH
            restore_helper.parent.mkdir(parents=True, exist_ok=True)
            restore_helper.write_text(
                make_restore_helper_script(
                    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                    "scripts/check_issue3_workspace_context.py",
                    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
                ),
                encoding="utf-8",
            )

            required = load_required_reentry_route_files(helper_root)
            required_paths = {path for path, _label in required}

            self.assertIn("scripts/check_issue3_workspace_context.py", required_paths)
            self.assertIn(
                "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
                required_paths,
            )

    def test_compare_passes_when_roots_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "helper"
            restored_root = root / "restored"
            helper_root.mkdir()
            restored_root.mkdir()
            restore_helper_text = make_restore_helper_script(
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
                "scripts/check_issue3_workspace_context.py",
                "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
                "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
            )
            (helper_root / RESTORE_HELPER_PATH).parent.mkdir(parents=True, exist_ok=True)
            (helper_root / RESTORE_HELPER_PATH).write_text(
                restore_helper_text, encoding="utf-8"
            )
            required_files = load_required_reentry_route_files(helper_root)
            write_required_files(
                helper_root, restored_root, required_files, restore_helper_text
            )

            report = compare_helper_surfaces(helper_root, restored_root)

            self.assertTrue(report["ok"])
            self.assertEqual(report["missing_in_restored"], [])
            self.assertEqual(report["drifted_files"], [])

    def test_compare_reports_dynamic_missing_and_drifted_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "helper"
            restored_root = root / "restored"
            helper_root.mkdir()
            restored_root.mkdir()
            restore_helper_text = make_restore_helper_script(
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
                "scripts/check_issue3_saved_zig_archive_candidates.py",
                "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
            )
            (helper_root / RESTORE_HELPER_PATH).parent.mkdir(parents=True, exist_ok=True)
            (helper_root / RESTORE_HELPER_PATH).write_text(
                restore_helper_text, encoding="utf-8"
            )
            required_files = load_required_reentry_route_files(helper_root)
            write_required_files(
                helper_root, restored_root, required_files, restore_helper_text
            )

            missing_path = "scripts/check_issue3_saved_zig_archive_candidates.py"
            drifted_path = "scripts/linux/show_issue3_windows_runtime_handoff_route.sh"
            (restored_root / missing_path).unlink()
            (restored_root / drifted_path).write_text("drifted", encoding="utf-8")

            report = compare_helper_surfaces(helper_root, restored_root)

            self.assertFalse(report["ok"])
            self.assertIn(missing_path, report["missing_in_restored"])
            self.assertIn(drifted_path, report["drifted_files"])

    def test_restored_helper_route_note_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "helper"
            restored_root = root / "restored"
            helper_root.mkdir()
            restored_root.mkdir()
            restore_helper_text = make_restore_helper_script(
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
            )
            (helper_root / RESTORE_HELPER_PATH).parent.mkdir(parents=True, exist_ok=True)
            (helper_root / RESTORE_HELPER_PATH).write_text(
                restore_helper_text, encoding="utf-8"
            )
            required_files = load_required_reentry_route_files(helper_root)
            write_required_files(
                helper_root, restored_root, required_files, restore_helper_text
            )

            missing_note = "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md"
            (restored_root / missing_note).unlink()

            report = compare_helper_surfaces(helper_root, restored_root)

            self.assertFalse(report["ok"])
            self.assertIn(missing_note, report["missing_in_restored"])

    def test_restored_helper_route_surface_checker_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "helper"
            restored_root = root / "restored"
            helper_root.mkdir()
            restored_root.mkdir()
            restore_helper_text = make_restore_helper_script(
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
            )
            (helper_root / RESTORE_HELPER_PATH).parent.mkdir(parents=True, exist_ok=True)
            (helper_root / RESTORE_HELPER_PATH).write_text(
                restore_helper_text, encoding="utf-8"
            )
            required_files = load_required_reentry_route_files(helper_root)
            write_required_files(
                helper_root, restored_root, required_files, restore_helper_text
            )

            missing_surface = (
                "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh"
            )
            (restored_root / missing_surface).unlink()

            report = compare_helper_surfaces(helper_root, restored_root)

            self.assertFalse(report["ok"])
            self.assertIn(missing_surface, report["missing_in_restored"])

    def test_serialize_report_adds_issue11_context(self) -> None:
        serialized = serialize_report(
            {
                "ok": True,
                "helper_root": "/tmp/helper",
                "restored_root": "/tmp/restored",
                "required_path_count": 7,
                "helper_files": [],
                "restored_files": [],
                "missing_in_helper": [],
                "missing_in_restored": [],
                "drifted_files": [],
            }
        )

        self.assertEqual(serialized["profile"], JSON_PROFILE)
        self.assertEqual(serialized["issue"], ISSUE_LABEL)
        self.assertTrue(serialized["ok"])

    def test_emit_text_uses_issue11_heading(self) -> None:
        report = {
            "ok": True,
            "helper_root": "/tmp/helper",
            "restored_root": "/tmp/restored",
            "missing_in_helper": [],
            "missing_in_restored": [],
            "drifted_files": [],
        }

        buffer = io.StringIO()
        with redirect_stdout(buffer):
            emit_text(report)

        output = buffer.getvalue()
        self.assertIn(ISSUE_LABEL, output)
        self.assertIn("Restored helper surface sync passed.", output)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            RestoredHelperSurfaceSyncTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    helper_root = Path(args.helper_root).resolve()
    restored_root = Path(args.restored_root).resolve()
    report = compare_helper_surfaces(helper_root, restored_root)

    if args.json:
        print(json.dumps(serialize_report(report), indent=2))
    else:
        emit_text(report)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())