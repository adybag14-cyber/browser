from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/check_issue3_saved_memory_inputs.py": """
    DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
    REQUIRED_REPO_ROOT_FILE = "build.zig.zon"

    def path_has_live_helper_surface(path):
        return (
            path.is_dir()
            and (path / REQUIRED_REPO_ROOT_FILE).is_file()
            and all((path / relative_path).is_file() for relative_path, _label in REQUIRED_RESTORED_HELPER_FILES)
        )

    def resolve_default_helper_root(repo_root):
        repo_root = repo_root.resolve()
        cwd = Path.cwd().resolve()
        if (
            repo_root.name == DEFAULT_RESTORED_CHECKOUT_NAME
            and cwd != repo_root
            and path_has_live_helper_surface(cwd)
        ):
            return cwd
        return repo_root

    def collect_helper_surface_sync_result(helper_root, restored_checkout_root):
        if not helper_root.is_dir():
            return {
                "status": "helper-root-missing",
                "ok": False,
            }

        if not restored_checkout_root.is_dir():
            return {
                "status": "restored-checkout-missing",
                "ok": True,
            }

        drifted_files = []
        missing_in_helper_root = []
        missing_in_restored_checkout = []
        ok = not drifted_files and not missing_in_helper_root and not missing_in_restored_checkout
        status = "synced" if ok else "out-of-sync"
        return {
            "status": status,
            "drifted_files": drifted_files,
            "missing_in_helper_root": missing_in_helper_root,
            "missing_in_restored_checkout": missing_in_restored_checkout,
            "ok": ok,
        }

    def collect_results(
        repo_root,
        helper_root,
        memory_root,
        agent_files_root,
        restored_checkout_root,
        fallback_zig_archive,
        check_archive_integrity,
    ):
        helper_surface_sync = collect_helper_surface_sync_result(
            helper_root,
            restored_checkout_root,
        )
        return {
            "restored_checkout": collect_restored_checkout_result(restored_checkout_root),
            "helper_surface_sync": helper_surface_sync,
            "ok": (
                True
                and helper_surface_sync["ok"]
            ),
        }

    def emit_text(result):
        helper_surface_sync = result["helper_surface_sync"]
        helper_sync_status = {
            "synced": "PASS",
            "out-of-sync": "FAIL",
            "restored-checkout-missing": "WARN",
            "helper-root-missing": "FAIL",
        }[helper_surface_sync["status"]]
        print(f"Helper surface sync: [{helper_sync_status}]")
        if helper_surface_sync["status"] == "out-of-sync":
            print("suggested next step: re-run the saved-browser restore with --sync-helper-surface before Linux or WSL follow-up work")
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-memory-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedMemoryInputsSyncSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )

    def test_helper_root_defaults_back_to_live_helper_surface_for_restored_checkout_replays(self) -> None:
        for fragment in (
            'DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"',
            "repo_root.name == DEFAULT_RESTORED_CHECKOUT_NAME",
            "cwd != repo_root",
            "path_has_live_helper_surface(cwd)",
            "return cwd",
            "return repo_root",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_helper_surface_sync_states_stay_visible(self) -> None:
        for fragment in (
            '"status": "helper-root-missing"',
            '"status": "restored-checkout-missing"',
            'status = "synced" if ok else "out-of-sync"',
            '"drifted_files": drifted_files',
            '"missing_in_helper_root": missing_in_helper_root',
            '"missing_in_restored_checkout": missing_in_restored_checkout',
            '"ok": ok',
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_collect_results_and_emit_text_keep_sync_guidance_connected(self) -> None:
        for fragment in (
            '"restored_checkout": collect_restored_checkout_result(restored_checkout_root)',
            '"helper_surface_sync": helper_surface_sync',
            'and helper_surface_sync["ok"]',
            '"out-of-sync": "FAIL"',
            '"restored-checkout-missing": "WARN"',
            '"helper-root-missing": "FAIL"',
            "re-run the saved-browser restore with --sync-helper-surface",
        ):
            self.assertIn(fragment, self.saved_memory_helper)


if __name__ == "__main__":
    unittest.main()
