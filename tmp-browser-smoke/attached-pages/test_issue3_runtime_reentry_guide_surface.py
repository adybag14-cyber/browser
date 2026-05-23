from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """\\
# Issue #3 Runtime Re-entry Gates

Use this note before reopening the direct issue `#3` runtime patch in:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

Read this together with:

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`

## The Two Hard Gates

### Gate 1: Writable publication path

- a writable checkout of `fork/headed-mode-foundation` is available
- the saved-browser-snapshot restore route has already produced a disposable
  checkout
- the current publication path can safely materialize the exact live file bodies
- the current runtime can publish low-level blob/tree/commit updates from the
  real branch head without rebuilding those files by hand

### Gate 2: Branch-compatible validation toolchain

Use a branch-compatible Zig toolchain and normal project invocation before
trusting any result from:

```powershell
zig test src/browser/Page.zig
zig test src/display/win32_backend.zig -target x86_64-windows-gnu
```

## Practical Re-entry Order

1. Reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`.
2. Print the helper surface:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

3. Confirm a writable publication path exists.
4. Re-check the branch-side runtime contract markers before touching the patch.
5. Stage the expected sibling-path dependencies before blaming source changes.
6. If the run is using saved dependency bundles, stage them before invoking Zig.
7. Print the saved-browser-snapshot route before trusting Linux or WSL validation.
8. Run the saved-input preflight before the Linux or WSL build-readiness helpers.
9. Start with the direct runtime Linux or WSL surface and then print the compact re-entry route.
10. Re-check Linux or WSL build readiness before trusting file-level Zig output.
11. Only after a matching Zig line is actually staged, rerun the readiness helper.
12. Only after those gates are green, reopen the direct code patch and the focused regression tests.
13. After the focused tests are green, move back to the reduced Google probe and then the broader Windows replay ladder.

## Validation Ladder After The Gates Open

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order
```

## If A Gate Is Still Closed

- stay on a smaller create-only docs, diagnostics, or validation slice
- do not hand-edit large existing file bodies through a brittle replacement path
- use `show_issue3_saved_browser_snapshot_route.sh` first when the missing piece
  is still the disposable checkout
- keep working in build/dependency readiness, docs, or validation routing
""",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": """\\
$route = [ordered]@{
    issue = "Google issue #3 Enter-submit runtime revalidation"
    read_first = @(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    )
    target_files = @(
        "src/browser/Page.zig",
        "src/display/win32_backend.zig"
    )
    related_files = @(
        "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        "scripts/check_issue3_saved_memory_inputs.py",
        "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
        "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
        "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "src/browser/tests/page/google_home_title_probe.html",
        "scripts/check_linux_build_readiness.py"
    )
    commands = [ordered]@{
        surface_check = "surface"
        saved_browser_snapshot_surface = "saved-snapshot-surface"
        saved_browser_snapshot_route = "saved-snapshot-route"
        contract_check = "contract-check"
        contract_self_test = "contract-self-test"
        saved_memory_preflight = "saved-memory-preflight"
        linux_runtime_surface = "linux-runtime-surface"
        linux_runtime_route = "linux-runtime-route"
        linux_build_readiness_skip_zig = "linux-readiness-skip-zig"
        linux_build_readiness = "linux-readiness"
        build = "zig build -Dtarget=x86_64-windows-msvc --summary all"
        focused_page_tests = "zig test src/browser/Page.zig"
        focused_win32_tests = "zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
        shared_enter_default = "shared-enter-default"
        shared_enter_deferred = "shared-enter-deferred"
        shared_enter_google = "shared-enter-google"
        shared_enter_google_click = "shared-enter-google-click"
        reduced_google_probe = "reduced-google-probe"
        reduced_google_fixture = "reduced-google-fixture"
        live_google = "live-google"
    }
    expected_signals = @(
        "Printable keydown and keypress leave text in the focused Google query input.",
        "Enter keydown alone does not force an early submit transition.",
        "Enter submit happens only after the later keypress-time DOM phase.",
        "Stale queued suppression entries do not drop real later text_input bytes."
    )
    notes = @(
        "Read docs/ISSUE3_RUNTIME_REENTRY_GATES.md before docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md whenever the next run may reopen Page.zig or win32_backend.zig.",
        "Run surface_check first when branch state may have moved and you want the gate note, helper, and probe files checked before replay.",
        "If no reusable checkout exists yet, run saved_browser_snapshot_surface and then saved_browser_snapshot_route before trusting Linux or WSL follow-up helpers against a restored checkout.",
        "Run contract_check before build or replay when you need a thin, source-based yes-or-no answer about whether the direct Page.zig and win32_backend.zig bridge markers are present on the current branch.",
        "Use shared_enter_google_click when reproducing the click-first path that most closely matches the real homepage boundary from issue #3.",
        "Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig and you want trace-ready output on the reduced fixture first."
    )
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-runtime-reentry-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
    return root


class Issue3RuntimeReentryGuideSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.gates_doc = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.helper_script = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )

    def test_runtime_reentry_doc_keeps_gate_sections_and_targets(self) -> None:
        for fragment in (
            "# Issue #3 Runtime Re-entry Gates",
            "- `src/browser/Page.zig`",
            "- `src/display/win32_backend.zig`",
            "### Gate 1: Writable publication path",
            "### Gate 2: Branch-compatible validation toolchain",
            "zig test src/browser/Page.zig",
            "zig test src/display/win32_backend.zig -target x86_64-windows-gnu",
        ):
            self.assertIn(fragment, self.gates_doc)

    def test_runtime_reentry_doc_keeps_branch_local_helper_and_linux_route(self) -> None:
        for fragment in (
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "show_issue3_saved_browser_snapshot_route.sh",
            "check_issue3_saved_memory_inputs.py",
            "check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.gates_doc)

    def test_runtime_reentry_doc_keeps_validation_ladder_and_closed_gate_guidance(self) -> None:
        for fragment in (
            "## Validation Ladder After The Gates Open",
            "chrome-google-home-title-probe.ps1",
            "show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order",
            "show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order",
            "stay on a smaller create-only docs, diagnostics, or validation slice",
            "do not hand-edit large existing file bodies through a brittle replacement path",
        ):
            self.assertIn(fragment, self.gates_doc)

    def test_helper_script_keeps_read_first_targets_and_related_files(self) -> None:
        for fragment in (
            'issue = "Google issue #3 Enter-submit runtime revalidation"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"',
            '"src/browser/Page.zig"',
            '"src/display/win32_backend.zig"',
            '"tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"',
            '"tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"',
        ):
            self.assertIn(fragment, self.helper_script)

    def test_helper_script_keeps_command_surfaces_for_reentry_and_replay(self) -> None:
        for fragment in (
            "surface_check = ",
            "saved_browser_snapshot_surface = ",
            "saved_browser_snapshot_route = ",
            "contract_check = ",
            "contract_self_test = ",
            "saved_memory_preflight = ",
            "linux_runtime_surface = ",
            "linux_runtime_route = ",
            "linux_build_readiness_skip_zig = ",
            "linux_build_readiness = ",
            "focused_page_tests = ",
            "focused_win32_tests = ",
            "shared_enter_google_click = ",
            "reduced_google_probe = ",
            "live_google = ",
        ):
            self.assertIn(fragment, self.helper_script)

    def test_helper_script_keeps_expected_signals_and_reentry_notes(self) -> None:
        for fragment in (
            "Printable keydown and keypress leave text in the focused Google query input.",
            "Enter keydown alone does not force an early submit transition.",
            "Enter submit happens only after the later keypress-time DOM phase.",
            "Stale queued suppression entries do not drop real later text_input bytes.",
            "Read docs/ISSUE3_RUNTIME_REENTRY_GATES.md before docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "Use shared_enter_google_click when reproducing the click-first path",
            "Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig",
        ):
            self.assertIn(fragment, self.helper_script)


if __name__ == "__main__":
    unittest.main()
