import argparse
import json
import os
import sys
from pathlib import Path


TARGET_DOCS = (
    "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
    "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
    "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md",
)
QUICKSTART_DOC_PATH = "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"
RAW_LAUNCHER_NEEDLE = "start_attached_pages_catalog.py"
WRAPPER_LAUNCHER_NEEDLE = "start_attached_pages_catalog.ps1"
LAUNCHER_COMPANION_NEEDLE = "show_google_issue3_attached_pages_launcher_companion.ps1"
LAUNCHER_COMPANION_SURFACE_CHECK_NEEDLE = (
    "check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1"
)
SIDECAR_SWITCH_NEEDLE = "AuditSidecars"
GOOGLE_STYLE_NEEDLE = "GoogleStyle"
REPLAY_QUICKSTART_SURFACE_CHECK_NEEDLE = (
    "check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1"
)
WINDOWS_ROUTE_SURFACE_CHECK_NEEDLE = (
    "check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1"
)
VALIDATION_ROUTER_NOTE_NEEDLE = (
    "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md"
)
VALIDATION_ROUTER_SURFACE_CHECK_NEEDLE = (
    "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1"
)
VALIDATION_ROUTER_HELPER_NEEDLE = (
    "show_google_issue3_validation_router_attached_html_quickstart.ps1"
)
ATTACHED_HTML_CHANGE_AREA_NOTE_NEEDLE = (
    "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md"
)
ATTACHED_HTML_CHANGE_AREA_HELPER_NEEDLE = (
    "show_google_issue3_attached_html_change_area_quickstart.ps1"
)
GOOGLE_SURFACE_CHECK_NEEDLE = (
    "check_google_attached_html_validation_surface.ps1"
)
GOOGLE_FLOW_NOTE_NEEDLE = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
GOOGLE_FLOW_HELPER_NEEDLE = (
    "show_google_attached_html_validation_flow.ps1"
)
GOOGLE_ENTRYPOINT_NOTE_NEEDLE = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md"
GOOGLE_ENTRYPOINT_SURFACE_CHECK_NEEDLE = (
    "check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1"
)
GOOGLE_ENTRYPOINT_HELPER_NEEDLE = (
    "show_google_issue3_google_attached_html_entrypoint.ps1"
)
PROOF_NOTE_NEEDLE = "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md"
PROOF_SURFACE_CHECK_NEEDLE = (
    "check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1"
)
PROOF_HELPER_NEEDLE = (
    "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"
)
REPLAY_ROUTE_SHORTCUT_NOTE_NEEDLE = "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md"
REPLAY_ROUTE_SHORTCUT_SURFACE_CHECK_NEEDLE = (
    "check_google_issue3_replay_route_shortcut_validation_surface.ps1"
)
REPLAY_ROUTE_SHORTCUT_HELPER_NEEDLE = (
    "show_google_issue3_replay_route_shortcut_entrypoint.ps1"
)
WINDOWS_REPLAY_BRIDGE_NOTE_NEEDLE = (
    "docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md"
)
WINDOWS_REPLAY_BRIDGE_HELPER_NEEDLE = (
    "show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1"
)


def resolve_repo_root(start_path: Path) -> Path:
    override = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
    if override:
        return Path(override).expanduser().resolve()

    cursor = start_path.expanduser().resolve()
    if cursor.is_file():
        cursor = cursor.parent

    while True:
        if (cursor / "build.zig").is_file():
            return cursor
        parent = cursor.parent
        if parent == cursor:
            raise FileNotFoundError(
                f"could not resolve the Lightpanda repo root from {start_path}"
            )
        cursor = parent


