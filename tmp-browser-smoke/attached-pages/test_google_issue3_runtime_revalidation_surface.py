from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

Read this together with:

- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`

### Gate 1: Writable publication path

- a writable checkout of `fork/headed-mode-foundation` is available
- the current publication path can safely materialize the exact live file bodies

### Gate 2: Branch-compatible validation toolchain

Use a branch-compatible Zig toolchain and normal project invocation before
trusting any result from:

```powershell
zig test src/browser/Page.zig
zig test src/display/win32_backend.zig -target x86_64-windows-gnu
```

```bash
python scripts/check_issue3_saved_memory_inputs.py --repo-root .
bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
```

## Practical Re-entry Order

1. Reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
2. Print the helper surface
3. Confirm a writable publication path exists
4. Re-check the branch-side runtime contract markers
5. Stage the expected sibling-path dependencies
6. If the run is using saved dependency bundles, stage them
7. Run the saved-input preflight before the Linux or WSL build-readiness helpers
8. Start with the direct runtime Linux or WSL surface check
9. Re-check Linux or WSL build readiness
10. rerun the readiness helper without the Zig skip
11. reopen the direct code patch

## Validation Ladder After The Gates Open

powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order

## If A Gate Is Still Closed

- stay on a smaller create-only docs, diagnostics, or validation slice
- keep using the saved-memory preflight, the direct runtime Linux or WSL surface check, and the compact re-entry route before widening back out
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
# Issue #3 Enter-Submit Runtime Revalidation

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
- `src/browser/tests/page/google_home_title_probe.html`

## Target `Page.zig` slice

- `_defer_native_text_input_enter_submit: bool`
- `_pending_native_enter_submit: ?*Element.Html.Input`
- `beginDeferredNativeTextInputEnterSubmit()`
- `endDeferredNativeTextInputEnterSubmit()`
- `applyDeferredNativeTextInputEnterSubmit()`

## Target `win32_backend.zig` slice

- replace the scalar `pending_text_input_suppressions` counter
- queue printable-key suppression by exact text bytes

## Focused regression coverage

- reduced Google fixture defers native Enter submit until keypress
- later real text still lands when stale suppression bytes do not match

google_home_title_probe.html?google-home-probe=1
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`

```bash
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
```

