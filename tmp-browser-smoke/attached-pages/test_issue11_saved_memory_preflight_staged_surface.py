from __future__ import annotations

import ast
import os
import pathlib
import re
import tempfile
import unittest


TARGET_FILE = "scripts/check_issue3_saved_memory_inputs.py"
TARGET_ROUTE_NOTE = "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md"
TARGET_ROUTE_PRINTER = "scripts/linux/show_issue3_saved_memory_inputs_route.sh"
TARGET_RESTORE_HELPER = "scripts/linux/restore_saved_browser_snapshot.sh"
TARGET_NESTED_RUNNER = "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh"
REQUIRED_PATHS = (
    "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
    "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
    "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
    "scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh",
    "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
    "scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh",
    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
)
REQUIRED_MEMORY_SYNC_SNIPPETS = (
    "repo_archives/browser/",
    "fix Memory sync first",
    "restore route still depends on the same saved snapshot and dependency bundles",
)
REQUIRED_ROUTE_NOTE_SNIPPETS = REQUIRED_PATHS + (
    "check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
    "show_issue3_staged_zig_toolchain_candidates_route.sh",
    "check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
    "show_issue3_staged_rust_toolchain_candidates_route.sh",
) + REQUIRED_MEMORY_SYNC_SNIPPETS
REQUIRED_ROUTE_PRINTER_SNIPPETS = (
    "nested_workspace_saved_memory_preflight",
    "quick_nested_workspace_saved_memory_preflight",
    "Issue #11 nested-workspace saved-Memory preflight:",
    "Quick nested-workspace saved-Memory presence check:",
    "check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
    "show_issue3_staged_zig_toolchain_candidates_route.sh",
    "check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
    "show_issue3_staged_rust_toolchain_candidates_route.sh",
) + REQUIRED_MEMORY_SYNC_SNIPPETS

FIXTURE_SOURCE = """
from __future__ import annotations

BASE_REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md", "fixture"),
    ("docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md", "fixture"),
    ("scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh", "fixture"),
    ("scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh", "fixture"),
    ("scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh", "fixture"),
    ("scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh", "fixture"),
    ("scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh", "fixture"),
)
"""

FIXTURE_ROUTE_NOTE = """
# Fixture saved-memory route

- docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md
- docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md
- scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh
- scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh
- scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh
- scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh
- scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh
- repo_archives/browser/
- fix Memory sync first
- restore route still depends on the same saved snapshot and dependency bundles
"""

FIXTURE_ROUTE_PRINTER = """
nested_workspace_saved_memory_preflight
quick_nested_workspace_saved_memory_preflight
Issue #11 nested-workspace saved-Memory preflight:
Quick nested-workspace saved-Memory presence check:
check_issue3_staged_zig_toolchain_candidates_route_surface.sh
show_issue3_staged_zig_toolchain_candidates_route.sh
check_issue3_staged_rust_toolchain_candidates_route_surface.sh
show_issue3_staged_rust_toolchain_candidates_route.sh
repo_archives/browser/
fix Memory sync first
restore route still depends on the same saved snapshot and dependency bundles
"""

FIXTURE_RESTORE_HELPER = """
#!/usr/bin/env bash

declare -a HELPER_SURFACE_PATHS=(
    "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md"
    "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md"
    "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh"
    "scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh"
    "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh"
    "scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh"
    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh"
)
"""

FIXTURE_NESTED_RUNNER = """
#!/usr/bin/env bash

CONTRACT_TARGET_ROOT="${RESTORED_CHECKOUT_ROOT}"

HELPER_CONTRACT_CMD=(
    python3
    "${HELPER_ROOT}/scripts/check_issue11_saved_memory_helper_contract.py"
    --repo-root "${CONTRACT_TARGET_ROOT}"
)

REENTRY_INVENTORY_CMD=(
    python3
    "${HELPER_ROOT}/scripts/check_issue11_reentry_inventory_consistency.py"
    --repo-root "${CONTRACT_TARGET_ROOT}"
)
"""


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-issue11-saved-memory-preflight-")
    )
    target = root / TARGET_FILE
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(FIXTURE_SOURCE.lstrip("\n"), encoding="utf-8")

    route_note = root / TARGET_ROUTE_NOTE
    route_note.parent.mkdir(parents=True, exist_ok=True)
    route_note.write_text(FIXTURE_ROUTE_NOTE.lstrip("\n"), encoding="utf-8")

    route_printer = root / TARGET_ROUTE_PRINTER
    route_printer.parent.mkdir(parents=True, exist_ok=True)
    route_printer.write_text(FIXTURE_ROUTE_PRINTER.lstrip("\n"), encoding="utf-8")

    restore_helper = root / TARGET_RESTORE_HELPER
    restore_helper.parent.mkdir(parents=True, exist_ok=True)
    restore_helper.write_text(FIXTURE_RESTORE_HELPER.lstrip("\n"), encoding="utf-8")

    nested_runner = root / TARGET_NESTED_RUNNER
    nested_runner.parent.mkdir(parents=True, exist_ok=True)
    nested_runner.write_text(FIXTURE_NESTED_RUNNER.lstrip("\n"), encoding="utf-8")
    return root


