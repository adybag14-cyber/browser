import argparse
import json
from pathlib import Path


RAW_LAUNCHER = "start_attached_pages_catalog.py"
WRAPPER_LAUNCHER = "start_attached_pages_catalog.ps1"
SIDECAR_FLAG = "AuditSidecars"
GOOGLE_FLAG = "GoogleStyle"
DEFAULT_RELATIVE_PATHS = (
    "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
    "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
)

REPLAY_QUICKSTART_SURFACE_CHECK = (
    "check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1"
)
WINDOWS_ROUTE_SURFACE_CHECK = (
    "check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1"
)
WINDOWS_VALIDATION_ROUTER_HELPER = (
    "show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1"
)
WINDOWS_ATTACHED_HTML_CATALOG_HELPER = (
    "show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1"
)
REPLAY_ROUTE_HELPER = "show_google_issue3_replay_route.ps1"
CONTEXTUAL_FLOW_HELPER = "show_google_issue3_contextual_flow.ps1"

PROOF_NOTE = "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md"
PROOF_SURFACE_CHECK = (
    "check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1"
)
PROOF_HELPER_MARKER = "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"

GOOGLE_SURFACE_CHECK = "check_google_attached_html_validation_surface.ps1"
GOOGLE_FLOW_NOTE = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
GOOGLE_FLOW_HELPER = "show_google_attached_html_validation_flow.ps1"
GOOGLE_ENTRYPOINT_NOTE = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md"
GOOGLE_ENTRYPOINT_SURFACE_CHECK = (
    "check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1"
)
GOOGLE_ENTRYPOINT_HELPER = "show_google_issue3_google_attached_html_entrypoint.ps1"

VALIDATION_ROUTER_ATTACHED_HTML_NOTE = (
    "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md"
)
VALIDATION_ROUTER_ATTACHED_HTML_SURFACE_CHECK = (
    "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1"
)
VALIDATION_ROUTER_ATTACHED_HTML_SURFACE_CHECK_RELATIVE_PATH = (
    f"scripts/windows/{VALIDATION_ROUTER_ATTACHED_HTML_SURFACE_CHECK}"
)
VALIDATION_ROUTER_ATTACHED_HTML_HELPER = (
    "show_google_issue3_validation_router_attached_html_quickstart.ps1"
)
ATTACHED_HTML_CHANGE_AREA_NOTE = "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md"
ATTACHED_HTML_CHANGE_AREA_HELPER = "show_google_issue3_attached_html_change_area_quickstart.ps1"
ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART_NOTE = (
    "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md"
)
ATTACHED_BUNDLE_FIRST_HELPER = "show_google_issue3_attached_bundle_first_entrypoint.ps1"
SUITE_CATALOG_ENTRYPOINTS_SURFACE_CHECK = (
    "check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1"
)

REPLAY_ROUTE_SHORTCUT_NOTE = "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md"
REPLAY_ROUTE_SHORTCUT_SURFACE_CHECK = (
    "check_google_issue3_replay_route_shortcut_validation_surface.ps1"
)
REPLAY_ROUTE_SHORTCUT_HELPER = "show_google_issue3_replay_route_shortcut_entrypoint.ps1"

REPLAY_SHORTCUTS_WINDOWS_REPLAY_NOTE = (
    "docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md"
)
REPLAY_SHORTCUTS_WINDOWS_REPLAY_HELPER = (
    "show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1"
)
REPLAY_SHORTCUTS_HELPER = "show_google_issue3_replay_shortcuts.ps1"
SAFE_ROUTE_ENTRYPOINTS_HELPER = "show_google_issue3_safe_route_entrypoints.ps1"


def resolve_paths(repo_root: Path, explicit_paths: list[str] | None) -> list[Path]:
    selected = explicit_paths or list(DEFAULT_RELATIVE_PATHS)
    paths: list[Path] = []
    for candidate in selected:
        candidate_path = Path(candidate)
        path = (repo_root / candidate).resolve() if not candidate_path.is_absolute() else candidate_path.resolve()
        if not path.is_file():
            raise FileNotFoundError(f"missing replay-note source: {path}")
        paths.append(path)
    return paths


