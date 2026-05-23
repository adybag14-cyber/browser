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
- `scripts/check_linux_build_readiness.py`

```bash
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
```
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": r"""
1. A fail-fast surface check using
   `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
2. A saved-archive preflight using `scripts/check_linux_build_readiness.py`
3. A `prepare_offline_build_inputs.sh --check-only` command for the offline
   dependency surface
4. A saved Rust `1.79.0` restore command
5. A PATH export that keeps the restored Rust toolchain ahead of any host Rust
6. A full readiness command that expects the saved archives, offline deps, and
   prebuilt V8 archive to be staged before retrying `zig build`

- Do not treat `403` fetch failures for `brotli`, `zlib`, `nghttp2`, or `curl`
  as source regressions before the offline restore route is staged.
- Treat the attached `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle
  as a surfaced fallback input only.
- Prefer a Zig `0.15.2` toolchain for honest branch validation after the saved
  archives and Rust toolchain are staged.
""",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": r"""
"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should point Linux or WSL reruns at the build-readiness route before focused Zig checks."
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux or WSL build-readiness note for the blocked issue #3 runtime lane."
"scripts/check_linux_build_readiness.py|file|Python helper that checks saved archives, sibling deps, offline deps, and toolchain readiness."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux route printer for the saved-archive-first recovery path."
"scripts/linux/restore_saved_rust_toolchain.sh|file|Saved Rust restore helper that should keep the check-only and restore commands on one branch-local surface."
"scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper that stages zig-v8-fork, boringssl-zig, and offline-deps."
"build.zig.zon|file|Manifest surface that defines the branch minimum Zig line and sibling path dependencies."

"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|The gate note keeps the Linux build-readiness note in the direct issue #3 read-first surface."
"scripts/check_linux_build_readiness.py|saved Rust toolchain archive|The readiness helper still knows the saved Rust archive contract."
"scripts/check_linux_build_readiness.py|saved browser dependency archive|The readiness helper still knows the saved browser dependency archive contract."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|fallback-zig-archive|The Linux route printer still supports an explicit attached fallback Zig archive override."
"scripts/linux/show_issue3_linux_build_readiness_route.sh|Fallback Zig archive:|The Linux route printer still prints the attached fallback Zig archive surface."
"scripts/linux/restore_saved_rust_toolchain.sh|--check-only|The saved Rust restore helper still supports surface-only validation without extraction."
"scripts/linux/prepare_offline_build_inputs.sh|--check-only|The offline prep helper still supports surface-only validation without mutation."
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": r"""
Usage:
  bash scripts/linux/show_issue3_linux_build_readiness_route.sh \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz]

FALLBACK_ZIG_ARCHIVE=""
PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check --expect-saved-archives --saved-archives-root ${SAVED_ARCHIVES_ROOT}/dependencies --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"
PREPARE_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh --browser-root ${REPO_ROOT} --browser-deps-archive ${BROWSER_DEPS_ARCHIVE} --boringssl-archive ${BORINGSSL_ARCHIVE} --html5ever-archive ${HTML5EVER_ARCHIVE} --check-only"
RUST_RESTORE_CHECK_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root ${REPO_ROOT} --dependencies-root ${SAVED_ARCHIVES_ROOT}/dependencies --toolchain-root ${RUST_TOOLCHAIN_DIR} --check-only"
RUST_RESTORE_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root ${REPO_ROOT} --dependencies-root ${SAVED_ARCHIVES_ROOT}/dependencies --toolchain-root ${RUST_TOOLCHAIN_DIR}"
RUST_PATH_COMMAND="export PATH=${RUST_TOOLCHAIN_DIR}/cargo/bin:${RUST_TOOLCHAIN_DIR}/rustc/bin:$PATH"
FULL_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --expect-saved-archives --saved-archives-root ${SAVED_ARCHIVES_ROOT}/dependencies --expect-offline-deps --require-prebuilt-v8 --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"

"Run the surface_check command first so missing branch-local docs or helper paths fail fast before offline staging starts."
"Treat the attached zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz bundle as a surfaced fallback input only"
"Prefer a Zig 0.15.2 toolchain for honest branch validation; the fallback Zig 0.17 dev line is known to fail in untouched branch files."
"Fallback Zig archive:"
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
        cls.surface_checker = read_text(
            cls.repo_root / "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.rust_restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_rust_toolchain.sh"
        )
        cls.offline_prepare = read_text(
            cls.repo_root / "scripts/linux/prepare_offline_build_inputs.sh"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_gate_note_keeps_linux_route_in_the_runtime_reentry_surface(self) -> None:
        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_linux_build_readiness.py",
            "bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh",
        ):
            self.assertIn(fragment, self.gate_note)

    def test_linux_route_note_keeps_saved_archive_and_toolchain_rules_visible(self) -> None:
        for fragment in (
            "saved-archive preflight using `scripts/check_linux_build_readiness.py`",
            "`prepare_offline_build_inputs.sh --check-only` command",
            "saved Rust `1.79.0` restore command",
            "prebuilt V8 archive to be staged before retrying `zig build`",
            "Do not treat `403` fetch failures for `brotli`, `zlib`, `nghttp2`, or `curl`",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "Prefer a Zig `0.15.2` toolchain for honest branch validation",
        ):
            self.assertIn(fragment, self.linux_route_note)

    def test_surface_checker_still_covers_the_branch_local_linux_route_contract(self) -> None:
        for fragment in (
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux or WSL build-readiness note",
            "scripts/check_linux_build_readiness.py|file|Python helper",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux route printer",
            "scripts/linux/restore_saved_rust_toolchain.sh|file|Saved Rust restore helper",
            "scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper",
            "build.zig.zon|file|Manifest surface",
            "saved Rust toolchain archive",
            "saved browser dependency archive",
            "fallback-zig-archive",
            "Fallback Zig archive:",
            "scripts/linux/restore_saved_rust_toolchain.sh|--check-only",
            "scripts/linux/prepare_offline_build_inputs.sh|--check-only",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_printer_keeps_saved_archive_commands_and_paths(self) -> None:
        for fragment in (
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "FALLBACK_ZIG_ARCHIVE",
            "scripts/check_linux_build_readiness.py --repo-root",
            "--skip-zig-check --expect-saved-archives",
            "prepare_offline_build_inputs.sh --browser-root",
            "restore_saved_rust_toolchain.sh --browser-root",
            "--check-only",
            "RUST_PATH_COMMAND=\"export PATH=${RUST_TOOLCHAIN_DIR}/cargo/bin:${RUST_TOOLCHAIN_DIR}/rustc/bin:$PATH\"",
            "--expect-offline-deps --require-prebuilt-v8",
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

    def test_rust_restore_helper_and_build_manifest_keep_the_same_restore_shape(self) -> None:
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
