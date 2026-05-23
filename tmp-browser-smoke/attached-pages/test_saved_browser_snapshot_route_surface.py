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
    .name = .browser,
    .version = "0.0.0",
    .minimum_zig_version = "0.15.2",
    .dependencies = .{
        .v8 = .{ .path = "../zig-v8-fork" },
        .@"boringssl-zig" = .{ .path = "../boringssl-zig" },
        .curl = .{ .url = "https://example.invalid/curl.tar.gz" },
    },
}
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
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
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
# Issue #3 Saved Browser Snapshot Restore Route

- `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

```bash
bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh
bash ./scripts/linux/restore_saved_browser_snapshot.sh --check-only
```
""",
    "scripts/linux/restore_saved_browser_snapshot.sh": r"""
#!/usr/bin/env bash
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
TOP_LEVEL_ENTRY="browser-fork-headed-mode-foundation"
FOLLOW_UP_MEMORY_CHECK="python scripts/check_issue3_saved_memory_inputs.py --repo-root '${DESTINATION}'"
FOLLOW_UP_BUILD_ROUTE="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root '${DESTINATION}'"
FOLLOW_UP_RUNTIME_ROUTE="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root '${DESTINATION}'"
--check-only
--json
--force
Archive top level:
Suggested follow-up checks:
build.zig.zon
""",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": r"""
ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh --repo-root ${REPO_ROOT}"
SURFACE_CHECK_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh --browser-root ${REPO_ROOT} --memory-root ${MEMORY_ROOT} --archive ${ARCHIVE_PATH} --destination ${DESTINATION} --check-only"
RESTORE_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh --browser-root ${REPO_ROOT} --memory-root ${MEMORY_ROOT} --archive ${ARCHIVE_PATH} --destination ${DESTINATION}"
SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${DESTINATION}"
LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${DESTINATION}"
RUNTIME_ROUTE_COMMAND="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ${DESTINATION}"
Route surface check:
Restore helper surface check:
Saved-Memory preflight against the restored checkout:
Linux or WSL build-readiness route from the restored checkout:
Direct runtime re-entry route from the restored checkout:
Fallback Zig archive:
fallback-zig-archive
""",
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|"
    "scripts/linux/restore_saved_browser_snapshot.sh|file|"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|"
    "scripts/check_issue3_saved_memory_inputs.py|file|"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|"
    "build.zig.zon|file|Manifest surface"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|restore_saved_browser_snapshot.sh --check-only|"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_linux_build_readiness_route.sh|"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|"
    "scripts/linux/restore_saved_browser_snapshot.sh|--check-only|"
    "scripts/linux/restore_saved_browser_snapshot.sh|--json|"
    "scripts/linux/restore_saved_browser_snapshot.sh|Suggested follow-up checks:|"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|check_issue3_saved_browser_snapshot_route_surface.sh|"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|restore_saved_browser_snapshot.sh --browser-root|"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-Memory preflight against the restored checkout:|"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_linux_build_readiness_route.sh --repo-root|"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root|"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|fallback-zig-archive|"
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|"
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|"
    "scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|"
)
""",
    "scripts/check_issue3_saved_memory_inputs.py": """
REQUIRED_MEMORY_FILES = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/README.md", "saved repo notes"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
)
OPTIONAL_MEMORY_FILES = (
    ("repo_archives/browser/session_entry_register.yaml", "session entry register"),
)
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
Saved Memory input check passed.

def test_collect_results_passes_with_required_files(self): ...
def test_collect_results_fails_when_required_archive_is_missing(self): ...
def test_default_roots_follow_workspace_layout(self): ...
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-snapshot-route-"))
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
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_route_note_keeps_restore_preflight_and_followup_routes_visible(self) -> None:
        for fragment in (
            "check_issue3_saved_browser_snapshot_route_surface.sh",
            "restore_saved_browser_snapshot.sh",
            "show_issue3_saved_browser_snapshot_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "restore_saved_browser_snapshot.sh --check-only",
        ):
            self.assertIn(fragment, self.route_note)

    def test_restore_helper_keeps_archive_followup_and_checkout_contract_markers(self) -> None:
        for fragment in (
            'DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"',
            'DEFAULT_DESTINATION_NAME="browser-memory-snapshot"',
            "TOP_LEVEL_ENTRY",
            "FOLLOW_UP_MEMORY_CHECK",
            "FOLLOW_UP_BUILD_ROUTE",
            "FOLLOW_UP_RUNTIME_ROUTE",
            "--check-only",
            "--json",
            "--force",
            "Archive top level:",
            "Suggested follow-up checks:",
            "build.zig.zon",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_route_helper_keeps_surface_restore_and_restored_checkout_followups(self) -> None:
        for fragment in (
            'ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh',
            'SURFACE_CHECK_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh',
            "--check-only",
            'RESTORE_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh',
            'SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py',
            'LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh',
            'RUNTIME_ROUTE_COMMAND="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh',
            "Route surface check:",
            "Restore helper surface check:",
            "Saved-Memory preflight against the restored checkout:",
            "Linux or WSL build-readiness route from the restored checkout:",
            "Direct runtime re-entry route from the restored checkout:",
            "Fallback Zig archive:",
            "fallback-zig-archive",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_surface_checker_keeps_route_restore_and_saved_memory_expectations(self) -> None:
        for fragment in (
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|',
            '"scripts/linux/restore_saved_browser_snapshot.sh|file|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|',
            '"scripts/check_issue3_saved_memory_inputs.py|file|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|',
            '"build.zig.zon|file|Manifest surface"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|restore_saved_browser_snapshot.sh --check-only|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|',
            '"scripts/linux/restore_saved_browser_snapshot.sh|--check-only|',
            '"scripts/linux/restore_saved_browser_snapshot.sh|--json|',
            '"scripts/linux/restore_saved_browser_snapshot.sh|Suggested follow-up checks:|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-Memory preflight against the restored checkout:|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_linux_build_readiness_route.sh --repo-root|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root|',
            '"scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|',
            '"scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|',
            '"scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_saved_memory_helper_keeps_archive_and_workspace_contracts(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/README.md",
            "repo_archives/browser/blocker_intelligence.yaml",
            "repo_archives/browser/session_entry_register.yaml",
            'DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "Saved Memory input check passed.",
            "def test_collect_results_passes_with_required_files",
            "def test_collect_results_fails_when_required_archive_is_missing",
            "def test_default_roots_follow_workspace_layout",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_companion_notes_and_manifest_keep_snapshot_route_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "saved Rust `1.79.0` toolchain",
            "Prefer a Zig `0.15.2` toolchain",
        ):
            self.assertIn(fragment, self.linux_route_note)

        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
            '.curl = .{ .url = "https://example.invalid/curl.tar.gz" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
