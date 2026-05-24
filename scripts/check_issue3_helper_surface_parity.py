#!/usr/bin/env python3

"""Check that the issue #3 helper-surface manifests stay aligned.

The saved-browser-snapshot restore route currently describes its synced helper
surface in three places:

- scripts/linux/restore_saved_browser_snapshot.sh
- scripts/check_issue3_saved_memory_inputs.py
- scripts/check_issue3_restored_checkout.py

This helper compares those manifests so future Linux or WSL re-entry work can
fail fast on drift before a restore, sync-only refresh, or restored-checkout
validation step reuses stale helper expectations.
"""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import re
import sys
import tempfile
import textwrap
import unittest

SOURCE_SPECS: tuple[tuple[str, str, str], ...] = (
    (
        "restore-script",
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "HELPER_SURFACE_PATHS",
    ),
    (
        "saved-memory-helper",
        "scripts/check_issue3_saved_memory_inputs.py",
        "REQUIRED_RESTORED_HELPER_FILES",
    ),
    (
        "restored-checkout-helper",
        "scripts/check_issue3_restored_checkout.py",
        "HELPER_SURFACE_PATHS",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #3 helper-surface manifests still agree "
            "before snapshot restore, sync-only refresh, or restored-checkout "
            "re-entry work."
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
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def unique_preserving_order(values: list[str]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for value in values:
        if value not in seen:
            seen.add(value)
            ordered.append(value)
    return ordered


def extract_bash_array_paths(text: str, array_name: str) -> list[str]:
    pattern = re.compile(
        rf"declare -a {re.escape(array_name)}=\(\n(?P<body>.*?)\n\)",
        re.DOTALL,
    )
    match = pattern.search(text)
    if match is None:
        raise ValueError(f"Could not find bash array {array_name}")
    return unique_preserving_order(re.findall(r'"([^"\n]+)"', match.group("body")))


def extract_python_tuple_paths(text: str, constant_name: str) -> list[str]:
    module = ast.parse(text)
    for node in module.body:
        target_name: str | None = None
        value_node: ast.AST | None = None
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id == constant_name:
                    target_name = target.id
                    value_node = node.value
                    break
        elif isinstance(node, ast.AnnAssign):
            if isinstance(node.target, ast.Name) and node.target.id == constant_name:
                target_name = node.target.id
                value_node = node.value
        if target_name is None or value_node is None:
            continue
        value = ast.literal_eval(value_node)
        if not isinstance(value, tuple):
            raise ValueError(f"{constant_name} is not a tuple")
        paths = [entry[0] for entry in value if isinstance(entry, tuple) and entry]
        return unique_preserving_order(paths)
    raise ValueError(f"Could not find python constant {constant_name}")


def load_manifest_paths(repo_root: Path) -> dict[str, list[str]]:
    manifests: dict[str, list[str]] = {}
    for source_name, relative_path, constant_name in SOURCE_SPECS:
        text = read_text(repo_root / relative_path)
        if relative_path.endswith(".sh"):
            manifests[source_name] = extract_bash_array_paths(text, constant_name)
        else:
            manifests[source_name] = extract_python_tuple_paths(text, constant_name)
    return manifests


def collect_surface_state(repo_root: Path) -> dict[str, object]:
    manifests = load_manifest_paths(repo_root)
    manifest_sets = {
        source_name: set(paths) for source_name, paths in manifests.items()
    }
    union_paths = set().union(*manifest_sets.values()) if manifest_sets else set()
    shared_paths = (
        set.intersection(*manifest_sets.values()) if manifest_sets else set()
    )
    duplicates = {
        source_name: sorted(
            {
                path
                for path in paths
                if paths.count(path) > 1
            }
        )
        for source_name, paths in manifests.items()
    }
    missing_from_sources = {
        source_name: sorted(union_paths - manifest_paths)
        for source_name, manifest_paths in manifest_sets.items()
    }
    missing_files = sorted(
        path for path in union_paths if not (repo_root / path).is_file()
    )
    aligned = (
        all(not values for values in missing_from_sources.values())
        and all(not values for values in duplicates.values())
        and not missing_files
    )
    return {
        "repo_root": str(repo_root),
        "source_order": [source_name for source_name, _, _ in SOURCE_SPECS],
        "manifests": manifests,
        "union_count": len(union_paths),
        "shared_count": len(shared_paths),
        "missing_from_sources": missing_from_sources,
        "duplicates": duplicates,
        "missing_files": missing_files,
        "aligned": aligned,
    }


def format_report(state: dict[str, object]) -> str:
    lines = [
        "Status: aligned"
        if state["aligned"]
        else "Status: drift detected",
        f"Repo root: {state['repo_root']}",
        f"Shared helper-surface entries: {state['shared_count']}",
        f"Union helper-surface entries: {state['union_count']}",
    ]
    manifests: dict[str, list[str]] = state["manifests"]  # type: ignore[assignment]
    missing_from_sources: dict[str, list[str]] = state["missing_from_sources"]  # type: ignore[assignment]
    duplicates: dict[str, list[str]] = state["duplicates"]  # type: ignore[assignment]
    missing_files: list[str] = state["missing_files"]  # type: ignore[assignment]
    for source_name in state["source_order"]:  # type: ignore[index]
        source_paths = manifests[source_name]
        lines.append(f"{source_name}: {len(source_paths)} entries")
        if missing_from_sources[source_name]:
            lines.append(
                f"  missing from {source_name}: "
                + ", ".join(missing_from_sources[source_name])
            )
        if duplicates[source_name]:
            lines.append(
                f"  duplicate entries in {source_name}: "
                + ", ".join(duplicates[source_name])
            )
    if missing_files:
        lines.append("Missing helper files on disk:")
        lines.extend(f"  - {path}" for path in missing_files)
    if not state["aligned"]:
        lines.append(
            "Suggested next step: update the drifted manifest source or restore "
            "the missing helper file before reusing --sync-helper-surface, "
            "--sync-only, or restored-checkout helper validation."
        )
    return "\n".join(lines)


def build_fixture_repo(
    *,
    remove_from_saved_memory: str | None = None,
    remove_disk_file: str | None = None,
) -> Path:
    root = Path(tempfile.mkdtemp(prefix="lightpanda-helper-surface-parity-"))
    helper_paths = [
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "scripts/check_issue3_saved_memory_inputs.py",
        "scripts/check_issue3_saved_archive_integrity.py",
        "scripts/check_issue3_restored_checkout.py",
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
    ]
    saved_memory_paths = list(helper_paths)
    if remove_from_saved_memory is not None:
        saved_memory_paths.remove(remove_from_saved_memory)

    restore_script = textwrap.dedent(
        """
        declare -a HELPER_SURFACE_PATHS=(
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
            "scripts/check_issue3_saved_memory_inputs.py"
            "scripts/check_issue3_saved_archive_integrity.py"
            "scripts/check_issue3_restored_checkout.py"
            "scripts/linux/restore_saved_browser_snapshot.sh"
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        """
    ).strip()
    saved_memory_helper = "REQUIRED_RESTORED_HELPER_FILES = (\n" + "\n".join(
        f'    ("{path}", "{Path(path).name}"),' for path in saved_memory_paths
    ) + "\n)\n"
    restored_helper = "HELPER_SURFACE_PATHS = (\n" + "\n".join(
        f'    ("{path}", "{Path(path).name}"),' for path in helper_paths
    ) + "\n)\n"

    fixture_files = {
        "scripts/linux/restore_saved_browser_snapshot.sh": restore_script,
        "scripts/check_issue3_saved_memory_inputs.py": saved_memory_helper,
        "scripts/check_issue3_restored_checkout.py": restored_helper,
    }
    for relative_path in helper_paths:
        fixture_files.setdefault(relative_path, "# helper surface fixture\n")
    if remove_disk_file is not None:
        fixture_files.pop(remove_disk_file, None)

    for relative_path, content in fixture_files.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
    return root


class HelperSurfaceParityTest(unittest.TestCase):
    def test_collect_surface_state_reports_aligned_helper_surface(self) -> None:
        repo_root = build_fixture_repo()
        state = collect_surface_state(repo_root)
        self.assertTrue(state["aligned"])
        self.assertEqual(state["union_count"], state["shared_count"])
        self.assertFalse(state["missing_files"])

    def test_collect_surface_state_reports_manifest_drift(self) -> None:
        repo_root = build_fixture_repo(
            remove_from_saved_memory="scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        state = collect_surface_state(repo_root)
        self.assertFalse(state["aligned"])
        missing = state["missing_from_sources"]  # type: ignore[assignment]
        self.assertIn(
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            missing["saved-memory-helper"],
        )

    def test_collect_surface_state_reports_missing_disk_file(self) -> None:
        repo_root = build_fixture_repo(
            remove_disk_file="scripts/check_issue3_saved_archive_integrity.py"
        )
        state = collect_surface_state(repo_root)
        self.assertFalse(state["aligned"])
        self.assertIn(
            "scripts/check_issue3_saved_archive_integrity.py",
            state["missing_files"],
        )


def run_self_test() -> int:
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(HelperSurfaceParityTest)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.self_test:
        return run_self_test()

    repo_root = Path(args.repo_root).resolve()
    state = collect_surface_state(repo_root)
    if args.json:
        print(json.dumps(state, indent=2, sort_keys=True))
    else:
        print(format_report(state))
    return 0 if state["aligned"] else 1


if __name__ == "__main__":
    sys.exit(main())
