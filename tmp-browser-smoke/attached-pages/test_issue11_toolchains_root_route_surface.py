from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


TARGET_HELPER = "scripts/check_issue11_toolchains_root_candidates.py"
TARGET_ROUTE_NOTE = "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
TARGET_ROUTE_PRINTER = "scripts/linux/show_issue3_linux_build_readiness_route.sh"

REQUIRED_HELPER_SNIPPETS = (
    "suggested_workspace_context_command",
    "suggested_readiness_command",
    "suggested_nested_preflight_command",
    "suggested_zig_recovery_command",
    "check_issue3_workspace_context.py",
    "show_issue3_zig_toolchain_recovery_route.sh",
    "--toolchains-root",
    "both .toolchains and toolchains are visible",
)

REQUIRED_ROUTE_NOTE_SNIPPETS = (
    "scripts/check_issue11_toolchains_root_candidates.py",
    "python scripts/check_issue11_toolchains_root_candidates.py --repo-root .",
    "Use its preferred `--toolchains-root` override",
    "When both `toolchains/` and `.toolchains/` may be visible above the checkout",
    "staged Rust",
    "staged Zig",
    "build-readiness rerun",
)

REQUIRED_ROUTE_PRINTER_SNIPPETS = (
    "TOOLCHAINS_ROOT_CANDIDATE_SCRIPT=",
    "TOOLCHAINS_ROOT_CANDIDATE_COMMAND=",
    "\"toolchains_root_candidates\":",
    "check_issue11_toolchains_root_candidates.py",
    "--toolchains-root",
    "WORKSPACE_CONTEXT_COMMAND",
    "TOOLCHAIN_ROUTE_COMMAND",
)

FIXTURE_HELPER = """
#!/usr/bin/env python3
suggested_workspace_context_command = [\"python\", \"scripts/check_issue3_workspace_context.py\", \"--repo-root\", \".\"]
suggested_readiness_command = [\"python\", \"scripts/check_linux_build_readiness.py\", \"--repo-root\", \".\", \"--toolchains-root\", \"/tmp/.toolchains\"]
suggested_nested_preflight_command = [\"bash\", \"scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh\", \"--repo-root\", \".\"]
suggested_zig_recovery_command = [\"bash\", \"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh\", \"--repo-root\", \".\", \"--toolchains-root\", \"/tmp/.toolchains\"]
warning = \"both .toolchains and toolchains are visible\"
"""

FIXTURE_ROUTE_NOTE = """
# Fixture Linux build-readiness route

- scripts/check_issue11_toolchains_root_candidates.py
- python scripts/check_issue11_toolchains_root_candidates.py --repo-root .
- Use its preferred `--toolchains-root` override
- When both `toolchains/` and `.toolchains/` may be visible above the checkout
- staged Rust
- staged Zig
- build-readiness rerun
"""

FIXTURE_ROUTE_PRINTER = """
TOOLCHAINS_ROOT_CANDIDATE_SCRIPT=/tmp/scripts/check_issue11_toolchains_root_candidates.py
TOOLCHAINS_ROOT_CANDIDATE_COMMAND=\"python /tmp/scripts/check_issue11_toolchains_root_candidates.py --repo-root /tmp/browser\"
WORKSPACE_CONTEXT_COMMAND=\"python /tmp/scripts/check_issue3_workspace_context.py --repo-root /tmp/browser\"
TOOLCHAIN_ROUTE_COMMAND=\"bash /tmp/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root /tmp/browser --toolchains-root /tmp/.toolchains\"
\"toolchains_root_candidates\":
check_issue11_toolchains_root_candidates.py
--toolchains-root
"""


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue11-toolchains-root-"))

    helper = root / TARGET_HELPER
    helper.parent.mkdir(parents=True, exist_ok=True)
    helper.write_text(FIXTURE_HELPER.lstrip("\n"), encoding="utf-8")

    route_note = root / TARGET_ROUTE_NOTE
    route_note.parent.mkdir(parents=True, exist_ok=True)
    route_note.write_text(FIXTURE_ROUTE_NOTE.lstrip("\n"), encoding="utf-8")

    route_printer = root / TARGET_ROUTE_PRINTER
    route_printer.parent.mkdir(parents=True, exist_ok=True)
    route_printer.write_text(FIXTURE_ROUTE_PRINTER.lstrip("\n"), encoding="utf-8")

    return root


class Issue11ToolchainsRootRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        cls.repo_root = pathlib.Path(env_root).resolve() if env_root else build_fixture_repo()
        cls.helper_source = (cls.repo_root / TARGET_HELPER).read_text(encoding="utf-8")
        cls.route_note = (cls.repo_root / TARGET_ROUTE_NOTE).read_text(encoding="utf-8")
        cls.route_printer = (cls.repo_root / TARGET_ROUTE_PRINTER).read_text(
            encoding="utf-8"
        )

    def test_helper_keeps_issue11_toolchains_root_commands_visible(self) -> None:
        for snippet in REQUIRED_HELPER_SNIPPETS:
            self.assertIn(snippet, self.helper_source)

    def test_linux_build_readiness_note_keeps_toolchains_root_handoff_visible(
        self,
    ) -> None:
        for snippet in REQUIRED_ROUTE_NOTE_SNIPPETS:
            self.assertIn(snippet, self.route_note)

    def test_linux_build_readiness_route_printer_keeps_toolchains_root_handoff_visible(
        self,
    ) -> None:
        for snippet in REQUIRED_ROUTE_PRINTER_SNIPPETS:
            self.assertIn(snippet, self.route_printer)


if __name__ == "__main__":
    unittest.main()
