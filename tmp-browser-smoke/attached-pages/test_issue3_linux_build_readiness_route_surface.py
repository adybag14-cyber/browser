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
python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
```
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": r"""
## Run The Surface Check First

```bash
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
```

## Run The Helper

```bash
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
```

1. A fail-fast surface check using
   `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
2. A saved-archive preflight using `scripts/check_linux_build_readiness.py`
3. A `prepare_offline_build_inputs.sh --check-only` command for the offline
   dependency surface
4. A saved Rust `1.79.0` restore command
5. A PATH export that keeps the restored Rust toolchain ahead of any host Rust
6. A full readiness command that expects the saved archives, offline deps, and
   prebuilt V8 archive to be staged before retrying `zig build`

- Prefer a Zig `0.15.2` toolchain for honest branch validation after the saved
  archives and Rust toolchain are staged.
""",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": r"""
declare -a REFERENCE_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should point Linux or WSL reruns at the build-readiness route before focused Zig checks."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note that should stay paired with the Linux readiness route."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux or WSL build-readiness note for the blocked issue #3 runtime lane."
    "scripts/check_linux_build_readiness.py|file|Python helper that checks saved archives, sibling deps, offline deps, and toolchain readiness."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux route printer for the saved-archive-first recovery path."
    "scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper that stages zig-v8-fork, boringssl-zig, and offline-deps."
    "build.zig.zon|file|Manifest surface that defines the branch minimum Zig line and sibling path dependencies."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|The gate note keeps the Linux build-readiness note in the direct issue #3 read-first surface."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_linux_build_readiness_route.sh|The gate note keeps the Linux route printer visible before focused Zig validation."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_linux_build_readiness.py|The gate note keeps the Linux readiness helper visible before focused Zig validation."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_linux_build_readiness_route_surface.sh|The Linux build-readiness note keeps its own fail-fast surface checker visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_linux_build_readiness.py|The Linux build-readiness note keeps the readiness helper named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/linux/show_issue3_linux_build_readiness_route.sh|The Linux build-readiness note keeps the route printer named explicitly."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_linux_build_readiness_route_surface.sh|The Linux route printer points back to the fail-fast surface checker."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_linux_build_readiness.py|The Linux route printer still points at the readiness helper."
    "scripts/check_linux_build_readiness.py|saved Rust toolchain archive|The readiness helper still knows the saved Rust archive contract."
    "scripts/check_linux_build_readiness.py|saved browser dependency archive|The readiness helper still knows the saved browser dependency archive contract."
    "scripts/linux/prepare_offline_build_inputs.sh|--check-only|The offline prep helper still supports surface-only validation without mutation."
)
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": r"""
SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root ${REPO_ROOT}"
PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check --expect-saved-archives --saved-archives-root ${SAVED_ARCHIVES_ROOT}/dependencies"
PREPARE_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh --browser-root ${REPO_ROOT} --browser-deps-archive ${BROWSER_DEPS_ARCHIVE} --boringssl-archive ${BORINGSSL_ARCHIVE} --html5ever-archive ${HTML5EVER_ARCHIVE} --check-only"
RUST_RESTORE_COMMAND="mkdir -p ${RUST_TOOLCHAIN_DIR} && tar -xf ${RUST_ARCHIVE} -C ${RUST_TOOLCHAIN_DIR} --strip-components=1"
RUST_PATH_COMMAND="export PATH=${RUST_TOOLCHAIN_DIR}/cargo/bin:$PATH"
FULL_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --expect-saved-archives --saved-archives-root ${SAVED_ARCHIVES_ROOT}/dependencies --expect-offline-deps --require-prebuilt-v8"

Prefer a Zig 0.15.2 toolchain for honest branch validation; the fallback Zig 0.17 dev line is known to fail in untouched branch files.
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
OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)

def build_prepare_offline_command(repo_root, saved_archives):
    command = [
        str(repo_root / "scripts" / "linux" / "prepare_offline_build_inputs.sh"),
        "--browser-root",
        str(repo_root),
        "--browser-deps-archive",
        str(saved_archives["browser_deps"]),
        "--boringssl-archive",
        str(saved_archives["boringssl"]),
        "--html5ever-archive",
        str(saved_archives["html5ever"]),
        "--check-only",
    ]
    return command

print("Suggested offline staging command:")
print("Suggested next step: stage sibling dependencies plus ../offline-deps with scripts/linux/prepare_offline_build_inputs.sh, use the saved Rust toolchain, and retry `zig build` with a Zig 0.15.2 toolchain.")
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-linux-route-surface-"))
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

        cls.gate_note = read_text(cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
        cls.route_note = read_text(cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")
        cls.surface_check = read_text(
            cls.repo_root / "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_gate_note_keeps_linux_route_in_the_issue3_reentry_surface(self) -> None:
        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_linux_build_readiness.py",
            "bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh",
        ):
            self.assertIn(fragment, self.gate_note)

    def test_route_note_keeps_the_saved_archive_first_sequence_visible(self) -> None:
        for fragment in (
            "A fail-fast surface check using",
            "`scripts/check_linux_build_readiness.py`",
            "prepare_offline_build_inputs.sh --check-only",
            "saved Rust `1.79.0` restore command",
            "PATH export",
            "full readiness command",
            "Prefer a Zig `0.15.2` toolchain",
        ):
            self.assertIn(fragment, self.route_note)

    def test_surface_checker_still_guards_the_expected_docs_and_helpers(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux or WSL build-readiness note',
            '"scripts/check_linux_build_readiness.py|file|Python helper',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux route printer',
            '"scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper',
            '"build.zig.zon|file|Manifest surface',
            'docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_linux_build_readiness.py',
            'docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/linux/show_issue3_linux_build_readiness_route.sh',
            'scripts/check_linux_build_readiness.py|saved Rust toolchain archive',
            'scripts/linux/prepare_offline_build_inputs.sh|--check-only',
        ):
            self.assertIn(fragment, self.surface_check)

    def test_route_printer_keeps_preflight_restore_and_full_readiness_commands(self) -> None:
        for fragment in (
            "SURFACE_CHECK_COMMAND=",
            "PREFLIGHT_COMMAND=",
            "--skip-zig-check --expect-saved-archives",
            "PREPARE_COMMAND=",
            "--check-only",
            "RUST_RESTORE_COMMAND=",
            "RUST_PATH_COMMAND=",
            "FULL_READINESS_COMMAND=",
            "--expect-offline-deps --require-prebuilt-v8",
            "Prefer a Zig 0.15.2 toolchain",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_readiness_helper_keeps_saved_archive_contract_and_prepare_command(self) -> None:
        for fragment in (
            '"rust_toolchain": "01-rust-*.tar.xz"',
            '"html5ever": "02-litefetch-html5ever-*.zip"',
            '"boringssl": "03-boringssl-zig-main.zip"',
            '"browser_deps": "04-zig-browser-depo.tar.zip"',
            '"rust_toolchain": "saved Rust toolchain archive"',
            '"browser_deps": "saved browser dependency archive"',
            'OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)',
            '"--html5ever-archive"',
            '"--check-only"',
            "Suggested offline staging command:",
            "saved Rust toolchain",
            "Zig 0.15.2 toolchain",
        ):
            self.assertIn(fragment, self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