def build_file_result(relative_path: str, text: str) -> dict[str, object]:
    hits: dict[str, list[dict[str, object]]] = {
        "raw_python_references": [],
        "wrapper_references": [],
        "launcher_companion_references": [],
        "launcher_companion_surface_check_references": [],
        "replay_quickstart_surface_checks": [],
        "windows_route_surface_checks": [],
        "validation_router_note_references": [],
        "validation_router_surface_check_references": [],
        "validation_router_helper_references": [],
        "attached_html_change_area_note_references": [],
        "attached_html_change_area_helper_references": [],
        "google_surface_check_references": [],
        "google_flow_note_references": [],
        "google_flow_helper_references": [],
        "google_entrypoint_note_references": [],
        "google_entrypoint_surface_check_references": [],
        "google_entrypoint_helper_references": [],
        "proof_note_references": [],
        "proof_surface_check_references": [],
        "proof_helper_references": [],
        "replay_route_shortcut_note_references": [],
        "replay_route_shortcut_surface_check_references": [],
        "replay_route_shortcut_helper_references": [],
        "windows_replay_bridge_note_references": [],
        "windows_replay_bridge_helper_references": [],
    }

    for line_number, line in enumerate(text.splitlines(), start=1):
        stripped = line.rstrip()
        if RAW_LAUNCHER_NEEDLE in line:
            hits["raw_python_references"].append({"line_number": line_number, "line": stripped})
        if WRAPPER_LAUNCHER_NEEDLE in line:
            hits["wrapper_references"].append(
                {
                    "line_number": line_number,
                    "line": stripped,
                    "mentions_sidecars": SIDECAR_SWITCH_NEEDLE in line,
                    "mentions_google_style": GOOGLE_STYLE_NEEDLE in line,
                }
            )
        if LAUNCHER_COMPANION_NEEDLE in line:
            hits["launcher_companion_references"].append({"line_number": line_number, "line": stripped})
        if LAUNCHER_COMPANION_SURFACE_CHECK_NEEDLE in line:
            hits["launcher_companion_surface_check_references"].append(
                {"line_number": line_number, "line": stripped}
            )
        if REPLAY_QUICKSTART_SURFACE_CHECK_NEEDLE in line:
            hits["replay_quickstart_surface_checks"].append({"line_number": line_number, "line": stripped})
        if WINDOWS_ROUTE_SURFACE_CHECK_NEEDLE in line:
            hits["windows_route_surface_checks"].append({"line_number": line_number, "line": stripped})
        if VALIDATION_ROUTER_NOTE_NEEDLE in line:
            hits["validation_router_note_references"].append({"line_number": line_number, "line": stripped})
        if VALIDATION_ROUTER_SURFACE_CHECK_NEEDLE in line:
            hits["validation_router_surface_check_references"].append(
                {"line_number": line_number, "line": stripped}
            )
        if VALIDATION_ROUTER_HELPER_NEEDLE in line:
            hits["validation_router_helper_references"].append({"line_number": line_number, "line": stripped})
        if ATTACHED_HTML_CHANGE_AREA_NOTE_NEEDLE in line:
            hits["attached_html_change_area_note_references"].append(
                {"line_number": line_number, "line": stripped}
            )
        if ATTACHED_HTML_CHANGE_AREA_HELPER_NEEDLE in line:
            hits["attached_html_change_area_helper_references"].append(
                {"line_number": line_number, "line": stripped}
            )
        if GOOGLE_SURFACE_CHECK_NEEDLE in line:
            hits["google_surface_check_references"].append({"line_number": line_number, "line": stripped})
        if GOOGLE_FLOW_NOTE_NEEDLE in line:
            hits["google_flow_note_references"].append({"line_number": line_number, "line": stripped})
        if GOOGLE_FLOW_HELPER_NEEDLE in line:
            hits["google_flow_helper_references"].append({"line_number": line_number, "line": stripped})
        if GOOGLE_ENTRYPOINT_NOTE_NEEDLE in line:
            hits["google_entrypoint_note_references"].append({"line_number": line_number, "line": stripped})
        if GOOGLE_ENTRYPOINT_SURFACE_CHECK_NEEDLE in line:
            hits["google_entrypoint_surface_check_references"].append(
                {"line_number": line_number, "line": stripped}
            )
        if GOOGLE_ENTRYPOINT_HELPER_NEEDLE in line:
            hits["google_entrypoint_helper_references"].append({"line_number": line_number, "line": stripped})
        if PROOF_NOTE_NEEDLE in line:
            hits["proof_note_references"].append({"line_number": line_number, "line": stripped})
        if PROOF_SURFACE_CHECK_NEEDLE in line:
            hits["proof_surface_check_references"].append({"line_number": line_number, "line": stripped})
        if PROOF_HELPER_NEEDLE in line:
            hits["proof_helper_references"].append({"line_number": line_number, "line": stripped})
        if REPLAY_ROUTE_SHORTCUT_NOTE_NEEDLE in line:
            hits["replay_route_shortcut_note_references"].append(
                {"line_number": line_number, "line": stripped}
            )
        if REPLAY_ROUTE_SHORTCUT_SURFACE_CHECK_NEEDLE in line:
            hits["replay_route_shortcut_surface_check_references"].append(
                {"line_number": line_number, "line": stripped}
            )
        if REPLAY_ROUTE_SHORTCUT_HELPER_NEEDLE in line:
            hits["replay_route_shortcut_helper_references"].append(
                {"line_number": line_number, "line": stripped}
            )
        if WINDOWS_REPLAY_BRIDGE_NOTE_NEEDLE in line:
            hits["windows_replay_bridge_note_references"].append(
                {"line_number": line_number, "line": stripped}
            )
        if WINDOWS_REPLAY_BRIDGE_HELPER_NEEDLE in line:
            hits["windows_replay_bridge_helper_references"].append(
                {"line_number": line_number, "line": stripped}
            )

    file_result: dict[str, object] = {
        "display_path": relative_path,
        "wrapper_sidecar_reference_count": sum(
            1 for line in hits["wrapper_references"] if line["mentions_sidecars"]
        ),
        "google_wrapper_sidecar_reference_count": sum(
            1
            for line in hits["wrapper_references"]
            if line["mentions_sidecars"] and line["mentions_google_style"]
        ),
    }
    for name, values in hits.items():
        file_result[name] = values[:20]
        file_result[f"{name[:-1]}_count" if name.endswith("s") else f"{name}_count"] = len(values)
    return file_result


