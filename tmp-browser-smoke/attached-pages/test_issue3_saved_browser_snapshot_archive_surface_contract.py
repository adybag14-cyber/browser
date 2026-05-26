from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md": """
    # Issue #3 Saved Browser Snapshot Archive Surface

    The checker mirrors the current helper-surface contract from
    `scripts/linux/restore_saved_browser_snapshot.sh`.

    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
    - `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
    - `scripts/check_issue3_workspace_context.py`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/check_issue3_staged_zig_toolchain_candidates.py`
    - `scripts/check_issue3_build_readiness_rerun.py`
    - `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
    - `scripts/linux/show_issue3_progress_tracker_route.sh`
    - `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
    - `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
    - `scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
    - `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
    - `scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh`
    - `scripts/linux/show_issue3_windows_runtime_handoff_route.sh`
    """,
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py": """
    RESTORE_HELPER_PATH = \"scripts/linux/restore_saved_browser_snapshot.sh\"
    KNOWN_REQUIRED_PATHS = [
        (\"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md\", \"progress tracker note\"),
        (\"docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md\", \"workspace context note\"),
        (\"docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md\", \"saved-memory inputs note\"),
        (\"docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md\", \"saved Rust build-readiness note\"),
        (\"docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md\", \"saved Rust archive candidates note\"),
        (\"scripts/check_issue3_workspace_context.py\", \"workspace context helper\"),
        (\"scripts/check_issue3_saved_rust_archive_candidates.py\", \"saved Rust archive candidates helper\"),
        (\"scripts/check_issue3_staged_rust_toolchain_candidates.py\", \"staged Rust toolchain candidates helper\"),
        (\"scripts/check_issue3_saved_zig_archive_candidates.py\", \"saved Zig archive candidates helper\"),
        (\"scripts/check_issue3_staged_zig_toolchain_candidates.py\", \"staged Zig toolchain candidates helper\"),
        (\"scripts/check_issue3_build_readiness_rerun.py\", \"build-readiness rerun helper\"),
        (\"scripts/linux/check_issue3_progress_tracker_route_surface.sh\", \"progress tracker surface\"),
        (\"scripts/linux/show_issue3_progress_tracker_route.sh\", \"progress tracker route\"),
        (\"scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh\", \"saved-memory inputs surface\"),
        (\"scripts/linux/show_issue3_saved_memory_inputs_route.sh\", \"saved-memory inputs route\"),
        (\"scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh\", \"saved Rust build-readiness surface\"),
        (\"scripts/linux/show_issue3_saved_rust_build_readiness_route.sh\", \"saved Rust build-readiness route\"),
        (\"scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh\", \"saved Rust archive candidates surface\"),
        (\"scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh\", \"saved Rust archive candidates route\"),
        (\"scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh\", \"Windows runtime handoff surface\"),
        (\"scripts/linux/show_issue3_windows_runtime_handoff_route.sh\", \"Windows runtime handoff route\"),
    ]

    def load_required_paths(repo_root: Path) -> list[tuple[str, str]]:
        required_paths = list(KNOWN_REQUIRED_PATHS)
        return required_paths

    required_paths = load_required_paths(Path("."))
    payload = {\"required_path_count\": len(required_paths)}
    """,
    "scripts/check_issue3_restored_checkout.py": """
    HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
        (\"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md\", \"tracker\"),
        (\"docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md\", \"workspace context\"),
        (\"docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md\", \"saved-memory inputs\"),
        (\"docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md\", \"saved Rust build-readiness\"),
        (\"docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md\", \"saved Rust archive candidates\"),
        (\"scripts/check_issue3_workspace_context.py\", \"workspace helper\"),
        (\"scripts/check_issue3_saved_rust_archive_candidates.py\", \"saved Rust archive candidates\"),
        (\"scripts/check_issue3_staged_rust_toolchain_candidates.py\", \"staged Rust candidates\"),
        (\"scripts/check_issue3_saved_zig_archive_candidates.py\", \"saved Zig candidates\"),
        (\"scripts/check_issue3_staged_zig_toolchain_candidates.py\", \"staged Zig candidates\"),
        (\"scripts/check_issue3_build_readiness_rerun.py\", \"build-readiness rerun\"),
        (\"scripts/linux/check_issue3_progress_tracker_route_surface.sh\", \"progress tracker surface\"),
        (\"scripts/linux/show_issue3_progress_tracker_route.sh\", \"progress tracker route\"),
        (\"scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh\", \"saved-memory surface\"),
        (\"scripts/linux/show_issue3_saved_memory_inputs_route.sh\", \"saved-memory route\"),
        (\"scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh\", \"saved Rust build-readiness surface\"),
        (\"scripts/linux/show_issue3_saved_rust_build_readiness_route.sh\", \"saved Rust build-readiness route\"),
        (\"scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh\", \"saved Rust archive candidates surface\"),
        (\"scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh\", \"saved Rust archive candidates route\"),
        (\"scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh\", \"Windows handoff surface\"),
        (\"scripts/linux/show_issue3_windows_runtime_handoff_route.sh\", \"Windows handoff route\"),
    )
    """,
    "scripts/linux/restore_saved_browser_snapshot.sh": """
    declare -a HELPER_SURFACE_PATHS=(
        \"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md\"
        \"docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md\"
        \"docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md\"
        \"docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md\"
        \"docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md\"
        \"scripts/check_issue3_workspace_context.py\"
        \"scripts/check_issue3_saved_rust_archive_candidates.py\"
        \"scripts/check_issue3_staged_rust_toolchain_candidates.py\"
        \"scripts/check_issue3_saved_zig_archive_candidates.py\"
        \"scripts/check_issue3_staged_zig_toolchain_candidates.py\"
        \"scripts/check_issue3_build_readiness_rerun.py\"
        \"scripts/linux/check_issue3_progress_tracker_route_surface.sh\"
        \"scripts/linux/show_issue3_progress_tracker_route.sh\"
        \"scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh\"
        \"scripts/linux/show_issue3_saved_memory_inputs_route.sh\"
        \"scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh\"
        \"scripts/linux/show_issue3_saved_rust_build_readiness_route.sh\"
        \"scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh\"
        \"scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh\"
        \"scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh\"
        \"scripts/linux/show_issue3_windows_runtime_handoff_route.sh\"
    )
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-snapshot-archive-surface-contract-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedBrowserSnapshotArchiveSurfaceContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.snapshot_doc = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md"
        )
        cls.archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
        )
        cls.restored_helper = read_text(
            cls.repo_root / "scripts/check_issue3_restored_checkout.py"
        )
        cls.restore_script = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )

    def test_snapshot_doc_mentions_dynamic_restore_contract_and_newer_routes(self) -> None:
        for fragment in (
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
            "scripts/check_issue3_workspace_context.py",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/check_issue3_staged_zig_toolchain_candidates.py",
            "scripts/check_issue3_build_readiness_rerun.py",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
            "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
            "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh",
            "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh",
            "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
        ):
            self.assertIn(fragment, self.snapshot_doc)

    def test_archive_helper_uses_dynamic_restore_surface_loader(self) -> None:
        for fragment in (
            'RESTORE_HELPER_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"',
            "KNOWN_REQUIRED_PATHS = [",
            '("docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md", "saved Rust build-readiness note"),',
            '("docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md", "saved Rust archive candidates note"),',
            '("scripts/check_issue3_saved_rust_archive_candidates.py", "saved Rust archive candidates helper"),',
            '("scripts/check_issue3_staged_rust_toolchain_candidates.py", "staged Rust toolchain candidates helper"),',
            '("scripts/check_issue3_staged_zig_toolchain_candidates.py", "staged Zig toolchain candidates helper"),',
            '("scripts/check_issue3_build_readiness_rerun.py", "build-readiness rerun helper"),',
            '("scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh", "saved Rust build-readiness surface"),',
            '("scripts/linux/show_issue3_saved_rust_build_readiness_route.sh", "saved Rust build-readiness route"),',
            '("scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh", "saved Rust archive candidates surface"),',
            '("scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh", "saved Rust archive candidates route"),',
            "def load_required_paths(repo_root: Path) -> list[tuple[str, str]]:",
            'required_paths = list(KNOWN_REQUIRED_PATHS)',
            '"required_path_count": len(required_paths)',
        ):
            self.assertIn(fragment, self.archive_helper)

    def test_restore_and_restored_checkout_surfaces_cover_newer_paths(self) -> None:
        for fragment in (
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
            "scripts/check_issue3_workspace_context.py",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/check_issue3_staged_zig_toolchain_candidates.py",
            "scripts/check_issue3_build_readiness_rerun.py",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
            "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
            "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh",
            "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh",
            "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
        ):
            self.assertIn(fragment, self.restored_helper)
            self.assertIn(fragment, self.restore_script)


if __name__ == "__main__":
    unittest.main()
