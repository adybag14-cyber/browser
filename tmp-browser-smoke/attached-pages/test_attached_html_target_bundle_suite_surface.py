import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1": r"""
$surface = [ordered]@{
    known_bundle_files = @(
        'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
        'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html'
        'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'
    )
    preferred_initial_page_hint = 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
    suite_commands = [ordered]@{
        attached_html_target_bundle = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
        attached_html = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        google_attached_html = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html"
    }
    helper_commands = [ordered]@{
        google_attached_html_surface_check = "check_google_attached_html_validation_surface.ps1"
        google_attached_html_asset_closure = "check_attached_html_local_asset_closure.ps1 -GoogleStyle"
        broader_attached_html_flow = "show_attached_html_validation_flow.ps1"
        google_attached_html_flow = "show_google_attached_html_validation_flow.ps1"
        google_attached_html_runner = "run_google_attached_html_validation.ps1 -Wait"
        google_issue3_attached_html_surface_check = "check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1"
        google_issue3_attached_html_entrypoint = "show_google_issue3_google_attached_html_entrypoint.ps1"
        bundle_surface_check = "check_attached_html_target_bundle_validation_surface.ps1"
        bundle_check = "check_attached_html_target_bundle.ps1"
        bundle_flow = "show_attached_html_target_bundle_validation_flow.ps1"
        bundle_runner = "run_attached_html_target_bundle_validation.ps1 -Wait"
        bundle_proof_entrypoint = "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"
        top_level_attached_html_bridge = "show_google_issue3_top_level_attached_html_entrypoint.ps1"
        bundle_first_entrypoint = "show_google_issue3_attached_bundle_first_entrypoint.ps1"
        replay_route = "show_google_issue3_replay_route.ps1"
        replay_shortcuts = "show_google_issue3_replay_shortcuts.ps1"
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
        'Start with the attached_html_target_bundle suite command when the current attached pages are already the likely three-page compatibility bundle and you want the compact suite surface first.',
        'Keep the attached_html suite command nearby when the replay may still need the broader attached-page fallback before it locks onto the pinned bundle branch.',
        'Keep the google_attached_html suite command nearby when the current inputs include a Google-like attached page and the narrower issue-specific Google attached-page chain still matters before bundle-first replay.',
        'Pass -BrowserExe when the bundle-specific route should stay pinned to a non-default Windows headed build through the suite surface, bundle-first entrypoint, printed bundle flow, and delegated bundle runner.',
        'Pass -PreferredInitialPage when the suite surface should keep the same Google-like page first across the broader attached-page lane, the narrower issue #3 re-entry helpers, and the compact bundle-first follow-up.',
        'Use bundle_proof_entrypoint after the bundle runner when the delegated bundle replay is green and the next decision depends on keeping the fixed-list screenshot-and-title proof pinned to the same saved inputs.'
    )
}
""",
    "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1": r"""
