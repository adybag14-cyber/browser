from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    This is the Linux or WSL companion for the Windows-first runtime re-entry
    helpers:

    - `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
    - `scripts/check_issue3_workspace_context.py`

    ## Resolve Workspace Roots When The Checkout Sits Deeper Than Default Layout

    ```bash
    python scripts/check_issue3_workspace_context.py --repo-root .
    ```

    Use `--json` when another helper needs the surfaced paths as structured output.

    ## Run The Helper

    If the repo checkout is not sitting beside the saved Memory folder, run the
    workspace-context helper first so the next readiness command or explicit
    route overrides use surfaced roots instead of hand-built guesses.
    """,
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md": """
    # Issue #3 Workspace-Context Route

    ```bash
    python scripts/check_issue3_workspace_context.py --repo-root .
    ```

    The helper prints a ready-to-rerun `scripts/check_linux_build_readiness.py`
    command that already includes the resolved roots.
    """,
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
    WORKSPACE_CONTEXT_SCRIPT="${REPO_ROOT}/scripts/check_issue3_workspace_context.py"
    WORKSPACE_CONTEXT_COMMAND="python $(format_shell_arg \"${WORKSPACE_CONTEXT_SCRIPT}\") --repo-root $(format_shell_arg \"${REPO_ROOT}\")"

    print(json.dumps({
        "read_first": [
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
        ],
        "commands": {
            "workspace_context": "python scripts/check_issue3_workspace_context.py --repo-root /tmp/browser"
        },
        "notes": [
            "Run the workspace_context command first when the checkout sits deeper than the default sibling layout so later route overrides reuse surfaced roots instead of hand-built guesses."
        ]
    }))

    Workspace-context helper when the checkout sits deeper than the default sibling layout:
      ${WORKSPACE_CONTEXT_COMMAND}
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-build-readiness-workspace-context-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3LinuxBuildReadinessWorkspaceContextRouteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.build_readiness_doc = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.workspace_context_doc = read_text(
            cls.repo_root / "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )

    def test_build_readiness_route_mentions_workspace_context_surfaces(self) -> None:
        for fragment in (
            "`docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`",
            "`scripts/check_issue3_workspace_context.py`",
            "## Resolve Workspace Roots When The Checkout Sits Deeper Than Default Layout",
            "python scripts/check_issue3_workspace_context.py --repo-root .",
            "Use `--json` when another helper needs the surfaced paths as structured output.",
            "workspace-context helper first so the next readiness command or explicit",
            "route overrides use surfaced roots instead of hand-built guesses.",
        ):
            self.assertIn(fragment, self.build_readiness_doc)

    def test_workspace_context_route_keeps_readiness_handoff_visible(self) -> None:
        for fragment in (
            "python scripts/check_issue3_workspace_context.py --repo-root .",
            "`scripts/check_linux_build_readiness.py`",
            "resolved roots",
        ):
            self.assertIn(fragment, self.workspace_context_doc)

    def test_route_printer_surfaces_workspace_context_handoff(self) -> None:
        for fragment in (
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "scripts/check_issue3_workspace_context.py",
            "WORKSPACE_CONTEXT_COMMAND",
            '"workspace_context":',
            "Run the workspace_context command first when the checkout sits deeper than the default sibling layout",
            "Workspace-context helper when the checkout sits deeper than the default sibling layout:",
        ):
            self.assertIn(fragment, self.route_printer)


if __name__ == "__main__":
    unittest.main()
