from __future__ import annotations

import os
import pathlib
import re
import tempfile
import unittest


DOC_PATH = "docs/ISSUE3_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md"
HELPER_PATH = "scripts/check_issue11_toolchains_root_candidates.py"
ROUTE_PRINTER_PATH = "scripts/linux/show_issue3_toolchains_root_candidates_route.sh"
SURFACE_CHECK_PATH = "scripts/linux/check_issue3_toolchains_root_candidates_route_surface.sh"

DOC_REQUIRED_COMPANIONS = (
    "scripts/linux/check_issue3_toolchains_root_candidates_route_surface.sh",
    "scripts/linux/show_issue3_toolchains_root_candidates_route.sh",
    "scripts/check_issue11_toolchains_root_candidates.py",
    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
    "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
    "scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh",
    "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
    "scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh",
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
    "scripts/check_linux_build_readiness.py",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh",
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
)

READ_FIRST_DOCS = (
    "docs/ISSUE3_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md",
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
    "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
    "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
)

ROUTE_COMMAND_KEYS = (
    "surface_check",
    "toolchains_root_candidates",
    "nested_preflight",
    "staged_rust_route",
    "staged_zig_route",
    "saved_rust_build_bridge",
    "linux_build_readiness_helper",
    "linux_build_readiness_route",
    "zig_recovery_route",
    "progress_tracker_route",
)

HELPER_REQUIRED_KEYS = (
    "status",
    "repo_root",
    "helper_root",
    "preferred_toolchains_root",
    "suggested_workspace_context_command",
    "suggested_readiness_command",
    "suggested_nested_preflight_command",
    "suggested_zig_recovery_command",
)

DOC_FIXTURE = """\
# Issue #3 Toolchains-Root Candidates Route

## Companion Surfaces

- `scripts/linux/check_issue3_toolchains_root_candidates_route_surface.sh`
- `scripts/linux/show_issue3_toolchains_root_candidates_route.sh`
- `scripts/check_issue11_toolchains_root_candidates.py`
- `scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh`
- `scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh`
- `scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh`
- `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
"""

HELPER_FIXTURE = """\
from __future__ import annotations

def collect_candidates(repo_root, helper_root=None):
    status = "attention"
    preferred_root = "/tmp/.toolchains"
    workspace_context_command = ["python", "scripts/check_issue3_workspace_context.py", "--repo-root", str(repo_root)]
    readiness_command = ["python", "scripts/check_linux_build_readiness.py", "--repo-root", str(repo_root), "--toolchains-root", preferred_root]
    nested_preflight_command = ["bash", "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh", "--repo-root", str(repo_root)]
    zig_recovery_command = ["bash", "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh", "--repo-root", str(repo_root), "--toolchains-root", preferred_root]
    return {
        "status": status,
        "repo_root": str(repo_root),
        "helper_root": str(helper_root or repo_root),
        "preferred_toolchains_root": preferred_root,
        "suggested_workspace_context_command": workspace_context_command,
        "suggested_readiness_command": readiness_command,
        "suggested_nested_preflight_command": nested_preflight_command,
        "suggested_zig_recovery_command": zig_recovery_command,
    }
"""

ROUTE_PRINTER_FIXTURE = """\
result = {
    "commands": {
        "surface_check": "bash ./scripts/linux/check_issue3_toolchains_root_candidates_route_surface.sh --repo-root /tmp/browser",
        "toolchains_root_candidates": "python ./scripts/check_issue11_toolchains_root_candidates.py --repo-root /tmp/browser --helper-root /tmp/browser",
        "nested_preflight": "bash ./scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh --repo-root /tmp/browser",
        "staged_rust_route": "bash ./scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh --repo-root /tmp/browser --toolchains-root /tmp/.toolchains",
        "staged_zig_route": "bash ./scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh --repo-root /tmp/browser --toolchains-root /tmp/.toolchains",
        "saved_rust_build_bridge": "bash ./scripts/linux/show_issue3_saved_rust_build_readiness_route.sh --repo-root /tmp/browser --toolchains-root /tmp/.toolchains",
        "linux_build_readiness_helper": "python ./scripts/check_linux_build_readiness.py --repo-root /tmp/browser --toolchains-root /tmp/.toolchains",
        "linux_build_readiness_route": "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root /tmp/browser",
        "zig_recovery_route": "bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root /tmp/browser --toolchains-root /tmp/.toolchains",
        "progress_tracker_route": "bash ./scripts/linux/show_issue3_progress_tracker_route.sh --repo-root /tmp/browser --toolchains-root /tmp/.toolchains",
    },
    "read_first": [
        "docs/ISSUE3_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md",
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
        "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
    ],
}
staged_rust_route_command = (
    f"bash {helper_root / 'scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh'} "
    f"--repo-root {repo_root} --toolchains-root {preferred_root}"
)
staged_zig_route_command = (
    f"bash {helper_root / 'scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh'} "
    f"--repo-root {repo_root} --toolchains-root {preferred_root}"
)
saved_rust_build_bridge_command = (
    f"bash {helper_root / 'scripts/linux/show_issue3_saved_rust_build_readiness_route.sh'} "
    f"--repo-root {repo_root} --toolchains-root {preferred_root}"
)
linux_build_readiness_helper_command = " ".join(report["suggested_readiness_command"])
zig_recovery_route_command = " ".join(report["suggested_zig_recovery_command"])
"""

