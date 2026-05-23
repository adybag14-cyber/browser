import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_function_block(source: str, function_name: str) -> str:
    pattern = re.compile(
        rf"function\s+{re.escape(function_name)}[^\{{]*\{{.*?^\}}",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(source)
    if not match:
        raise AssertionError(f"Could not find function block for {function_name}")
    return match.group(0)


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
$googleFormControlsEnterOrderArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleFormControlsEnterOrderArguments -Name RepoRoot -Value $RepoRoot
if ($isCustomBrowserExe) {
    Add-SharedArgument -Arguments $googleFormControlsEnterOrderArguments -Name BrowserExe -Value $BrowserExe
}

function Get-GoogleFormControlsEnterOrderCommands {
    return @(
        (Format-HelperCommand -ScriptName 'check_google_form_controls_enter_order_validation_surface.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_trace_guide.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'run_google_form_controls_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
    )
}

function Get-GoogleFormControlsEnterOrderNotes {
    $notes = @(
        "Use this when issue #3 is already narrowed to the smallest shared Enter-order checkpoint on the real headed surface.",
        "Run the surface checker first so missing docs, wrappers, or the raw probe fail before you trust the dedicated runner.",
        "Widen back out to the broader shared Enter-order ladder only after this dedicated gate stays green."
    )

    if ($isCustomBrowserExe) {
        $notes += "Current browser override: $BrowserExe"
    }

    return $notes
}

function Get-GoogleSharedEnterOrderCommands {
    return @(
        (Format-HelperCommand -ScriptName 'check_google_shared_enter_order_validation_surface.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'run_google_shared_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_trace_guide.ps1' -Arguments $googleFormControlsEnterOrderArguments)
    )
}

function Get-GoogleSharedEnterOrderNotes {
    $notes = @(
        "Use this when issue #3 is already narrowed to the reusable shared Enter-order ladder between the smaller bounded input probes and the later live Google pass.",
        "Run the shared surface checker first so missing docs, shared wrappers, or reduced localhost probes fail before you trust the wider Enter-order ladder.",
        "Keep the dedicated form-controls flow and trace guide nearby so the last shared keypress-before-submit gate stays easy to reopen without widening all the way back out."
    )

    if ($isCustomBrowserExe) {
        $notes += "Current browser override: $BrowserExe"
    }

    return $notes
}

Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)

switch ($true) {
    { $ChangeArea -eq "google-shared-enter-order" } {
        Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
        Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
            "Use these when the shared Enter-order ladder is already narrowed and you want the last shared form-controls keypress-before-submit gate reopened on its own surface."
        )
        break
    }
}
""",
    "scripts/windows/show_google_shared_enter_order_validation_flow.ps1": r"""
$flow = [ordered]@{
    next_steps = @(
        "Use powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus -InputText 'Q' -Port 8157 -RepoRoot 'C:\src\browser' -BrowserExe 'C:\src\browser\zig-out\bin\lightpanda.exe' -Host '127.0.0.1' when you want the reusable shared page to replay the same click-first Google-shaped path before you hand off to the dedicated form-controls ladder.",
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1 -RepoRoot 'C:\src\browser' -BrowserExe 'C:\src\browser\zig-out\bin\lightpanda.exe' -Host '127.0.0.1' -SharedInputText 'Q' -SharedEnterOrderPort 8157 -ServerReadyTimeoutSeconds 15 -HomeWindowReadyAttempts 60 -HomeTitleWaitAttempts 80 -HomePollMilliseconds 250 when you want only the dedicated shared form-controls gate printed with the same repo-root, browser, host, shared input, and timing context before you run it.",
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1 -RepoRoot 'C:\src\browser' -BrowserExe 'C:\src\browser\zig-out\bin\lightpanda.exe' -Host '127.0.0.1' -SharedInputText 'Q' -SharedEnterOrderPort 8157 -ServerReadyTimeoutSeconds 15 -HomeWindowReadyAttempts 60 -HomeTitleWaitAttempts 80 -HomePollMilliseconds 250 when you want the dedicated gate markers translated into click-focus, typed-text, keypress, and submit failure stages without reconstructing the current shared Enter-order context by hand.",
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_validation_flow.ps1 -RepoRoot 'C:\src\browser' -BrowserExe 'C:\src\browser\zig-out\bin\lightpanda.exe' -Host '127.0.0.1' -InputText 'Q' -WindowReadyAttempts 60 -PollMilliseconds 250 when you want the later live-trace handoff reopened with the same repo-root, browser, host, shared input, and bounded wait settings before the next real Google capture.",
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot 'C:\src\browser' -SummaryPath 'summary.json' -InputPath 'bundle-one.html' 'bundle-two.html' -BrowserExe 'C:\src\browser\zig-out\bin\lightpanda.exe' -Host '127.0.0.1' -SharedInputText 'Q' when you want the higher-level issue #3 next-step matrix reopened with the same repo-root, saved summary, pinned input paths, browser override, host, and shared input context before choosing between replay shortcuts, the attached bundle branch, or the safe-route wrapper chain.",
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot 'C:\src\browser' -SummaryPath 'summary.json' -InputPath 'bundle-one.html' 'bundle-two.html' when you want the broader issue #3 replay bridge reopened with the same repo-root, saved summary, and pinned input-path context before you widen back out from the shared Enter-order slice."
    )
    notes = @(
        "Use the shared click-first fallback when you want to compare the reusable Google-shaped page against the dedicated form-controls gate before widening back to the broader shared Enter-order ladder.",
        "The printed next-step commands now preserve the current repo root, custom browser path, host, shared input, Enter mutation, and timing settings where those later helpers support them, including the live-trace handoff.",
        "When SummaryPath or InputPath are supplied, the suite-router next-step and replay-route helpers now keep that same saved-summary or pinned-bundle context attached instead of dropping back to generic route defaults.",
        "The higher-level issue #3 route helpers reopened from this flow now also keep the current browser override and host context where those downstream helpers support them."
    )
}
""",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": r"""
$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "surface-check"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1" }
        [ordered]@{ name = "trace-guide"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1" }
        [ordered]@{ name = "shared-click-focus-fallback"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus -RepoRoot 'C:\src\browser' -BrowserExe 'C:\src\browser\zig-out\bin\lightpanda.exe' -Host '127.0.0.1' -InputText 'Q' -Port 8157 -ServerReadyTimeoutSeconds 15 -WindowReadyAttempts 60 -TitleWaitAttempts 80 -PollMilliseconds 250" }
        [ordered]@{ name = "recommended"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1" }
        [ordered]@{ name = "raw-probe"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1 -RepoRoot 'C:\src\browser' -BrowserExe 'C:\src\browser\zig-out\bin\lightpanda.exe' -Host '127.0.0.1' -InputText 'Q' -Port 8157 -ServerReadyTimeoutSeconds 15 -WindowReadyAttempts 60 -TitleWaitAttempts 80 -PollMilliseconds 250" }
        [ordered]@{ name = "broader-stack"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1 -RepoRoot 'C:\src\browser' -BrowserExe 'C:\src\browser\zig-out\bin\lightpanda.exe' -Host '127.0.0.1' -SharedInputText 'Q' -SharedEnterOrderPort 8157 -ServerReadyTimeoutSeconds 15 -HomeWindowReadyAttempts 60 -HomeTitleWaitAttempts 80 -HomePollMilliseconds 250" }
    )
    notes = @(
        "Use the shared click-first fallback when you want to compare the reusable Google-shaped page against the dedicated gate before widening back to the broader shared Enter-order ladder.",
        "Port 8157 is shared on purpose with the broader Enter-order helpers, so one override keeps the dedicated gate, the shared click-first fallback, and the wider stack in sync.",
        "The shared click-first fallback reuses -GoogleEnterOrder -ClickFocus with the same repo root, browser path, host, shared input text, shared Enter-order port, and timing settings as the dedicated gate.",
        "The printed next-step commands now preserve the current repo root, browser path, host, shared input text, shared Enter-order port, and timing settings where those later helpers support them.",
        "Use the raw probe command only when you need the direct script surface; otherwise prefer the dedicated wrapper so the runbook and issue comments stay consistent."
    )
}
""",
    "scripts/windows/run_google_shared_enter_order_validation.ps1": r"""
$surfaceCheckArgs = @{
    RepoRoot = $RepoRoot
}
$sharedArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Phase = "shared"
    Host = $Host
    SharedInputText = $SharedInputText
    SharedLabelPort = $SharedLabelPort
    SharedDefaultPort = $SharedDefaultPort
    SharedDeferredPort = $SharedDeferredPort
    SharedReducedGooglePort = $SharedReducedGooglePort
    InlineFlowPort = $InlineFlowPort
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
}
$titleProbeArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    Port = $TitleProbePort
    InputText = $SharedInputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WindowReadyAttempts = $HomeWindowReadyAttempts
    TitleWaitAttempts = $HomeTitleWaitAttempts
    PollMilliseconds = $HomePollMilliseconds
}
$formControlsEnterOrderArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    SharedEnterOrderPort = $SharedEnterOrderPort
    SharedInputText = $SharedInputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
}
Write-Host "=== google-shared-enter-order-surface ==="
Write-Host "=== google-title-localhost ==="
Write-Host "=== google-home-keypress-submit ==="
Write-Host "=== google-enter-order-localhost ==="
Write-Host "=== form-controls-google-enter-order-surface ==="
Write-Host "=== form-controls-google-enter-order ==="
Write-Host "Next: if the shared surface check, shared gates, localhost title probe, reduced-home keypress-before-submit probe, localhost Enter-order wrapper, dedicated shared form-controls surface check, and dedicated shared form-controls Google enter-order runner stay green, move on to the smallest live Google manual pass."
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-enter-order-route-context-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleEnterOrderRouteContextSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.router = read_text(cls.repo_root / "scripts/windows/show_headed_validation_suites.ps1")
        cls.shared_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_shared_enter_order_validation_flow.ps1"
        )
        cls.form_controls_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1"
        )
        cls.shared_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_shared_enter_order_validation.ps1"
        )

    def test_router_keeps_repo_root_and_browser_override_arguments_for_google_enter_order_routes(self) -> None:
        args_block = re.search(
            r"\$googleFormControlsEnterOrderArguments = .*?if \(\$isCustomBrowserExe\) \{.*?\}",
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(args_block, "router should build shared google enter-order arguments")
        body = args_block.group(0)
        self.assertIn("Add-SharedArgument -Arguments $googleFormControlsEnterOrderArguments -Name RepoRoot -Value $RepoRoot", body)
        self.assertIn("Add-SharedArgument -Arguments $googleFormControlsEnterOrderArguments -Name BrowserExe -Value $BrowserExe", body)

        for function_name in (
            "Get-GoogleFormControlsEnterOrderCommands",
            "Get-GoogleSharedEnterOrderCommands",
        ):
            function_block = extract_function_block(self.router, function_name)
            self.assertIn("$googleFormControlsEnterOrderArguments", function_block)

    def test_router_notes_keep_custom_browser_guidance_for_both_google_enter_order_routes(self) -> None:
        form_controls_notes = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderNotes")
        self.assertIn("surface checker first", form_controls_notes)
        self.assertIn("broader shared Enter-order ladder", form_controls_notes)
        self.assertIn('Current browser override: $BrowserExe', form_controls_notes)

        shared_notes = extract_function_block(self.router, "Get-GoogleSharedEnterOrderNotes")
        self.assertIn("shared surface checker first", shared_notes)
        self.assertIn("dedicated form-controls flow and trace guide nearby", shared_notes)
        self.assertIn('Current browser override: $BrowserExe', shared_notes)

    def test_google_shared_change_area_keeps_dedicated_form_controls_follow_up_route(self) -> None:
        shared_change_area = re.search(
            r'\{ \$ChangeArea -eq "google-shared-enter-order" \} \{(.*?)break',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(shared_change_area, "google-shared-enter-order change area should exist")
        body = shared_change_area.group(1)
        self.assertIn('Write-Route -Name "google-shared-enter-order"', body)
        self.assertIn('Write-Route -Name "dedicated-form-controls-follow-up"', body)
        self.assertIn("last shared form-controls keypress-before-submit gate reopened on its own surface", body)

    def test_shared_flow_keeps_context_preserving_handoff_chain(self) -> None:
        expected_fragments = (
            r".\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus",
            r".\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
            r".\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1",
            r".\scripts\windows\show_google_trace_validation_flow.ps1",
            r".\scripts\windows\show_google_issue3_suite_router_next_steps.ps1",
            r".\scripts\windows\show_google_issue3_replay_route.ps1",
            "saved summary, pinned input paths, browser override, host, and shared input context",
            "saved-summary or pinned-bundle context attached",
            "including the live-trace handoff",
            "current browser override and host context",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.shared_flow)

    def test_dedicated_form_controls_flow_keeps_click_first_and_broader_stack_context(self) -> None:
        expected_steps = (
            'name = "shared-click-focus-fallback"',
            'name = "recommended"',
            'name = "raw-probe"',
            'name = "broader-stack"',
        )
        for step in expected_steps:
            self.assertIn(step, self.form_controls_flow)

        expected_notes = (
            "Port 8157 is shared on purpose",
            "same repo root, browser path, host, shared input text, shared Enter-order port, and timing settings",
            "current repo root, browser path, host, shared input text, shared Enter-order port, and timing settings",
            "dedicated wrapper so the runbook and issue comments stay consistent",
        )
        for note in expected_notes:
            self.assertIn(note, self.form_controls_flow)

    def test_shared_runner_keeps_full_google_enter_order_sequence_visible(self) -> None:
        for stage in (
            "=== google-shared-enter-order-surface ===",
            "=== google-title-localhost ===",
            "=== google-home-keypress-submit ===",
            "=== google-enter-order-localhost ===",
            "=== form-controls-google-enter-order-surface ===",
            "=== form-controls-google-enter-order ===",
        ):
            self.assertIn(stage, self.shared_runner)

        for field in (
            "RepoRoot = $RepoRoot",
            "BrowserExe = $BrowserExe",
            "Host = $Host",
            "SharedInputText = $SharedInputText",
            "SharedEnterOrderPort = $SharedEnterOrderPort",
            "HomeWindowReadyAttempts = $HomeWindowReadyAttempts",
            "HomeTitleWaitAttempts = $HomeTitleWaitAttempts",
            "HomePollMilliseconds = $HomePollMilliseconds",
        ):
            self.assertIn(field, self.shared_runner)

        self.assertIn(
            "move on to the smallest live Google manual pass",
            self.shared_runner,
        )


if __name__ == "__main__":
    unittest.main()
