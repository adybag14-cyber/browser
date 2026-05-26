from __future__ import annotations

import importlib.util
import os
import pathlib
import tempfile
import unittest


HELPER_RELATIVE_PATH = "scripts/check_issue11_saved_memory_live_helper_surface.py"


def load_helper_module(repo_root: pathlib.Path):
    target = repo_root / HELPER_RELATIVE_PATH
    spec = importlib.util.spec_from_file_location(
        "issue11_saved_memory_live_helper_surface", target
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load helper module from {target}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class Issue11SavedMemoryLiveHelperSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]
        cls.helper = load_helper_module(cls.repo_root)

    def test_required_surface_paths_cover_issue11_helper_contract_layer(self) -> None:
        required_paths = {
            path for path, _label in self.helper.REQUIRED_HELPER_PATHS
        }
        self.assertIn(
            "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
            required_paths,
        )
        self.assertIn(
            "scripts/check_issue11_saved_memory_helper_contract.py",
            required_paths,
        )
        self.assertIn(
            "scripts/check_issue11_reentry_inventory_consistency.py",
            required_paths,
        )
        self.assertIn(
            "scripts/check_issue11_nested_workspace_saved_memory_preflight_contract.py",
            required_paths,
        )

    def test_collect_surface_passes_for_complete_fixture_repo(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = self.helper.write_fixture_repo(pathlib.Path(tmpdir))
            result = self.helper.collect_surface(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(result["missing"], [])

    def test_collect_surface_flags_missing_route_printer(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = self.helper.write_fixture_repo(
                pathlib.Path(tmpdir),
                {"scripts/linux/show_issue3_saved_memory_inputs_route.sh"},
            )
            result = self.helper.collect_surface(repo_root)
            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
                result["missing"],
            )


if __name__ == "__main__":
    unittest.main()