def extract_base_required_helper_paths(source_text: str) -> set[str]:
    module = ast.parse(source_text)

    for node in module.body:
        value = None
        if isinstance(node, ast.Assign):
            if any(
                isinstance(target, ast.Name)
                and target.id == "BASE_REQUIRED_RESTORED_HELPER_FILES"
                for target in node.targets
            ):
                value = node.value
        elif isinstance(node, ast.AnnAssign):
            if (
                isinstance(node.target, ast.Name)
                and node.target.id == "BASE_REQUIRED_RESTORED_HELPER_FILES"
            ):
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

    raise AssertionError("BASE_REQUIRED_RESTORED_HELPER_FILES is missing")


def extract_restore_helper_paths(source_text: str) -> set[str]:
    marker = 'declare -a HELPER_SURFACE_PATHS=('
    in_block = False
    paths: set[str] = set()

    for line in source_text.splitlines():
        stripped = line.strip()
        if not in_block:
            if stripped == marker:
                in_block = True
            continue

        if stripped == ")":
            break

        if stripped.startswith('"') and stripped.endswith('"'):
            paths.add(stripped.strip('"'))

    if not in_block:
        raise AssertionError("HELPER_SURFACE_PATHS block is missing")
    return paths


def extract_command_repo_root(source_text: str, command_name: str) -> str:
    marker = f"{command_name}=("
    in_block = False

    for line in source_text.splitlines():
        stripped = line.strip()
        if not in_block:
            if stripped == marker:
                in_block = True
            continue

        if stripped == ")":
            break

        match = re.search(r'--repo-root\s+"([^"]+)"', stripped)
        if match:
            return match.group(1)

    raise AssertionError(f"{command_name} repo root target is missing")


class Issue11SavedMemoryPreflightStagedSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        cls.repo_root = pathlib.Path(env_root).resolve() if env_root else build_fixture_repo()
        cls.source = (cls.repo_root / TARGET_FILE).read_text(encoding="utf-8")
        cls.route_note = (cls.repo_root / TARGET_ROUTE_NOTE).read_text(encoding="utf-8")
        cls.route_printer = (cls.repo_root / TARGET_ROUTE_PRINTER).read_text(
            encoding="utf-8"
        )
        cls.restore_helper = (cls.repo_root / TARGET_RESTORE_HELPER).read_text(
            encoding="utf-8"
        )
        cls.nested_runner = (cls.repo_root / TARGET_NESTED_RUNNER).read_text(
            encoding="utf-8"
        )

    def test_base_required_helper_tuple_is_present(self) -> None:
        self.assertIn("BASE_REQUIRED_RESTORED_HELPER_FILES", self.source)

    def test_base_required_helper_tuple_keeps_issue11_staged_followups_explicit(
        self,
    ) -> None:
        base_paths = extract_base_required_helper_paths(self.source)
        for relative_path in REQUIRED_PATHS:
            self.assertIn(relative_path, base_paths)

    def test_saved_memory_route_note_keeps_issue11_staged_followups_visible(
        self,
    ) -> None:
        for snippet in REQUIRED_ROUTE_NOTE_SNIPPETS:
            self.assertIn(snippet, self.route_note)

    def test_saved_memory_route_printer_keeps_issue11_staged_followups_visible(
        self,
    ) -> None:
        for snippet in REQUIRED_ROUTE_PRINTER_SNIPPETS:
            self.assertIn(snippet, self.route_printer)

    def test_restore_helper_surface_keeps_issue11_staged_followups_explicit(
        self,
    ) -> None:
        helper_paths = extract_restore_helper_paths(self.restore_helper)
        for relative_path in REQUIRED_PATHS:
            self.assertIn(relative_path, helper_paths)

    def test_nested_runner_helper_contract_targets_restored_checkout(self) -> None:
        self.assertIn('CONTRACT_TARGET_ROOT="${RESTORED_CHECKOUT_ROOT}"', self.nested_runner)
        self.assertEqual(
            extract_command_repo_root(self.nested_runner, "HELPER_CONTRACT_CMD"),
            "${CONTRACT_TARGET_ROOT}",
        )

    def test_nested_runner_reentry_inventory_targets_restored_checkout(self) -> None:
        self.assertEqual(
            extract_command_repo_root(self.nested_runner, "REENTRY_INVENTORY_CMD"),
            "${CONTRACT_TARGET_ROOT}",
        )


if __name__ == "__main__":
    unittest.main()