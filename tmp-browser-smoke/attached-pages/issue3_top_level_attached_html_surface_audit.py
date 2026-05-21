from __future__ import annotations

from pathlib import Path
from typing import Iterable


NOTE_EXPECTATIONS: tuple[str, ...] = (
    r"show_headed_validation_suites.ps1 -ChangeArea attached-html",
    r"show_attached_html_validation_flow.ps1",
    r"start_attached_pages_catalog.ps1 -AuditSidecars -InputPath '<attached-html-root>'",
    r"check_google_attached_html_validation_surface.ps1",
    r"check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
    r"show_google_attached_html_validation_flow.ps1",
    r"show_google_issue3_top_level_attached_html_quickstart.ps1",
    r"check_google_issue3_top_level_attached_html_quickstart_validation_surface.ps1",
)

HELPER_EXPECTATIONS: tuple[str, ...] = (
    "attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand",
    "google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand",
    "Bundle proof helper:",
    "Use google_issue3_attached_html_surface_check when the replay has already narrowed",
)


def _missing_snippets(text: str, snippets: Iterable[str]) -> list[str]:
    return [snippet for snippet in snippets if snippet not in text]


def audit_note_text(text: str) -> list[str]:
    return _missing_snippets(text, NOTE_EXPECTATIONS)


def audit_helper_text(text: str) -> list[str]:
    return _missing_snippets(text, HELPER_EXPECTATIONS)


def audit_repo(repo_root: str | Path) -> list[str]:
    repo_root = Path(repo_root)
    note_path = repo_root / "docs" / "ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md"
    helper_path = repo_root / "scripts" / "windows" / "show_google_issue3_top_level_attached_html_quickstart.ps1"

    failures: list[str] = []
    failures.extend(
        f"missing note snippet: {snippet}"
        for snippet in audit_note_text(note_path.read_text(encoding="utf-8"))
    )
    failures.extend(
        f"missing helper snippet: {snippet}"
        for snippet in audit_helper_text(helper_path.read_text(encoding="utf-8"))
    )
    return failures
