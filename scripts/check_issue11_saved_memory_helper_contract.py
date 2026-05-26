#!/usr/bin/env python3

"""Check the issue #11 saved-memory helper contract for restore-route drift.

This helper is for the Linux/WSL headed re-entry lane. It compares the main
saved-memory preflight, the restored-checkout checker, the snapshot-restore
helper, and the saved-memory route printer so future runs can fail fast when
newer helper-surface paths are present in one place but not the others.
"""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import tempfile
import textwrap
import unittest


FILES = {
    "saved_memory_helper": "scripts/check_issue3_saved_memory_inputs.py",
    "restored_checkout_helper": "scripts/check_issue3_restored_checkout.py",
    "restore_helper": "scripts/linux/restore_saved_browser_snapshot.sh",
    "saved_memory_route": "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
}

SHARED_FRAGMENTS: tuple[tuple[str, tuple[str, ...], str], ...] = (
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        ("restored_checkout_helper", "restore_helper", "saved_memory_route"),
        "Issue #11 progress-tracker handoff should stay visible across the live helper contract.",
    ),
    (
        "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the narrower restored-helper surface sync route visible.",
    ),
    (
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the saved snapshot archive-surface note visible.",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the saved Rust build-readiness bridge visible.",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the saved Rust archive-candidate route visible.",
    ),
    (
        "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
        ("restore_helper",),
        "The restore helper should keep the staged Zig toolchain route visible to downstream issue #11 checks.",
    ),
    (
        "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
        ("restore_helper",),
        "The restore helper should keep the staged Rust toolchain route visible to downstream issue #11 checks.",
    ),
    (
        "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the saved snapshot archive-surface helper visible.",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the saved Rust archive-candidate helper visible.",
    ),
    (
        "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the staged Rust toolchain candidate helper visible.",
    ),
    (
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        ("saved_memory_helper", "restored_checkout_helper", "restore_helper"),
        "Saved Zig archive candidate discovery should stay visible in the shared helper contract.",
    ),
    (
        "scripts/check_issue3_staged_zig_toolchain_candidates.py",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the staged Zig toolchain candidate helper visible.",
    ),
    (
        "scripts/check_issue3_restored_helper_surface_sync.py",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the restored-helper surface sync checker visible.",
    ),
    (
        "scripts/check_issue3_build_readiness_rerun.py",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the build-readiness rerun helper visible.",
    ),
    (
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the issue #11 progress-tracker surface checker visible.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the issue #11 progress-tracker route printer visible.",
    ),
    (
        "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the restored-helper surface sync route checker visible.",
    ),
    (
        "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the restored-helper surface sync route printer visible.",
    ),
    (
        "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
        ("saved_memory_route",),
        "The saved-memory route should keep its own fail-fast surface checker visible.",
    ),
    (
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
        ("saved_memory_route",),
        "The saved-memory route should keep its own route printer visible.",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the saved Rust build-readiness route checker visible.",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the saved Rust build-readiness route printer visible.",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the saved Rust archive-candidates route checker visible.",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the saved Rust archive-candidates route printer visible.",
    ),
    (
        "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
        ("restore_helper",),
        "The restore helper should keep the staged Zig route surface checker visible to downstream issue #11 checks.",
    ),
    (
        "scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh",
        ("restore_helper",),
        "The restore helper should keep the staged Zig route printer visible to downstream issue #11 checks.",
    ),
    (
        "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
        ("restore_helper",),
        "The restore helper should keep the staged Rust route surface checker visible to downstream issue #11 checks.",
    ),
    (
        "scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh",
        ("restore_helper",),
        "The restore helper should keep the staged Rust route printer visible to downstream issue #11 checks.",
    ),
    (
        "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
        ("restored_checkout_helper", "restore_helper", "saved_memory_route"),
        "The restore-side helpers and saved-memory route should keep the nested-workspace issue #11 rerun helper visible.",
    ),
    (
        "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the Windows runtime handoff surface checker visible.",
    ),
    (
        "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
        ("restored_checkout_helper", "restore_helper"),
        "The restore-side helpers should keep the Windows runtime handoff route printer visible.",
    ),
    (
        "live_helper_restored_checkout_preflight",
        ("saved_memory_route",),
        "The saved-memory route should expose the live-helper preflight command for restored snapshots.",
    ),
)

MISSING_FILE_SENTINEL = "<required contract file is missing>"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #11 saved-memory helper contract has drifted "
            "between the saved-memory preflight, restored-checkout helper, "
            "snapshot-restore helper, and saved-memory route printer."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of a line-oriented summary",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused self-tests and exit",
    )
    return parser


def extract_restore_helper_paths(script_text: str) -> set[str]:
    marker = 'declare -a HELPER_SURFACE_PATHS=('
    in_block = False
    paths: set[str] = set()

    for line in script_text.splitlines():
        stripped = line.strip()
        if not in_block:
            if stripped == marker:
                in_block = True
            continue

        if stripped == ")":
            break

        if stripped.startswith('"') and stripped.endswith('"'):
            paths.add(stripped.strip('"'))

    return paths


