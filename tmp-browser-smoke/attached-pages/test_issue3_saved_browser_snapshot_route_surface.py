from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "build.zig.zon": """
.{ .minimum_zig_version = "0.15.2" }
""",
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
# Issue #3 Saved Browser Snapshot Restore Route

- `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `restore_saved_browser_snapshot.sh --check-only`
- `show_issue3_saved_browser_snapshot_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `show_issue3_linux_build_readiness_route.sh`
- `show_issue3_enter_submit_runtime_revalidation_route.sh`
- `--helper-root /path/to/live/browser`
- `--sync-helper-surface`
- `Do not switch into the restored checkout`
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
""",
    "scripts/check_issue3_saved_memory_inputs.py": """
REQUIRED_MEMORY_FILES = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
)
print("Saved Memory input check passed.")
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
#!/usr/bin/env bash
""",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": """
#!/usr/bin/env bash
""",
    "scripts/linux/restore_saved_browser_snapshot.sh": r"""
--check-only
--helper-root
--fallback-zig-archive
--sync-helper-surface
Follow-up helper root:
Fallback Zig archive:
Helper surface sync:
Suggested follow-up checks:
show_issue3_linux_build_readiness_route.sh
show_issue3_enter_submit_runtime_revalidation_route.sh
""",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": r"""
check_issue3_saved_browser_snapshot_route_surface.sh
restore_saved_browser_snapshot.sh
--helper-root
--sync-helper-surface
follow_up_helper_root
Sync helper surface:
Saved-Memory preflight against the restored checkout:
show_issue3_linux_build_readiness_route.sh
show_issue3_enter_submit_runtime_revalidation_route.sh
fallback-zig-archive
current issue #3 helper docs and scripts
""",
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh": r"""
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|
"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|
"scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|
"scripts/linux/restore_saved_browser_snapshot.sh|file|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|
"scripts/check_issue3_saved_memory_inputs.py|file|
"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|
"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|
"build.zig.zon|file|Manifest surface"
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|restore_saved_browser_snapshot.sh --check-only|
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_linux_build_readiness_route.sh|
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|--helper-root /path/to/live/browser|
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|--sync-helper-surface|
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Do not switch into the restored checkout|
"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|
"scripts/linux/restore_saved_browser_snapshot.sh|--check-only|
"scripts/linux/restore_saved_browser_snapshot.sh|--helper-root|
"scripts/linux/restore_saved_browser_snapshot.sh|--fallback-zig-archive|
"scripts/linux/restore_saved_browser_snapshot.sh|--sync-helper-surface|
"scripts/linux/restore_saved_browser_snapshot.sh|Follow-up helper root:|
"scripts/linux/restore_saved_browser_snapshot.sh|Fallback Zig archive:|
"scripts/linux/restore_saved_browser_snapshot.sh|Helper surface sync:|
"scripts/linux/restore_saved_browser_snapshot.sh|Suggested follow-up checks:|
"scripts/linux/restore_saved_browser_snapshot.sh|show_issue3_linux_build_readiness_route.sh|
"scripts/linux/restore_saved_browser_snapshot.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|check_issue3_saved_browser_snapshot_route_surface.sh|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|restore_saved_browser_snapshot.sh|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|--helper-root|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|--sync-helper-surface|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|follow_up_helper_root|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Sync helper surface:|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-Memory preflight against the restored checkout:|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_linux_build_readiness_route.sh|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|fallback-zig-archive|
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|current issue #3 helper docs and scripts|
"scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|
"scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|
"scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|
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

    def test_route_note_keeps_restore_surface_and_followups_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "restore_saved_browser_snapshot.sh --check-only",
            "show_issue3_saved_browser_snapshot_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "--helper-root /path/to/live/browser",
            "--sync-helper-surface",
            "Do not switch into the restored checkout",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_helper_keeps_surface_restore_sync_and_followup_commands(self) -> None:
        for fragment in (
            "check_issue3_saved_browser_snapshot_route_surface.sh",
            "restore_saved_browser_snapshot.sh",
            "--helper-root",
            "--sync-helper-surface",
            "follow_up_helper_root",
            "Sync helper surface:",
            "Saved-Memory preflight against the restored checkout:",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "fallback-zig-archive",
            "current issue #3 helper docs and scripts",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_surface_checker_keeps_docs_helpers_and_snippet_expectations(self) -> None:
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
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|restore_saved_browser_snapshot.sh --check-only|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|',
            '"scripts/linux/restore_saved_browser_snapshot.sh|--fallback-zig-archive|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|follow_up_helper_root|',
            '"scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_restore_helper_keeps_check_only_sync_and_followup_surface(self) -> None:
        for fragment in (
            "--check-only",
            "--helper-root",
            "--fallback-zig-archive",
            "--sync-helper-surface",
            "Follow-up helper root:",
            "Fallback Zig archive:",
            "Helper surface sync:",
            "Suggested follow-up checks:",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_saved_memory_helper_keeps_snapshot_blocker_and_pass_surface(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/blocker_intelligence.yaml",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_runtime_gates_keep_saved_snapshot_route_visible(self) -> None:
        self.assertIn("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", self.runtime_gates)


if __name__ == "__main__":
    unittest.main()
