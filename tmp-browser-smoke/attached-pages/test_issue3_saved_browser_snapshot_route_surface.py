from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "build.zig.zon": """
.{ .name = "browser", .minimum_zig_version = "0.15.2" }
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
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
""",
    "scripts/linux/restore_saved_browser_snapshot.sh": r"""
Usage:
  bash scripts/linux/restore_saved_browser_snapshot.sh --check-only --json
Suggested follow-up checks:
python scripts/check_issue3_saved_memory_inputs.py --repo-root "${DESTINATION}"
bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root "${DESTINATION}"
bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root "${DESTINATION}"
""",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": r"""
ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh --repo-root ${REPO_ROOT}"
RESTORE_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh --browser-root ${REPO_ROOT}"
SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${DESTINATION} --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"
LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${DESTINATION}"
RUNTIME_ROUTE_COMMAND="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ${DESTINATION}"
Saved-Memory preflight against the restored checkout:
fallback-zig-archive
""",
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh": r"""
REFERENCE_PATHS=(
  "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Read-first saved-browser-snapshot restore note."
  "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Companion Linux or WSL build-readiness note."
  "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note."
  "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Surface checker."
  "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper."
  "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Route printer."
  "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory input preflight."
  "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Companion build-readiness route."
  "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Companion runtime route."
  "build.zig.zon|file|Manifest surface."
)
CONTENT_EXPECTATIONS=(
  "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|Note keeps surface checker visible."
  "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|Note prints route surface-check command."
  "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|restore_saved_browser_snapshot.sh --check-only|Note keeps restore helper surface check visible."
  "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|Note keeps route printer visible."
  "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|Note keeps saved-Memory preflight visible."
  "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_linux_build_readiness_route.sh|Note keeps build-readiness route visible."
  "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|Note keeps runtime route visible."
  "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Gate note keeps snapshot route visible."
  "scripts/linux/restore_saved_browser_snapshot.sh|--check-only|Restore helper supports surface-only validation."
  "scripts/linux/restore_saved_browser_snapshot.sh|--json|Restore helper supports structured output."
  "scripts/linux/restore_saved_browser_snapshot.sh|Suggested follow-up checks:|Restore helper prints next-step checks."
  "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|check_issue3_saved_browser_snapshot_route_surface.sh|Route printer points back to surface checker."
  "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|restore_saved_browser_snapshot.sh --browser-root|Route printer prints restore helper invocation."
  "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-Memory preflight against the restored checkout:|Route printer prints saved-Memory preflight step."
  "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_linux_build_readiness_route.sh --repo-root|Route printer prints build-readiness follow-up."
  "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root|Route printer prints runtime follow-up."
  "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|fallback-zig-archive|Route printer supports fallback Zig override."
  "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|Saved-Memory preflight checks repo snapshot."
  "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|Saved-Memory preflight checks blocker intelligence."
  "scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|Saved-Memory preflight reports pass surface."
)
""",
    "scripts/check_issue3_saved_memory_inputs.py": """
REQUIRED_MEMORY_FILES = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
)
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
def build_parser():
    parser.add_argument("--fallback-zig-archive")
Saved Memory input check passed.
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": "# companion route\n",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": "# companion route\n",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": "# companion route\n",
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
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )
        cls.route_printer = read_text(
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

    def test_route_note_keeps_restore_surface_followup_and_runtime_commands_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "restore_saved_browser_snapshot.sh --check-only",
            "show_issue3_saved_browser_snapshot_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
        ):
            self.assertIn(fragment, self.route_note)

    def test_restore_helper_keeps_check_only_json_and_followup_commands(self) -> None:
        for fragment in (
            "--check-only",
            "--json",
            "Suggested follow-up checks:",
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root",
            "show_issue3_linux_build_readiness_route.sh --repo-root",
            "show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_route_printer_keeps_surface_restore_preflight_and_followup_commands(self) -> None:
        for fragment in (
            'ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh',
            'RESTORE_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh --browser-root',
            'SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root',
            'LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root',
            'RUNTIME_ROUTE_COMMAND="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root',
            "Saved-Memory preflight against the restored checkout:",
            "fallback-zig-archive",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_surface_checker_keeps_reference_paths_and_content_expectations_in_scope(self) -> None:
        for fragment in (
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"scripts/linux/restore_saved_browser_snapshot.sh|file|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|',
            '"scripts/check_issue3_saved_memory_inputs.py|file|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|',
            '"build.zig.zon|file|Manifest surface."',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|restore_saved_browser_snapshot.sh --check-only|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|',
            '"scripts/linux/restore_saved_browser_snapshot.sh|Suggested follow-up checks:|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-Memory preflight against the restored checkout:|',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|fallback-zig-archive|',
            '"scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|',
            '"scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|',
            '"scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_saved_memory_preflight_keeps_repo_blocker_and_fallback_zig_contracts(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/blocker_intelligence.yaml",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--fallback-zig-archive",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_runtime_gates_and_manifest_still_point_at_the_restore_route(self) -> None:
        self.assertIn("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", self.runtime_gates)
        self.assertIn('.minimum_zig_version = "0.15.2"', self.build_manifest)


if __name__ == "__main__":
    unittest.main()
