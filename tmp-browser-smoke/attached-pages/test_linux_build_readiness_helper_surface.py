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
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `scripts/check_issue3_workspace_context.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_restored_helper_surface_sync.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- saved Rust `1.79.0` restore command
- `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`

```bash
bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh
python ./scripts/check_issue3_restored_helper_surface_sync.py \
  --helper-root . \
  --restored-root ../browser-memory-snapshot
bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh
bash ./scripts/linux/show_issue3_progress_tracker_route.sh
python scripts/check_issue3_saved_archive_integrity.py --repo-root .
bash ./scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh
bash ./scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh
```
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": r"""
docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md
docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md
docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md
docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md
docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
WORKSPACE_CONTEXT_COMMAND="python scripts/check_issue3_workspace_context.py --repo-root ${REPO_ROOT}"
RESTORED_CHECKOUT_ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh --repo-root ${REPO_ROOT}"
RESTORED_CHECKOUT_ROUTE_COMMAND="bash scripts/linux/show_issue3_restored_checkout_reentry_route.sh --repo-root ${REPO_ROOT}"
RESTORED_HELPER_SYNC_ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh --repo-root ${REPO_ROOT}"
RESTORED_HELPER_SYNC_ROUTE_COMMAND="bash scripts/linux/show_issue3_restored_helper_surface_sync_route.sh --helper-root ${REPO_ROOT} --restored-root ${RESTORED_CHECKOUT_ROOT} --memory-root ${MEMORY_ROOT}"
SAVED_MEMORY_ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh --repo-root ${REPO_ROOT}"
SAVED_MEMORY_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_memory_inputs_route.sh --repo-root ${REPO_ROOT}"
PROGRESS_TRACKER_ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_progress_tracker_route_surface.sh --repo-root ${REPO_ROOT}"
PROGRESS_TRACKER_ROUTE_COMMAND="bash scripts/linux/show_issue3_progress_tracker_route.sh --repo-root ${REPO_ROOT}"
SAVED_RUST_ARCHIVE_ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh --repo-root ${REPO_ROOT}"
SAVED_RUST_ARCHIVE_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh --repo-root ${REPO_ROOT}"
STAGED_RUST_ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh --repo-root ${REPO_ROOT}"
STAGED_RUST_ROUTE_COMMAND="bash scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh --repo-root ${REPO_ROOT}"
SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python scripts/check_issue3_saved_archive_integrity.py --repo-root ${REPO_ROOT}"
PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check --skip-rust-check --expect-saved-archives"
FULL_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --expect-offline-deps --require-prebuilt-v8"
Restored-checkout route surface check:
Restored-checkout re-entry route:
Restored helper-surface sync route surface check:
Restored helper-surface sync route:
Saved Memory route surface check:
Saved Memory route:
Progress-tracker route surface check:
Progress-tracker route:
Saved Rust archive route surface check:
Saved Rust archive route:
Staged Rust route surface check:
Staged Rust route:
Saved archive integrity preflight:
Fallback Zig archive:
issue #11 should stay visible as the current status lane
""",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": r"""
"docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|file|Read-first restored helper-surface sync note that should stay visible before wider saved-memory follow-up helpers."
"scripts/check_issue3_restored_helper_surface_sync.py|file|Restored helper-surface sync helper used before wider saved-memory, build-readiness, or runtime follow-up helpers."
"scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh|file|Fail-fast restored helper-surface sync checker used before wider saved-memory follow-up helpers are trusted."
"scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|file|Compact restored helper-surface sync route printer for refreshing helper drift before wider follow-up helpers."
"scripts/linux/check_issue3_progress_tracker_route_surface.sh|file|Fail-fast issue #11 progress-tracker checker used before the Linux or WSL lane trusts that lower-volume status route."
"scripts/linux/show_issue3_progress_tracker_route.sh|file|Compact issue #11 progress-tracker route printer that keeps the lower-volume status lane visible."
"scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh|file|Fail-fast saved Rust archive-candidate route checker used before the route rebuilds the saved Rust restore path by hand."
"scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh|file|Compact saved Rust archive-candidate route printer for surfacing the preferred saved Rust restore path."
"scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh|file|Fail-fast staged Rust candidate route checker used before the route blames host Rust or replays the restore path."
"scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh|file|Compact staged Rust candidate route printer for surfacing reusable Rust toolchains under ../toolchains."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|The Linux build-readiness note keeps the restored helper-surface sync route visible before the raw saved-memory preflight."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_restored_helper_surface_sync.py|The Linux build-readiness note keeps the restored helper-surface sync helper named explicitly before wider follow-up helpers."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh|The Linux build-readiness note keeps the exact restored helper-surface sync surface-check command visible."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|The Linux build-readiness note keeps the exact restored helper-surface sync route command visible."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|The Linux build-readiness note keeps the issue #11 handoff note visible before broader build-readiness or Zig follow-up output is treated as the plan."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh|The Linux build-readiness note keeps the exact progress-tracker surface-check command visible."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/show_issue3_progress_tracker_route.sh|The Linux build-readiness note keeps the exact progress-tracker route command visible."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh|The Linux build-readiness note keeps the exact saved Rust archive-candidate surface-check command visible."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh|The Linux build-readiness note keeps the exact saved Rust archive-candidate route command visible."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh|The Linux build-readiness note keeps the exact staged Rust surface-check command visible."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh|The Linux build-readiness note keeps the exact staged Rust route command visible."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|RESTORED_HELPER_SYNC_ROUTE_SURFACE_COMMAND|The Linux route printer keeps a dedicated restored helper-surface sync surface-check command before the raw saved-memory preflight."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|RESTORED_HELPER_SYNC_ROUTE_COMMAND|The Linux route printer keeps a dedicated restored helper-surface sync route command before the raw saved-memory preflight."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|PROGRESS_TRACKER_ROUTE_SURFACE_COMMAND|The Linux route printer keeps a dedicated progress-tracker route surface-check command before the raw saved-memory preflight."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|PROGRESS_TRACKER_ROUTE_COMMAND|The Linux route printer keeps a dedicated progress-tracker route command before the raw saved-memory preflight."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_RUST_ARCHIVE_ROUTE_SURFACE_COMMAND|The Linux route printer keeps a dedicated saved Rust archive surface-check command before the restore path is rebuilt."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_RUST_ARCHIVE_ROUTE_COMMAND|The Linux route printer keeps a dedicated saved Rust archive route command before the restore path is rebuilt."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|STAGED_RUST_ROUTE_SURFACE_COMMAND|The Linux route printer keeps a dedicated staged Rust route surface-check command before host Rust or restore drift is blamed."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|STAGED_RUST_ROUTE_COMMAND|The Linux route printer keeps a dedicated staged Rust route command before host Rust or restore drift is blamed."
"scripts/check_linux_build_readiness.py|saved Rust toolchain archive|The readiness helper still knows the saved Rust archive contract."
"scripts/check_linux_build_readiness.py|saved browser dependency archive|The readiness helper still knows the saved browser dependency archive contract."
""",
    "scripts/check_linux_build_readiness.py": """
SAVED_ARCHIVE_LABELS = {
    "rust_toolchain": "saved Rust toolchain archive",
    "html5ever": "saved html5ever dependency archive",
    "boringssl": "saved BoringSSL archive",
    "browser_deps": "saved browser dependency archive",
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-linux-readiness-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class LinuxBuildReadinessHelperSurfaceTest(unittest.TestCase):
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
        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_runtime_gates_keep_linux_readiness_lane_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_route_note_keeps_restored_helper_sync_and_issue11_handoff_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
            "scripts/check_issue3_restored_helper_surface_sync.py",
            "bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
            "bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "bash ./scripts/linux/show_issue3_progress_tracker_route.sh",
            "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
            "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
            "bash ./scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh",
            "bash ./scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh",
            "bash ./scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
            "bash ./scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh",
            "saved Rust `1.79.0` restore command",
            "`zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_helper_keeps_restored_helper_sync_progress_and_saved_rust_commands(self) -> None:
        for fragment in (
            "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
            'WORKSPACE_CONTEXT_COMMAND="python scripts/check_issue3_workspace_context.py',
            'RESTORED_CHECKOUT_ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh',
            'RESTORED_CHECKOUT_ROUTE_COMMAND="bash scripts/linux/show_issue3_restored_checkout_reentry_route.sh',
            'RESTORED_HELPER_SYNC_ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh',
            'RESTORED_HELPER_SYNC_ROUTE_COMMAND="bash scripts/linux/show_issue3_restored_helper_surface_sync_route.sh',
            'PROGRESS_TRACKER_ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_progress_tracker_route_surface.sh',
            'PROGRESS_TRACKER_ROUTE_COMMAND="bash scripts/linux/show_issue3_progress_tracker_route.sh',
            'SAVED_RUST_ARCHIVE_ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh',
            'SAVED_RUST_ARCHIVE_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh',
            'STAGED_RUST_ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh',
            'STAGED_RUST_ROUTE_COMMAND="bash scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh',
            "Restored helper-surface sync route surface check:",
            "Restored helper-surface sync route:",
            "Progress-tracker route surface check:",
            "Progress-tracker route:",
            "Saved Rust archive route surface check:",
            "Saved Rust archive route:",
            "Staged Rust route surface check:",
            "Staged Rust route:",
            "issue #11 should stay visible as the current status lane",
            "Fallback Zig archive:",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_surface_checker_keeps_restored_helper_sync_progress_and_saved_rust_expectations(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|file|',
            '"scripts/check_issue3_restored_helper_surface_sync.py|file|',
            '"scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh|file|',
            '"scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|file|',
            '"scripts/linux/check_issue3_progress_tracker_route_surface.sh|file|',
            '"scripts/linux/show_issue3_progress_tracker_route.sh|file|',
            '"scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh|file|',
            '"scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh|file|',
            '"scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh|file|',
            '"scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_restored_helper_surface_sync.py|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/show_issue3_progress_tracker_route.sh|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|RESTORED_HELPER_SYNC_ROUTE_SURFACE_COMMAND|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|RESTORED_HELPER_SYNC_ROUTE_COMMAND|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|PROGRESS_TRACKER_ROUTE_SURFACE_COMMAND|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|PROGRESS_TRACKER_ROUTE_COMMAND|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_RUST_ARCHIVE_ROUTE_SURFACE_COMMAND|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_RUST_ARCHIVE_ROUTE_COMMAND|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|STAGED_RUST_ROUTE_SURFACE_COMMAND|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|STAGED_RUST_ROUTE_COMMAND|',
            '"scripts/check_linux_build_readiness.py|saved Rust toolchain archive|',
            '"scripts/check_linux_build_readiness.py|saved browser dependency archive|',
        ):
            self.assertIn(fragment, self.surface_checker)


if __name__ == "__main__":
    unittest.main()
