import tempfile
import unittest
from pathlib import Path

from issue3_replay_note_launcher_contract import audit_paths, failure_reasons, resolve_paths


DEFAULT_FILES = (
    "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
    "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
)

PASSING_CONTENT = """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_contextual_flow.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
- `docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1
"""


def write_default_files(root: Path, contents: str) -> list[Path]:
    paths: list[Path] = []
    for relative_path in DEFAULT_FILES:
        path = root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")
        paths.append(path)
    return paths


class ReplayNoteLauncherContractTests(unittest.TestCase):
    def test_resolve_paths_uses_default_replay_notes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            write_default_files(root, "placeholder")
            resolved = resolve_paths(root, None)
            self.assertEqual(3, len(resolved))

    def test_passes_with_full_bridge_contract(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(root, PASSING_CONTENT)
            audit = audit_paths(paths, root)
            self.assertEqual([], failure_reasons(audit))

    def test_fails_when_google_entrypoint_note_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md`\n", ""
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the issue-specific Google attached-html entrypoint note visible",
                failure_reasons(audit),
            )

    def test_fails_when_google_entrypoint_surface_check_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the issue-specific Google attached-html entrypoint surface checker visible",
                failure_reasons(audit),
            )

    def test_fails_when_validation_router_note_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`\n", ""
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the validation-router attached-html quickstart note visible",
                failure_reasons(audit),
            )

    def test_fails_when_validation_router_surface_check_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the validation-router attached-html surface checker visible",
                failure_reasons(audit),
            )

    def test_fails_when_validation_router_helper_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the validation-router attached-html quickstart helper visible",
                failure_reasons(audit),
            )

    def test_fails_when_change_area_note_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`\n", ""
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the attached-html change-area quickstart note visible",
                failure_reasons(audit),
            )

    def test_fails_when_change_area_helper_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the attached-html change-area quickstart helper visible",
                failure_reasons(audit),
            )

    def test_fails_when_target_bundle_quickstart_note_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`\n", ""
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the attached-html target-bundle quickstart note visible",
                failure_reasons(audit),
            )

    def test_fails_when_bundle_first_helper_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the bundle-first attached-html helper visible",
                failure_reasons(audit),
            )

    def test_fails_when_suite_catalog_surface_check_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the suite-catalog entrypoints surface checker visible",
                failure_reasons(audit),
            )

    def test_fails_when_replay_route_helper_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route.ps1\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the broader replay-route helper visible",
                failure_reasons(audit),
            )

    def test_fails_when_contextual_flow_helper_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_contextual_flow.ps1\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the context-preserving replay helper visible",
                failure_reasons(audit),
            )

    def test_fails_when_windows_replay_bridge_note_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "- `docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md`\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the replay-shortcuts Windows replay bridge note visible",
                failure_reasons(audit),
            )

    def test_fails_when_windows_replay_bridge_helper_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the replay-shortcuts Windows replay bridge helper visible",
                failure_reasons(audit),
            )

    def test_fails_when_replay_shortcuts_helper_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the replay-shortcuts helper visible",
                failure_reasons(audit),
            )

    def test_fails_when_safe_route_helper_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                PASSING_CONTENT.replace(
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1\n",
                    "",
                ),
            )
            audit = audit_paths(paths, root)
            self.assertIn(
                "replay notes do not keep the safe-route entrypoints helper visible",
                failure_reasons(audit),
            )


if __name__ == "__main__":
    unittest.main()