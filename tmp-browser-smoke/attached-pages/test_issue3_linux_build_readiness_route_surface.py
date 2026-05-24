from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": r"""
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`

```bash
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
```
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": r"""
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_linux_build_readiness.py`

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
python scripts/check_issue3_saved_archive_integrity.py --repo-root .
```

- Prefer the synced saved-browser-snapshot route when the restored checkout
  should become its own follow-up root because the saved archive can lag the
  current branch-local helper surface.
- saved Rust `1.79.0` restore command
- zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
""",
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": r"""
- `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
- Prefer a Zig `0.15.2` or other `0.15.x` toolchain for honest validation on
  this branch.
""",
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md": r"""
- `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/linux/prepare_offline_build_inputs.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `prepare_offline_build_inputs.sh --check-only`
- `check_linux_build_readiness.py`
""",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": r"""
"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should point Linux or WSL reruns at the build-readiness route before focused Zig checks."
"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note that should stay paired with the Linux readiness route."
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot restore note that should stay visible when no reusable checkout exists yet."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux or WSL build-readiness note for the blocked issue #3 runtime lane."
"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Read-first Zig toolchain recovery note for the blocked issue #3 Linux or WSL route."
"docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|Read-first offline build-inputs note for the blocked issue #3 Linux or WSL route."
"scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory input preflight that checks the repo snapshot, notes, dependency archives, and fallback Zig surface before offline staging starts."
"scripts/check_issue3_saved_archive_integrity.py|file|Saved archive integrity helper that proves the saved repo snapshot and dependency bundles still match their expected exact artifacts before offline staging starts."
"scripts/check_linux_build_readiness.py|file|Python helper that checks saved archives, sibling deps, offline deps, and toolchain readiness."
"scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Fail-fast saved-browser-snapshot checker used when no reusable checkout exists yet."
"scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Compact saved-browser-snapshot route printer for restoring a disposable checkout before Linux or WSL staging continues."
"scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that keeps the saved repo snapshot extraction path on one branch-local surface."
"scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Fail-fast Zig toolchain recovery checker used before the route blames the fallback Zig bundle."
"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Compact Zig toolchain recovery route printer for selecting a branch-compatible Zig line."
"scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|Fail-fast saved Rust route checker used before the route reuses the saved Rust archive."
"scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Compact saved Rust route printer for reusing the saved Rust archive."
"scripts/linux/check_issue3_offline_build_inputs_route_surface.sh|file|Fail-fast offline build-inputs checker used before the route stages saved archives into sibling dependencies."
"scripts/linux/show_issue3_offline_build_inputs_route.sh|file|Compact offline build-inputs route printer for staging sibling dependencies from the saved archives."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux route printer for the saved-archive-first recovery path."
"scripts/linux/restore_saved_rust_toolchain.sh|file|Saved Rust restore helper that should keep the check-only and restore commands on one branch-local surface."
"scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper that stages zig-v8-fork, boringssl-zig, and offline-deps."
"build.zig.zon|file|Manifest surface that defines the branch minimum Zig line and sibling path dependencies."

"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|The gate note keeps the Linux build-readiness note in the direct issue #3 read-first surface."
"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_linux_build_readiness_route.sh|The gate note keeps the Linux route printer visible before focused Zig validation."
"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_issue3_saved_memory_inputs.py|The gate note keeps the saved-Memory input preflight visible before offline staging or focused Zig validation."
"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_linux_build_readiness.py|The gate note keeps the Linux readiness helper visible before focused Zig validation."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|The Linux build-readiness note keeps the saved-browser-snapshot restore note visible when no reusable checkout exists yet."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|The Linux build-readiness note keeps the Zig recovery note visible before fallback Zig is blamed."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|The Linux build-readiness note keeps the dedicated offline-inputs route visible before raw archive staging."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_browser_snapshot_route_surface.sh|The Linux build-readiness note keeps the saved-browser-snapshot surface checker visible."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The Linux build-readiness note keeps the saved-browser-snapshot route printer visible."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|restore_saved_browser_snapshot.sh|The Linux build-readiness note keeps the saved-browser-snapshot restore helper visible."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_linux_build_readiness_route_surface.sh|The Linux build-readiness note keeps its own fail-fast surface checker visible."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|The Linux build-readiness note keeps the saved-Memory input preflight named explicitly."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|The Linux build-readiness note keeps the saved-archive integrity helper named explicitly."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|The Linux build-readiness note keeps the exact saved-archive integrity command visible before offline staging starts."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The Linux build-readiness note keeps the Zig recovery route named explicitly."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh|The Linux build-readiness note keeps the saved Rust route surface checker named explicitly."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh|The Linux build-readiness note keeps the saved Rust route named explicitly."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_offline_build_inputs_route.sh|The Linux build-readiness note keeps the offline build-inputs route named explicitly."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|saved Rust 1.79.0 restore command|The Linux build-readiness note keeps the saved Rust restore step visible before trusting Linux or WSL Zig output."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The Linux build-readiness note keeps the attached fallback Zig archive visible as a surfaced input."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|The Linux route printer keeps the saved-browser-snapshot note in its read-first companion list."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|The Linux route printer keeps the saved Rust note in its read-first companion list."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|The Linux route printer keeps the Zig recovery note in its read-first companion list."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|The Linux route printer keeps the offline build-inputs note in its read-first companion list."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_saved_browser_snapshot_route.sh|The Linux route printer keeps a saved-browser-snapshot restore route visible before the broader readiness helper."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The Linux route printer keeps the Zig toolchain recovery helper visible before trusting fallback Zig."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_saved_rust_toolchain_route_surface.sh|The Linux route printer keeps the saved Rust route surface checker visible before the saved Rust route itself."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_saved_rust_toolchain_route.sh|The Linux route printer keeps the saved Rust route printer visible before the broader readiness helper."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_offline_build_inputs_route.sh|The Linux route printer keeps the offline build-inputs helper visible before the raw prepare command."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved-browser-snapshot route when no reusable checkout exists yet:|The Linux route printer still prints the saved-browser-snapshot recovery step before the saved-Memory preflight."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_MEMORY_INPUTS_COMMAND|The Linux route printer keeps a dedicated saved-Memory preflight command before the broader saved-archive preflight."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_ARCHIVE_INTEGRITY_COMMAND|The Linux route printer keeps a dedicated saved-archive integrity command before the broader saved-archive preflight."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|TOOLCHAIN_ROUTE_COMMAND|The Linux route printer keeps a dedicated Zig recovery command before the broader saved-archive preflight."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_RUST_SURFACE_COMMAND|The Linux route printer keeps a dedicated saved Rust surface-check command before the saved Rust route."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|OFFLINE_ROUTE_COMMAND|The Linux route printer keeps a dedicated offline build-inputs command before the broader saved-archive preflight."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_saved_memory_inputs.py|The Linux route printer still points at the saved-Memory input preflight helper."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_saved_archive_integrity.py|The Linux route printer still points at the saved-archive integrity helper."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Memory input preflight:|The Linux route printer still prints the saved-Memory preflight step before the broader readiness helper."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved archive integrity preflight:|The Linux route printer still prints the saved-archive integrity step before the broader readiness helper."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|Zig toolchain recovery route:|The Linux route printer still prints the Zig toolchain recovery step before the broader readiness helper."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Rust route surface check:|The Linux route printer still prints the saved Rust route surface-check step before the saved Rust route."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|Offline build-inputs route:|The Linux route printer still prints the offline build-inputs step before the raw prepare command."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_linux_build_readiness_route_surface.sh|The Linux route printer points back to the fail-fast surface checker."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_linux_build_readiness.py|The Linux route printer still points at the readiness helper."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|restore_saved_rust_toolchain.sh|The Linux route printer still points at the saved Rust restore helper."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|fallback-zig-archive|The Linux route printer still supports an explicit attached fallback Zig archive override."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|Fallback Zig archive:|The Linux route printer still prints the attached fallback Zig archive surface."
"scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|The saved-Memory input preflight still checks for the saved repo snapshot before route replay."
"scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|The saved-Memory input preflight still checks for blocker intelligence before route replay."
"scripts/check_issue3_saved_memory_inputs.py|--fallback-zig-archive|The saved-Memory input preflight still supports an explicit fallback Zig archive override."
"scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|The saved-Memory input preflight still reports a clear pass surface."
"scripts/check_issue3_saved_archive_integrity.py|Saved archive integrity check passed.|The saved-archive integrity helper still reports a clear pass surface."
"scripts/check_linux_build_readiness.py|saved Rust toolchain archive|The readiness helper still knows the saved Rust archive contract."
"scripts/check_linux_build_readiness.py|saved browser dependency archive|The readiness helper still knows the saved browser dependency archive contract."
"scripts/linux/restore_saved_rust_toolchain.sh|--check-only|The saved Rust restore helper still supports surface-only validation without extraction."
"scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:|The saved Rust restore helper still prints the PATH/CARGO/RUSTC handoff surface."
"scripts/linux/prepare_offline_build_inputs.sh|--check-only|The offline prep helper still supports surface-only validation without mutation."
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": r"""
Usage:
  bash scripts/linux/show_issue3_linux_build_readiness_route.sh \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz]

"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
"docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md"
"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
"docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md"
"saved_browser_snapshot_route": "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
"saved_browser_snapshot_route_synced": "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh --sync-helper-surface"
SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python scripts/check_issue3_saved_archive_integrity.py --repo-root ${REPO_ROOT}"
TOOLCHAIN_ROUTE_COMMAND="bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root ${REPO_ROOT}"
SAVED_RUST_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh --repo-root ${REPO_ROOT}"
OFFLINE_ROUTE_COMMAND="bash scripts/linux/show_issue3_offline_build_inputs_route.sh --repo-root ${REPO_ROOT}"
RUST_RESTORE_CHECK_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root ${REPO_ROOT} --dependencies-root ${SAVED_ARCHIVES_ROOT}/dependencies --toolchain-root ${RUST_TOOLCHAIN_DIR} --check-only"
RUST_RESTORE_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root ${REPO_ROOT} --dependencies-root ${SAVED_ARCHIVES_ROOT}/dependencies --toolchain-root ${RUST_TOOLCHAIN_DIR}"
RUST_PATH_COMMAND="export PATH=${RUST_TOOLCHAIN_DIR}/cargo/bin:${RUST_TOOLCHAIN_DIR}/rustc/bin:$PATH"
FULL_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --expect-saved-archives --saved-archives-root ${SAVED_ARCHIVES_ROOT}/dependencies --expect-offline-deps --require-prebuilt-v8 --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"

"Use the saved_browser_snapshot_route command when no reusable checkout exists yet"
"Prefer the saved_browser_snapshot_route_synced command when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface."
"Recommended synced saved-browser-snapshot route when the archive helper surface may be stale:"
"Saved Memory input preflight:"
"Saved archive integrity preflight:"
"Zig toolchain recovery route:"
"Saved Rust route surface check:"
"Offline build-inputs route:"
"Fallback Zig archive:"
"Treat the attached zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz bundle as a surfaced fallback input only"
"Prefer a Zig 0.15.2 toolchain for honest branch validation"
""",
    "scripts/check_linux_build_readiness.py": r"""
SAVED_ARCHIVE_GLOBS: dict[str, str] = {
    "rust_toolchain": "01-rust-*.tar.xz",
    "html5ever": "02-litefetch-html5ever-*.zip",
    "boringssl": "03-boringssl-zig-main.zip",
    "browser_deps": "04-zig-browser-depo.tar.zip",
}
SAVED_ARCHIVE_LABELS: dict[str, str] = {
    "rust_toolchain": "saved Rust toolchain archive",
    "html5ever": "saved html5ever dependency archive",
    "boringssl": "saved BoringSSL archive",
    "browser_deps": "saved browser dependency archive",
}
REQUIRED_SAVED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")
OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)
OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")
PREBUILT_V8_GLOB = "libc_v8_*.a"
--expect-offline-deps
--require-prebuilt-v8
--expect-saved-archives
--saved-archives-root
--skip-zig-check
--fallback-zig-archive
def check_optional_file(path: pathlib.Path, label: str) -> list[str]:
does not match the branch's expected
""",
    "scripts/check_issue3_saved_archive_integrity.py": r"""
EXPECTED_MEMORY_ARCHIVES: tuple[tuple[str, str, str], ...] = (
    (
        "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
        "saved repo snapshot",
        "d1ce047d2f9dd5a9dd7c5a661f3f0caeeac0ff51a19bcdb3c9f3104c081babf0",
    ),
    (
        "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
        "saved Rust toolchain archive",
        "ce552d6bf22a2544ea78647d98cb405d5089af58dbcaa4efea711bf8becd71c5",
    ),
)
DEFAULT_FALLBACK_ZIG_NAME = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_FALLBACK_ZIG_SHA256 = "f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818"
--require-fallback-zig
--json
Saved archive integrity check passed.
Suggested next step:
""",
    "scripts/linux/restore_saved_rust_toolchain.sh": r"""
Usage:
  bash scripts/linux/restore_saved_rust_toolchain.sh \
    --browser-root /path/to/browser-repo \
    --dependencies-root /path/to/memory/repo_archives/browser/dependencies \
    --toolchain-root /path/to/toolchains/rust-1.79.0 \
    [--check-only]

Suggested shell setup:
  export PATH=/toolchains/rust-1.79.0/cargo/bin:/toolchains/rust-1.79.0/rustc/bin:$PATH
""",
    "scripts/linux/prepare_offline_build_inputs.sh": r"""
Usage:
  scripts/linux/prepare_offline_build_inputs.sh \
    --browser-deps-archive /path/to/zig-browser-depo.tar.zip \
    --boringssl-archive /path/to/boringssl-zig-main.zip \
    [--html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip] \
    [--browser-root /path/to/browser-repo] \
    [--check-only]

This helper restores the sibling dependency layout that build.zig.zon expects
for offline Linux validation:
  ../zig-v8-fork
  ../boringssl-zig
  ../offline-deps/{brotli,zlib,nghttp2,curl}

it rewrites ../zig-v8-fork/build.zig.zon to skip the unused depot_tools fetch
Use --check-only to validate the supplied paths and print the derived restore
layout without mutating the repo or extracting any archives.
""",
    "scripts/check_issue3_saved_memory_inputs.py": r"""
REQUIRED_MEMORY_FILES = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
)
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
parser.add_argument("--fallback-zig-archive")
Saved Memory input check passed.
""",
    "build.zig.zon": r"""
.minimum_zig_version = "0.15.2",
.v8 = .{
    .path = "../zig-v8-fork",
},
.@"boringssl-zig" = .{
    .path = "../boringssl-zig",
},
.brotli = .{
    .url = "https://github.com/google/brotli/archive/",
},
.zlib = .{
    .url = "https://github.com/madler/zlib/releases/download/",
},
.nghttp2 = .{
    .url = "https://github.com/nghttp2/nghttp2/releases/download/",
},
.curl = .{
    .url = "https://github.com/curl/curl/releases/download/",
},
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-linux-build-readiness-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3LinuxBuildReadinessRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.gate_note = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.linux_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.zig_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.offline_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root / "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.archive_integrity_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_archive_integrity.py"
        )
        cls.rust_restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_rust_toolchain.sh"
        )
        cls.offline_prepare = read_text(
            cls.repo_root / "scripts/linux/prepare_offline_build_inputs.sh"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_gate_note_keeps_linux_route_in_the_runtime_reentry_surface(self) -> None:
        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
            "bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh",
        ):
            self.assertIn(fragment, self.gate_note)

    def test_linux_route_note_keeps_saved_archive_toolchain_and_followup_routes_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
            "saved Rust `1.79.0` restore command",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        ):
            self.assertIn(fragment, self.linux_route_note)

    def test_surface_checker_still_covers_the_branch_local_linux_route_contract(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot restore note",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Read-first Zig toolchain recovery note",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|Read-first offline build-inputs note",
            "scripts/check_issue3_saved_archive_integrity.py|file|Saved archive integrity helper",
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Fail-fast Zig toolchain recovery checker",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Compact Zig toolchain recovery route printer",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|Fail-fast saved Rust route checker",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Compact saved Rust route printer",
            "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh|file|Fail-fast offline build-inputs checker",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh|file|Compact offline build-inputs route printer",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_ARCHIVE_INTEGRITY_COMMAND",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh|TOOLCHAIN_ROUTE_COMMAND",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_RUST_SURFACE_COMMAND",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh|OFFLINE_ROUTE_COMMAND",
            "scripts/check_issue3_saved_archive_integrity.py|Saved archive integrity check passed.",
            "scripts/linux/restore_saved_rust_toolchain.sh|--check-only",
            "scripts/linux/prepare_offline_build_inputs.sh|--check-only",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_printer_keeps_saved_archive_commands_paths_and_synced_snapshot_handoff(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "saved_browser_snapshot_route",
            "saved_browser_snapshot_route_synced",
            "SAVED_MEMORY_INPUTS_COMMAND",
            "SAVED_ARCHIVE_INTEGRITY_COMMAND",
            "TOOLCHAIN_ROUTE_COMMAND",
            "SAVED_RUST_SURFACE_COMMAND",
            "OFFLINE_ROUTE_COMMAND",
            "RUST_PATH_COMMAND=\"export PATH=${RUST_TOOLCHAIN_DIR}/cargo/bin:${RUST_TOOLCHAIN_DIR}/rustc/bin:$PATH\"",
            "Saved Memory input preflight:",
            "Saved archive integrity preflight:",
            "Zig toolchain recovery route:",
            "Saved Rust route surface check:",
            "Offline build-inputs route:",
            "Use the saved_browser_snapshot_route command when no reusable checkout exists yet",
            "Prefer the saved_browser_snapshot_route_synced command when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface.",
            "Recommended synced saved-browser-snapshot route when the archive helper surface may be stale:",
            "Treat the attached zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz bundle as a surfaced fallback input only",
            "Fallback Zig archive:",
            "Prefer a Zig 0.15.2 toolchain for honest branch validation",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_readiness_helper_keeps_saved_archive_and_offline_dependency_contracts(self) -> None:
        for fragment in (
            '"rust_toolchain": "01-rust-*.tar.xz"',
            '"html5ever": "02-litefetch-html5ever-*.zip"',
            '"boringssl": "03-boringssl-zig-main.zip"',
            '"browser_deps": "04-zig-browser-depo.tar.zip"',
            '"rust_toolchain": "saved Rust toolchain archive"',
            '"browser_deps": "saved browser dependency archive"',
            'REQUIRED_SAVED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")',
            'OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)',
            'OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")',
            'PREBUILT_V8_GLOB = "libc_v8_*.a"',
            "--expect-offline-deps",
            "--require-prebuilt-v8",
            "--expect-saved-archives",
            "--saved-archives-root",
            "--skip-zig-check",
            "--fallback-zig-archive",
            "def check_optional_file(path: pathlib.Path, label: str) -> list[str]:",
            "does not match the branch's expected",
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_archive_integrity_helper_keeps_expected_saved_artifact_contracts(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "saved repo snapshot",
            "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "saved Rust toolchain archive",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--require-fallback-zig",
            "--json",
            "Saved archive integrity check passed.",
            "Suggested next step:",
        ):
            self.assertIn(fragment, self.archive_integrity_helper)

    def test_zig_and_offline_route_notes_keep_followup_helpers_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "Prefer a Zig `0.15.2` or other `0.15.x` toolchain for honest validation",
        ):
            self.assertIn(fragment, self.zig_route_note)

        for fragment in (
            "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "prepare_offline_build_inputs.sh --check-only",
        ):
            self.assertIn(fragment, self.offline_route_note)

    def test_saved_memory_helper_rust_restore_helper_and_build_manifest_keep_the_same_restore_shape(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/blocker_intelligence.yaml",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--fallback-zig-archive",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

        for fragment in (
            "--browser-root /path/to/browser-repo",
            "--dependencies-root /path/to/memory/repo_archives/browser/dependencies",
            "--toolchain-root /path/to/toolchains/rust-1.79.0",
            "--check-only",
            "Suggested shell setup:",
            "/cargo/bin:/toolchains/rust-1.79.0/rustc/bin:$PATH",
        ):
            self.assertIn(fragment, self.rust_restore_helper)

        for fragment in (
            "--browser-deps-archive /path/to/zig-browser-depo.tar.zip",
            "--boringssl-archive /path/to/boringssl-zig-main.zip",
            "[--html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip]",
            "[--check-only]",
            "../zig-v8-fork",
            "../boringssl-zig",
            "../offline-deps/{brotli,zlib,nghttp2,curl}",
            "skip the unused depot_tools fetch",
            "without mutating the repo or extracting any archives.",
        ):
            self.assertIn(fragment, self.offline_prepare)

        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.path = "../zig-v8-fork"',
            '.path = "../boringssl-zig"',
            '.url = "https://github.com/google/brotli/archive/',
            '.url = "https://github.com/madler/zlib/releases/download/',
            '.url = "https://github.com/nghttp2/nghttp2/releases/download/',
            '.url = "https://github.com/curl/curl/releases/download/',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
