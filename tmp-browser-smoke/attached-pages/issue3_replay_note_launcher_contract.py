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

PROOF_NOTE = "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md"
PROOF_SURFACE_CHECK = (
    "check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1"
)
PROOF_HELPER_MARKER = "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"

GOOGLE_FLOW_NOTE = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
GOOGLE_FLOW_HELPER = "show_google_attached_html_validation_flow.ps1"
GOOGLE_ENTRYPOINT_HELPER = "show_google_issue3_google_attached_html_entrypoint.ps1"


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
    raw_count = 0
    wrapper_count = 0
    wrapper_sidecar_count = 0
    google_wrapper_sidecar_count = 0
    proof_note_count = 0
    proof_surface_check_count = 0
    proof_helper_count = 0
    google_flow_note_count = 0
    google_flow_helper_count = 0
    google_entrypoint_helper_count = 0

    for path in paths:
        text = path.read_text(encoding="utf-8", errors="ignore")
        relative_path = path.relative_to(repo_root).as_posix()
        raw_hits: list[dict[str, object]] = []
        wrapper_hits: list[dict[str, object]] = []
        proof_note_hits: list[dict[str, object]] = []
        proof_surface_hits: list[dict[str, object]] = []
        proof_helper_hits: list[dict[str, object]] = []
        google_flow_note_hits: list[dict[str, object]] = []
        google_flow_helper_hits: list[dict[str, object]] = []
        google_entrypoint_hits: list[dict[str, object]] = []

        for line_number, line in enumerate(text.splitlines(), start=1):
            stripped = line.rstrip()
            if RAW_LAUNCHER in line:
                raw_hits.append({"line_number": line_number, "line": stripped})
            if WRAPPER_LAUNCHER in line:
                wrapper_hits.append(
                    {
                        "line_number": line_number,
                        "line": stripped,
                        "mentions_sidecars": SIDECAR_FLAG in line,
                        "mentions_google_style": GOOGLE_FLAG in line,
                    }
                )
            if PROOF_NOTE in line:
                proof_note_hits.append({"line_number": line_number, "line": stripped})
            if PROOF_SURFACE_CHECK in line:
                proof_surface_hits.append({"line_number": line_number, "line": stripped})
            if PROOF_HELPER_MARKER in line:
                proof_helper_hits.append({"line_number": line_number, "line": stripped})
            if GOOGLE_FLOW_NOTE in line:
                google_flow_note_hits.append({"line_number": line_number, "line": stripped})
            if GOOGLE_FLOW_HELPER in line:
                google_flow_helper_hits.append({"line_number": line_number, "line": stripped})
            if GOOGLE_ENTRYPOINT_HELPER in line:
                google_entrypoint_hits.append({"line_number": line_number, "line": stripped})

        raw_count += len(raw_hits)
        wrapper_count += len(wrapper_hits)
        wrapper_sidecar_count += sum(1 for hit in wrapper_hits if hit["mentions_sidecars"])
        google_wrapper_sidecar_count += sum(
            1 for hit in wrapper_hits if hit["mentions_sidecars"] and hit["mentions_google_style"]
        )
        proof_note_count += len(proof_note_hits)
        proof_surface_check_count += len(proof_surface_hits)
        proof_helper_count += len(proof_helper_hits)
        google_flow_note_count += len(google_flow_note_hits)
        google_flow_helper_count += len(google_flow_helper_hits)
        google_entrypoint_helper_count += len(google_entrypoint_hits)

        file_results.append(
            {
                "path": str(path),
                "display_path": relative_path,
                "raw_python_reference_count": len(raw_hits),
                "raw_python_references": raw_hits,
                "wrapper_reference_count": len(wrapper_hits),
                "wrapper_references": wrapper_hits,
                "proof_note_reference_count": len(proof_note_hits),
                "proof_note_references": proof_note_hits,
                "proof_surface_check_count": len(proof_surface_hits),
                "proof_surface_checks": proof_surface_hits,
                "proof_helper_count": len(proof_helper_hits),
                "proof_helpers": proof_helper_hits,
                "google_flow_note_reference_count": len(google_flow_note_hits),
                "google_flow_note_references": google_flow_note_hits,
                "google_flow_helper_count": len(google_flow_helper_hits),
                "google_flow_helpers": google_flow_helper_hits,
                "google_entrypoint_helper_count": len(google_entrypoint_hits),
                "google_entrypoint_helpers": google_entrypoint_hits,
            }
        )

    return {
        "repo_root": str(repo_root),
        "file_count": len(file_results),
        "raw_python_reference_count": raw_count,
        "wrapper_reference_count": wrapper_count,
        "wrapper_sidecar_reference_count": wrapper_sidecar_count,
        "google_wrapper_sidecar_reference_count": google_wrapper_sidecar_count,
        "proof_note_reference_count": proof_note_count,
        "proof_surface_check_count": proof_surface_check_count,
        "proof_helper_count": proof_helper_count,
        "google_flow_note_reference_count": google_flow_note_count,
        "google_flow_helper_count": google_flow_helper_count,
        "google_entrypoint_helper_count": google_entrypoint_helper_count,
        "files": file_results,
    }


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
    if audit["proof_note_reference_count"] == 0:
        reasons.append("replay notes do not keep the pinned bundle proof note visible")
    if audit["proof_surface_check_count"] == 0:
        reasons.append("replay notes do not keep the pinned bundle proof surface checker visible")
    if audit["proof_helper_count"] == 0:
        reasons.append("replay notes do not keep the pinned bundle proof helper visible")
    if audit["google_flow_note_reference_count"] == 0:
        reasons.append("replay notes do not keep the Google attached-html flow note visible")
    if audit["google_flow_helper_count"] == 0:
        reasons.append("replay notes do not keep the Google attached-html flow helper visible")
    if audit["google_entrypoint_helper_count"] == 0:
        reasons.append("replay notes do not keep the issue-specific Google attached-html entrypoint visible")
    return reasons