def audit_paths(paths: list[Path], repo_root: Path) -> dict[str, object]:
    file_results: list[dict[str, object]] = []
    validation_router_attached_html_surface_check_path = (
        repo_root / VALIDATION_ROUTER_ATTACHED_HTML_SURFACE_CHECK_RELATIVE_PATH
    ).resolve()
    counts = {
        "raw_python_reference_count": 0,
        "wrapper_reference_count": 0,
        "wrapper_sidecar_reference_count": 0,
        "google_wrapper_sidecar_reference_count": 0,
        "replay_quickstart_surface_check_count": 0,
        "windows_route_surface_check_count": 0,
        "windows_validation_router_helper_count": 0,
        "windows_attached_html_catalog_helper_count": 0,
        "replay_route_helper_count": 0,
        "contextual_flow_helper_count": 0,
        "proof_note_reference_count": 0,
        "proof_surface_check_count": 0,
        "proof_helper_count": 0,
        "google_surface_check_count": 0,
        "google_flow_note_reference_count": 0,
        "google_flow_helper_count": 0,
        "google_entrypoint_note_count": 0,
        "google_entrypoint_surface_check_count": 0,
        "google_entrypoint_helper_count": 0,
        "validation_router_attached_html_note_count": 0,
        "validation_router_attached_html_surface_check_count": 0,
        "validation_router_attached_html_surface_check_exists": (
            validation_router_attached_html_surface_check_path.is_file()
        ),
        "validation_router_attached_html_surface_check_path": str(
            validation_router_attached_html_surface_check_path
        ),
        "validation_router_attached_html_helper_count": 0,
        "attached_html_change_area_note_count": 0,
        "attached_html_change_area_helper_count": 0,
        "attached_html_target_bundle_quickstart_note_count": 0,
        "attached_bundle_first_helper_count": 0,
        "suite_catalog_entrypoints_surface_check_count": 0,
        "replay_route_shortcut_note_count": 0,
        "replay_route_shortcut_surface_check_count": 0,
        "replay_route_shortcut_helper_count": 0,
        "replay_shortcuts_windows_replay_note_count": 0,
        "replay_shortcuts_windows_replay_helper_count": 0,
        "replay_shortcuts_helper_count": 0,
        "safe_route_entrypoints_helper_count": 0,
    }

    for path in paths:
        text = path.read_text(encoding="utf-8", errors="ignore")
        relative_path = path.relative_to(repo_root).as_posix()
        hits = {
            "raw_python_references": [],
            "wrapper_references": [],
            "replay_quickstart_surface_checks": [],
            "windows_route_surface_checks": [],
            "windows_validation_router_helpers": [],
            "windows_attached_html_catalog_helpers": [],
            "replay_route_helpers": [],
            "contextual_flow_helpers": [],
            "proof_note_references": [],
            "proof_surface_checks": [],
            "proof_helpers": [],
            "google_surface_checks": [],
            "google_flow_note_references": [],
            "google_flow_helpers": [],
            "google_entrypoint_note_references": [],
            "google_entrypoint_surface_checks": [],
            "google_entrypoint_helpers": [],
            "validation_router_attached_html_note_references": [],
            "validation_router_attached_html_surface_checks": [],
            "validation_router_attached_html_helpers": [],
            "attached_html_change_area_note_references": [],
            "attached_html_change_area_helpers": [],
            "attached_html_target_bundle_quickstart_note_references": [],
            "attached_bundle_first_helpers": [],
            "suite_catalog_entrypoints_surface_checks": [],
            "replay_route_shortcut_note_references": [],
            "replay_route_shortcut_surface_checks": [],
            "replay_route_shortcut_helpers": [],
            "replay_shortcuts_windows_replay_note_references": [],
            "replay_shortcuts_windows_replay_helpers": [],
            "replay_shortcuts_helpers": [],
            "safe_route_entrypoints_helpers": [],
        }

        for line_number, line in enumerate(text.splitlines(), start=1):
            stripped = line.rstrip()
            if RAW_LAUNCHER in line:
                hits["raw_python_references"].append({"line_number": line_number, "line": stripped})
            if WRAPPER_LAUNCHER in line:
                hits["wrapper_references"].append(
                    {
                        "line_number": line_number,
                        "line": stripped,
                        "mentions_sidecars": SIDECAR_FLAG in line,
                        "mentions_google_style": GOOGLE_FLAG in line,
                    }
                )
            if REPLAY_QUICKSTART_SURFACE_CHECK in line:
                hits["replay_quickstart_surface_checks"].append({"line_number": line_number, "line": stripped})
            if WINDOWS_ROUTE_SURFACE_CHECK in line:
                hits["windows_route_surface_checks"].append({"line_number": line_number, "line": stripped})
            if WINDOWS_VALIDATION_ROUTER_HELPER in line:
                hits["windows_validation_router_helpers"].append({"line_number": line_number, "line": stripped})
            if WINDOWS_ATTACHED_HTML_CATALOG_HELPER in line:
                hits["windows_attached_html_catalog_helpers"].append({"line_number": line_number, "line": stripped})
            if REPLAY_ROUTE_HELPER in line:
                hits["replay_route_helpers"].append({"line_number": line_number, "line": stripped})
            if CONTEXTUAL_FLOW_HELPER in line:
                hits["contextual_flow_helpers"].append({"line_number": line_number, "line": stripped})
            if PROOF_NOTE in line:
                hits["proof_note_references"].append({"line_number": line_number, "line": stripped})
            if PROOF_SURFACE_CHECK in line:
                hits["proof_surface_checks"].append({"line_number": line_number, "line": stripped})
            if PROOF_HELPER_MARKER in line:
                hits["proof_helpers"].append({"line_number": line_number, "line": stripped})
            if GOOGLE_SURFACE_CHECK in line:
                hits["google_surface_checks"].append({"line_number": line_number, "line": stripped})
            if GOOGLE_FLOW_NOTE in line:
                hits["google_flow_note_references"].append({"line_number": line_number, "line": stripped})
            if GOOGLE_FLOW_HELPER in line:
                hits["google_flow_helpers"].append({"line_number": line_number, "line": stripped})
            if GOOGLE_ENTRYPOINT_NOTE in line:
                hits["google_entrypoint_note_references"].append({"line_number": line_number, "line": stripped})
            if GOOGLE_ENTRYPOINT_SURFACE_CHECK in line:
                hits["google_entrypoint_surface_checks"].append({"line_number": line_number, "line": stripped})
            if GOOGLE_ENTRYPOINT_HELPER in line:
                hits["google_entrypoint_helpers"].append({"line_number": line_number, "line": stripped})
            if VALIDATION_ROUTER_ATTACHED_HTML_NOTE in line:
                hits["validation_router_attached_html_note_references"].append(
                    {"line_number": line_number, "line": stripped}
                )
            if VALIDATION_ROUTER_ATTACHED_HTML_SURFACE_CHECK in line:
                hits["validation_router_attached_html_surface_checks"].append(
                    {"line_number": line_number, "line": stripped}
                )
            if VALIDATION_ROUTER_ATTACHED_HTML_HELPER in line:
                hits["validation_router_attached_html_helpers"].append(
                    {"line_number": line_number, "line": stripped}
                )
            if ATTACHED_HTML_CHANGE_AREA_NOTE in line:
                hits["attached_html_change_area_note_references"].append(
                    {"line_number": line_number, "line": stripped}
                )
            if ATTACHED_HTML_CHANGE_AREA_HELPER in line:
                hits["attached_html_change_area_helpers"].append(
                    {"line_number": line_number, "line": stripped}
                )
            if ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART_NOTE in line:
                hits["attached_html_target_bundle_quickstart_note_references"].append(
                    {"line_number": line_number, "line": stripped}
                )
            if ATTACHED_BUNDLE_FIRST_HELPER in line:
                hits["attached_bundle_first_helpers"].append(
                    {"line_number": line_number, "line": stripped}
                )
            if SUITE_CATALOG_ENTRYPOINTS_SURFACE_CHECK in line:
                hits["suite_catalog_entrypoints_surface_checks"].append(
                    {"line_number": line_number, "line": stripped}
                )
            if REPLAY_ROUTE_SHORTCUT_NOTE in line:
                hits["replay_route_shortcut_note_references"].append({"line_number": line_number, "line": stripped})
            if REPLAY_ROUTE_SHORTCUT_SURFACE_CHECK in line:
                hits["replay_route_shortcut_surface_checks"].append({"line_number": line_number, "line": stripped})
            if REPLAY_ROUTE_SHORTCUT_HELPER in line:
                hits["replay_route_shortcut_helpers"].append({"line_number": line_number, "line": stripped})
            if REPLAY_SHORTCUTS_WINDOWS_REPLAY_NOTE in line:
                hits["replay_shortcuts_windows_replay_note_references"].append(
                    {"line_number": line_number, "line": stripped}
                )
            if REPLAY_SHORTCUTS_WINDOWS_REPLAY_HELPER in line:
                hits["replay_shortcuts_windows_replay_helpers"].append(
                    {"line_number": line_number, "line": stripped}
                )
            if REPLAY_SHORTCUTS_HELPER in line:
                hits["replay_shortcuts_helpers"].append({"line_number": line_number, "line": stripped})
            if SAFE_ROUTE_ENTRYPOINTS_HELPER in line:
                hits["safe_route_entrypoints_helpers"].append({"line_number": line_number, "line": stripped})

        counts["raw_python_reference_count"] += len(hits["raw_python_references"])
        counts["wrapper_reference_count"] += len(hits["wrapper_references"])
        counts["wrapper_sidecar_reference_count"] += sum(
            1 for hit in hits["wrapper_references"] if hit["mentions_sidecars"]
        )
        counts["google_wrapper_sidecar_reference_count"] += sum(
            1
            for hit in hits["wrapper_references"]
            if hit["mentions_sidecars"] and hit["mentions_google_style"]
        )
        counts["replay_quickstart_surface_check_count"] += len(hits["replay_quickstart_surface_checks"])
        counts["windows_route_surface_check_count"] += len(hits["windows_route_surface_checks"])
        counts["windows_validation_router_helper_count"] += len(hits["windows_validation_router_helpers"])
        counts["windows_attached_html_catalog_helper_count"] += len(hits["windows_attached_html_catalog_helpers"])
        counts["replay_route_helper_count"] += len(hits["replay_route_helpers"])
        counts["contextual_flow_helper_count"] += len(hits["contextual_flow_helpers"])
        counts["proof_note_reference_count"] += len(hits["proof_note_references"])
        counts["proof_surface_check_count"] += len(hits["proof_surface_checks"])
        counts["proof_helper_count"] += len(hits["proof_helpers"])
        counts["google_surface_check_count"] += len(hits["google_surface_checks"])
        counts["google_flow_note_reference_count"] += len(hits["google_flow_note_references"])
        counts["google_flow_helper_count"] += len(hits["google_flow_helpers"])
        counts["google_entrypoint_note_count"] += len(hits["google_entrypoint_note_references"])
        counts["google_entrypoint_surface_check_count"] += len(
            hits["google_entrypoint_surface_checks"]
        )
        counts["google_entrypoint_helper_count"] += len(hits["google_entrypoint_helpers"])
        counts["validation_router_attached_html_note_count"] += len(
            hits["validation_router_attached_html_note_references"]
        )
        counts["validation_router_attached_html_surface_check_count"] += len(
            hits["validation_router_attached_html_surface_checks"]
        )
        counts["validation_router_attached_html_helper_count"] += len(
            hits["validation_router_attached_html_helpers"]
        )
        counts["attached_html_change_area_note_count"] += len(
            hits["attached_html_change_area_note_references"]
        )
        counts["attached_html_change_area_helper_count"] += len(
            hits["attached_html_change_area_helpers"]
        )
        counts["attached_html_target_bundle_quickstart_note_count"] += len(
            hits["attached_html_target_bundle_quickstart_note_references"]
        )
        counts["attached_bundle_first_helper_count"] += len(
            hits["attached_bundle_first_helpers"]
        )
        counts["suite_catalog_entrypoints_surface_check_count"] += len(
            hits["suite_catalog_entrypoints_surface_checks"]
        )
        counts["replay_route_shortcut_note_count"] += len(hits["replay_route_shortcut_note_references"])
        counts["replay_route_shortcut_surface_check_count"] += len(
            hits["replay_route_shortcut_surface_checks"]
        )
        counts["replay_route_shortcut_helper_count"] += len(hits["replay_route_shortcut_helpers"])
        counts["replay_shortcuts_windows_replay_note_count"] += len(
            hits["replay_shortcuts_windows_replay_note_references"]
        )
        counts["replay_shortcuts_windows_replay_helper_count"] += len(
            hits["replay_shortcuts_windows_replay_helpers"]
        )
        counts["replay_shortcuts_helper_count"] += len(hits["replay_shortcuts_helpers"])
        counts["safe_route_entrypoints_helper_count"] += len(hits["safe_route_entrypoints_helpers"])

        file_results.append(
            {
                "path": str(path),
                "display_path": relative_path,
                **{f"{k[:-1]}_count" if k.endswith("s") else k: len(v) for k, v in hits.items() if isinstance(v, list)},
                **hits,
            }
        )

    return {"repo_root": str(repo_root), "file_count": len(file_results), **counts, "files": file_results}


