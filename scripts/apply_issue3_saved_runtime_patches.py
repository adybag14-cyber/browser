#!/usr/bin/env python3

"""Check or apply the saved issue #3 runtime patches in a writable checkout.

This helper keeps the saved Memory patch route branch-local so the next writable
checkout can reopen the direct headed Enter-submit fix without rebuilding patch
paths or `git apply` commands by hand.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


DEFAULT_PAGE_PATCH = (
    "repo_archives/browser/patches/"
    "2026-05-22-issue3-enter-submit-page-revalidated.patch"
)
DEFAULT_WIN32_PATCH = (
    "repo_archives/browser/patches/"
    "2026-05-22-issue3-enter-submit-win32-revalidated.patch"
)
TARGET_FILES: tuple[str, ...] = (
    "src/browser/Page.zig",
    "src/display/win32_backend.zig",
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check or apply the saved issue #3 runtime patches from Memory in "
            "a writable browser checkout."
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
        help=(
            "Path to the workspace memory root "
            "(default: ../memory beside the repo workspace)"
        ),
    )
    parser.add_argument(
        "--page-patch",
        default=None,
        help="Optional explicit path to the saved Page.zig runtime patch",
    )
    parser.add_argument(
        "--win32-patch",
        default=None,
        help="Optional explicit path to the saved Win32 runtime patch",
    )
    parser.add_argument(
        "--check-only",
        action="store_true",
        help="Validate the saved patches and target files without applying them",
    )
    parser.add_argument(
        "--allow-dirty-targets",
        action="store_true",
        help=(
            "Allow apply mode even when the target files already have local "
            "changes"
        ),
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


def resolve_patch_paths(
    *,
    repo_root: Path,
    memory_root: Path | None,
    page_patch: str | None,
    win32_patch: str | None,
) -> tuple[Path, Path, Path]:
    resolved_memory_root = (
        Path(memory_root).resolve()
        if memory_root is not None
        else resolve_default_memory_root(repo_root)
    )
    resolved_page_patch = (
        Path(page_patch).resolve()
        if page_patch is not None
        else (resolved_memory_root / DEFAULT_PAGE_PATCH).resolve()
    )
    resolved_win32_patch = (
        Path(win32_patch).resolve()
        if win32_patch is not None
        else (resolved_memory_root / DEFAULT_WIN32_PATCH).resolve()
    )
    return resolved_memory_root, resolved_page_patch, resolved_win32_patch


def run_git(
    repo_root: Path, args: list[str]
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo_root), *args],
        capture_output=True,
        text=True,
    )


def probe_patch(repo_root: Path, patch_path: Path) -> dict[str, object]:
    forward = run_git(repo_root, ["apply", "--check", str(patch_path)])
    if forward.returncode == 0:
        return {
            "patch": str(patch_path),
            "status": "applies_cleanly",
            "detail": "",
        }

    reverse = run_git(
        repo_root,
        ["apply", "--reverse", "--check", str(patch_path)],
    )
    if reverse.returncode == 0:
        return {
            "patch": str(patch_path),
            "status": "already_applied",
            "detail": "",
        }

    detail = (forward.stderr or forward.stdout or "").strip()
    return {
        "patch": str(patch_path),
        "status": "failed",
        "detail": detail,
    }


def collect_dirty_targets(repo_root: Path) -> list[str]:
    result = run_git(repo_root, ["status", "--porcelain", "--", *TARGET_FILES])
    if result.returncode != 0:
        raise RuntimeError(
            "git status failed for target files: "
            + (result.stderr or result.stdout).strip()
        )
    dirty: list[str] = []
    for line in result.stdout.splitlines():
        if not line.strip():
            continue
        dirty.append(line[3:])
    return dirty


def collect_results(
    *,
    repo_root: Path,
    memory_root: Path,
    page_patch_path: Path,
    win32_patch_path: Path,
    allow_dirty_targets: bool,
) -> dict[str, object]:
    missing_inputs: list[str] = []

    target_rows = []
    for target in TARGET_FILES:
        target_path = (repo_root / target).resolve()
        exists = target_path.is_file()
        if not exists:
            missing_inputs.append(target)
        target_rows.append(
            {
                "path": str(target_path),
                "exists": exists,
            }
        )

    patch_rows = []
    for label, patch_path in (
        ("page_patch", page_patch_path),
        ("win32_patch", win32_patch_path),
    ):
        exists = patch_path.is_file()
        if not exists:
            missing_inputs.append(label)
        patch_rows.append(
            {
                "label": label,
                "path": str(patch_path),
                "exists": exists,
            }
        )

    dirty_targets: list[str] = []
    patch_statuses: list[dict[str, object]] = []
    if not missing_inputs:
        dirty_targets = collect_dirty_targets(repo_root)
        patch_statuses = [
            probe_patch(repo_root, page_patch_path),
            probe_patch(repo_root, win32_patch_path),
        ]

    status_ok = (
        not missing_inputs
        and all(entry["status"] != "failed" for entry in patch_statuses)
        and (allow_dirty_targets or not dirty_targets)
    )

    return {
        "ok": status_ok,
        "repo_root": str(repo_root),
        "memory_root": str(memory_root),
        "target_files": target_rows,
        "patch_files": patch_rows,
        "dirty_targets": dirty_targets,
        "allow_dirty_targets": allow_dirty_targets,
        "patch_statuses": patch_statuses,
    }


def apply_patches(
    *,
    repo_root: Path,
    patch_statuses: list[dict[str, object]],
) -> list[str]:
    applied: list[str] = []
    for entry in patch_statuses:
        if entry["status"] != "applies_cleanly":
            continue
        patch_path = Path(str(entry["patch"]))
        result = run_git(repo_root, ["apply", str(patch_path)])
        if result.returncode != 0:
            raise RuntimeError(
                f"git apply failed for {patch_path}: "
                + (result.stderr or result.stdout).strip()
            )
        applied.append(str(patch_path))
    return applied


def emit_text(result: dict[str, object], applied: list[str]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Memory root: {result['memory_root']}")
    print("Target files:")
    for entry in result["target_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['path']}")
    print("Saved patches:")
    for entry in result["patch_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['label']}: {entry['path']}")
    if result["dirty_targets"]:
        print("Dirty target files:")
        for path in result["dirty_targets"]:
            print(f"  [WARN] {path}")
    else:
        print("Dirty target files: none")
    print("Patch checks:")
    for entry in result["patch_statuses"]:
        print(f"  [{entry['status']}] {entry['patch']}")
        if entry["detail"]:
            print(f"    {entry['detail']}")
    if applied:
        print("Applied patches:")
        for patch in applied:
            print(f"  [APPLIED] {patch}")
    elif result["ok"]:
        print("No patches needed to be applied.")


class ApplyIssue3SavedRuntimePatchesTests(unittest.TestCase):
    def test_default_memory_root_follows_workspace_layout(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        self.assertEqual(
            resolve_default_memory_root(repo_root),
            Path("/tmp/workspace/memory"),
        )

    def test_resolve_patch_paths_uses_memory_defaults(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        memory_root, page_patch, win32_patch = resolve_patch_paths(
            repo_root=repo_root,
            memory_root=None,
            page_patch=None,
            win32_patch=None,
        )
        self.assertEqual(memory_root, Path("/tmp/workspace/memory"))
        self.assertTrue(str(page_patch).endswith(DEFAULT_PAGE_PATCH))
        self.assertTrue(str(win32_patch).endswith(DEFAULT_WIN32_PATCH))

    def test_collect_results_reports_missing_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            memory_root = Path(tmpdir) / "memory"
            memory_root.mkdir()
            result = collect_results(
                repo_root=repo_root,
                memory_root=memory_root,
                page_patch_path=memory_root / "missing-page.patch",
                win32_patch_path=memory_root / "missing-win32.patch",
                allow_dirty_targets=False,
            )
            self.assertFalse(result["ok"])
            self.assertEqual(len(result["target_files"]), 2)
            self.assertEqual(len(result["patch_files"]), 2)
            self.assertEqual(result["patch_statuses"], [])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            ApplyIssue3SavedRuntimePatchesTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root, page_patch_path, win32_patch_path = resolve_patch_paths(
        repo_root=repo_root,
        memory_root=args.memory_root,
        page_patch=args.page_patch,
        win32_patch=args.win32_patch,
    )

    result = collect_results(
        repo_root=repo_root,
        memory_root=memory_root,
        page_patch_path=page_patch_path,
        win32_patch_path=win32_patch_path,
        allow_dirty_targets=args.allow_dirty_targets,
    )

    if not result["ok"]:
        if args.json:
            print(json.dumps(result, indent=2))
        else:
            emit_text(result, [])
        return 1

    applied: list[str] = []
    if not args.check_only:
        applied = apply_patches(
            repo_root=repo_root,
            patch_statuses=result["patch_statuses"],
        )

    if args.json:
        print(json.dumps({**result, "applied_patches": applied}, indent=2))
    else:
        emit_text(result, applied)
    return 0


if __name__ == "__main__":
    sys.exit(main())
