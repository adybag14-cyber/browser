from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


TARGET_HELPER = "scripts/check_issue11_toolchains_root_candidates.py"
TARGET_ROUTE_NOTE = "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
TARGET_ROUTE_SURFACE = "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
TARGET_ROUTE_PRINTER = "scripts/linux/show_issue3_linux_build_readiness_route.sh"

REQUIRED_HELPER_SNIPPETS = (
    "suggested_workspace_context_command",
    "suggested_readiness_command",
    "suggested_nested_preflight_command",
    "suggested_zig_recovery_command",
    "both .toolchains and toolchains are visible",
)

REQUIRED_ROUTE_NOTE_SNIPPETS = (
    "python scripts/check_issue11_toolchains_root_candidates.py --repo-root .",
    "toolchains/` and `.toolchains/`",
    "Use its preferred `--toolchains-root` override",
    "run_issue11_nested_workspace_saved_memory_preflight.sh",
    "show_issue3_zig_toolchain_recovery_route.sh",
)

REQUIRED_ROUTE_SURFACE_SNIPPETS = (
    "scripts/check_issue11_toolchains_root_candidates.py|file|",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue11_toolchains_root_candidates.py --repo-root .|",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|TOOLCHAINS_ROOT_CANDIDATE_COMMAND|",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Issue #11 toolchains-root candidate helper when the workspace may expose both toolchains/ and .toolchains/:|",
)

REQUIRED_ROUTE_PRINTER_SNIPPETS = (
    "TOOLCHAINS_ROOT_CANDIDATE_SCRIPT=",
    "TOOLCHAINS_ROOT_CANDIDATE_COMMAND=",
    "\"toolchains_root_candidates\":",
    "Issue #11 toolchains-root candidate helper when the workspace may expose both toolchains/ and .toolchains/:",
    "Run the issue #11 toolchains-root candidate helper before the saved Rust or Zig route printers",
)

FIXTURE_HELPER = """
suggested_workspace_context_command = [\"python\", \"scripts/check_issue3_workspace_context.py\"]
suggested_readiness_command = [\"python\", \"scripts/check_linux_build_readiness.py\", \"--toolchains-root\", \"/tmp/.toolchains\"]
suggested_nested_preflight_command = [\"bash\", \"scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh\"]
suggested_zig_recovery_command = [\"bash\", \"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh\", \"--toolchains-root\", \"/tmp/.toolchains\"]
warning = \"both .toolchains and toolchains are visible\"
"""

FIXTURE_ROUTE_NOTE = """
# Fixture Linux build-readiness route

When both `toolchains/` and `.toolchains/` may be visible above the checkout,
stop guessing before later reruns inherit the wrong root:

```bash
python scripts/check_issue11_toolchains_root_candidates.py --repo-root .
```

Use its preferred `--toolchains-root` override before rerunning
`scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh` or
`scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`.
"""

FIXTURE_ROUTE_SURFACE = """
declare -a REFERENCE_PATHS=(
    \"scripts/check_issue11_toolchains_root_candidates.py|file|Toolchains-root candidate helper.\"
)

declare -a CONTENT_EXPECTATIONS=(
    \"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue11_toolchains_root_candidates.py --repo-root .|The Linux build-readiness note keeps the exact toolchains-root candidate command visible.\"
    \"scripts/linux/show_issue3_linux_build_readiness_route.sh|TOOLCHAINS_ROOT_CANDIDATE_COMMAND|The Linux route printer keeps the toolchains-root candidate command visible.\"
    \"scripts/linux/show_issue3_linux_build_readiness_route.sh|Issue #11 toolchains-root candidate helper when the workspace may expose both toolchains/ and .toolchains/:|The Linux route printer keeps the toolchains-root handoff visible.\"
)
"""

FIXTURE_ROUTE_PRINTER = """
TOOLCHAINS_ROOT_CANDIDATE_SCRIPT=/tmp/scripts/check_issue11_toolchains_root_candidates.py
TOOLCHAINS_ROOT_CANDIDATE_COMMAND=\"python /tmp/scripts/check_issue11_toolchains_root_candidates.py --repo-root /tmp/browser\"

\"toolchains_root_candidates\":

Issue #11 toolchains-root candidate helper when the workspace may expose both toolchains/ and .toolchains/:
  ${TOOLCHAINS_ROOT_CANDIDATE_COMMAND}

- Run the issue #11 toolchains-root candidate helper before the saved Rust or Zig route printers when a nested checkout or mixed toolchains/ versus .toolchains/ workspace could make later reruns guess the wrong shared toolchains root.
"""


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-issue11-linux-surface-")
    )

    helper = root / TARGET_HELPER
    helper.parent.mkdir(parents=True, exist_ok=True)
    helper.write_text(FIXTURE_HELPER.lstrip("\n"), encoding="utf-8")

    route_note = root / TARGET_ROUTE_NOTE
    route_note.parent.mkdir(parents=True, exist_ok=True)
    route_note.write_text(FIXTURE_ROUTE_NOTE.lstrip("\n"), encoding="utf-8")

    route_surface = root / TARGET_ROUTE_SURFACE
    route_surface.parent.mkdir(parents=True, exist_ok=True)
    route_surface.write_text(FIXTURE_ROUTE_SURFACE.lstrip("\n"), encoding="utf-8")

    route_printer = root / TARGET_ROUTE_PRINTER
    route_printer.parent.mkdir(parents=True, exist_ok=True)
    route_printer.write_text(FIXTURE_ROUTE_PRINTER.lstrip("\n"), encoding="utf-8")

    return root


class Issue11LinuxBuildReadinessSurfaceContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        cls.repo_root = pathlib.Path(env_root).resolve() if env_root else build_fixture_repo()
        cls.helper_source = (cls.repo_root / TARGET_HELPER).read_text(encoding="utf-8")
        cls.route_note = (cls.repo_root / TARGET_ROUTE_NOTE).read_text(encoding="utf-8")
        cls.route_surface = (cls.repo_root / TARGET_ROUTE_SURFACE).read_text(
            encoding="utf-8"
        )
        cls.route_printer = (cls.repo_root / TARGET_ROUTE_PRINTER).read_text(
            encoding="utf-8"
        )

    def test_toolchains_helper_keeps_followup_commands_visible(self) -> None:
        for snippet in REQUIRED_HELPER_SNIPPETS:
            self.assertIn(snippet, self.helper_source)

    def test_route_note_keeps_toolchains_handoff_visible(self) -> None:
        for snippet in REQUIRED_ROUTE_NOTE_SNIPPETS:
            self.assertIn(snippet, self.route_note)

    def test_route_surface_checks_toolchains_handoff(self) -> None:
        for snippet in REQUIRED_ROUTE_SURFACE_SNIPPETS:
            self.assertIn(snippet, self.route_surface)

    def test_route_printer_keeps_toolchains_handoff_visible(self) -> None:
        for snippet in REQUIRED_ROUTE_PRINTER_SNIPPETS:
            self.assertIn(snippet, self.route_printer)


if __name__ == "__main__":
    unittest.main()
