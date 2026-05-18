import argparse
import json
import os
import sys
from pathlib import Path


TEXT_EXTENSIONS = {".md", ".ps1", ".py", ".txt"}
DIRECT_SIDECAR_HELPER_NEEDLE = "attached_pages_sidecar_audit.py"
WRAPPER_LAUNCHER_NEEDLE = "start_attached_pages_catalog.ps1"
SIDECAR_SWITCH_NEEDLE = "AuditSidecars"
GOOGLE_STYLE_NEEDLE = "GoogleStyle"
ALLOW_MISSING_SIDECARS_NEEDLE = "AllowMissingSidecars"


def normalize_inputs(
    root: Path | None = None, selected_files: list[Path] | None = None
) -> tuple[Path, list[Path]]:
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


def build_reference_audit(
    root: Path | None = None, *, selected_files: list[Path] | None = None
) -> dict[str, object]:
    bundle_root, files = normalize_inputs(root, selected_files)
    file_results: list[dict[str, object]] = []
    files_with_direct_sidecar_helper = 0
    direct_sidecar_helper_reference_count = 0
    wrapper_sidecar_reference_count = 0
    google_wrapper_sidecar_reference_count = 0
    allow_missing_wrapper_sidecar_reference_count = 0

    for path in files:
        text = path.read_text(encoding="utf-8", errors="ignore")
        relative_path = path.relative_to(bundle_root).as_posix()
        direct_lines: list[dict[str, object]] = []
        wrapper_lines: list[dict[str, object]] = []

        for line_number, line in enumerate(text.splitlines(), start=1):
            if DIRECT_SIDECAR_HELPER_NEEDLE in line:
                direct_lines.append({"line_number": line_number, "line": line.rstrip()})
            if WRAPPER_LAUNCHER_NEEDLE in line and SIDECAR_SWITCH_NEEDLE in line:
                wrapper_lines.append(
                    {
                        "line_number": line_number,
                        "line": line.rstrip(),
                        "mentions_google_style": GOOGLE_STYLE_NEEDLE in line,
                        "mentions_allow_missing_sidecars": ALLOW_MISSING_SIDECARS_NEEDLE in line,
                    }
                )

        file_google_wrapper_sidecar_reference_count = sum(
            1 for line in wrapper_lines if line["mentions_google_style"]
        )
        file_allow_missing_wrapper_sidecar_reference_count = sum(
            1 for line in wrapper_lines if line["mentions_allow_missing_sidecars"]
        )

        direct_sidecar_helper_reference_count += len(direct_lines)
        wrapper_sidecar_reference_count += len(wrapper_lines)
        google_wrapper_sidecar_reference_count += file_google_wrapper_sidecar_reference_count
        allow_missing_wrapper_sidecar_reference_count += (
            file_allow_missing_wrapper_sidecar_reference_count
        )

        if direct_lines:
            files_with_direct_sidecar_helper += 1

        file_results.append(
            {
                "path": str(path),
                "display_path": relative_path,
                "direct_sidecar_helper_references": direct_lines,
                "direct_sidecar_helper_reference_count": len(direct_lines),
                "wrapper_sidecar_references": wrapper_lines[:20],
                "wrapper_sidecar_reference_count": len(wrapper_lines),
                "google_wrapper_sidecar_reference_count": file_google_wrapper_sidecar_reference_count,
                "allow_missing_wrapper_sidecar_reference_count": (
                    file_allow_missing_wrapper_sidecar_reference_count
                ),
            }
        )

    return {
        "root": str(bundle_root),
        "file_count": len(file_results),
        "files_with_direct_sidecar_helper": files_with_direct_sidecar_helper,
        "direct_sidecar_helper_reference_count": direct_sidecar_helper_reference_count,
        "wrapper_sidecar_reference_count": wrapper_sidecar_reference_count,
        "google_wrapper_sidecar_reference_count": google_wrapper_sidecar_reference_count,
        "allow_missing_wrapper_sidecar_reference_count": allow_missing_wrapper_sidecar_reference_count,
        "files": file_results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Attached Pages Sidecar Reference Audit",
        "",
        f"Root: {audit['root']}",
        f"Files scanned: {audit['file_count']}",
        f"Files with direct sidecar helper references: {audit['files_with_direct_sidecar_helper']}",
        f"Direct sidecar helper references: {audit['direct_sidecar_helper_reference_count']}",
        f"Wrapper sidecar references: {audit['wrapper_sidecar_reference_count']}",
        f"Google-style wrapper sidecar references: {audit['google_wrapper_sidecar_reference_count']}",
        "Wrapper allow-missing-sidecars references: "
        f"{audit['allow_missing_wrapper_sidecar_reference_count']}",
        "",
    ]

    for file_result in audit["files"]:
        if (
            not file_result["direct_sidecar_helper_reference_count"]
            and not file_result["wrapper_sidecar_reference_count"]
        ):
            continue
        lines.append(f"File: {file_result['display_path']}")
        if file_result["direct_sidecar_helper_reference_count"]:
            lines.append(
                "Direct sidecar helper references: "
                f"{file_result['direct_sidecar_helper_reference_count']}"
            )
            for entry in file_result["direct_sidecar_helper_references"][:5]:
                lines.append(f"  line {entry['line_number']}: {entry['line']}")
        else:
            lines.append("Direct sidecar helper references: 0")
        if file_result["wrapper_sidecar_reference_count"]:
            lines.append(
                f"Wrapper sidecar references: {file_result['wrapper_sidecar_reference_count']}"
            )
            lines.append(
                "Google-style wrapper sidecar references: "
                f"{file_result['google_wrapper_sidecar_reference_count']}"
            )
            lines.append(
                "Wrapper allow-missing-sidecars references: "
                f"{file_result['allow_missing_wrapper_sidecar_reference_count']}"
            )
        else:
            lines.append("Wrapper sidecar references: 0")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def collect_failure_reasons(
    audit: dict[str, object],
    *,
    allow_direct_sidecar_helper: bool,
    require_wrapper_sidecar: bool,
    require_google_wrapper_sidecar: bool,
) -> list[str]:
    failure_reasons: list[str] = []
    if audit["direct_sidecar_helper_reference_count"] > 0 and not allow_direct_sidecar_helper:
        failure_reasons.append("direct attached-pages sidecar helper references remain")
    if require_wrapper_sidecar and audit["wrapper_sidecar_reference_count"] == 0:
        failure_reasons.append("no wrapper-backed sidecar audit references were found")
    if require_google_wrapper_sidecar and audit["google_wrapper_sidecar_reference_count"] == 0:
        failure_reasons.append("no Google-style wrapper-backed sidecar audit references were found")
    return failure_reasons


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Report stale direct attached-pages sidecar helper references and "
            "wrapper-backed sidecar audit coverage."
        )
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
        "--allow-direct-sidecar-helper",
        action="store_true",
        help="Return success even when direct sidecar helper references remain.",
    )
    parser.add_argument(
        "--require-wrapper-sidecar",
        action="store_true",
        help="Return failure unless at least one wrapper-backed sidecar audit reference is present.",
    )
    parser.add_argument(
        "--require-google-wrapper-sidecar",
        action="store_true",
        help="Return failure unless at least one Google-style wrapper-backed sidecar audit reference is present.",
    )
    args = parser.parse_args()

    selected_files = [Path(path) for path in args.selected_files] if args.selected_files else None
    root = Path(args.root) if args.root else None
    audit = build_reference_audit(root, selected_files=selected_files)
    failure_reasons = collect_failure_reasons(
        audit,
        allow_direct_sidecar_helper=args.allow_direct_sidecar_helper,
        require_wrapper_sidecar=args.require_wrapper_sidecar,
        require_google_wrapper_sidecar=args.require_google_wrapper_sidecar,
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