def extract_saved_memory_base_paths(source_text: str) -> set[str]:
    try:
        module = ast.parse(source_text)
    except SyntaxError:
        return set()

    for node in module.body:
        value = None
        if isinstance(node, ast.Assign):
            if any(isinstance(target, ast.Name) and target.id == "BASE_REQUIRED_RESTORED_HELPER_FILES" for target in node.targets):
                value = node.value
        elif isinstance(node, ast.AnnAssign):
            if isinstance(node.target, ast.Name) and node.target.id == "BASE_REQUIRED_RESTORED_HELPER_FILES":
                value = node.value

        if value is None or not isinstance(value, (ast.Tuple, ast.List)):
            continue

        paths: set[str] = set()
        for element in value.elts:
            if not isinstance(element, (ast.Tuple, ast.List)) or not element.elts:
                continue
            first = element.elts[0]
            if isinstance(first, ast.Constant) and isinstance(first.value, str):
                paths.add(first.value)
        return paths

    return set()


def saved_memory_helper_mirrors_restore_paths(source_text: str) -> bool:
    required_fragments = (
        "def extract_restore_helper_paths(",
        "helper_paths = extract_restore_helper_paths(",
        "for helper_path in helper_paths:",
        "required.append(",
    )
    return all(fragment in source_text for fragment in required_fragments)


def is_path_fragment(fragment: str) -> bool:
    return "/" in fragment


def read_contract_files(repo_root: Path) -> tuple[dict[str, str], dict[str, str]]:
    texts: dict[str, str] = {}
    missing_files: dict[str, str] = {}
    for key, rel_path in FILES.items():
        path = repo_root / rel_path
        try:
            texts[key] = path.read_text(encoding="utf-8")
        except OSError:
            texts[key] = ""
            missing_files[key] = rel_path
    return texts, missing_files


def collect_saved_memory_coverage(texts: dict[str, str]) -> set[str]:
    covered = extract_saved_memory_base_paths(texts["saved_memory_helper"])
    if saved_memory_helper_mirrors_restore_paths(texts["saved_memory_helper"]):
        covered.update(extract_restore_helper_paths(texts["restore_helper"]))
    return covered


def collect_results(repo_root: Path) -> dict[str, object]:
    texts, missing_files = read_contract_files(repo_root)
    checks: list[dict[str, object]] = []
    missing_count = 0
    missing_by_file: dict[str, list[str]] = {
        FILES[key]: [MISSING_FILE_SENTINEL] for key in missing_files
    }

    for fragment, required_in, purpose in SHARED_FRAGMENTS:
        for key in required_in:
            if key in missing_files:
                continue
            exists = fragment in texts[key]
            if not exists:
                missing_count += 1
                missing_by_file.setdefault(FILES[key], []).append(fragment)
            checks.append(
                {
                    "file_key": key,
                    "path": FILES[key],
                    "fragment": fragment,
                    "purpose": purpose,
                    "exists": exists,
                }
            )

    saved_memory_text = texts["saved_memory_helper"]
    saved_memory_coverage = collect_saved_memory_coverage(texts)
    restore_side_fragments = {
        fragment
        for fragment, _required_in, _purpose in SHARED_FRAGMENTS
        if fragment in texts["restored_checkout_helper"] or fragment in texts["restore_helper"]
    }
    underreported_fragments = sorted(
        fragment
        for fragment in restore_side_fragments
        if (
            fragment not in saved_memory_coverage
            if is_path_fragment(fragment)
            else fragment not in saved_memory_text
        )
    )

    ok = not missing_files and missing_count == 0 and not underreported_fragments
    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "checks": checks,
        "missing_by_file": missing_by_file,
        "missing_contract_files": [FILES[key] for key in sorted(missing_files)],
        "underreported_fragments": underreported_fragments,
        "missing_count": missing_count,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    for check in result["checks"]:
        status = "PASS" if check["exists"] else "FAIL"
        print(f"[{status}] {check['path']}")
        print(f"  fragment: {check['fragment']}")
        print(f"  {check['purpose']}")

    if result["missing_contract_files"]:
        print("\nMissing contract files:")
        for path in result["missing_contract_files"]:
            print(f"  - {path}")

    if result["underreported_fragments"]:
        print("\nUnder-reported restore-side fragments:", flush=True)
        for fragment in result["underreported_fragments"]:
            print(f"  - {fragment}")

    if result["ok"]:
        print("\nSaved-memory helper contract check passed.")
    else:
        print("\nSaved-memory helper contract check failed.")


