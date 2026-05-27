from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


ROUTE_NOTE_PATH = "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
ROUTE_PRINTER_PATH = "scripts/linux/show_issue3_progress_tracker_route.sh"
ROUTE_SURFACE_PATH = "scripts/linux/check_issue3_progress_tracker_route_surface.sh"
HELPER_PATH = "scripts/check_issue11_toolchains_root_candidates.py"

FIXTURE_ROUTE_NOTE = """
# Issue #3 Progress Tracker Route

Use issue `#11` instead for the lower-volume Linux or WSL re-entry lane.

If the immediate slice is about choosing between visible `toolchains/` and
hidden `.toolchains/` roots before later Linux or WSL helpers trust a guessed
default, keep the toolchains-root candidate helper visible first:

```bash
python ./scripts/check_issue11_toolchains_root_candidates.py --repo-root .
```

Use its surfaced `--toolchains-root` override before rerunning saved-Rust,
build-readiness rerun, matching-line, Linux build-readiness, or Zig recovery
helpers from the same workspace layout.
"""

FIXTURE_ROUTE_PRINTER = """
#!/usr/bin/env bash

TOOLCHAINS_ROOT_CANDIDATES_COMMAND="python3 scripts/check_issue11_toolchains_root_candidates.py --repo-root ."

cat <<'EOF2'
Toolchains-root candidates:
  ${TOOLCHAINS_ROOT_CANDIDATES_COMMAND}
EOF2

printf '{\n'
printf '  "commands": {\n'
printf '    "toolchains_root_candidates": %s\n' "${TOOLCHAINS_ROOT_CANDIDATES_COMMAND}"
printf '  }\n'
printf '}\n'
"""

FIXTURE_ROUTE_SURFACE = """
#!/usr/bin/env bash

declare -a REFERENCE_PATHS=(
    "scripts/check_issue11_toolchains_root_candidates.py|file|Issue #11 toolchains-root candidate helper used when both toolchains/ and .toolchains/ may be visible and later reruns need one explicit surfaced root."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|scripts/check_issue11_toolchains_root_candidates.py|The progress-tracker note keeps the toolchains-root candidate helper visible before later reruns trust a guessed toolchains root."
    "scripts/linux/show_issue3_progress_tracker_route.sh|check_issue11_toolchains_root_candidates.py|The route printer still exposes the toolchains-root candidate helper."
    "scripts/linux/show_issue3_progress_tracker_route.sh|toolchains_root_candidates|The route printer JSON output exposes the toolchains-root candidate helper explicitly."
    "scripts/linux/show_issue3_progress_tracker_route.sh|Toolchains-root candidates:|The route printer keeps the toolchains-root candidate helper visible in the human-readable handoff."
)
"""

FIXTURE_HELPER = """
#!/usr/bin/env python3

def collect_candidates(repo_root, helper_root=None):
    hidden_root = ".toolchains"
    visible_root = "toolchains"
    preferred_reason = "prefer hidden .toolchains when it exists because staged shared toolchains may live there"
    warnings = [
        "both .toolchains and toolchains are visible; pass --toolchains-root explicitly so later reruns do not pick the wrong surface"
    ]
    return {
        "preferred_reason": preferred_reason,
        "warnings": warnings,
        "suggested_readiness_command": [
            "python",
            "scripts/check_linux_build_readiness.py",
            "--repo-root",
            str(repo_root),
            "--toolchains-root",
            hidden_root,
        ],
        "suggested_nested_preflight_command": [
            "bash",
            "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
            "--repo-root",
            str(repo_root),
        ],
        "suggested_zig_recovery_command": [
            "bash",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "--repo-root",
            str(repo_root),
            "--toolchains-root",
            hidden_root,
        ],
    }
"""


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-issue11-toolchains-progress-surface-")
    )
    fixture_files = {
        ROUTE_NOTE_PATH: FIXTURE_ROUTE_NOTE.lstrip("\n"),
        ROUTE_PRINTER_PATH: FIXTURE_ROUTE_PRINTER.lstrip("\n"),
        ROUTE_SURFACE_PATH: FIXTURE_ROUTE_SURFACE.lstrip("\n"),
        HELPER_PATH: FIXTURE_HELPER.lstrip("\n"),
    }
    for relative_path, content in fixture_files.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
    return root


class Issue11ToolchainsRootCandidatesProgressSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        cls.repo_root = pathlib.Path(env_root).resolve() if env_root else build_fixture_repo()
        cls.route_note = (cls.repo_root / ROUTE_NOTE_PATH).read_text(encoding="utf-8")
        cls.route_printer = (cls.repo_root / ROUTE_PRINTER_PATH).read_text(
            encoding="utf-8"
        )
        cls.route_surface = (cls.repo_root / ROUTE_SURFACE_PATH).read_text(
            encoding="utf-8"
        )
        cls.helper_source = (cls.repo_root / HELPER_PATH).read_text(encoding="utf-8")

    def test_route_note_keeps_toolchains_helper_and_override_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "toolchains/` and\nhidden `.toolchains/`",
            "scripts/check_issue11_toolchains_root_candidates.py",
            "--toolchains-root",
            "build-readiness rerun",
            "Zig recovery",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_printer_keeps_toolchains_handoff_visible(self) -> None:
        for fragment in (
            "check_issue11_toolchains_root_candidates.py",
            "toolchains_root_candidates",
            "Toolchains-root candidates:",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_route_surface_keeps_toolchains_helper_contract_visible(self) -> None:
        for fragment in (
            "scripts/check_issue11_toolchains_root_candidates.py",
            "toolchains_root_candidates",
            "Toolchains-root candidates:",
        ):
            self.assertIn(fragment, self.route_surface)

    def test_helper_prefers_hidden_root_and_threads_explicit_override(self) -> None:
        for fragment in (
            ".toolchains",
            "toolchains",
            "pass --toolchains-root explicitly",
            "suggested_readiness_command",
            "check_linux_build_readiness.py",
            "suggested_nested_preflight_command",
            "run_issue11_nested_workspace_saved_memory_preflight.sh",
            "suggested_zig_recovery_command",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "--toolchains-root",
        ):
            self.assertIn(fragment, self.helper_source)


if __name__ == "__main__":
    unittest.main()
