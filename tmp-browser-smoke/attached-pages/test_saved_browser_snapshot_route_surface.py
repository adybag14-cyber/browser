from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "build.zig.zon": """
.{
    .name = "browser",
    .version = "0.0.0",
    .minimum_zig_version = "0.15.2",
    .dependencies = .{
        .v8 = .{ .path = "../zig-v8-fork" },
        .@"boringssl-zig" = .{ .path = "../boringssl-zig" },
        .curl = .{ .url = "https://example.invalid/curl.tar.gz" },
    },
}
""",
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
# Issue #3 Saved Browser Snapshot Restore Route

- `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `--helper-root /path/to/live/browser`
- `restore_saved_browser_snapshot.sh --check-only`
- `--sync-helper-surface`
- Do not switch into the restored checkout
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
- `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `python scripts/check_issue3_saved_memory_inputs.py --repo-root .`
""",
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Read-first saved-browser-snapshot restore note."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Companion Linux or WSL build-readiness note."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note."
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Fail-fast surface checker."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Compact route printer."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory input preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Build-readiness route printer."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Runtime route printer."
    "build.zig.zon|file|Manifest surface"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|Note keeps route surface checker visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|restore_saved_browser_snapshot.sh --check-only|Note keeps restore helper surface check visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|--helper-root /path/to/live/browser|Note keeps helper-root override visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|--sync-helper-surface|Note keeps helper-surface sync mode visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Do not switch into the restored checkout|Note warns the snapshot may not carry the newest route scripts."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Gate note keeps saved-browser-snapshot route visible."
    "scripts/linux/restore_saved_browser_snapshot.sh|--helper-root|Restore helper supports helper-root override."
    "scripts/linux/restore_saved_browser_snapshot.sh|--sync-helper-surface|Restore helper supports helper-surface sync mode."
    "scripts/linux/restore_saved_browser_snapshot.sh|Helper surface sync:|Restore helper prints helper-surface sync status."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|helper_root|Route printer exposes helper_root in JSON output."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|follow_up_helper_root|Route printer exposes follow-up helper root in JSON output."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|--sync-helper-surface|Route printer keeps helper-surface sync mode visible."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Sync helper surface:|Route printer prints helper-surface sync status."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|current issue #3 helper docs and scripts|Route printer explains what helper sync copies."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|Saved-Memory input preflight checks blocker intelligence."
)
""",
    "scripts/linux/restore_saved_browser_snapshot.sh": r"""
Usage:
  bash scripts/linux/restore_saved_browser_snapshot.sh \
    [--browser-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--sync-helper-surface] \
    [--check-only] \
    [--json] \
    [--force]

if [[ ! -f "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py" ]]; then
    exit 1
fi
if [[ ! -f "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh" ]]; then
    exit 1
fi
if [[ ! -f "${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh" ]]; then
    exit 1
fi
TOP_LEVEL_ENTRY="$(python3 - "${ARCHIVE_PATH}" <<'PY'
import zipfile
PY
)"
FOLLOW_UP_MEMORY_CHECK="python ${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py --repo-root ${DESTINATION}"
FOLLOW_UP_BUILD_ROUTE="bash ${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${DESTINATION}"
FOLLOW_UP_RUNTIME_ROUTE="bash ${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ${DESTINATION}"
echo "Helper root:        ${HELPER_ROOT}"
echo "Helper surface sync:   enabled"
echo "Suggested follow-up checks:"
""",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": r"""
ROUTE_SURFACE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh --repo-root ${HELPER_ROOT}"
SURFACE_CHECK_COMMAND="bash ${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh --browser-root ${REPO_ROOT} --helper-root ${HELPER_ROOT} --memory-root ${MEMORY_ROOT} --archive ${ARCHIVE_PATH} --destination ${DESTINATION} --check-only"
RESTORE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh --browser-root ${REPO_ROOT} --helper-root ${HELPER_ROOT} --memory-root ${MEMORY_ROOT} --archive ${ARCHIVE_PATH} --destination ${DESTINATION} --sync-helper-surface"
SAVED_MEMORY_PREFLIGHT_COMMAND="python ${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py --repo-root ${DESTINATION}"
LINUX_BUILD_ROUTE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${DESTINATION}"
RUNTIME_ROUTE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ${DESTINATION}"
SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"
{
  "helper_root": "x",
  "follow_up_helper_root": "x",
  "fallback_zig_archive": "x"
}
Helper root:
Sync helper surface:
Saved-Memory preflight against the restored checkout:
live branch-local helper surface
current issue #3 helper docs and scripts
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
def resolve_default_memory_root(repo_root): return repo_root.parent / "memory"
def resolve_default_agent_files_root(repo_root): return repo_root.parent / "agent_files"
parser.add_argument("--fallback-zig-archive")
parser.add_argument("--self-test")
print("Saved Memory input check passed.")

