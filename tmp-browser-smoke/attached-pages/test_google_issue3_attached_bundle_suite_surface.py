import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1": r"""
$surface = [ordered]@{
    suite_commands = [ordered]@{
        attached_html_target_bundle = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'attached-html-target-bundle'"
        attached_html = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'attached-html'"
        google_attached_html = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'google-attached-html'"
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
        bundle_reference = "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md"
        bundle_quickstart = "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md"
        bundle_proof = "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md"
        bundle_checklist = "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md"
        validation_chain = "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md"
    }
    notes = @(
        "Use this helper when you want the attached-html-target-bundle suite surface printed with the broader attached-page lane",
        "Start with the attached_html_target_bundle suite command when the current attached pages are already the likely three-page compatibility bundle",
        "Run google_attached_html_surface_check, google_attached_html_asset_closure, broader_attached_html_flow, google_attached_html_flow, and google_attached_html_runner before the bundle-only route",
        "Run google_issue3_attached_html_surface_check and google_issue3_attached_html_entrypoint after the broader Google-shaped attached-page surface looks right",
        "Run bundle_surface_check before trusting the bundle-only replay after branch moves or helper renames.",
        "Run bundle_check right after bundle_surface_check when you want the current saved-page set revalidated as the same known three-page compatibility bundle",
        "Use bundle_proof_entrypoint after the bundle runner when the delegated bundle replay is green",
        "Use bundle_first_entrypoint when explicit input paths, repo-root context, replay-route context, or a non-default BrowserExe are already in play",
        "Return to replay_route or replay_shortcuts only after the pinned bundle route makes the next attached-page failure state clear."
    )
}
$surface.recommended_next_key = if ($surface.explicit_input_path_count -gt 0) {
    'bundle_first_entrypoint'
} else {
    'bundle_surface_check'
}
""",
    "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1": r"""