def failure_reasons(audit: dict[str, object]) -> list[str]:
    reasons: list[str] = []
    if audit["raw_python_reference_count"] > 0:
        reasons.append("raw Python attached-pages launcher references remain in replay notes")
    if audit["wrapper_reference_count"] == 0:
        reasons.append("replay notes do not mention the wrapper-backed attached-pages launcher")
    if audit["wrapper_sidecar_reference_count"] == 0:
        reasons.append("replay notes do not keep the wrapper-backed sidecar audit visible")
    if audit["google_wrapper_sidecar_reference_count"] == 0:
        reasons.append("replay notes do not keep the Google-style wrapper-backed sidecar audit visible")
    if audit["replay_quickstart_surface_check_count"] == 0:
        reasons.append("replay notes do not keep the replay attached-html quickstart surface check visible")
    if audit["windows_route_surface_check_count"] == 0:
        reasons.append("replay notes do not keep the broader Windows attached-html route surface check visible")
    if audit["windows_validation_router_helper_count"] == 0:
        reasons.append("replay notes do not keep the broader Windows validation-router attached-html bridge helper visible")
    if audit["windows_attached_html_catalog_helper_count"] == 0:
        reasons.append("replay notes do not keep the broader Windows attached-html catalog quickstart helper visible")
    if audit["replay_route_helper_count"] == 0:
        reasons.append("replay notes do not keep the broader replay-route helper visible")
    if audit["contextual_flow_helper_count"] == 0:
        reasons.append("replay notes do not keep the context-preserving replay helper visible")
    if audit["proof_note_reference_count"] == 0:
        reasons.append("replay notes do not keep the pinned bundle proof note visible")
    if audit["proof_surface_check_count"] == 0:
        reasons.append("replay notes do not keep the pinned bundle proof surface checker visible")
    if audit["proof_helper_count"] == 0:
        reasons.append("replay notes do not keep the pinned bundle proof helper visible")
    if audit["google_surface_check_count"] == 0:
        reasons.append("replay notes do not keep the Google attached-html surface check visible")
    if audit["google_flow_note_reference_count"] == 0:
        reasons.append("replay notes do not keep the Google attached-html flow note visible")
    if audit["google_flow_helper_count"] == 0:
        reasons.append("replay notes do not keep the Google attached-html flow helper visible")
    if audit["google_entrypoint_note_count"] == 0:
        reasons.append("replay notes do not keep the issue-specific Google attached-html entrypoint note visible")
    if audit["google_entrypoint_surface_check_count"] == 0:
        reasons.append("replay notes do not keep the issue-specific Google attached-html entrypoint surface checker visible")
    if audit["google_entrypoint_helper_count"] == 0:
        reasons.append("replay notes do not keep the issue-specific Google attached-html entrypoint visible")
    if audit["validation_router_attached_html_note_count"] == 0:
        reasons.append("replay notes do not keep the validation-router attached-html quickstart note visible")
    if not audit["validation_router_attached_html_surface_check_exists"]:
        reasons.append(
            "validation-router attached-html surface checker is missing from scripts/windows"
        )
    elif audit["validation_router_attached_html_surface_check_count"] == 0:
        reasons.append("replay notes do not keep the validation-router attached-html surface checker visible")
    if audit["validation_router_attached_html_helper_count"] == 0:
        reasons.append("replay notes do not keep the validation-router attached-html quickstart helper visible")
    if audit["attached_html_change_area_note_count"] == 0:
        reasons.append("replay notes do not keep the attached-html change-area quickstart note visible")
    if audit["attached_html_change_area_helper_count"] == 0:
        reasons.append("replay notes do not keep the attached-html change-area quickstart helper visible")
    if audit["attached_html_target_bundle_quickstart_note_count"] == 0:
        reasons.append("replay notes do not keep the attached-html target-bundle quickstart note visible")
    if audit["attached_bundle_first_helper_count"] == 0:
        reasons.append("replay notes do not keep the bundle-first attached-html helper visible")
    if audit["suite_catalog_entrypoints_surface_check_count"] == 0:
        reasons.append("replay notes do not keep the suite-catalog entrypoints surface checker visible")
    if audit["replay_route_shortcut_note_count"] == 0:
        reasons.append("replay notes do not keep the replay-route shortcut bridge note visible")
    if audit["replay_route_shortcut_surface_check_count"] == 0:
        reasons.append("replay notes do not keep the replay-route shortcut surface checker visible")
    if audit["replay_route_shortcut_helper_count"] == 0:
        reasons.append("replay notes do not keep the replay-route shortcut helper visible")
    if audit["replay_shortcuts_windows_replay_note_count"] == 0:
        reasons.append("replay notes do not keep the replay-shortcuts Windows replay bridge note visible")
    if audit["replay_shortcuts_windows_replay_helper_count"] == 0:
        reasons.append("replay notes do not keep the replay-shortcuts Windows replay bridge helper visible")
    if audit["replay_shortcuts_helper_count"] == 0:
        reasons.append("replay notes do not keep the replay-shortcuts helper visible")
    if audit["safe_route_entrypoints_helper_count"] == 0:
        reasons.append("replay notes do not keep the safe-route entrypoints helper visible")
    return reasons