def test_collect_results_passes_with_required_files(self): ...
def test_collect_results_fails_when_required_archive_is_missing(self): ...
def test_default_roots_follow_workspace_layout(self): ...
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `saved Rust `1.79.0` toolchain`
- `Prefer a Zig `0.15.2` toolchain`
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
#!/usr/bin/env bash
""",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": """
#!/usr/bin/env bash
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-snapshot-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class SavedBrowserSnapshotRouteSurfaceTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        )
        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.linux_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        cls.saved_memory_inputs = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_route_note_keeps_restore_surface_followup_and_guardrails_visible(self) -> None:
        for fragment in (
            "check_issue3_saved_browser_snapshot_route_surface.sh",
            "restore_saved_browser_snapshot.sh",
            "show_issue3_saved_browser_snapshot_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "--helper-root /path/to/live/browser",
            "restore_saved_browser_snapshot.sh --check-only",
            "--sync-helper-surface",
            "Do not switch into the restored checkout",
        ):
            self.assertIn(fragment, self.route_note)

    def test_surface_checker_keeps_reference_paths_and_content_expectations(self) -> None:
        for fragment in (
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"scripts/linux/restore_saved_browser_snapshot.sh|file|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|',
            '"scripts/check_issue3_saved_memory_inputs.py|file|',
            '"build.zig.zon|file|Manifest surface"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|restore_saved_browser_snapshot.sh --check-only|',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|--helper-root /path/to/live/browser|',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|--sync-helper-surface|',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Do not switch into the restored checkout|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|',
            '"scripts/linux/restore_saved_browser_snapshot.sh|--helper-root|',
            '"scripts/linux/restore_saved_browser_snapshot.sh|--sync-helper-surface|',
            '"scripts/linux/restore_saved_browser_snapshot.sh|Helper surface sync:|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|helper_root|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|follow_up_helper_root|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|--sync-helper-surface|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Sync helper surface:|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|current issue #3 helper docs and scripts|',
            '"scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_restore_helper_keeps_check_only_helper_root_sync_followups_and_zip_probe(self) -> None:
        for fragment in (
            "--check-only",
            "--helper-root /path/to/live/browser-repo",
            "--sync-helper-surface",
            "--json",
            "scripts/check_issue3_saved_memory_inputs.py",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "TOP_LEVEL_ENTRY",
            "import zipfile",
            "FOLLOW_UP_MEMORY_CHECK",
            "FOLLOW_UP_BUILD_ROUTE",
            "FOLLOW_UP_RUNTIME_ROUTE",
            "Helper root:",
            "Helper surface sync:",
            "Suggested follow-up checks:",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_route_helper_keeps_surface_check_restore_preflight_sync_and_json_fields(self) -> None:
        for fragment in (
            "ROUTE_SURFACE_COMMAND",
            "check_issue3_saved_browser_snapshot_route_surface.sh",
            "SURFACE_CHECK_COMMAND",
            "restore_saved_browser_snapshot.sh",
            "--check-only",
            "RESTORE_COMMAND",
            "--sync-helper-surface",
            "SAVED_MEMORY_PREFLIGHT_COMMAND",
            "scripts/check_issue3_saved_memory_inputs.py",
            "LINUX_BUILD_ROUTE_COMMAND",
            "RUNTIME_ROUTE_COMMAND",
            "--fallback-zig-archive",
            '"helper_root"',
            '"follow_up_helper_root"',
            "Helper root:",
            "Sync helper surface:",
            "Saved-Memory preflight against the restored checkout:",
            "live branch-local helper surface",
            "current issue #3 helper docs and scripts",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_saved_memory_inputs_helper_and_runtime_gates_keep_snapshot_route_contract(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/README.md",
            "repo_archives/browser/blocker_intelligence.yaml",
            "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
            "repo_archives/browser/dependencies/03-boringssl-zig-main.zip",
            "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
            "repo_archives/browser/session_entry_register.yaml",
            'DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'repo_root.parent / "memory"',
            'repo_root.parent / "agent_files"',
            "--fallback-zig-archive",
            "--self-test",
            "Saved Memory input check passed.",
            "def test_collect_results_passes_with_required_files",
            "def test_collect_results_fails_when_required_archive_is_missing",
            "def test_default_roots_follow_workspace_layout",
        ):
            self.assertIn(fragment, self.saved_memory_inputs)

        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "show_issue3_saved_browser_snapshot_route.sh",
            "scripts/check_linux_build_readiness.py",
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
        ):
            self.assertIn(fragment, self.runtime_gates)

        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "check_issue3_saved_browser_snapshot_route_surface.sh",
            "show_issue3_saved_browser_snapshot_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "saved Rust `1.79.0` toolchain",
            "Prefer a Zig `0.15.2` toolchain",
        ):
            self.assertIn(fragment, self.linux_route_note)


if __name__ == "__main__":
    unittest.main()
