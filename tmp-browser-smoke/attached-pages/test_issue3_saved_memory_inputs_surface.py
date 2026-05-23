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

- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `python scripts/check_issue3_saved_memory_inputs.py --repo-root .`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `--fallback-zig-archive`
- saved Memory repo snapshot
- saved Rust 1.79.0 restore command
- zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": r"""
SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"
PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check --expect-saved-archives --saved-archives-root ${SAVED_ARCHIVES_ROOT}/dependencies"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"
fi
cat <<EOF
Saved Memory input preflight:
EOF
""",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux note"
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory preflight helper"
    "scripts/check_linux_build_readiness.py|file|Python helper"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|Linux note keeps saved Memory preflight helper visible."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_MEMORY_INPUTS_COMMAND|Route printer keeps a dedicated saved Memory preflight command."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Memory input preflight:|Route printer still prints the saved Memory preflight step."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|Saved Memory helper checks the repo snapshot."
)
""",
    "scripts/check_issue3_saved_memory_inputs.py": """
REQUIRED_MEMORY_FILES = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/README.md", "saved repo notes"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    ("repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz", "saved Rust toolchain archive"),
    ("repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip", "saved html5ever dependency archive"),
    ("repo_archives/browser/dependencies/03-boringssl-zig-main.zip", "saved BoringSSL archive"),
    ("repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip", "saved browser dependency archive"),
)
OPTIONAL_MEMORY_FILES = (
    ("repo_archives/browser/session_entry_register.yaml", "session entry register"),
)
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
def build_parser():
    parser.add_argument("--memory-root")
    parser.add_argument("--agent-files-root")
    parser.add_argument("--fallback-zig-archive")
    parser.add_argument("--json")
    parser.add_argument("--self-test")
def resolve_default_memory_root(repo_root): ...
def resolve_default_agent_files_root(repo_root): ...
def emit_text(result):
    print("Saved Memory input check passed.")
    print("restore or remount the saved repo and dependency archives before reopening the issue #3 runtime route.")
class SavedMemoryInputsTests(unittest.TestCase):
    def test_collect_results_passes_with_required_files(self): ...
    def test_collect_results_fails_when_required_archive_is_missing(self): ...
    def test_default_roots_follow_workspace_layout(self): ...
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-memory-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class SavedMemoryInputsSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
        )
        cls.memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )

    def test_route_note_keeps_saved_memory_preflight_visible(self) -> None:
        for fragment in (
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
            "--fallback-zig-archive",
            "saved Memory repo snapshot",
            "saved Rust 1.79.0 restore command",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_helper_keeps_saved_memory_command_and_output_label(self) -> None:
        for fragment in (
            'SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py',
            "--fallback-zig-archive",
            "Saved Memory input preflight:",
            'PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py',
        ):
            self.assertIn(fragment, self.route_helper)

    def test_surface_checker_keeps_saved_memory_references(self) -> None:
        for fragment in (
            '"scripts/check_issue3_saved_memory_inputs.py|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_MEMORY_INPUTS_COMMAND|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Memory input preflight:|',
            '"scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_memory_helper_keeps_required_archives_and_cli_switches(self) -> None:
        for fragment in (
            'repo_archives/browser/01-browser-fork-headed-mode-foundation.zip',
            'repo_archives/browser/README.md',
            'repo_archives/browser/blocker_intelligence.yaml',
            'repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz',
            'repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip',
            'repo_archives/browser/session_entry_register.yaml',
            'DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            '"--memory-root"',
            '"--agent-files-root"',
            '"--fallback-zig-archive"',
            '"--json"',
            '"--self-test"',
            "resolve_default_memory_root",
            "resolve_default_agent_files_root",
            "Saved Memory input check passed.",
            "restore or remount the saved repo and dependency archives before reopening the issue #3 runtime route.",
            "def test_collect_results_passes_with_required_files",
            "def test_collect_results_fails_when_required_archive_is_missing",
            "def test_default_roots_follow_workspace_layout",
        ):
            self.assertIn(fragment, self.memory_helper)


if __name__ == "__main__":
    unittest.main()
