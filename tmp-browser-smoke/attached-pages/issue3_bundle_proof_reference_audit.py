import argparse
import json
import os
import sys
from pathlib import Path


TEXT_EXTENSIONS = {".md", ".ps1", ".py", ".txt"}
PROOF_HELPER_NEEDLE = "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"
PROOF_NOTE_NEEDLE = "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md"
BUNDLE_SURFACE_NEEDLE = "show_google_issue3_attached_html_target_bundle_suite_surface.ps1"
BUNDLE_CHECK_NEEDLE = "check_attached_html_target_bundle_validation_surface.ps1"
BUNDLE_RUNNER_NEEDLE = "run_attached_html_target_bundle_validation.ps1"


def normalize_inputs(root: Path | None = None, selected_files: list[Path] | None = None) -> tuple[Path, list[Path]]:
    if selected_files:
        resolved_files: list[Path] = []
        seen: set[Path] = set()
        for candidate in selected_files:
            resolved = candidate.expanduser().resolve()
            if not resolved.is_file():
                raise FileNotFoundError(f"selected file does not exist: {resolved}")
            if resolved.suffix.lower() not in TEXT_EXTENSIONS:
                raise ValueError(f"selected file is not a supported text source: {resolved}")
            if resolved in seen:
                continue
            seen.add(resolved)
            resolved_files.append(resolved)
        if not resolved_files:
            raise ValueError("selected file list must not be empty")
        common_root = (
            resolved_files[0].parent
            if len(resolved_files) == 1
            else Path(os.path.commonpath([str(path.parent) for path in resolved_files]))
        )
        return common_root, resolved_files

    if root is None:
        raise ValueError("either a root or selected files are required")

    resolved_root = root.expanduser().resolve()
    if resolved_root.is_file():
        if resolved_root.suffix.lower() not in TEXT_EXTENSIONS:
            raise ValueError(f"selected file is not a supported text source: {resolved_root}")
        return resolved_root.parent, [resolved_root]
    if resolved_root.is_dir():
        files = sorted(
            path
            for path in resolved_root.rglob("*")
            if path.is_file() and path.suffix.lower() in TEXT_EXTENSIONS
        )
        return resolved_root, files
    raise FileNotFoundError(f"root does not exist: {resolved_root}")


def _collect_line_matches(text: str, needle: str) -> list[dict[str, object]]:
    matches: list[dict[str, object]] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        if needle in line:
            matches.append({"line_number": line_number, "line": line.rstrip()})
    return matches