$entrypoint = [ordered]@{
    broader_attached_html_suite_router_command = "show_headed_validation_suites.ps1 -ChangeArea 'attached-html'"
    google_attached_html_suite_router_command = "show_headed_validation_suites.ps1 -ChangeArea 'google-attached-html'"
    windows_replay_attached_html_quickstart_command = "show_google_issue3_windows_replay_attached_html_quickstart.ps1"
    top_level_attached_html_quickstart_command = "show_google_issue3_top_level_attached_html_quickstart.ps1"
    attached_html_shortcut_command = "show_google_issue3_attached_html_shortcut_entrypoint.ps1"
    attached_html_flow_command = "show_attached_html_validation_flow.ps1"
    google_attached_html_flow_command = "show_google_attached_html_validation_flow.ps1"
    bundle_surface_check_command = "check_attached_html_target_bundle_validation_surface.ps1"
    bundle_check_command = "check_attached_html_target_bundle.ps1"
    suite_router_command = "show_headed_validation_suites.ps1 -ChangeArea 'attached-html-target-bundle'"
    bundle_flow_command = "show_attached_html_target_bundle_validation_flow.ps1"
    bundle_runner_command = "run_attached_html_target_bundle_validation.ps1 -Wait"
    bundle_proof_surface_check_command = "check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1"
    bundle_proof_entrypoint_command = "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"
    local_html_fixture_surface_check_command = "check_local_html_fixture_validation_surface.ps1"
    local_html_fixture_probe_command = "chrome-local-html-fixture-probe.ps1"
    replay_shortcuts_command = "show_google_issue3_replay_shortcuts.ps1"
    return_to_safe_route_command = "show_google_issue3_safe_route_entrypoints.ps1"
    notes = @(
        "Use this helper when the current saved or attached pages are still the known three-page compatibility bundle",
        "Use broader_attached_html_suite_router_command first when the next replay is still being chosen from the wider attached-page router",
        "Use google_attached_html_suite_router_command next when the current replay should keep the Google-shaped attached-page route visible",
        "Use windows_replay_attached_html_quickstart_command first when the replay reopened from the broader Windows replay route",
        "Use top_level_attached_html_quickstart_command next when you want the compact top-level attached-page bridge kept visible",
        "Use attached_html_shortcut_command next when the route is already clearly inside the shorter attached-page helper chain",
        "Use suite_router_command when you want the attached-html-target-bundle suite surface reprinted beside the broader attached-page suite routers",
        "After the bundle runner turns green, reopen bundle_proof_surface_check_command and bundle_proof_entrypoint_command",
        "After the bundle runner turns green, reopen local_html_fixture_surface_check_command and local_html_fixture_probe_command",
        "Use replay_shortcuts_command after the bundle replay when you want the broader issue #3 discovery bridge",
        "Return to the broader issue #3 safe-route helper only after the bundle replay or the reusable fixed-list proof path makes the next Google-style input or submit failure state clear."
    )
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-bundle-suite-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class AttachedBundleSuiteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.bundle_suite_surface = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1"
        )
        cls.bundle_first_entrypoint = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1"
        )

    def test_bundle_suite_surface_keeps_router_commands_visible(self) -> None:
        expected_fragments = (
            "show_headed_validation_suites.ps1",
            "attached-html-target-bundle",
            "attached-html'",
            "google-attached-html",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.bundle_suite_surface)

    def test_bundle_suite_surface_keeps_google_bundle_and_reentry_helpers(self) -> None:
        expected_helpers = (
            "check_google_attached_html_validation_surface.ps1",
            "check_attached_html_local_asset_closure.ps1",
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "run_google_attached_html_validation.ps1",
            "check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
            "show_google_issue3_google_attached_html_entrypoint.ps1",
            "check_attached_html_target_bundle_validation_surface.ps1",
            "check_attached_html_target_bundle.ps1",
            "show_attached_html_target_bundle_validation_flow.ps1",
            "run_attached_html_target_bundle_validation.ps1",
            "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
            "show_google_issue3_top_level_attached_html_entrypoint.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
            "show_google_issue3_replay_route.ps1",
            "show_google_issue3_replay_shortcuts.ps1",
        )
        for helper in expected_helpers:
            self.assertIn(helper, self.bundle_suite_surface)

    def test_bundle_suite_surface_keeps_notes_and_next_step_logic(self) -> None:
        expected_notes = (
            "attached-html-target-bundle suite surface printed with the broader attached-page lane",
            "three-page compatibility bundle",
            "broader Google-shaped attached-page surface",
            "bundle-only replay after branch moves or helper renames",
            "delegated bundle replay is green",
            "explicit input paths, repo-root context, replay-route context, or a non-default BrowserExe are already in play",
            "replay_route or replay_shortcuts",
            "bundle_first_entrypoint",
            "bundle_surface_check",
        )
        for note in expected_notes:
            self.assertIn(note, self.bundle_suite_surface)

    def test_bundle_suite_surface_keeps_bundle_notes_nearby(self) -> None:
        expected_paths = (
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md",
            "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md",
        )
        for path in expected_paths:
            self.assertIn(path, self.bundle_suite_surface)

    def test_bundle_first_entrypoint_keeps_pre_bundle_reentry_and_bundle_followups(self) -> None:
        expected_fragments = (
            "show_headed_validation_suites.ps1 -ChangeArea 'attached-html'",
            "show_headed_validation_suites.ps1 -ChangeArea 'google-attached-html'",
            "show_google_issue3_windows_replay_attached_html_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_shortcut_entrypoint.ps1",
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "check_attached_html_target_bundle_validation_surface.ps1",
            "check_attached_html_target_bundle.ps1",
            "show_headed_validation_suites.ps1 -ChangeArea 'attached-html-target-bundle'",
            "show_attached_html_target_bundle_validation_flow.ps1",
            "run_attached_html_target_bundle_validation.ps1",
            "check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
            "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
            "check_local_html_fixture_validation_surface.ps1",
            "chrome-local-html-fixture-probe.ps1",
            "show_google_issue3_replay_shortcuts.ps1",
            "show_google_issue3_safe_route_entrypoints.ps1",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.bundle_first_entrypoint)

    def test_bundle_first_entrypoint_keeps_reentry_notes(self) -> None:
        expected_notes = (
            "known three-page compatibility bundle",
            "wider attached-page router",
            "Google-shaped attached-page route visible",
            "broader Windows replay route",
            "compact top-level attached-page bridge",
            "shorter attached-page helper chain",
            "attached-html-target-bundle suite surface reprinted beside the broader attached-page suite routers",
            "bundle_proof_surface_check_command and bundle_proof_entrypoint_command",
            "local_html_fixture_surface_check_command and local_html_fixture_probe_command",
            "broader issue #3 discovery bridge",
            "broader issue #3 safe-route helper",
        )
        for note in expected_notes:
            self.assertIn(note, self.bundle_first_entrypoint)


if __name__ == "__main__":
    unittest.main()
