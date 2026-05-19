import tempfile
import unittest
from pathlib import Path

from issue3_replay_note_launcher_contract import audit_paths, failure_reasons, resolve_paths


DEFAULT_FILES = (
    "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
    "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
)

PASSING_CONTENT = """powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
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

    def test_fails_when_raw_python_reference_remains(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(root, "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py")
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("raw Python attached-pages launcher references remain in replay notes", reasons)

    def test_fails_when_wrapper_lacks_sidecar_flags(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("replay notes do not keep the wrapper-backed sidecar audit visible", reasons)
            self.assertIn(
                "replay notes do not keep the Google-style wrapper-backed sidecar audit visible",
                reasons,
            )

    def test_fails_when_replay_quickstart_surface_check_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn(
                "replay notes do not keep the replay attached-html quickstart surface check visible",
                reasons,
            )

    def test_fails_when_windows_route_surface_check_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn(
                "replay notes do not keep the broader Windows attached-html route surface check visible",
                reasons,
            )

    def test_fails_when_proof_note_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("replay notes do not keep the pinned bundle proof note visible", reasons)

    def test_fails_when_proof_checker_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("replay notes do not keep the pinned bundle proof surface checker visible", reasons)

    def test_fails_when_proof_helper_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("replay notes do not keep the pinned bundle proof helper visible", reasons)

    def test_fails_when_google_surface_check_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("replay notes do not keep the Google attached-html surface check visible", reasons)

    def test_fails_when_google_flow_note_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("replay notes do not keep the Google attached-html flow note visible", reasons)

    def test_fails_when_google_flow_helper_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("replay notes do not keep the Google attached-html flow helper visible", reasons)

    def test_fails_when_google_entrypoint_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn(
                "replay notes do not keep the issue-specific Google attached-html entrypoint visible",
                reasons,
            )

    def test_fails_when_replay_route_shortcut_note_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("replay notes do not keep the replay-route shortcut bridge note visible", reasons)

    def test_fails_when_replay_route_shortcut_checker_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("replay notes do not keep the replay-route shortcut surface checker visible", reasons)

    def test_fails_when_replay_route_shortcut_helper_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
""",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("replay notes do not keep the replay-route shortcut helper visible", reasons)

    def test_passes_with_google_wrapper_sidecar_and_route_contract(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(root, PASSING_CONTENT)
            audit = audit_paths(paths, root)
            self.assertEqual([], failure_reasons(audit))


if __name__ == "__main__":
    unittest.main()