SURFACE_CHECK_FIXTURE = """\
required_keys = (
    "toolchains_root_candidates",
    "nested_preflight",
    "staged_rust_route",
    "staged_zig_route",
    "saved_rust_build_bridge",
    "linux_build_readiness_helper",
    "linux_build_readiness_route",
    "zig_recovery_route",
    "progress_tracker_route",
)
for key in required_keys:
    pass
for key in (
    "staged_rust_route",
    "staged_zig_route",
    "saved_rust_build_bridge",
    "linux_build_readiness_helper",
    "zig_recovery_route",
):
    if "--toolchains-root" not in command or preferred_root not in command:
        failures.append(
            f"toolchains-root route handoff `{key}` is missing the surfaced --toolchains-root override"
        )
"""


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-issue11-toolchains-root-route-")
    )
    for relative_path, content in (
        (DOC_PATH, DOC_FIXTURE),
        (HELPER_PATH, HELPER_FIXTURE),
        (ROUTE_PRINTER_PATH, ROUTE_PRINTER_FIXTURE),
        (SURFACE_CHECK_PATH, SURFACE_CHECK_FIXTURE),
    ):
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
    return root


def load_repo_root() -> pathlib.Path:
    env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
    if env_root:
        return pathlib.Path(env_root).resolve()
    return build_fixture_repo()


def extract_command_keys(source: str) -> set[str]:
    return set(re.findall(r'"([a-z_]+)":', source))


class Issue11ToolchainsRootCandidatesRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = load_repo_root()
        cls.doc_source = (cls.repo_root / DOC_PATH).read_text(encoding="utf-8")
        cls.helper_source = (cls.repo_root / HELPER_PATH).read_text(encoding="utf-8")
        cls.route_printer_source = (
            cls.repo_root / ROUTE_PRINTER_PATH
        ).read_text(encoding="utf-8")
        cls.surface_check_source = (
            cls.repo_root / SURFACE_CHECK_PATH
        ).read_text(encoding="utf-8")

    def test_route_note_lists_required_companion_surfaces(self) -> None:
        for relative_path in DOC_REQUIRED_COMPANIONS:
            self.assertIn(relative_path, self.doc_source)

    def test_helper_keeps_required_report_keys(self) -> None:
        for key in HELPER_REQUIRED_KEYS:
            self.assertIn(f'"{key}"', self.helper_source)

    def test_route_printer_lists_read_first_docs(self) -> None:
        for relative_path in READ_FIRST_DOCS:
            self.assertIn(relative_path, self.route_printer_source)

    def test_route_printer_exposes_required_command_keys(self) -> None:
        command_keys = extract_command_keys(self.route_printer_source)
        for key in ROUTE_COMMAND_KEYS:
            self.assertIn(key, command_keys)

    def test_route_printer_keeps_toolchains_root_handoffs_explicit(self) -> None:
        self.assertIn(
            'f"--repo-root {repo_root} --toolchains-root {preferred_root}"',
            self.route_printer_source,
        )
        self.assertIn(
            'linux_build_readiness_helper_command = " ".join(report["suggested_readiness_command"])',
            self.route_printer_source,
        )
        self.assertIn(
            'zig_recovery_route_command = " ".join(report["suggested_zig_recovery_command"])',
            self.route_printer_source,
        )

    def test_surface_checker_requires_route_keys_and_override_guards(self) -> None:
        for key in ROUTE_COMMAND_KEYS[1:]:
            self.assertIn(f'"{key}"', self.surface_check_source)
        self.assertIn(
            "missing the surfaced --toolchains-root override",
            self.surface_check_source,
        )


if __name__ == "__main__":
    unittest.main()