def render_text(audit: dict[str, object], reasons: list[str]) -> str:
    lines = [
        "Issue #3 Replay Note Launcher Contract",
        "",
        f"Repo root: {audit['repo_root']}",
        f"Files scanned: {audit['file_count']}",
        f"Raw Python references: {audit['raw_python_reference_count']}",
        f"Wrapper references: {audit['wrapper_reference_count']}",
        f"Wrapper sidecar references: {audit['wrapper_sidecar_reference_count']}",
        f"Google-style wrapper sidecar references: {audit['google_wrapper_sidecar_reference_count']}",
        f"Pinned proof note references: {audit['proof_note_reference_count']}",
        f"Pinned proof checker references: {audit['proof_surface_check_count']}",
        f"Pinned proof helper references: {audit['proof_helper_count']}",
        f"Google flow note references: {audit['google_flow_note_reference_count']}",
        f"Google flow helper references: {audit['google_flow_helper_count']}",
        f"Google entrypoint references: {audit['google_entrypoint_helper_count']}",
        "",
    ]

    for file_result in audit["files"]:
        lines.append(f"File: {file_result['display_path']}")
        lines.append(f"  Raw Python references: {file_result['raw_python_reference_count']}")
        lines.append(f"  Wrapper references: {file_result['wrapper_reference_count']}")
        lines.append(f"  Pinned proof note references: {file_result['proof_note_reference_count']}")
        lines.append(f"  Pinned proof checker references: {file_result['proof_surface_check_count']}")
        lines.append(f"  Pinned proof helper references: {file_result['proof_helper_count']}")
        lines.append(f"  Google flow note references: {file_result['google_flow_note_reference_count']}")
        lines.append(f"  Google flow helper references: {file_result['google_flow_helper_count']}")
        lines.append(f"  Google entrypoint references: {file_result['google_entrypoint_helper_count']}")
        for hit in file_result["raw_python_references"][:5]:
            lines.append(f"  Raw line {hit['line_number']}: {hit['line']}")
        for hit in file_result["wrapper_references"][:5]:
            lines.append(f"  Wrapper line {hit['line_number']}: {hit['line']}")
        for hit in file_result["proof_note_references"][:3]:
            lines.append(f"  Proof note line {hit['line_number']}: {hit['line']}")
        for hit in file_result["proof_surface_checks"][:3]:
            lines.append(f"  Proof check line {hit['line_number']}: {hit['line']}")
        for hit in file_result["proof_helpers"][:3]:
            lines.append(f"  Proof helper line {hit['line_number']}: {hit['line']}")
        for hit in file_result["google_flow_note_references"][:3]:
            lines.append(f"  Google note line {hit['line_number']}: {hit['line']}")
        for hit in file_result["google_flow_helpers"][:3]:
            lines.append(f"  Google flow line {hit['line_number']}: {hit['line']}")
        for hit in file_result["google_entrypoint_helpers"][:3]:
            lines.append(f"  Google entry line {hit['line_number']}: {hit['line']}")
        lines.append("")

    for reason in reasons:
        lines.append(f"FAIL: {reason}")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Fail if the issue #3 replay notes drift away from the wrapper-backed launcher, "
            "the pinned proof route, or the dedicated Google attached-html replay surface."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Repo root that contains the replay-note docs.")
    parser.add_argument(
        "--path",
        action="append",
        dest="paths",
        help="Explicit replay-note path to inspect. Repeat to override the default note trio.",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of the text report.")
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