def render_text(audit: dict[str, object], reasons: list[str]) -> str:
    lines = [
        "Issue #3 Replay Note Launcher Contract",
        "",
        f"Repo root: {audit['repo_root']}",
        f"Files scanned: {audit['file_count']}",
        f"Windows route surface-check references: {audit['windows_route_surface_check_count']}",
        f"Windows validation-router bridge helper references: {audit['windows_validation_router_helper_count']}",
        f"Windows catalog quickstart helper references: {audit['windows_attached_html_catalog_helper_count']}",
        f"Replay-route helper references: {audit['replay_route_helper_count']}",
        f"Contextual-flow helper references: {audit['contextual_flow_helper_count']}",
        f"Validation-router quickstart note references: {audit['validation_router_attached_html_note_count']}",
        f"Validation-router surface-check file present: {audit['validation_router_attached_html_surface_check_exists']}",
        f"Validation-router surface-check references: {audit['validation_router_attached_html_surface_check_count']}",
        f"Validation-router quickstart helper references: {audit['validation_router_attached_html_helper_count']}",
        f"Change-area quickstart note references: {audit['attached_html_change_area_note_count']}",
        f"Change-area quickstart helper references: {audit['attached_html_change_area_helper_count']}",
        f"Target-bundle quickstart note references: {audit['attached_html_target_bundle_quickstart_note_count']}",
        f"Bundle-first helper references: {audit['attached_bundle_first_helper_count']}",
        f"Suite-catalog surface-check references: {audit['suite_catalog_entrypoints_surface_check_count']}",
        f"Replay-shortcuts helper references: {audit['replay_shortcuts_helper_count']}",
        f"Safe-route helper references: {audit['safe_route_entrypoints_helper_count']}",
        "",
    ]
    for reason in reasons:
        lines.append(f"FAIL: {reason}")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Fail if the issue #3 replay notes drift away from the wrapper-backed launcher, "
            "the replay-side and Windows-side route checks, the broader Windows validation-router bridge and Windows catalog quickstart helpers, "
            "the broader replay-route helper, the context-preserving replay helper, "
            "the pinned proof route, the dedicated Google attached-html replay surface, the issue-specific Google "
            "attached-html entrypoint note and checker, the validation-router quickstart note and surface checker, the validation-router "
            "surface-check file itself, the validation-router and change-area attached-html quickstart helpers, the bundle-first target-bundle handoff, "
            "the suite-catalog entrypoints surface checker, the replay-route shortcut companion, the replay-shortcuts helpers, "
            "or the safe-route entrypoints helper."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Repo root that contains the replay-note docs.")
    parser.add_argument("--path", action="append", dest="paths")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    paths = resolve_paths(repo_root, args.paths)
    audit = audit_paths(paths, repo_root)
    reasons = failure_reasons(audit)

    if args.json:
        payload = dict(audit)
        payload["failure_reasons"] = reasons
        print(json.dumps(payload, indent=2))
    else:
        print(render_text(audit, reasons), end="")
    return 1 if reasons else 0


if __name__ == "__main__":
    raise SystemExit(main())