1. A fail-fast surface check using
   `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
2. A saved-archive preflight using `scripts/check_linux_build_readiness.py`
3. A `prepare_offline_build_inputs.sh --check-only` command
4. A saved Rust `1.79.0` restore command

- Prefer a Zig `0.15.2` toolchain
""",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r"""
$runtimeContractCheckerPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke\google-investigation-next\check_issue3_enter_submit_runtime_contract.py"
$linuxBuildReadinessScriptPath = Join-Path $resolvedRepoRoot "scripts\check_linux_build_readiness.py"
$focusedPageTestsCommand = "zig test src/browser/Page.zig"
$focusedWin32TestsCommand = "zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
$route = [ordered]@{
    read_first = @(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    )
    target_files = @(
        "src/browser/Page.zig",
        "src/display/win32_backend.zig"
    )
    commands = [ordered]@{
        surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        contract_check = $runtimeContractCheckCommand
        contract_self_test = $runtimeContractSelfTestCommand
        linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
        linux_build_readiness = $linuxBuildReadinessFullCommand
        focused_page_tests = $focusedPageTestsCommand
        focused_win32_tests = $focusedWin32TestsCommand
        shared_enter_default = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1"
        shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("DeferredEnter")
        shared_enter_google = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder")
        shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder", "ClickFocus")
        reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"
        reduced_google_fixture = "& ``\"$resolvedBrowserExe``\" browse --headed --window_width 1366 --window_height 900 ``\"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1``\""
        live_google = "& ``\"$resolvedBrowserExe``\" browse --headed --window_width 1366 --window_height 900 ``\"https://www.google.com/``\""
    }
    expected_signals = @(
        "Printable keydown and keypress leave text in the focused Google query input.",
        "Enter keydown alone does not force an early submit transition.",
        "Enter submit happens only after the later keypress-time DOM phase.",
        "Stale queued suppression entries do not drop real later text_input bytes."
    )
    notes = @(
        "Use linux_build_readiness_skip_zig when the re-entry depends on Linux or WSL dependency staging and you need to confirm the saved inputs before trusting focused Zig output.",
        "Use focused_page_tests and focused_win32_tests only when the current checkout already has a branch-compatible Zig toolchain; the attached Zig 0.17 dev fallback can fail in untouched branch files before these focused assertions run.",
        "Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig and you want trace-ready output on the reduced fixture first."
    )
}
""",
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": r"""
$references = @(
    (New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Kind "file" -Purpose "Branch-local gate note"),
    (New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file" -Purpose "Branch-local runtime-first note"),
    (New-ValidationReference -Path "scripts/check_linux_build_readiness.py" -Kind "file" -Purpose "Branch-compatible build-readiness helper"),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Kind "file" -Purpose "Helper that prints the gated Windows-first route."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py" -Kind "file" -Purpose "Source-based checker")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/check_issue3_saved_memory_inputs.py" -Purpose "The gate note keeps the saved-memory preflight visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh" -Purpose "The gate note keeps the direct runtime Linux or WSL surface check visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh" -Purpose "The gate note keeps the compact direct runtime route visible."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "The production guide keeps the fail-fast runtime surface checker visible."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "The roadmap quick routes keep the compact runtime revalidation helper visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand' -Purpose "The helper prints the light preflight command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"' -Purpose "The helper exposes the fail-fast surface checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Stale queued suppression entries do not drop real later text_input bytes." -Purpose "The helper keeps the stale-suppression success signal visible.")
)
""",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": """
REFERENCE_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note"
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux or WSL build-readiness note"
    "scripts/check_linux_build_readiness.py|file|Python helper"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux route printer"
    "scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper"
    "build.zig.zon|file|Manifest surface"
)

CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|The gate note keeps the Linux build-readiness note visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_linux_build_readiness_route_surface.sh|The Linux build-readiness note keeps its own fail-fast surface checker visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_linux_build_readiness.py|The Linux build-readiness note keeps the readiness helper named explicitly."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_linux_build_readiness_route_surface.sh|The Linux route printer points back to the fail-fast surface checker."
    "scripts/check_linux_build_readiness.py|saved Rust toolchain archive|The readiness helper still knows the saved Rust archive contract."
    "scripts/linux/prepare_offline_build_inputs.sh|--check-only|The offline prep helper still supports surface-only validation without mutation."
)
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root ${REPO_ROOT}"
PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check --expect-saved-archives"
PREPARE_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh --browser-root ${REPO_ROOT} --check-only"
RUST_RESTORE_COMMAND="mkdir -p ${RUST_TOOLCHAIN_DIR} && tar -xf ${RUST_ARCHIVE} -C ${RUST_TOOLCHAIN_DIR} --strip-components=1"
RUST_PATH_COMMAND="export PATH=${RUST_TOOLCHAIN_DIR}/cargo/bin:$PATH"
FULL_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --expect-saved-archives --expect-offline-deps --require-prebuilt-v8"

notes=(
  "Run the surface_check command first so missing branch-local docs or helper paths fail fast before offline staging starts."
  "Use the saved-archive preflight before treating Linux or WSL Zig output as issue #3 evidence."
  "Keep the saved Rust 1.79.0 toolchain on PATH before retrying cargo-backed build steps."
  "Prefer a Zig 0.15.2 toolchain for honest branch validation; the fallback Zig 0.17 dev line is known to fail in untouched branch files."
)
""",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": """
PAGE_REQUIRED_MARKERS = (
    "_defer_native_text_input_enter_submit: bool = false",
    "_pending_native_enter_submit: ?*Element.Html.Input = null",
    "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
)

WIN32_REQUIRED_MARKERS = (
    "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
    "queuePendingTextInputSuppression(self, key);",
    "try page.applyDeferredNativeTextInputEnterSubmit();",
    "fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void {",
    "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
)

PAGE_TEST_MARKERS = (
    'test "Page reduced Google fixture defers native Enter submit until keypress" {',
)

WIN32_TEST_MARKERS = (
    'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
    'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
)

def run_self_test() -> int:
    print("SELF_TEST=pass")
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-runtime-reentry-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3RuntimeRevalidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.runtime_note = read_text(
            cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )
        cls.linux_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.windows_helper = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        cls.windows_surface = read_text(
            cls.repo_root
            / "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )
        cls.linux_surface = read_text(
            cls.repo_root / "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
        )
        cls.linux_route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.runtime_contract = read_text(
            cls.repo_root
            / "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
        )

    def test_runtime_gates_keep_read_first_docs_and_direct_runtime_bridge(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "check_issue3_enter_submit_runtime_contract.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
            "Gate 1: Writable publication path",
            "Gate 2: Branch-compatible validation toolchain",
            "Validation Ladder After The Gates Open",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_runtime_gates_keep_reentry_order_and_saved_input_preflight(self) -> None:
        for fragment in (
            "Confirm a writable publication path exists",
            "Re-check the branch-side runtime contract markers",
            "Run the saved-input preflight before the Linux or WSL build-readiness helpers",
            "Start with the direct runtime Linux or WSL surface check",
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
            "bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check",
            "show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order",
            "show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order",
            "stay on a smaller create-only docs, diagnostics, or validation slice",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_runtime_revalidation_note_keeps_target_slices_and_focused_coverage(self) -> None:
        for fragment in (
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "_defer_native_text_input_enter_submit: bool",
            "_pending_native_enter_submit: ?*Element.Html.Input",
            "beginDeferredNativeTextInputEnterSubmit()",
            "applyDeferredNativeTextInputEnterSubmit()",
            "queue printable-key suppression by exact text bytes",
            "reduced Google fixture defers native Enter submit until keypress",
            "later real text still lands when stale suppression bytes do not match",
            "google_home_title_probe.html?google-home-probe=1",
        ):
            self.assertIn(fragment, self.runtime_note)

    def test_windows_helper_keeps_runtime_contract_linux_readiness_and_replay_commands(self) -> None:
        for fragment in (
            "check_issue3_enter_submit_runtime_contract.py",
            'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            "contract_check = $runtimeContractCheckCommand",
            "contract_self_test = $runtimeContractSelfTestCommand",
            "linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand",
            "linux_build_readiness = $linuxBuildReadinessFullCommand",
            "shared_enter_default",
            "shared_enter_deferred",
            "shared_enter_google",
            "shared_enter_google_click",
            "reduced_google_probe",
            "reduced_google_fixture",
            "live_google",
            "Stale queued suppression entries do not drop real later text_input bytes.",
            "Use linux_build_readiness_skip_zig",
            "the attached Zig 0.17 dev fallback can fail in untouched branch files",
            "Use reduced_google_probe before live Google",
        ):
            self.assertIn(fragment, self.windows_helper)

    def test_windows_surface_checker_keeps_saved_input_and_direct_runtime_contracts(self) -> None:
        for fragment in (
            'New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            'New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"',
            'New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"',
            'New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/check_issue3_saved_memory_inputs.py"',
            'New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"',
            'New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet \'linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand\'',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Stale queued suppression entries do not drop real later text_input bytes."',
        ):
            self.assertIn(fragment, self.windows_surface)

    def test_linux_route_surfaces_keep_readiness_and_offline_restore_contracts(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/check_linux_build_readiness.py",
            "prepare_offline_build_inputs.sh --check-only",
            "saved Rust `1.79.0` restore command",
            "Prefer a Zig `0.15.2` toolchain",
            'SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh',
            'PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py',
            'PREPARE_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh',
            'RUST_RESTORE_COMMAND="mkdir -p ${RUST_TOOLCHAIN_DIR}',
            'FULL_READINESS_COMMAND="python scripts/check_linux_build_readiness.py',
            "Run the surface_check command first",
            "Use the saved-archive preflight before treating Linux or WSL Zig output as issue #3 evidence.",
        ):
            self.assertTrue(
                fragment in self.linux_route_note or fragment in self.linux_route_helper
            )

    def test_linux_surface_checker_keeps_route_and_archive_expectations(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux or WSL build-readiness note"',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux route printer"',
            '"build.zig.zon|file|Manifest surface"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|The gate note keeps the Linux build-readiness note visible."',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_linux_build_readiness_route_surface.sh|The Linux route printer points back to the fail-fast surface checker."',
            '"scripts/check_linux_build_readiness.py|saved Rust toolchain archive|The readiness helper still knows the saved Rust archive contract."',
            '"scripts/linux/prepare_offline_build_inputs.sh|--check-only|The offline prep helper still supports surface-only validation without mutation."',
        ):
            self.assertIn(fragment, self.linux_surface)

    def test_runtime_contract_checker_keeps_markers_and_self_test_surface(self) -> None:
        for fragment in (
            "_defer_native_text_input_enter_submit: bool = false",
            "_pending_native_enter_submit: ?*Element.Html.Input = null",
            "beginDeferredNativeTextInputEnterSubmit",
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            "queuePendingTextInputSuppression(self, key);",
            "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
            'test "Page reduced Google fixture defers native Enter submit until keypress" {',
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
            "def run_self_test() -> int:",
            'print("SELF_TEST=pass")',
        ):
            self.assertIn(fragment, self.runtime_contract)


if __name__ == "__main__":
    unittest.main()
