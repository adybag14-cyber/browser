from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": r"""
# Issue #3 Runtime Re-entry Gates

Use this note before reopening the direct issue `#3` runtime patch in:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

Read this together with:

- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/WINDOWS_FULL_USE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `scripts/check_linux_build_readiness.py`

## The Two Hard Gates

### Gate 1: Writable publication path

- a writable checkout of `fork/headed-mode-foundation` is available
- the current publication path can safely materialize the exact live file bodies,
  apply a small patch, and republish them without manual full-body drift
- the current runtime can publish low-level blob/tree/commit updates from the
  real branch head without rebuilding those files by hand

### Gate 2: Branch-compatible validation toolchain

```powershell
zig test src/browser/Page.zig
zig test src/display/win32_backend.zig -target x86_64-windows-gnu
```

## Practical Re-entry Order

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

```bash
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py \
  --page src/browser/Page.zig \
  --win32 src/display/win32_backend.zig
```

- `../zig-v8-fork`
- `../boringssl-zig`

```bash
python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
```

## Validation Ladder After The Gates Open

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order
```

## If A Gate Is Still Closed

- stay on a smaller create-only docs, diagnostics, or validation slice
- keep `show_google_issue3_enter_submit_runtime_revalidation.ps1` as the shared
  re-entry surface so the exact runtime route does not need to be rebuilt by hand
""",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r"""
$runtimeContractCheckerPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke\google-investigation-next\check_issue3_enter_submit_runtime_contract.py"
$pageSourcePath = Join-Path $resolvedRepoRoot "src\browser\Page.zig"
$win32SourcePath = Join-Path $resolvedRepoRoot "src\display\win32_backend.zig"
$linuxBuildReadinessScriptPath = Join-Path $resolvedRepoRoot "scripts\check_linux_build_readiness.py"

$route = [ordered]@{
    issue = "Google issue #3 Enter-submit runtime revalidation"
    read_first = @(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    )
    target_files = @(
        "src/browser/Page.zig",
        "src/display/win32_backend.zig"
    )
    related_files = @(
        "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
        "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
        "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "src/browser/tests/page/google_home_title_probe.html",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
        "docs/WINDOWS_FULL_USE.md",
        "scripts/check_linux_build_readiness.py"
    )
    commands = [ordered]@{
        surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        contract_check = $runtimeContractCheckCommand
        contract_self_test = $runtimeContractSelfTestCommand
        linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
        linux_build_readiness = $linuxBuildReadinessFullCommand
        build = "zig build -Dtarget=x86_64-windows-msvc --summary all"
        focused_page_tests = "zig test src/browser/Page.zig"
        focused_win32_tests = "zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
        shared_enter_default = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1"
        shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("DeferredEnter")
        shared_enter_google = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder")
        shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder", "ClickFocus")
        reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"
        reduced_google_fixture = "& ``"$resolvedBrowserExe``" browse --headed --window_width 1366 --window_height 900 ``"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1``""
        live_google = "& ``"$resolvedBrowserExe``" browse --headed --window_width 1366 --window_height 900 ``"https://www.google.com/``""
    }
    notes = @(
        "Run surface_check first when branch state may have moved and you want the gate note, helper, and probe files checked before replay.",
        "Run contract_check before build or replay when you need a thin, source-based yes-or-no answer about whether the direct Page.zig and win32_backend.zig bridge markers are present on the current branch.",
        "Use linux_build_readiness_skip_zig when the re-entry depends on Linux or WSL dependency staging and you need to confirm the saved inputs before trusting focused Zig output.",
        "Use focused_page_tests and focused_win32_tests only when the current checkout already has a branch-compatible Zig toolchain; the attached Zig 0.17 dev fallback can fail in untouched branch files before these focused assertions run.",
        "Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig and you want trace-ready output on the reduced fixture first.",
        "If the focused Zig tests fail in untouched branch files before the new assertions run, fall back to contract_check, the shared Enter-order ladder, and the reduced Google probe so the runtime boundary can still be narrowed honestly.",
        "Only jump to reduced_google_fixture or live_google after the source contract check, shared Enter-order ladder, and reduced Google probe agree on the same event ordering."
    )
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-runtime-reentry-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3RuntimeReentrySurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.reentry_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.runtime_helper = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )

    def test_reentry_gates_keep_the_two_hard_gates_visible(self) -> None:
        for fragment in (
            "## The Two Hard Gates",
            "### Gate 1: Writable publication path",
            "a writable checkout of `fork/headed-mode-foundation` is available",
            "apply a small patch, and republish them without manual full-body drift",
            "### Gate 2: Branch-compatible validation toolchain",
            "zig test src/browser/Page.zig",
            "zig test src/display/win32_backend.zig -target x86_64-windows-gnu",
        ):
            self.assertIn(fragment, self.reentry_gates)

    def test_reentry_gates_keep_runtime_targets_and_companions(self) -> None:
        for fragment in (
            "`src/browser/Page.zig`",
            "`src/display/win32_backend.zig`",
            "`scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`",
            "`tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`",
            "`scripts/check_linux_build_readiness.py`",
            "`docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`",
            "`docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`",
            "`docs/WINDOWS_FULL_USE.md`",
        ):
            self.assertIn(fragment, self.reentry_gates)

    def test_reentry_gates_keep_replay_order_and_validation_ladder(self) -> None:
        for fragment in (
            r"powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test",
            "--page src/browser/Page.zig",
            "--win32 src/display/win32_backend.zig",
            "`../zig-v8-fork`",
            "`../boringssl-zig`",
            "python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check",
            "zig build -Dtarget=x86_64-windows-msvc --summary all",
            r"powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1",
            "show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order",
            "show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order",
        ):
            self.assertIn(fragment, self.reentry_gates)

    def test_reentry_gates_keep_closed_gate_guidance(self) -> None:
        for fragment in (
            "stay on a smaller create-only docs, diagnostics, or validation slice",
            "keep `show_google_issue3_enter_submit_runtime_revalidation.ps1` as the shared",
        ):
            self.assertIn(fragment, self.reentry_gates)

    def test_runtime_helper_keeps_read_first_targets_and_related_files(self) -> None:
        for fragment in (
            'issue = "Google issue #3 Enter-submit runtime revalidation"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"src/browser/Page.zig"',
            '"src/display/win32_backend.zig"',
            '"scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            '"tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"',
            '"tmp-browser-smoke/form-controls/enter-submit-probe.ps1"',
            '"tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"',
            '"scripts/check_linux_build_readiness.py"',
        ):
            self.assertIn(fragment, self.runtime_helper)

    def test_runtime_helper_keeps_command_ladder(self) -> None:
        for fragment in (
            'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            'linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand',
            'linux_build_readiness = $linuxBuildReadinessFullCommand',
            'build = "zig build -Dtarget=x86_64-windows-msvc --summary all"',
            'focused_page_tests = "zig test src/browser/Page.zig"',
            'focused_win32_tests = "zig test src/display/win32_backend.zig -target x86_64-windows-gnu"',
            'shared_enter_default = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"',
            'shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1" -Switches @("DeferredEnter")',
            'shared_enter_google = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder")',
            'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder", "ClickFocus")',
            'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"',
            'reduced_google_fixture = "& ``"$resolvedBrowserExe``" browse --headed --window_width 1366 --window_height 900 ``"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1``""',
            'live_google = "& ``"$resolvedBrowserExe``" browse --headed --window_width 1366 --window_height 900 ``"https://www.google.com/``""',
        ):
            self.assertIn(fragment, self.runtime_helper)

    def test_runtime_helper_keeps_notes_for_reentry_decisions(self) -> None:
        for fragment in (
            "Run surface_check first when branch state may have moved",
            "Run contract_check before build or replay",
            "Use linux_build_readiness_skip_zig when the re-entry depends on Linux or WSL dependency staging",
            "Use focused_page_tests and focused_win32_tests only when the current checkout already has a branch-compatible Zig toolchain",
            "Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig",
            "fall back to contract_check, the shared Enter-order ladder, and the reduced Google probe",
            "Only jump to reduced_google_fixture or live_google after the source contract check",
        ):
            self.assertIn(fragment, self.runtime_helper)

    def test_runtime_helper_and_reentry_gates_agree_on_core_runtime_contract(self) -> None:
        for fragment in (
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "check_issue3_enter_submit_runtime_contract.py",
            "check_linux_build_readiness.py",
            "zig build -Dtarget=x86_64-windows-msvc --summary all",
            "zig test src/browser/Page.zig",
            "zig test src/display/win32_backend.zig -target x86_64-windows-gnu",
        ):
            self.assertIn(fragment, self.reentry_gates)
            self.assertIn(fragment, self.runtime_helper)


if __name__ == "__main__":
    unittest.main()
