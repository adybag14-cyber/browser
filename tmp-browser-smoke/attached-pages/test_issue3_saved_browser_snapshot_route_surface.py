from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
# Issue #3 Saved Browser Snapshot Restore Route

- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --check-only
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

- archive: `../memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip`
- destination: `../browser-memory-snapshot`

```bash
python scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

- Prefer a disposable restored checkout for helper validation when the live branch still needs a safer publication path for large existing files.
""",
    "scripts/linux/restore_saved_browser_snapshot.sh": """
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
CHECK_ONLY=false
JSON=false
FORCE_RESTORE=false
TOP_LEVEL_ENTRY="$(python3 - "${ARCHIVE_PATH}" <<'PY'
print("browser-fork-headed-mode-foundation")
PY
)"
FOLLOW_UP_MEMORY_CHECK="python scripts/check_issue3_saved_memory_inputs.py --repo-root '${DESTINATION}'"
FOLLOW_UP_ROUTE="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root '${DESTINATION}'"
if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Saved browser snapshot restore surface check passed."
    echo "Archive top level:  ${TOP_LEVEL_ENTRY}"
    echo "Suggested restore command:"
    echo "Suggested follow-up checks:"
fi
if [[ -e "${DESTINATION}" ]]; then
    if [[ "${FORCE_RESTORE}" == "true" ]]; then
        rm -rf "${DESTINATION}"
    else
        echo "Use --force to replace the existing restored checkout."
        exit 1
    fi
fi
if [[ ! -f "${DESTINATION}/build.zig.zon" ]]; then
    echo "Restored checkout is missing build.zig.zon: ${DESTINATION}/build.zig.zon" >&2
    exit 1
fi
echo "Saved browser snapshot is ready."
""",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": """
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
FALLBACK_ZIG_ARCHIVE=""
SURFACE_CHECK_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh --browser-root ${REPO_ROOT} --memory-root ${MEMORY_ROOT} --archive ${ARCHIVE_PATH} --destination ${DESTINATION} --check-only"
RESTORE_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh --browser-root ${REPO_ROOT} --memory-root ${MEMORY_ROOT} --archive ${ARCHIVE_PATH} --destination ${DESTINATION}"
SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${DESTINATION}"
LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${DESTINATION}"
RUNTIME_ROUTE_COMMAND="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ${DESTINATION}"
SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"
LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"
"issue": "Google issue #3 saved browser snapshot restore route"
"surface_check": "..."
"restore": "..."
"saved_memory_preflight": "..."
"linux_build_route": "..."
"runtime_route": "..."
Read first
==========
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
Working rules
=============
  - Run the surface check first so the saved archive path, top-level folder, and follow-up commands are confirmed before extraction.
  - Run the saved-Memory preflight against the restored checkout before trusting broader build-readiness or runtime helper output.
  - Reopen the direct Page.zig plus win32_backend.zig runtime lane only after the restored checkout exists and the branch-compatible validation gate is no longer the blocker.
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
parser.add_argument("--fallback-zig-archive")
parser.add_argument("--json")
parser.add_argument("--self-test")
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-browser-snapshot-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedBrowserSnapshotRouteSurfaceTest(unittest.TestCase):
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
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )

    def test_route_note_keeps_restore_surface_and_follow_up_routes_visible(self) -> None:
        for fragment in (
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "restore_saved_browser_snapshot.sh --check-only",
            "show_issue3_saved_browser_snapshot_route.sh",
            "../memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "../browser-memory-snapshot",
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot",
            "show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot",
            "show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot",
            "Prefer a disposable restored checkout for helper validation",
        ):
            self.assertIn(fragment, self.route_note)

    def test_restore_helper_keeps_archive_detection_force_guard_and_follow_up_checks(self) -> None:
        for fragment in (
            'DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"',
            'DEFAULT_DESTINATION_NAME="browser-memory-snapshot"',
            "CHECK_ONLY=false",
            "JSON=false",
            "FORCE_RESTORE=false",
            "TOP_LEVEL_ENTRY=",
            "FOLLOW_UP_MEMORY_CHECK=",
            "scripts/check_issue3_saved_memory_inputs.py --repo-root",
            "FOLLOW_UP_ROUTE=",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root",
            "Saved browser snapshot restore surface check passed.",
            "Suggested restore command:",
            "Suggested follow-up checks:",
            'if [[ -e "${DESTINATION}" ]]',
            'if [[ "${FORCE_RESTORE}" == "true" ]]',
            "Use --force to replace the existing restored checkout.",
            'if [[ ! -f "${DESTINATION}/build.zig.zon" ]]',
            "Restored checkout is missing build.zig.zon",
            "Saved browser snapshot is ready.",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_route_helper_keeps_surface_restore_preflight_and_runtime_handoff_commands(self) -> None:
        for fragment in (
            'DEFAULT_DESTINATION_NAME="browser-memory-snapshot"',
            'DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"',
            "FALLBACK_ZIG_ARCHIVE=",
            'SURFACE_CHECK_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh',
            "--check-only",
            'RESTORE_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh',
            'SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root',
            'LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root',
            'RUNTIME_ROUTE_COMMAND="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root',
            '--fallback-zig-archive',
            '"issue": "Google issue #3 saved browser snapshot restore route"',
            '"surface_check":',
            '"restore":',
            '"saved_memory_preflight":',
            '"linux_build_route":',
            '"runtime_route":',
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "Run the surface check first so the saved archive path, top-level folder, and follow-up commands are confirmed before extraction.",
            "Run the saved-Memory preflight against the restored checkout before trusting broader build-readiness or runtime helper output.",
            "Reopen the direct Page.zig plus win32_backend.zig runtime lane only after the restored checkout exists",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_saved_memory_helper_keeps_snapshot_dependency_and_fallback_zig_contract(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/README.md",
            "repo_archives/browser/blocker_intelligence.yaml",
            "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
            "03-boringssl-zig-main.zip",
            "04-zig-browser-depo.tar.zip",
            "repo_archives/browser/session_entry_register.yaml",
            'DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "--fallback-zig-archive",
            "--json",
            "--self-test",
        ):
            self.assertIn(fragment, self.saved_memory_helper)


if __name__ == "__main__":
    unittest.main()
