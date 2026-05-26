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
    - `scripts/check_issue3_workspace_context.py`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `--skip-archive-integrity-check`
    - `--json`
    - `--memory-root`
    - `--agent-files-root`
    - `--restored-checkout-root`
    - `--helper-root`
    - surfaced live helper, Memory, agent-files, restored-checkout, and optional fallback-Zig paths
    - the compact issue `#11` wrapper
    """,
    "scripts/check_issue3_workspace_context.py": """
    def collect_context(repo_root, explicit_archive):
        return {
            "helper_root": "/workspace/browser",
            "memory_root": "/workspace/memory",
            "agent_files_root": "/workspace/agent_files",
            "restored_checkout_root": "/workspace/browser-memory-snapshot",
            "fallback_zig_archive": "/workspace/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "suggested_saved_memory_preflight_command": [
                "python",
                "scripts/check_issue3_saved_memory_inputs.py",
                "--repo-root",
                "/workspace/browser",
                "--helper-root",
                "/workspace/browser",
                "--memory-root",
                "/workspace/memory",
                "--agent-files-root",
                "/workspace/agent_files",
                "--restored-checkout-root",
                "/workspace/browser-memory-snapshot",
            ],
        }
    """,
    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh": r"""
    Usage:
      bash scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh \
        [--repo-root /path/to/browser-repo] \
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
        [--skip-archive-integrity-check] \
        [--json]

    Use the branch-local workspace-context helper to resolve the nearest practical
    helper, Memory, agent-files, and restored-checkout roots, then rerun the saved
    Memory preflight with those surfaced paths threaded through explicitly.

    WORKSPACE_CONTEXT_SCRIPT="${DEFAULT_REPO_ROOT}/scripts/check_issue3_workspace_context.py"
    WORKSPACE_CONTEXT_CMD=(
        python3
        "${WORKSPACE_CONTEXT_SCRIPT}"
        --repo-root "${REPO_ROOT}"
        --json
    )
    CONTEXT_JSON="$(${WORKSPACE_CONTEXT_CMD[@]})"
    print(context["helper_root"])
    print(context["memory_root"])
    print(context["agent_files_root"])
    print(context["restored_checkout_root"])
    fallback = context.get("fallback_zig_archive")
    PREFLIGHT_CMD=(
        python3
        "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
        --repo-root "${REPO_ROOT}"
        --helper-root "${HELPER_ROOT}"
        --memory-root "${MEMORY_ROOT}"
        --agent-files-root "${AGENT_FILES_ROOT}"
        --restored-checkout-root "${RESTORED_CHECKOUT_ROOT}"
    )
    if [[ -n "${SURFACED_FALLBACK_ZIG}" ]]; then
        PREFLIGHT_CMD+=(--fallback-zig-archive "${SURFACED_FALLBACK_ZIG}")
    fi
    if [[ "${SKIP_ARCHIVE_INTEGRITY_CHECK}" -eq 1 ]]; then
        PREFLIGHT_CMD+=(--skip-archive-integrity-check)
    fi
    if [[ "${JSON}" -eq 1 ]]; then
        print(json.dumps({
            "profile": "issue11-nested-workspace-saved-memory-preflight",
            "workspace_context": context,
            "preflight": preflight,
            "command": command,
            "command_shell": " ".join(shlex.quote(part) for part in command),
        }, indent=2))
    fi

    Issue #11 nested-workspace saved-Memory preflight
    Repo root:              ${REPO_ROOT}
    Live helper root:       ${HELPER_ROOT}
    Memory root:            ${MEMORY_ROOT}
    Agent files root:       ${AGENT_FILES_ROOT}
    Restored checkout root: ${RESTORED_CHECKOUT_ROOT}
    Fallback Zig archive:   ${SURFACED_FALLBACK_ZIG:-not surfaced}

    Workspace-context command:
    Saved-Memory preflight command:
    "${PREFLIGHT_CMD[@]}"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="issue11-nested-workspace-preflight-"))
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
            cls.repo_root = pathlib.Path(__file__).resolve().parents[1]

        cls.route_note = read_text(cls.repo_root / "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md")
        cls.workspace_context_helper = read_text(
            cls.repo_root / "scripts/check_issue3_workspace_context.py"
        )
        cls.wrapper = read_text(
            cls.repo_root / "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh"
        )

    def test_route_note_keeps_nested_workspace_wrapper_visible(self) -> None:
        for fragment in (
            "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
            "scripts/check_issue3_workspace_context.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "--skip-archive-integrity-check",
            "--json",
            "--memory-root",
            "--agent-files-root",
            "--restored-checkout-root",
            "--helper-root",
            "surfaced live helper, Memory, agent-files, restored-checkout, and optional fallback-Zig paths",
            "the compact issue `#11` wrapper",
        ):
            self.assertIn(fragment, self.route_note)

    def test_workspace_context_helper_keeps_roots_that_wrapper_consumes(self) -> None:
        for fragment in (
            '"helper_root"',
            '"memory_root"',
            '"agent_files_root"',
            '"restored_checkout_root"',
            '"fallback_zig_archive"',
            '"suggested_saved_memory_preflight_command"',
            '"--helper-root"',
            '"--memory-root"',
            '"--agent-files-root"',
            '"--restored-checkout-root"',
        ):
            self.assertIn(fragment, self.workspace_context_helper)

    def test_wrapper_keeps_workspace_context_and_explicit_preflight_threading(self) -> None:
        for fragment in (
            "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--skip-archive-integrity-check",
            "--json",
            'WORKSPACE_CONTEXT_SCRIPT="${DEFAULT_REPO_ROOT}/scripts/check_issue3_workspace_context.py"',
            'CONTEXT_JSON="$(${WORKSPACE_CONTEXT_CMD[@]})"',
            'print(context["helper_root"])',
            'print(context["memory_root"])',
            'print(context["agent_files_root"])',
            'print(context["restored_checkout_root"])',
            'fallback = context.get("fallback_zig_archive")',
            '"${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py"',
            '--helper-root "${HELPER_ROOT}"',
            '--memory-root "${MEMORY_ROOT}"',
            '--agent-files-root "${AGENT_FILES_ROOT}"',
            '--restored-checkout-root "${RESTORED_CHECKOUT_ROOT}"',
            'PREFLIGHT_CMD+=(--fallback-zig-archive "${SURFACED_FALLBACK_ZIG}")',
            'PREFLIGHT_CMD+=(--skip-archive-integrity-check)',
        ):
            self.assertIn(fragment, self.wrapper)

    def test_wrapper_keeps_json_contract_visible(self) -> None:
        for fragment in (
            '"profile": "issue11-nested-workspace-saved-memory-preflight"',
            '"workspace_context": context',
            '"preflight": preflight',
            '"command": command',
            '"command_shell": " ".join(shlex.quote(part) for part in command)',
        ):
            self.assertIn(fragment, self.wrapper)

    def test_wrapper_keeps_text_summary_surface_visible(self) -> None:
        for fragment in (
            "Issue #11 nested-workspace saved-Memory preflight",
            "Repo root:",
            "Live helper root:",
            "Memory root:",
            "Agent files root:",
            "Restored checkout root:",
            "Fallback Zig archive:",
            "Workspace-context command:",
            "Saved-Memory preflight command:",
            '"${PREFLIGHT_CMD[@]}"',
        ):
            self.assertIn(fragment, self.wrapper)


if __name__ == "__main__":
    unittest.main()