def build_saved_memory_helper_fixture(*, mirror_restore_paths: bool) -> str:
    base_paths = (
        'BASE_REQUIRED_RESTORED_HELPER_FILES = (\n'
        '    ("scripts/check_issue3_saved_zig_archive_candidates.py", "fixture"),\n'
        ')\n'
    )
    if not mirror_restore_paths:
        return base_paths

    return (
        base_paths
        + "\n"
        + textwrap.dedent(
            """
            def extract_restore_helper_paths(script_text: str) -> list[str]:
                return []


            def load_required_restored_helper_files(helper_root):
                required = list(BASE_REQUIRED_RESTORED_HELPER_FILES)
                helper_paths = extract_restore_helper_paths("fixture")
                for helper_path in helper_paths:
                    required.append((helper_path, "mirrored"))
                return required
            """
        ).strip()
        + "\n"
    )


def build_restore_helper_fixture(*, include_restore_fragments: bool) -> str:
    restore_paths = [
        fragment
        for fragment, required_in, _purpose in SHARED_FRAGMENTS
        if include_restore_fragments and "restore_helper" in required_in and is_path_fragment(fragment)
    ]
    lines = ["#!/usr/bin/env bash", "", "declare -a HELPER_SURFACE_PATHS=("]
    lines.extend(f'    "{fragment}"' for fragment in restore_paths)
    lines.append(")")
    lines.append("")
    return "\n".join(lines)


def build_fixture_repo(
    *,
    mirror_restore_paths: bool,
    include_restore_fragments: bool = True,
) -> Path:
    root = Path(tempfile.mkdtemp(prefix="issue11-saved-memory-contract-"))
    for rel_path in FILES.values():
        target = root / rel_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("", encoding="utf-8")

    restored_bits = "\n".join(
        fragment
        for fragment, required_in, _purpose in SHARED_FRAGMENTS
        if "restored_checkout_helper" in required_in
    )
    route_bits = "\n".join(
        fragment
        for fragment, required_in, _purpose in SHARED_FRAGMENTS
        if "saved_memory_route" in required_in
    )

    (root / FILES["restored_checkout_helper"]).write_text(
        textwrap.dedent(
            f"""
            {restored_bits}
            """
        ).strip()
        + "\n",
        encoding="utf-8",
    )
    (root / FILES["restore_helper"]).write_text(
        build_restore_helper_fixture(include_restore_fragments=include_restore_fragments),
        encoding="utf-8",
    )
    (root / FILES["saved_memory_route"]).write_text(
        textwrap.dedent(
            f"""
            {route_bits}
            """
        ).strip()
        + "\n",
        encoding="utf-8",
    )
    (root / FILES["saved_memory_helper"]).write_text(
        build_saved_memory_helper_fixture(mirror_restore_paths=mirror_restore_paths),
        encoding="utf-8",
    )
    return root


class Issue11SavedMemoryHelperContractTests(unittest.TestCase):
    def test_passes_when_dynamic_restore_mirroring_is_present(self) -> None:
        repo_root = build_fixture_repo(
            mirror_restore_paths=True,
        )
        result = collect_results(repo_root)
        self.assertTrue(result["ok"])
        self.assertEqual(result["underreported_fragments"], [])
        self.assertEqual(result["missing_contract_files"], [])

    def test_flags_restore_side_paths_when_saved_memory_helper_lacks_dynamic_mirroring(self) -> None:
        repo_root = build_fixture_repo(mirror_restore_paths=False)
        result = collect_results(repo_root)
        self.assertFalse(result["ok"])
        self.assertIn(
            "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
            result["underreported_fragments"],
        )
        self.assertIn(
            "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
            result["underreported_fragments"],
        )
        self.assertIn(
            "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
            result["underreported_fragments"],
        )
        self.assertIn(
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            result["underreported_fragments"],
        )
        self.assertIn(
            "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
            result["underreported_fragments"],
        )
        self.assertIn(
            "scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh",
            result["underreported_fragments"],
        )
        self.assertIn(
            "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
            result["underreported_fragments"],
        )

    def test_flags_restore_helper_fragments_missing_from_contract_checks(self) -> None:
        repo_root = build_fixture_repo(
            mirror_restore_paths=True,
            include_restore_fragments=False,
        )
        result = collect_results(repo_root)
        self.assertFalse(result["ok"])
        self.assertGreater(result["missing_count"], 0)

    def test_reports_missing_restore_helper_file_without_crashing(self) -> None:
        repo_root = build_fixture_repo(
            mirror_restore_paths=True,
        )
        (repo_root / FILES["restore_helper"]).unlink()
        result = collect_results(repo_root)
        self.assertFalse(result["ok"])
        self.assertIn(FILES["restore_helper"], result["missing_contract_files"])
        self.assertEqual(
            result["missing_by_file"][FILES["restore_helper"]],
            [MISSING_FILE_SENTINEL],
        )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue11SavedMemoryHelperContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps({"profile": "issue11-saved-memory-helper-contract", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
