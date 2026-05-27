from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


TARGET_FILE = "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh"

REQUIRED_USAGE_SNIPPETS = (
    "Use the branch-local workspace-context helper to resolve the nearest practical",
    "restored-checkout-only issue #11 contract checks run only",
)

REQUIRED_JSON_SNIPPETS = (
    '"profile": "issue11-nested-workspace-saved-memory-preflight"',
    '"contract_target_root": contract_target_root or None',
    '"contract_checks_skipped": contract_checks_skipped',
    '"helper_contract_command_shell": helper_contract_command_shell',
    '"reentry_inventory_command_shell": reentry_inventory_command_shell',
    '"saved_snapshot_route_command_shell":',
)

FIXTURE_SOURCE = """#!/usr/bin/env bash

usage() {
    cat <<'EOUSAGE'
Use the branch-local workspace-context helper to resolve the nearest practical
helper, Memory, agent-files, and restored-checkout roots, then rerun the saved
Memory preflight. The restored-checkout-only issue #11 contract checks run only
after a reusable snapshot exists.
EOUSAGE
}

PREFLIGHT_CMD=(
    python3
    "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
    --repo-root "${REPO_ROOT}"
    --helper-root "${HELPER_ROOT}"
    --memory-root "${MEMORY_ROOT}"
    --agent-files-root "${AGENT_FILES_ROOT}"
    --restored-checkout-root "${RESTORED_CHECKOUT_ROOT}"
)

SAVED_SNAPSHOT_ROUTE_CMD=(
    bash
    "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
    --repo-root "${REPO_ROOT}"
    --helper-root "${HELPER_ROOT}"
    --memory-root "${MEMORY_ROOT}"
    --destination "${RESTORED_CHECKOUT_ROOT}"
    --sync-helper-surface
)

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

print(json.dumps({
    "profile": "issue11-nested-workspace-saved-memory-preflight",
    "saved_snapshot_route_command_shell": "ok",
    "helper_contract_command_shell": helper_contract_command_shell,
    "reentry_inventory_command_shell": reentry_inventory_command_shell,
    "contract_target_root": contract_target_root or None,
    "contract_checks_skipped": contract_checks_skipped,
}, indent=2))
"""


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-issue11-nested-preflight-contract-")
    )
    target = root / TARGET_FILE
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(FIXTURE_SOURCE, encoding="utf-8")
    return root


def extract_array_block(source_text: str, name: str) -> str:
    marker = f"{name}=("
    lines = source_text.splitlines()
    for index, line in enumerate(lines):
        if line.strip() != marker:
            continue
        block: list[str] = []
        for inner in lines[index + 1 :]:
            if inner.strip() == ")":
                return "\n".join(block)
            block.append(inner)
    raise AssertionError(f"{name} block is missing")


class Issue11NestedWorkspaceSavedMemoryPreflightContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        cls.repo_root = pathlib.Path(env_root).resolve() if env_root else build_fixture_repo()
        cls.source = (cls.repo_root / TARGET_FILE).read_text(encoding="utf-8")

    def test_usage_keeps_restored_checkout_contract_context_visible(self) -> None:
        for snippet in REQUIRED_USAGE_SNIPPETS:
            self.assertIn(snippet, self.source)

    def test_preflight_command_keeps_helper_and_restored_roots_explicit(self) -> None:
        block = extract_array_block(self.source, "PREFLIGHT_CMD")
        self.assertIn('--repo-root "${REPO_ROOT}"', block)
        self.assertIn('--helper-root "${HELPER_ROOT}"', block)
        self.assertIn('--memory-root "${MEMORY_ROOT}"', block)
        self.assertIn('--agent-files-root "${AGENT_FILES_ROOT}"', block)
        self.assertIn('--restored-checkout-root "${RESTORED_CHECKOUT_ROOT}"', block)

    def test_contract_commands_target_restored_checkout_root(self) -> None:
        helper_block = extract_array_block(self.source, "HELPER_CONTRACT_CMD")
        inventory_block = extract_array_block(self.source, "REENTRY_INVENTORY_CMD")

        self.assertIn("check_issue11_saved_memory_helper_contract.py", helper_block)
        self.assertIn('--repo-root "${CONTRACT_TARGET_ROOT}"', helper_block)
        self.assertNotIn('--repo-root "${HELPER_ROOT}"', helper_block)

        self.assertIn("check_issue11_reentry_inventory_consistency.py", inventory_block)
        self.assertIn('--repo-root "${CONTRACT_TARGET_ROOT}"', inventory_block)
        self.assertNotIn('--repo-root "${HELPER_ROOT}"', inventory_block)

    def test_json_output_surfaces_contract_metadata(self) -> None:
        for snippet in REQUIRED_JSON_SNIPPETS:
            self.assertIn(snippet, self.source)

    def test_saved_snapshot_route_keeps_helper_surface_sync_enabled(self) -> None:
        block = extract_array_block(self.source, "SAVED_SNAPSHOT_ROUTE_CMD")
        self.assertIn('--destination "${RESTORED_CHECKOUT_ROOT}"', block)
        self.assertIn("--sync-helper-surface", block)


if __name__ == "__main__":
    unittest.main()
