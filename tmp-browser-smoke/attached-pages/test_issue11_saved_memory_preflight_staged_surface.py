from __future__ import annotations

import ast
import os
import pathlib
import tempfile
import unittest


TARGET_FILE = "scripts/check_issue3_saved_memory_inputs.py"
REQUIRED_PATHS = (
    "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
    "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
    "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
    "scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh",
    "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
    "scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh",
    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
)

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


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-issue11-saved-memory-preflight-")
    )
    target = root / TARGET_FILE
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(FIXTURE_SOURCE.lstrip("\n"), encoding="utf-8")
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


class Issue11SavedMemoryPreflightStagedSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        cls.repo_root = pathlib.Path(env_root).resolve() if env_root else build_fixture_repo()
        cls.source = (cls.repo_root / TARGET_FILE).read_text(encoding="utf-8")

    def test_base_required_helper_tuple_is_present(self) -> None:
        self.assertIn("BASE_REQUIRED_RESTORED_HELPER_FILES", self.source)

    def test_base_required_helper_tuple_keeps_issue11_staged_followups_explicit(self) -> None:
        base_paths = extract_base_required_helper_paths(self.source)
        for relative_path in REQUIRED_PATHS:
            self.assertIn(relative_path, base_paths)


if __name__ == "__main__":
    unittest.main()