def build_reference_audit(root: Path | None = None, *, selected_files: list[Path] | None = None) -> dict[str, object]:
    bundle_root, files = normalize_inputs(root, selected_files)
    file_results: list[dict[str, object]] = []

    proof_helper_reference_count = 0
    proof_note_reference_count = 0
    bundle_surface_reference_count = 0
    bundle_check_reference_count = 0
    bundle_runner_reference_count = 0

    for path in files:
        text = path.read_text(encoding="utf-8", errors="ignore")
        relative_path = path.relative_to(bundle_root).as_posix()

        proof_helper_references = _collect_line_matches(text, PROOF_HELPER_NEEDLE)
        proof_note_references = _collect_line_matches(text, PROOF_NOTE_NEEDLE)
        bundle_surface_references = _collect_line_matches(text, BUNDLE_SURFACE_NEEDLE)
        bundle_check_references = _collect_line_matches(text, BUNDLE_CHECK_NEEDLE)
        bundle_runner_references = _collect_line_matches(text, BUNDLE_RUNNER_NEEDLE)

        proof_helper_reference_count += len(proof_helper_references)
        proof_note_reference_count += len(proof_note_references)
        bundle_surface_reference_count += len(bundle_surface_references)
        bundle_check_reference_count += len(bundle_check_references)
        bundle_runner_reference_count += len(bundle_runner_references)

        file_results.append(
            {
                "path": str(path),
                "display_path": relative_path,
                "proof_helper_references": proof_helper_references[:20],
                "proof_helper_reference_count": len(proof_helper_references),
                "proof_note_references": proof_note_references[:20],
                "proof_note_reference_count": len(proof_note_references),
                "bundle_surface_references": bundle_surface_references[:20],
                "bundle_surface_reference_count": len(bundle_surface_references),
                "bundle_check_references": bundle_check_references[:20],
                "bundle_check_reference_count": len(bundle_check_references),
                "bundle_runner_references": bundle_runner_references[:20],
                "bundle_runner_reference_count": len(bundle_runner_references),
            }
        )

    return {
        "root": str(bundle_root),
        "file_count": len(file_results),
        "proof_helper_reference_count": proof_helper_reference_count,
        "proof_note_reference_count": proof_note_reference_count,
        "bundle_surface_reference_count": bundle_surface_reference_count,
        "bundle_check_reference_count": bundle_check_reference_count,
        "bundle_runner_reference_count": bundle_runner_reference_count,
        "files": file_results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Issue #3 Bundle Proof Reference Audit",
        "",
        f"Root: {audit['root']}",
        f"Files scanned: {audit['file_count']}",
        f"Proof helper references: {audit['proof_helper_reference_count']}",
        f"Proof note references: {audit['proof_note_reference_count']}",
        f"Bundle surface references: {audit['bundle_surface_reference_count']}",
        f"Bundle surface-check references: {audit['bundle_check_reference_count']}",
        f"Bundle runner references: {audit['bundle_runner_reference_count']}",
        "",
    ]

    for file_result in audit["files"]:
        if not any(
            file_result[key]
            for key in (
                "proof_helper_reference_count",
                "proof_note_reference_count",
                "bundle_surface_reference_count",
                "bundle_check_reference_count",
                "bundle_runner_reference_count",
            )
        ):
            continue

        lines.append(f"File: {file_result['display_path']}")
        lines.append(f"Proof helper references: {file_result['proof_helper_reference_count']}")
        lines.append(f"Proof note references: {file_result['proof_note_reference_count']}")
        lines.append(f"Bundle surface references: {file_result['bundle_surface_reference_count']}")
        lines.append(f"Bundle surface-check references: {file_result['bundle_check_reference_count']}")
        lines.append(f"Bundle runner references: {file_result['bundle_runner_reference_count']}")
        for label, entries_key in (
            ("proof helper", "proof_helper_references"),
            ("proof note", "proof_note_references"),
            ("bundle surface", "bundle_surface_references"),
            ("bundle surface-check", "bundle_check_references"),
            ("bundle runner", "bundle_runner_references"),
        ):
            entries = file_result[entries_key]
            for entry in entries[:3]:
                lines.append(f"  {label} line {entry['line_number']}: {entry['line']}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def collect_failure_reasons(
    audit: dict[str, object],
    *,
    require_proof_helper: bool,
    require_proof_note: bool,
    require_bundle_surface: bool,
    require_bundle_runner: bool,
) -> list[str]:
    failure_reasons: list[str] = []
    if require_proof_helper and audit["proof_helper_reference_count"] == 0:
        failure_reasons.append("no issue #3 bundle proof helper references were found")
    if require_proof_note and audit["proof_note_reference_count"] == 0:
        failure_reasons.append("no issue #3 bundle proof note references were found")
    if require_bundle_surface and audit["bundle_surface_reference_count"] == 0:
        failure_reasons.append("no issue #3 bundle suite-surface references were found")
    if require_bundle_runner and audit["bundle_runner_reference_count"] == 0:
        failure_reasons.append("no issue #3 bundle runner references were found")
    return failure_reasons


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Report issue #3 bundle proof-route references across attached-pages notes and helpers."
    )
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument("--root", help="Directory or single text file to inspect.")
    input_group.add_argument(
        "--path",
        action="append",
        dest="selected_files",
        help="Explicit text file to inspect. Repeat to pin the audit to a file list.",
    )
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of a text report.")
    parser.add_argument(
        "--require-proof-helper",
        action="store_true",
        help="Return failure unless at least one proof-helper reference is present.",
    )
    parser.add_argument(
        "--require-proof-note",
        action="store_true",
        help="Return failure unless at least one proof-note reference is present.",
    )
    parser.add_argument(
        "--require-bundle-surface",
        action="store_true",
        help="Return failure unless at least one bundle suite-surface reference is present.",
    )
    parser.add_argument(
        "--require-bundle-runner",
        action="store_true",
        help="Return failure unless at least one bundle runner reference is present.",
    )
    args = parser.parse_args()

    selected_files = [Path(path) for path in args.selected_files] if args.selected_files else None
    root = Path(args.root) if args.root else None
    audit = build_reference_audit(root, selected_files=selected_files)
    failure_reasons = collect_failure_reasons(
        audit,
        require_proof_helper=args.require_proof_helper,
        require_proof_note=args.require_proof_note,
        require_bundle_surface=args.require_bundle_surface,
        require_bundle_runner=args.require_bundle_runner,
    )

    if args.json:
        payload = dict(audit)
        payload["failure_reasons"] = failure_reasons
        print(json.dumps(payload, indent=2))
    else:
        print(render_text_report(audit), end="")
        for reason in failure_reasons:
            print(f"FAIL: {reason}", file=sys.stderr)

    if failure_reasons:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())