$entrypoint = [ordered]@{
    broader_attached_html_suite_router_command = "show_headed_validation_suites.ps1 -ChangeArea attached-html"
    google_attached_html_suite_router_command = "show_headed_validation_suites.ps1 -ChangeArea google-attached-html"
    windows_replay_attached_html_quickstart_command = "show_google_issue3_windows_replay_attached_html_quickstart.ps1"
    top_level_attached_html_quickstart_command = "show_google_issue3_top_level_attached_html_quickstart.ps1"
    attached_html_shortcut_command = "show_google_issue3_attached_html_shortcut_entrypoint.ps1"
    attached_html_flow_command = "show_attached_html_validation_flow.ps1"
    google_attached_html_flow_command = "show_google_attached_html_validation_flow.ps1"
    bundle_surface_check_command = "check_attached_html_target_bundle_validation_surface.ps1"
    bundle_check_command = "check_attached_html_target_bundle.ps1"
    suite_router_command = "show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
    bundle_flow_command = "show_attached_html_target_bundle_validation_flow.ps1"
    bundle_runner_command = "run_attached_html_target_bundle_validation.ps1 -Wait"
    bundle_proof_surface_check_command = "check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1"
    bundle_proof_entrypoint_command = "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"
    local_html_fixture_surface_check_command = "check_local_html_fixture_validation_surface.ps1"
    local_html_fixture_probe_command = "chrome-local-html-fixture-probe.ps1"
    replay_shortcuts_command = "show_google_issue3_replay_shortcuts.ps1"
    return_to_safe_route_command = "show_google_issue3_safe_route_entrypoints.ps1"
    notes = @(
        'Use broader_attached_html_suite_router_command first when the next replay is still being chosen from the wider attached-page router and you want the generic attached-page branch visible before the replay narrows back into the pinned bundle-only lane.',
        'Use google_attached_html_suite_router_command next when the current replay should keep the Google-shaped attached-page route visible beside the broader attached-page branch before the bundle-only branch takes over.',
        'Use windows_replay_attached_html_quickstart_command first when the replay reopened from the broader Windows replay route and you want the newer attached-html ladder visible before you commit to the bundle-only branch.',
        'Use top_level_attached_html_quickstart_command next when you want the compact top-level attached-page bridge kept visible before the replay drops from the replay-side attached-html ladder into the pinned bundle route.',
        'After the bundle runner turns green, reopen bundle_proof_surface_check_command and bundle_proof_entrypoint_command so the written proof note, the proof-only helper, and the reusable fixed-list screenshot-and-title proof stay pinned to the same bundle inputs before the route widens back out.',
        'After the bundle runner turns green, reopen local_html_fixture_surface_check_command and local_html_fixture_probe_command so the same pinned compatibility bundle can pass through the reusable screenshot-and-title proof path before the route widens back into the larger issue #3 helper chain.',
        'Pass -InputPath when you want to keep an explicit bundle path or fixed file list pinned through the bundle check, the broader attached-page flow helper, the Google-shaped attached-page flow guide, the proof-entrypoint helper, the printed bundle flow helper, the delegated bundle runner, the local fixture proof command, replay-shortcuts helper, and safe-route return command instead of relying on auto-discovery.',
        'Pass -RepoRoot and -SummaryPath when the replay is running from a non-default checkout and you want the replay-side attached-html quickstart, the top-level quickstart, the attached-page shortcut, the broader attached-page suite routers, the proof-entrypoint helper, the replay-shortcuts helper, and the safe-route return commands to preserve that same context.'
    )
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-bundle-suite-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class AttachedHtmlTargetBundleSuiteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.bundle_suite = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1"
        )
        cls.bundle_first = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1"
        )

    def test_bundle_suite_keeps_pinned_bundle_inventory_and_suite_commands(self) -> None:
        for fragment in (
            "Control your online safety and privacy",
            "Research Manager, Interpretability at Anthropic",
            "Presidential Unsealing and Reporting System for UAP Encounters",
            "preferred_initial_page_hint",
            "attached_html_target_bundle",
            "-ChangeArea attached-html-target-bundle",
            "attached_html =",
            "-ChangeArea attached-html",
            "google_attached_html =",
            "-ChangeArea google-attached-html",
        ):
            self.assertIn(fragment, self.bundle_suite)

    def test_bundle_suite_keeps_broader_google_bundle_and_proof_helpers(self) -> None:
        for fragment in (
            "google_attached_html_surface_check",
            "check_attached_html_local_asset_closure.ps1",
            "broader_attached_html_flow",
            "google_attached_html_flow",
            "google_issue3_attached_html_surface_check",
            "google_issue3_attached_html_entrypoint",
            "bundle_surface_check",
            "bundle_check",
            "bundle_flow",
            "bundle_runner",
            "bundle_proof_entrypoint",
            "top_level_attached_html_bridge",
            "bundle_first_entrypoint",
            "replay_route",
            "replay_shortcuts",
        ):
            self.assertIn(fragment, self.bundle_suite)

    def test_bundle_suite_keeps_note_paths_and_context_pinning_guidance(self) -> None:
        for fragment in (
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md",
            "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md",
            "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md",
            "broader attached-page lane",
            "Google-shaped attached-page follow-up route",
            "Pass -BrowserExe",
            "Pass -PreferredInitialPage",
            "bundle_proof_entrypoint after the bundle runner",
        ):
            self.assertIn(fragment, self.bundle_suite)

    def test_bundle_first_entrypoint_keeps_reentry_bundle_proof_and_safe_return(self) -> None:
        for fragment in (
            "broader_attached_html_suite_router_command",
            "google_attached_html_suite_router_command",
            "windows_replay_attached_html_quickstart_command",
            "top_level_attached_html_quickstart_command",
            "attached_html_shortcut_command",
            "attached_html_flow_command",
            "google_attached_html_flow_command",
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
            self.assertIn(fragment, self.bundle_first)

    def test_bundle_first_entrypoint_keeps_replay_order_and_context_arguments(self) -> None:
        for fragment in (
            "wider attached-page router",
            "Google-shaped attached-page route visible",
            "newer attached-html ladder visible",
            "compact top-level attached-page bridge",
            "fixed-list screenshot-and-title proof",
            "Pass -InputPath",
            "Pass -RepoRoot and -SummaryPath",
            "show_google_issue3_safe_route_entrypoints.ps1",
        ):
            self.assertIn(fragment, self.bundle_first)


if __name__ == "__main__":
    unittest.main()
