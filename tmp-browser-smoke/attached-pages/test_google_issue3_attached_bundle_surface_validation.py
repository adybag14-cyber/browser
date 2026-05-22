import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_ordered_block(source: str, block_name: str) -> str:
    pattern = re.compile(
        rf"{re.escape(block_name)}\s*=\s*\[ordered\]@\{{.*?^\}}",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(source)
    if not match:
        raise AssertionError(f"Could not find ordered block for {block_name}")
    return match.group(0)


FIXTURE_FILES = {
    "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1": r"""
$surface = [ordered]@{
    explicit_input_path_count = 0
    known_bundle_files = @(
        'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
        'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html'
        'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'
    )
    preferred_initial_page_hint = 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
    suite_commands = [ordered]@{
        attached_html_target_bundle = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'attached-html-target-bundle'"
        attached_html = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'attached-html'"
        google_attached_html = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'google-attached-html'"
    }
    helper_commands = [ordered]@{
        google_attached_html_surface_check = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1"
        google_attached_html_asset_closure = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle"
        broader_attached_html_flow = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
        google_attached_html_flow = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
        google_attached_html_runner = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait"
        google_issue3_attached_html_surface_check = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1"
        google_issue3_attached_html_entrypoint = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1"
        bundle_surface_check = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1"
        bundle_check = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1"
        bundle_flow = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1"
        bundle_runner = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait"
        bundle_proof_entrypoint = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"
        top_level_attached_html_bridge = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1"
        bundle_first_entrypoint = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1"
        replay_route = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1"
        replay_shortcuts = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1"
    }
    note_paths = [ordered]@{
        bundle_reference = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
        bundle_quickstart = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
        bundle_proof = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'
        bundle_checklist = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
        top_level_attached_html_bridge = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
        bundle_first_bridge = 'docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md'
        google_attached_html_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        google_issue3_attached_html_entrypoint = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
        windows_replay_attached_html_quickstart = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
        validation_chain = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    }
    notes = @(
        'Use this helper when you want the attached-html-target-bundle suite surface printed with the broader attached-page lane, the full Google-shaped attached-page follow-up route, the narrower issue-specific Google attached-page checker and entrypoint, the bundle checker, and the proof-entry follow-up still visible beside it.',
        'Pass -BrowserExe when the bundle-specific route should stay pinned to a non-default Windows headed build through the suite surface, bundle-first entrypoint, printed bundle flow, and delegated bundle runner.',
        'Pass -PreferredInitialPage when the suite surface should keep the same Google-like page first across the broader attached-page lane, the narrower issue #3 re-entry helpers, and the compact bundle-first follow-up.'
    )
}
$surface.recommended_next_key = 'bundle_surface_check'
""",
    "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1": r"""
$entrypoint = [ordered]@{
    explicit_input_path_count = 0
    broader_attached_html_suite_router_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'attached-html'"
    google_attached_html_suite_router_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'google-attached-html'"
    windows_replay_attached_html_quickstart_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1"
    top_level_attached_html_quickstart_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1"
    attached_html_shortcut_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1"
    attached_html_flow_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
    google_attached_html_flow_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
    bundle_surface_check_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1"
    bundle_check_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1"
    suite_router_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'attached-html-target-bundle'"
    bundle_flow_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1"
    bundle_runner_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait"
    bundle_proof_surface_check_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1"
    bundle_proof_entrypoint_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"
    local_html_fixture_surface_check_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1"
    local_html_fixture_probe_command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1"
    replay_shortcuts_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1"
    return_to_safe_route_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1"
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    attached_html_shortcut_note_path = 'docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    attached_html_target_bundle_reference_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    attached_html_target_bundle_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
    attached_html_target_bundle_proof_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'
    attached_html_target_bundle_checklist_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    notes = @(
        'Use broader_attached_html_suite_router_command first when the next replay is still being chosen from the wider attached-page router and you want the generic attached-page branch visible before the replay narrows back into the pinned bundle-only lane.',
        'Use google_attached_html_suite_router_command next when the current replay should keep the Google-shaped attached-page route visible beside the broader attached-page branch before the bundle-only branch takes over.',
        'Start with bundle_surface_check_command so the pinned bundle reference note, bundle quickstart, written proof note, pinned manual checklist, checker, helper, runner, and delegated attached-html surfaces fail fast before localhost replay.',
        'After the bundle runner turns green, reopen local_html_fixture_surface_check_command and local_html_fixture_probe_command so the same pinned compatibility bundle can pass through the reusable screenshot-and-title proof path before the route widens back into the larger issue #3 helper chain.',
        'Pass -BrowserExe when the replay should stay pinned to a non-default Windows headed build through the broader attached-page suite routers, the top-level attached-page quickstart, the Google-shaped flow helper, the printed bundle flow helper, and the delegated bundle runner instead of drifting back to .\zig-out\bin\lightpanda.exe.',
        'Pass -InputPath when you want to keep an explicit bundle path or fixed file list pinned through the bundle check, the broader attached-page flow helper, the Google-shaped attached-page flow guide, the proof-entrypoint helper, the printed bundle flow helper, the delegated bundle runner, the local fixture proof command, replay-shortcuts helper, and safe-route return command instead of relying on auto-discovery.',
        'Pass -RepoRoot and -SummaryPath when the replay is running from a non-default checkout and you want the replay-side attached-html quickstart, the top-level quickstart, the attached-page shortcut, the broader attached-page suite routers, the proof-entrypoint helper, the replay-shortcuts helper, and the safe-route return commands to preserve that same context.'
    )
}
$entrypoint.recommended_next_key = 'bundle_surface_check_command'
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-bundle-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3AttachedBundleSurfaceValidationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parent

        cls.bundle_suite_surface = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1"
        )
        cls.bundle_first_entrypoint = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1"
        )

    def test_bundle_suite_surface_keeps_pinned_bundle_identity(self) -> None:
        for fragment in (
            "Google Safety Centre",
            "Anthropic",
            "U.S. Department of War",
            "preferred_initial_page_hint",
        ):
            self.assertIn(fragment, self.bundle_suite_surface)

    def test_bundle_suite_surface_keeps_suite_reentry_commands(self) -> None:
        suite_commands = extract_ordered_block(self.bundle_suite_surface, "suite_commands")
        for fragment in (
            "show_headed_validation_suites.ps1 -ChangeArea 'attached-html-target-bundle'",
            "show_headed_validation_suites.ps1 -ChangeArea 'attached-html'",
            "show_headed_validation_suites.ps1 -ChangeArea 'google-attached-html'",
        ):
            self.assertIn(fragment, suite_commands)

    def test_bundle_suite_surface_keeps_broader_google_and_bundle_followups(self) -> None:
        helper_commands = extract_ordered_block(self.bundle_suite_surface, "helper_commands")
        for fragment in (
            "check_google_attached_html_validation_surface.ps1",
            "check_attached_html_local_asset_closure.ps1",
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "run_google_attached_html_validation.ps1 -Wait",
            "check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
            "show_google_issue3_google_attached_html_entrypoint.ps1",
            "check_attached_html_target_bundle_validation_surface.ps1",
            "check_attached_html_target_bundle.ps1",
            "show_attached_html_target_bundle_validation_flow.ps1",
            "run_attached_html_target_bundle_validation.ps1 -Wait",
            "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
            "show_google_issue3_top_level_attached_html_entrypoint.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
            "show_google_issue3_replay_route.ps1",
            "show_google_issue3_replay_shortcuts.ps1",
        ):
            self.assertIn(fragment, helper_commands)

    def test_bundle_suite_surface_keeps_note_references_and_context_guidance(self) -> None:
        for fragment in (
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md",
            "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md",
            "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
            "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md",
            "Pass -BrowserExe",
            "Pass -PreferredInitialPage",
        ):
            self.assertIn(fragment, self.bundle_suite_surface)

    def test_bundle_first_entrypoint_keeps_reentry_ladder(self) -> None:
        for fragment in (
            "broader_attached_html_suite_router_command",
            "google_attached_html_suite_router_command",
            "windows_replay_attached_html_quickstart_command",
            "top_level_attached_html_quickstart_command",
            "attached_html_shortcut_command",
            "attached_html_flow_command",
            "google_attached_html_flow_command",
        ):
            self.assertIn(fragment, self.bundle_first_entrypoint)

    def test_bundle_first_entrypoint_keeps_bundle_and_proof_commands(self) -> None:
        for fragment in (
            "bundle_surface_check_command",
            "bundle_check_command",
            "suite_router_command",
            "bundle_flow_command",
            "bundle_runner_command",
            "bundle_proof_surface_check_command",
            "bundle_proof_entrypoint_command",
            "local_html_fixture_surface_check_command",
            "local_html_fixture_probe_command",
            "replay_shortcuts_command",
            "return_to_safe_route_command",
        ):
            self.assertIn(fragment, self.bundle_first_entrypoint)

    def test_bundle_first_entrypoint_keeps_notes_for_replay_and_bundle_docs(self) -> None:
        for fragment in (
            "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
            "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md",
            "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md",
        ):
            self.assertIn(fragment, self.bundle_first_entrypoint)

    def test_bundle_first_entrypoint_keeps_context_and_fixed_list_guidance(self) -> None:
        for fragment in (
            "Pass -BrowserExe",
            "Pass -InputPath",
            "Pass -RepoRoot and -SummaryPath",
            "same pinned compatibility bundle",
            "reusable",
            "proof path",
            "broader attached-page suite routers",
            "Google-shaped attached-page route",
        ):
            self.assertIn(fragment, self.bundle_first_entrypoint)


if __name__ == "__main__":
    unittest.main()