def build_replay_doc_audit(repo_root: Path) -> dict[str, object]:
    resolved_root = repo_root.expanduser().resolve()
    file_results: list[dict[str, object]] = []
    counts = {
        "raw_python_reference_count": 0,
        "wrapper_reference_count": 0,
        "wrapper_sidecar_reference_count": 0,
        "google_wrapper_sidecar_reference_count": 0,
        "launcher_companion_reference_count": 0,
        "launcher_companion_surface_check_reference_count": 0,
        "replay_quickstart_surface_check_count": 0,
        "windows_route_surface_check_count": 0,
        "validation_router_note_count": 0,
        "validation_router_surface_check_count": 0,
        "validation_router_helper_count": 0,
        "attached_html_change_area_note_count": 0,
        "attached_html_change_area_helper_count": 0,
        "google_surface_check_count": 0,
        "google_flow_note_count": 0,
        "google_flow_helper_count": 0,
        "google_entrypoint_note_count": 0,
        "google_entrypoint_surface_check_count": 0,
        "google_entrypoint_helper_count": 0,
        "proof_note_count": 0,
        "proof_surface_check_count": 0,
        "proof_helper_count": 0,
        "replay_route_shortcut_note_count": 0,
        "replay_route_shortcut_surface_check_count": 0,
        "replay_route_shortcut_helper_count": 0,
        "windows_replay_bridge_note_count": 0,
        "windows_replay_bridge_helper_count": 0,
    }

    for relative_path in TARGET_DOCS:
        path = resolved_root / relative_path
        if not path.is_file():
            raise FileNotFoundError(f"required replay note not found: {path}")
        file_result = build_file_result(relative_path, path.read_text(encoding="utf-8", errors="ignore"))
        file_results.append(file_result)

        counts["raw_python_reference_count"] += file_result["raw_python_reference_count"]
        counts["wrapper_reference_count"] += file_result["wrapper_reference_count"]
        counts["wrapper_sidecar_reference_count"] += file_result["wrapper_sidecar_reference_count"]
        counts["google_wrapper_sidecar_reference_count"] += file_result[
            "google_wrapper_sidecar_reference_count"
        ]
        counts["launcher_companion_reference_count"] += file_result[
            "launcher_companion_reference_count"
        ]
        counts["launcher_companion_surface_check_reference_count"] += file_result[
            "launcher_companion_surface_check_reference_count"
        ]
        counts["replay_quickstart_surface_check_count"] += file_result[
            "replay_quickstart_surface_check_count"
        ]
        counts["windows_route_surface_check_count"] += file_result[
            "windows_route_surface_check_count"
        ]
        counts["validation_router_note_count"] += file_result["validation_router_note_reference_count"]
        counts["validation_router_surface_check_count"] += file_result[
            "validation_router_surface_check_reference_count"
        ]
        counts["validation_router_helper_count"] += file_result[
            "validation_router_helper_reference_count"
        ]
        counts["attached_html_change_area_note_count"] += file_result[
            "attached_html_change_area_note_reference_count"
        ]
        counts["attached_html_change_area_helper_count"] += file_result[
            "attached_html_change_area_helper_reference_count"
        ]
        counts["google_surface_check_count"] += file_result["google_surface_check_reference_count"]
        counts["google_flow_note_count"] += file_result["google_flow_note_reference_count"]
        counts["google_flow_helper_count"] += file_result["google_flow_helper_reference_count"]
        counts["google_entrypoint_note_count"] += file_result[
            "google_entrypoint_note_reference_count"
        ]
        counts["google_entrypoint_surface_check_count"] += file_result[
            "google_entrypoint_surface_check_reference_count"
        ]
        counts["google_entrypoint_helper_count"] += file_result[
            "google_entrypoint_helper_reference_count"
        ]
        counts["proof_note_count"] += file_result["proof_note_reference_count"]
        counts["proof_surface_check_count"] += file_result["proof_surface_check_reference_count"]
        counts["proof_helper_count"] += file_result["proof_helper_reference_count"]
        counts["replay_route_shortcut_note_count"] += file_result[
            "replay_route_shortcut_note_reference_count"
        ]
        counts["replay_route_shortcut_surface_check_count"] += file_result[
            "replay_route_shortcut_surface_check_reference_count"
        ]
        counts["replay_route_shortcut_helper_count"] += file_result[
            "replay_route_shortcut_helper_reference_count"
        ]
        counts["windows_replay_bridge_note_count"] += file_result[
            "windows_replay_bridge_note_reference_count"
        ]
        counts["windows_replay_bridge_helper_count"] += file_result[
            "windows_replay_bridge_helper_reference_count"
        ]

    return {
        "repo_root": str(resolved_root),
        "target_doc_count": len(file_results),
        "target_docs": list(TARGET_DOCS),
        **counts,
        "files": file_results,
    }


