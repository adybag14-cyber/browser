from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    # Issue #3 Progress Tracker Route

    Use issue `#11` instead for the lower-volume Linux or WSL re-entry lane.

    - `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`
    - `scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
    - `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
    - `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
    - `scripts/check_issue3_staged_zig_toolchain_candidates.py`
    - `scripts/check_issue3_build_readiness_rerun.py`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/check_linux_build_readiness.py`
    - `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - Goal:
    - Achieved:
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
    - `scripts/linux/show_issue3_progress_tracker_route.sh`

    That route keeps the issue `#11` start and completion update format visible.
    """,
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh": """
    declare -a REFERENCE_PATHS=(
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|route note"
        "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|file|saved Rust bridge note"
        "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh|file|saved Rust bridge surface"
        "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|file|saved Rust bridge route"
        "scripts/check_issue3_saved_rust_archive_candidates.py|file|saved Rust archive candidates"
        "scripts/check_issue3_staged_rust_toolchain_candidates.py|file|staged Rust toolchain candidates"
        "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh|file|saved Zig route surface"
        "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|file|saved Zig route"
        "scripts/check_issue3_staged_zig_toolchain_candidates.py|file|staged Zig toolchain candidates"
        "scripts/check_issue3_build_readiness_rerun.py|file|build-readiness rerun helper"
        "scripts/linux/check_issue3_zig_toolchain_match.sh|file|matching-line gate"
        "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh|file|archive-restore surface"
    )

    declare -a CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|issue \\`#11\\`|tracker issue stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_saved_rust_build_readiness_route_surface.sh|saved Rust bridge surface stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_rust_build_readiness_route.sh|saved Rust bridge route stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_saved_rust_archive_candidates.py|saved Rust archive discovery stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_staged_rust_toolchain_candidates.py|staged Rust candidate helper stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_saved_zig_archive_candidates_route_surface.sh|saved Zig route surface stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_zig_archive_candidates_route.sh|saved Zig route stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_staged_zig_toolchain_candidates.py|staged Zig candidate helper stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_build_readiness_rerun.py|build-readiness rerun helper stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_zig_toolchain_match.sh|matching-line gate stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_zig_toolchain_archive_restore_route_surface.sh|archive-restore surface stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|fallback archive override stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|Goal:|start template stays visible"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|Achieved:|completion template stays visible"
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|build-readiness route keeps tracker note visible"
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|issue \\`#11\\`|build-readiness route keeps tracker issue visible"
        "scripts/linux/show_issue3_progress_tracker_route.sh|saved_rust_build_readiness_route_surface|JSON exposes saved Rust bridge surface"
        "scripts/linux/show_issue3_progress_tracker_route.sh|saved_rust_build_readiness_route|JSON exposes saved Rust bridge route"
        "scripts/linux/show_issue3_progress_tracker_route.sh|saved_rust_archive_candidates|JSON exposes saved Rust archive discovery"
        "scripts/linux/show_issue3_progress_tracker_route.sh|staged_rust_toolchain_candidates|JSON exposes staged Rust candidates"
        "scripts/linux/show_issue3_progress_tracker_route.sh|saved_zig_archive_route_surface|JSON exposes saved Zig route surface"
        "scripts/linux/show_issue3_progress_tracker_route.sh|saved_zig_archive_candidates_route|JSON exposes saved Zig route"
        "scripts/linux/show_issue3_progress_tracker_route.sh|staged_zig_toolchain_candidates|JSON exposes staged Zig candidates"
        "scripts/linux/show_issue3_progress_tracker_route.sh|build_readiness_rerun_helper|JSON exposes build-readiness rerun helper"
        "scripts/linux/show_issue3_progress_tracker_route.sh|zig_toolchain_matching_line_gate|JSON exposes matching-line gate"
        "scripts/linux/show_issue3_progress_tracker_route.sh|zig_archive_restore_surface|JSON exposes archive-restore surface"
        "scripts/linux/show_issue3_progress_tracker_route.sh|fallback_zig_archive|JSON exposes fallback archive path"
        "scripts/linux/show_issue3_progress_tracker_route.sh|issue_url|JSON exposes issue URL"
        "scripts/linux/show_issue3_progress_tracker_route.sh|start_comment_template|JSON exposes start template"
        "scripts/linux/show_issue3_progress_tracker_route.sh|completion_comment_template|JSON exposes completion template"
    )
    """,
    "scripts/linux/show_issue3_progress_tracker_route.sh": """
    ISSUE_NUMBER=11
    ISSUE_URL="https://github.com/adybag14-cyber/browser/issues/11"
    SAVED_RUST_BRIDGE_ROUTE_SURFACE_COMMAND="bash ./scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh"
    SAVED_RUST_BRIDGE_ROUTE_COMMAND="bash ./scripts/linux/show_issue3_saved_rust_build_readiness_route.sh"
    SAVED_RUST_ARCHIVE_CANDIDATES_COMMAND="python3 ./scripts/check_issue3_saved_rust_archive_candidates.py"
    STAGED_RUST_TOOLCHAIN_CANDIDATES_COMMAND="python3 ./scripts/check_issue3_staged_rust_toolchain_candidates.py"
    SAVED_ZIG_ARCHIVE_ROUTE_SURFACE_COMMAND="bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh"
    SAVED_ZIG_ARCHIVE_ROUTE_COMMAND="bash ./scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh"
    STAGED_ZIG_CANDIDATES_COMMAND="python3 ./scripts/check_issue3_staged_zig_toolchain_candidates.py"
    BUILD_READINESS_RERUN_COMMAND="python3 ./scripts/check_issue3_build_readiness_rerun.py"
    MATCHING_LINE_GATE_COMMAND="bash ./scripts/linux/check_issue3_zig_toolchain_match.sh"
    ARCHIVE_RESTORE_SURFACE_COMMAND="bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    FALLBACK_ZIG_ARCHIVE="/tmp/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    "saved_rust_build_readiness_route_surface"
    "saved_rust_build_readiness_route"
    "saved_rust_archive_candidates"
    "staged_rust_toolchain_candidates"
    "saved_zig_archive_route_surface"
    "saved_zig_archive_candidates_route"
    "staged_zig_toolchain_candidates"
    "build_readiness_rerun_helper"
    "zig_toolchain_matching_line_gate"
    "zig_archive_restore_surface"
    "fallback_zig_archive"
    "issue_url"
    "start_comment_template"
    "completion_comment_template"
    Goal:
    Achieved:
    Saved Rust build-readiness bridge route:
    Build-readiness rerun helper:
    --fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue11-progress-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11ProgressTrackerRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.progress_note = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root / "scripts/linux/check_issue3_progress_tracker_route_surface.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_progress_tracker_route.sh"
        )

    def test_progress_note_keeps_issue11_saved_rust_saved_zig_and_templates_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
            "check_issue3_saved_rust_build_readiness_route_surface.sh",
            "show_issue3_saved_rust_build_readiness_route.sh",
            "check_issue3_saved_rust_archive_candidates.py",
            "check_issue3_staged_rust_toolchain_candidates.py",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "show_issue3_saved_zig_archive_candidates_route.sh",
            "check_issue3_staged_zig_toolchain_candidates.py",
            "check_issue3_build_readiness_rerun.py",
            "check_issue3_zig_toolchain_match.sh",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "check_linux_build_readiness.py",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "Goal:",
            "Achieved:",
        ):
            self.assertIn(fragment, self.progress_note)

    def test_surface_checker_keeps_saved_rust_saved_zig_and_rerun_contract_in_scope(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
            "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "scripts/check_issue3_staged_zig_toolchain_candidates.py",
            "scripts/check_issue3_build_readiness_rerun.py",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "issue \\`#11\\`",
            "Goal:",
            "Achieved:",
            "saved_rust_build_readiness_route_surface",
            "saved_rust_build_readiness_route",
            "saved_rust_archive_candidates",
            "staged_rust_toolchain_candidates",
            "saved_zig_archive_route_surface",
            "saved_zig_archive_candidates_route",
            "staged_zig_toolchain_candidates",
            "build_readiness_rerun_helper",
            "zig_toolchain_matching_line_gate",
            "zig_archive_restore_surface",
            "fallback_zig_archive",
            "issue_url",
            "start_comment_template",
            "completion_comment_template",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_helper_keeps_issue11_bridge_and_json_keys_visible(self) -> None:
        for fragment in (
            'ISSUE_NUMBER=11',
            'ISSUE_URL="https://github.com/adybag14-cyber/browser/issues/11"',
            "SAVED_RUST_BRIDGE_ROUTE_SURFACE_COMMAND",
            "SAVED_RUST_BRIDGE_ROUTE_COMMAND",
            "SAVED_RUST_ARCHIVE_CANDIDATES_COMMAND",
            "STAGED_RUST_TOOLCHAIN_CANDIDATES_COMMAND",
            "SAVED_ZIG_ARCHIVE_ROUTE_SURFACE_COMMAND",
            "SAVED_ZIG_ARCHIVE_ROUTE_COMMAND",
            "STAGED_ZIG_CANDIDATES_COMMAND",
            "BUILD_READINESS_RERUN_COMMAND",
            "MATCHING_LINE_GATE_COMMAND",
            "ARCHIVE_RESTORE_SURFACE_COMMAND",
            '"saved_rust_build_readiness_route_surface"',
            '"saved_rust_build_readiness_route"',
            '"saved_rust_archive_candidates"',
            '"staged_rust_toolchain_candidates"',
            '"saved_zig_archive_route_surface"',
            '"saved_zig_archive_candidates_route"',
            '"staged_zig_toolchain_candidates"',
            '"build_readiness_rerun_helper"',
            '"zig_toolchain_matching_line_gate"',
            '"zig_archive_restore_surface"',
            '"fallback_zig_archive"',
            '"issue_url"',
            '"start_comment_template"',
            '"completion_comment_template"',
            "Saved Rust build-readiness bridge route:",
            "Build-readiness rerun helper:",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "Goal:",
            "Achieved:",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_build_readiness_note_keeps_progress_tracker_route_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "check_issue3_progress_tracker_route_surface.sh",
            "show_issue3_progress_tracker_route.sh",
            "issue `#11`",
        ):
            self.assertIn(fragment, self.build_readiness_note)


if __name__ == "__main__":
    unittest.main()
