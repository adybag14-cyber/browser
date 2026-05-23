from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`

7. If the run depends on the saved Memory repo and dependency bundles, run the
   saved-input preflight before the Linux or WSL build-readiness helpers:

```bash
python scripts/check_issue3_saved_memory_inputs.py --repo-root .
```
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`

## Run The Saved-Memory Preflight Next

```bash
python scripts/check_issue3_saved_memory_inputs.py --repo-root .
```

2. A saved-Memory preflight using `scripts/check_issue3_saved_memory_inputs.py`
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": r"""
SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"
PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT}"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"
fi

    "saved_memory_inputs": ${SAVED_MEMORY_INPUTS_COMMAND@Q},

        "Run the saved_memory_inputs command before the broader saved-archive preflight when the route depends on the saved Memory repo snapshot and dependency bundles.",

  Saved Memory input preflight:
    ${SAVED_MEMORY_INPUTS_COMMAND}
""",
    "scripts/check_issue3_saved_memory_inputs.py": """
REQUIRED_MEMORY_FILES = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/README.md", "saved repo notes"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
)

DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

def build_parser():
    parser.add_argument("--repo-root")
    parser.add_argument("--memory-root")
    parser.add_argument("--agent-files-root")
    parser.add_argument("--fallback-zig-archive")
    parser.add_argument("--json")
    parser.add_argument("--self-test")

class SavedMemoryInputsTests(unittest.TestCase):
    def test_collect_results_passes_with_required_files(self): ...
    def test_collect_results_fails_when_required_archive_is_missing(self): ...
    def test_default_roots_follow_workspace_layout(self): ...
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-memory-preflight-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedMemoryPreflightSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.linux_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.linux_route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )

    def test_runtime_docs_keep_saved_memory_preflight_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_memory_inputs.py",
            "saved-input preflight before the Linux or WSL build-readiness helpers",
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
        ):
            self.assertIn(fragment, self.runtime_gates)

        for fragment in (
            "scripts/check_issue3_saved_memory_inputs.py",
            "Run The Saved-Memory Preflight Next",
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
            "A saved-Memory preflight using `scripts/check_issue3_saved_memory_inputs.py`",
        ):
            self.assertIn(fragment, self.linux_route_note)

    def test_linux_route_helper_keeps_saved_memory_preflight_before_archive_preflight(self) -> None:
        for fragment in (
            'SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root',
            'SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive',
            '"saved_memory_inputs": ${SAVED_MEMORY_INPUTS_COMMAND@Q}',
            "Run the saved_memory_inputs command before the broader saved-archive preflight",
            "Saved Memory input preflight:",
            "${SAVED_MEMORY_INPUTS_COMMAND}",
        ):
            self.assertIn(fragment, self.linux_route_helper)

    def test_saved_memory_helper_keeps_required_inputs_cli_and_self_tests(self) -> None:
        for fragment in (
            "saved repo snapshot",
            "saved repo notes",
            "blocker intelligence",
            "DEFAULT_FALLBACK_ZIG",
            "--repo-root",
            "--memory-root",
            "--agent-files-root",
            "--fallback-zig-archive",
            "--json",
            "--self-test",
            "test_collect_results_passes_with_required_files",
            "test_collect_results_fails_when_required_archive_is_missing",
            "test_default_roots_follow_workspace_layout",
        ):
            self.assertIn(fragment, self.saved_memory_helper)


if __name__ == "__main__":
    unittest.main()
