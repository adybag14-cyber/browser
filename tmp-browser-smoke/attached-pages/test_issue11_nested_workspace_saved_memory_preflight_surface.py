from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md": """
    # Issue #3 Saved Memory Inputs Route

    - `scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh`
    - `scripts/check_issue11_saved_memory_helper_contract.py`
    - `scripts/check_issue11_reentry_inventory_consistency.py`
    - `restored checkout`
    """,
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh": """
    Issue #11 nested-workspace saved-Memory preflight:
      bash ./scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh --repo-root /tmp/browser

    Issue #11 saved-memory helper-contract check for the restored checkout:
      python ./scripts/check_issue11_saved_memory_helper_contract.py --repo-root /tmp/browser-memory-snapshot

    Issue #11 re-entry inventory consistency check for the restored checkout:
      python ./scripts/check_issue11_reentry_inventory_consistency.py --repo-root /tmp/browser-memory-snapshot
    """,
    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh": """
    HELPER_CONTRACT_CMD=(
        python3
        "${HELPER_ROOT}/scripts/check_issue11_saved_memory_helper_contract.py"
        --repo-root "${RESTORED_CHECKOUT_ROOT}"
    )

    REENTRY_INVENTORY_CMD=(
        python3
        "${HELPER_ROOT}/scripts/check_issue11_reentry_inventory_consistency.py"
        --repo-root "${RESTORED_CHECKOUT_ROOT}"
    )

    helper_contract_command = [
        "python3",
        f"{context['helper_root']}/scripts/check_issue11_saved_memory_helper_contract.py",
        "--repo-root",
        context["restored_checkout_root"],
    ]

    reentry_inventory_command = [
        "python3",
        f"{context['helper_root']}/scripts/check_issue11_reentry_inventory_consistency.py",
        "--repo-root",
        context["restored_checkout_root"],
    ]

    Issue #11 helper-contract command:
      $(printf '%q ' "${HELPER_CONTRACT_CMD[@]}")

    Issue #11 re-entry inventory command:
      $(printf '%q ' "${REENTRY_INVENTORY_CMD[@]}")
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="issue11-nested-preflight-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11NestedWorkspaceSavedMemoryPreflightSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_doc = read_text(cls.repo_root / "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md")
        cls.route_script = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_memory_inputs_route.sh"
        )
        cls.nested_runner = read_text(
            cls.repo_root / "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh"
        )

    def test_route_surfaces_keep_nested_runner_and_restored_checkout_contract_visible(self) -> None:
        for fragment in (
            "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
            "scripts/check_issue11_saved_memory_helper_contract.py",
            "scripts/check_issue11_reentry_inventory_consistency.py",
            "restored checkout",
        ):
            self.assertIn(fragment, self.route_doc)

        for fragment in (
            "Issue #11 nested-workspace saved-Memory preflight:",
            "Issue #11 saved-memory helper-contract check for the restored checkout:",
            "Issue #11 re-entry inventory consistency check for the restored checkout:",
            "scripts/check_issue11_saved_memory_helper_contract.py",
            "scripts/check_issue11_reentry_inventory_consistency.py",
            "browser-memory-snapshot",
        ):
            self.assertIn(fragment, self.route_script)

        runner_index = self.route_script.index("Issue #11 nested-workspace saved-Memory preflight:")
        helper_index = self.route_script.index(
            "Issue #11 saved-memory helper-contract check for the restored checkout:"
        )
        inventory_index = self.route_script.index(
            "Issue #11 re-entry inventory consistency check for the restored checkout:"
        )
        self.assertLess(runner_index, helper_index)
        self.assertLess(helper_index, inventory_index)

    def test_nested_runner_commands_target_the_restored_checkout_in_shell_mode(self) -> None:
        for fragment in (
            "HELPER_CONTRACT_CMD=(",
            '"${HELPER_ROOT}/scripts/check_issue11_saved_memory_helper_contract.py"',
            "REENTRY_INVENTORY_CMD=(",
            '"${HELPER_ROOT}/scripts/check_issue11_reentry_inventory_consistency.py"',
        ):
            self.assertIn(fragment, self.nested_runner)

        self.assertGreaterEqual(
            self.nested_runner.count('--repo-root "${RESTORED_CHECKOUT_ROOT}"'),
            2,
        )

    def test_nested_runner_json_and_printed_commands_keep_restored_checkout_targets(self) -> None:
        for fragment in (
            'f"{context[\'helper_root\']}/scripts/check_issue11_saved_memory_helper_contract.py"',
            'f"{context[\'helper_root\']}/scripts/check_issue11_reentry_inventory_consistency.py"',
            'context["restored_checkout_root"]',
            "Issue #11 helper-contract command:",
            "Issue #11 re-entry inventory command:",
            '$(printf \'%q \' "${HELPER_CONTRACT_CMD[@]}")',
            '$(printf \'%q \' "${REENTRY_INVENTORY_CMD[@]}")',
        ):
            self.assertIn(fragment, self.nested_runner)

        self.assertGreaterEqual(
            self.nested_runner.count('context["restored_checkout_root"]'),
            2,
        )


if __name__ == "__main__":
    unittest.main()
