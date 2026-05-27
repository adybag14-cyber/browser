from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


FIXTURE_FILES = {
    "scripts/check_issue3_saved_memory_inputs.py": """
def extract_restore_helper_paths(script_text: str) -> list[str]:
    return []


def load_required_restored_helper_files(helper_root):
    required = []
    helper_paths = extract_restore_helper_paths("fixture")
    for helper_path in helper_paths:
        required.append((helper_path, "mirrored"))
    return required
""",
    "scripts/check_issue11_saved_memory_helper_contract.py": """
SHARED_FRAGMENTS = (
    ("docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md", ("restore_helper",), "fixture"),
    ("docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md", ("restore_helper",), "fixture"),
    ("scripts/check_issue3_staged_rust_toolchain_candidates.py", ("restored_checkout_helper", "restore_helper"), "fixture"),
    ("scripts/check_issue3_staged_zig_toolchain_candidates.py", ("restored_checkout_helper", "restore_helper"), "fixture"),
    ("scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh", ("restore_helper",), "fixture"),
    ("scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh", ("restore_helper",), "fixture"),
    ("scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh", ("restored_checkout_helper", "restore_helper", "saved_memory_route"), "fixture"),
)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-memory-mirror-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11SavedMemoryDynamicMirrorSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        else:
            cls.repo_root = build_fixture_repo()

        cls.saved_memory_helper = (
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        ).read_text(encoding="utf-8")
        cls.contract_checker = (
            cls.repo_root / "scripts/check_issue11_saved_memory_helper_contract.py"
        ).read_text(encoding="utf-8")

    def test_saved_memory_helper_uses_dynamic_restore_surface_mirroring(self) -> None:
        for fragment in (
            "def extract_restore_helper_paths(",
            'helper_paths = extract_restore_helper_paths(',
            "for helper_path in helper_paths:",
            "required.append(",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_contract_checker_keeps_staged_and_nested_followups_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
            "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/check_issue3_staged_zig_toolchain_candidates.py",
            "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
            "scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh",
            "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
        ):
            self.assertIn(fragment, self.contract_checker)


if __name__ == "__main__":
    unittest.main()