def collect_failure_reasons(
    audit: dict[str, object],
    *,
    allow_raw_launcher: bool,
    require_wrapper_sidecar: bool,
    require_google_wrapper_sidecar: bool,
    require_launcher_companion: bool,
    require_launcher_companion_surface_check: bool,
    require_replay_quickstart_surface_check: bool,
    require_windows_route_surface_check: bool,
    require_validation_router_note: bool,
    require_validation_router_surface_check: bool,
    require_validation_router_helper: bool,
    require_attached_html_change_area_note: bool,
    require_attached_html_change_area_helper: bool,
    require_google_surface_check: bool,
    require_google_flow_note: bool,
    require_google_flow_helper: bool,
    require_google_entrypoint_note: bool,
    require_google_entrypoint_surface_check: bool,
    require_google_entrypoint_helper: bool,
    require_proof_note: bool,
    require_proof_surface_check: bool,
    require_proof_helper: bool,
    require_replay_route_shortcut_note: bool,
    require_replay_route_shortcut_surface_check: bool,
    require_replay_route_shortcut_helper: bool,
    require_windows_replay_bridge_note: bool,
    require_windows_replay_bridge_helper: bool,
) -> list[str]:
    failure_reasons: list[str] = []
    if audit["raw_python_reference_count"] > 0 and not allow_raw_launcher:
        failure_reasons.append("raw Python attached-pages launcher references remain")
        quickstart_result = next(
            (
                file_result
                for file_result in audit["files"]
                if file_result["display_path"] == QUICKSTART_DOC_PATH
            ),
            None,
        )
        if quickstart_result and quickstart_result["raw_python_reference_count"] > 0:
            failure_reasons.append(
                "Windows replay quickstart still carries raw Python attached-pages launcher references"
            )
    if require_wrapper_sidecar and audit["wrapper_sidecar_reference_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the wrapper-backed sidecar audit visible"
        )
    if require_google_wrapper_sidecar and audit["google_wrapper_sidecar_reference_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the Google-style wrapper-backed sidecar audit visible"
        )
    if require_launcher_companion and audit["launcher_companion_reference_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the attached-pages launcher companion visible"
        )
    if (
        require_launcher_companion_surface_check
        and audit["launcher_companion_surface_check_reference_count"] == 0
    ):
        failure_reasons.append(
            "replay notes do not keep the attached-pages launcher companion surface checker visible"
        )
    if require_replay_quickstart_surface_check and audit["replay_quickstart_surface_check_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the replay attached-html quickstart surface check visible"
        )
    if require_windows_route_surface_check and audit["windows_route_surface_check_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the broader Windows attached-html route surface check visible"
        )
    if require_validation_router_note and audit["validation_router_note_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the validation-router attached-html quickstart note visible"
        )
    if (
        require_validation_router_surface_check
        and audit["validation_router_surface_check_count"] == 0
    ):
        failure_reasons.append(
            "replay notes do not keep the validation-router attached-html quickstart surface checker visible"
        )
    if require_validation_router_helper and audit["validation_router_helper_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the validation-router attached-html quickstart helper visible"
        )
    if (
        require_attached_html_change_area_note
        and audit["attached_html_change_area_note_count"] == 0
    ):
        failure_reasons.append(
            "replay notes do not keep the attached-html change-area quickstart note visible"
        )
    if (
        require_attached_html_change_area_helper
        and audit["attached_html_change_area_helper_count"] == 0
    ):
        failure_reasons.append(
            "replay notes do not keep the attached-html change-area quickstart helper visible"
        )
    if require_google_surface_check and audit["google_surface_check_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the Google attached-html surface check visible"
        )
    if require_google_flow_note and audit["google_flow_note_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the Google attached-html flow note visible"
        )
    if require_google_flow_helper and audit["google_flow_helper_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the Google attached-html flow helper visible"
        )
    if require_google_entrypoint_note and audit["google_entrypoint_note_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the issue-specific Google attached-html entrypoint note visible"
        )
    if (
        require_google_entrypoint_surface_check
        and audit["google_entrypoint_surface_check_count"] == 0
    ):
        failure_reasons.append(
            "replay notes do not keep the issue-specific Google attached-html entrypoint surface checker visible"
        )
    if require_google_entrypoint_helper and audit["google_entrypoint_helper_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the issue-specific Google attached-html entrypoint visible"
        )
    if require_proof_note and audit["proof_note_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the pinned bundle proof note visible"
        )
    if require_proof_surface_check and audit["proof_surface_check_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the pinned bundle proof surface checker visible"
        )
    if require_proof_helper and audit["proof_helper_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the pinned bundle proof helper visible"
        )
    if require_replay_route_shortcut_note and audit["replay_route_shortcut_note_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the replay-route shortcut bridge note visible"
        )
    if (
        require_replay_route_shortcut_surface_check
        and audit["replay_route_shortcut_surface_check_count"] == 0
    ):
        failure_reasons.append(
            "replay notes do not keep the replay-route shortcut surface checker visible"
        )
    if (
        require_replay_route_shortcut_helper
        and audit["replay_route_shortcut_helper_count"] == 0
    ):
        failure_reasons.append(
            "replay notes do not keep the replay-route shortcut helper visible"
        )
    if require_windows_replay_bridge_note and audit["windows_replay_bridge_note_count"] == 0:
        failure_reasons.append(
            "replay notes do not keep the replay-shortcuts Windows replay bridge note visible"
        )
    if (
        require_windows_replay_bridge_helper
        and audit["windows_replay_bridge_helper_count"] == 0
    ):
        failure_reasons.append(
            "replay notes do not keep the replay-shortcuts Windows replay bridge helper visible"
        )
    return failure_reasons


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Issue #3 Replay Docs Launcher Audit",
        "",
        f"Repo root: {audit['repo_root']}",
        f"Target docs: {audit['target_doc_count']}",
        f"Raw Python launcher references: {audit['raw_python_reference_count']}",
        f"Wrapper sidecar references: {audit['wrapper_sidecar_reference_count']}",
        f"Google-style wrapper sidecar references: {audit['google_wrapper_sidecar_reference_count']}",
        f"Launcher companion references: {audit['launcher_companion_reference_count']}",
        (
            "Launcher companion surface-check references: "
            f"{audit['launcher_companion_surface_check_reference_count']}"
        ),
        f"Validation-router note references: {audit['validation_router_note_count']}",
        (
            "Validation-router surface-check references: "
            f"{audit['validation_router_surface_check_count']}"
        ),
        f"Validation-router helper references: {audit['validation_router_helper_count']}",
        f"Google entrypoint note references: {audit['google_entrypoint_note_count']}",
        (
            "Google entrypoint surface-check references: "
            f"{audit['google_entrypoint_surface_check_count']}"
        ),
        f"Google entrypoint helper references: {audit['google_entrypoint_helper_count']}",
        f"Replay-route shortcut note references: {audit['replay_route_shortcut_note_count']}",
        (
            "Replay-route shortcut surface-check references: "
            f"{audit['replay_route_shortcut_surface_check_count']}"
        ),
        (
            "Replay-shortcuts Windows replay bridge references: "
            f"{audit['windows_replay_bridge_helper_count']}"
        ),
        "",
    ]
    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Audit the issue #3 replay docs for stale raw-Python launcher references "
            "and missing attached-html discovery surfaces."
        )
    )
    parser.add_argument("--repo-root", help="Override the Lightpanda repo root.")
    parser.add_argument("--json", action="store_true", help="Print JSON output.")
    parser.add_argument(
        "--allow-raw-launcher",
        action="store_true",
        help="Return success even when raw Python launcher references remain.",
    )
    parser.add_argument("--require-wrapper-sidecar", action="store_true")
    parser.add_argument("--require-google-wrapper-sidecar", action="store_true")
    parser.add_argument("--require-launcher-companion", action="store_true")
    parser.add_argument("--require-launcher-companion-surface-check", action="store_true")
    parser.add_argument("--require-replay-quickstart-surface-check", action="store_true")
    parser.add_argument("--require-windows-route-surface-check", action="store_true")
    parser.add_argument("--require-validation-router-note", action="store_true")
    parser.add_argument("--require-validation-router-surface-check", action="store_true")
    parser.add_argument("--require-validation-router-helper", action="store_true")
    parser.add_argument("--require-attached-html-change-area-note", action="store_true")
    parser.add_argument("--require-attached-html-change-area-helper", action="store_true")
    parser.add_argument("--require-google-surface-check", action="store_true")
    parser.add_argument("--require-google-flow-note", action="store_true")
    parser.add_argument("--require-google-flow-helper", action="store_true")
    parser.add_argument("--require-google-entrypoint-note", action="store_true")
    parser.add_argument("--require-google-entrypoint-surface-check", action="store_true")
    parser.add_argument("--require-google-entrypoint-helper", action="store_true")
    parser.add_argument("--require-proof-note", action="store_true")
    parser.add_argument("--require-proof-surface-check", action="store_true")
    parser.add_argument("--require-proof-helper", action="store_true")
    parser.add_argument("--require-replay-route-shortcut-note", action="store_true")
    parser.add_argument("--require-replay-route-shortcut-surface-check", action="store_true")
    parser.add_argument("--require-replay-route-shortcut-helper", action="store_true")
    parser.add_argument("--require-windows-replay-bridge-note", action="store_true")
    parser.add_argument("--require-windows-replay-bridge-helper", action="store_true")
    args = parser.parse_args(argv)

    repo_root = (
        Path(args.repo_root).expanduser().resolve()
        if args.repo_root
        else resolve_repo_root(Path(__file__))
    )
    audit = build_replay_doc_audit(repo_root)
    failure_reasons = collect_failure_reasons(
        audit,
        allow_raw_launcher=args.allow_raw_launcher,
        require_wrapper_sidecar=args.require_wrapper_sidecar,
        require_google_wrapper_sidecar=args.require_google_wrapper_sidecar,
        require_launcher_companion=args.require_launcher_companion,
        require_launcher_companion_surface_check=args.require_launcher_companion_surface_check,
        require_replay_quickstart_surface_check=args.require_replay_quickstart_surface_check,
        require_windows_route_surface_check=args.require_windows_route_surface_check,
        require_validation_router_note=args.require_validation_router_note,
        require_validation_router_surface_check=args.require_validation_router_surface_check,
        require_validation_router_helper=args.require_validation_router_helper,
        require_attached_html_change_area_note=args.require_attached_html_change_area_note,
        require_attached_html_change_area_helper=args.require_attached_html_change_area_helper,
        require_google_surface_check=args.require_google_surface_check,
        require_google_flow_note=args.require_google_flow_note,
        require_google_flow_helper=args.require_google_flow_helper,
        require_google_entrypoint_note=args.require_google_entrypoint_note,
        require_google_entrypoint_surface_check=args.require_google_entrypoint_surface_check,
        require_google_entrypoint_helper=args.require_google_entrypoint_helper,
        require_proof_note=args.require_proof_note,
        require_proof_surface_check=args.require_proof_surface_check,
        require_proof_helper=args.require_proof_helper,
        require_replay_route_shortcut_note=args.require_replay_route_shortcut_note,
        require_replay_route_shortcut_surface_check=args.require_replay_route_shortcut_surface_check,
        require_replay_route_shortcut_helper=args.require_replay_route_shortcut_helper,
        require_windows_replay_bridge_note=args.require_windows_replay_bridge_note,
        require_windows_replay_bridge_helper=args.require_windows_replay_bridge_helper,
    )

    if args.json:
        payload = dict(audit)
        payload["failure_reasons"] = failure_reasons
        print(json.dumps(payload, indent=2))
    else:
        print(render_text_report(audit), end="")
        for reason in failure_reasons:
            print(f"FAIL: {reason}", file=sys.stderr)

    return 1 if failure_reasons else 0


if __name__ == "__main__":
    raise SystemExit(main())
