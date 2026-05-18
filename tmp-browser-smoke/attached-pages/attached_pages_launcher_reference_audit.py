import argparse
import json
import os
from pathlib import Path


TEXT_EXTENSIONS = {".md", ".ps1", ".py", ".txt"}
RAW_LAUNCHER_NEEDLE = "start_attached_pages_catalog.py"
WRAPPER_LAUNCHER_NEEDLE = "start_attached_pages_catalog.ps1"
SIDECAR_SWITCH_NEEDLE = "AuditSidecars"
GOOGLE_STYLE_NEEDLE = "GoogleStyle"


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


def build_reference_audit(root: Path | None = None, *, selected_files: list[Path] | None = None) -> dict[str, object]:
    bundle_root, files = normalize_inputs(root, selected_files)
    file_results: list[dict[str, object]] = []
    files_with_raw_launcher = 0
    raw_reference_count = 0
    wrapper_reference_count = 0
    wrapper_sidecar_reference_count = 0
    google_wrapper_sidecar_reference_count = 0

    for path in files:
        text = path.read_text(encoding="utf-8", errors="ignore")
        relative_path = path.relative_to(bundle_root).as_posix()
        raw_lines: list[dict[str, object]] = []
        wrapper_lines: list[dict[str, object]] = []

        for line_number, line in enumerate(text.splitlines(), start=1):
            if RAW_LAUNCHER_NEEDLE in line:
                raw_lines.append({"line_number": line_number, "line": line.rstrip()})
            if WRAPPER_LAUNCHER_NEEDLE in line:
                wrapper_line = {
                    "line_number": line_number,
                    "line": line.rstrip(),
                    "mentions_sidecars": SIDECAR_SWITCH_NEEDLE in line,
                    "mentions_google_style": GOOGLE_STYLE_NEEDLE in line,
                }
                wrapper_lines.append(wrapper_line)

        raw_reference_count += len(raw_lines)
        wrapper_reference_count += len(wrapper_lines)
        wrapper_sidecar_reference_count += sum(1 for line in wrapper_lines if line["mentions_sidecars"])
        google_wrapper_sidecar_reference_count += sum(
            1 for line in wrapper_lines if line["mentions_sidecars"] and line["mentions_google_style"]
        )

        if raw_lines:
            files_with_raw_launcher += 1

        file_results.append(
            {
                "path": str(path),
                "display_path": relative_path,
                "raw_python_references": raw_lines,
                "raw_python_reference_count": len(raw_lines),
                "wrapper_references": wrapper_lines[:20],
                "wrapper_reference_count": len(wrapper_lines),
            }
        )

    return {
        "root": str(bundle_root),
        "file_count": len(file_results),
        "files_with_raw_python": files_with_raw_launcher,
        "raw_python_reference_count": raw_reference_count,
        "wrapper_reference_count": wrapper_reference_count,
        "wrapper_sidecar_reference_count": wrapper_sidecar_reference_count,
        "google_wrapper_sidecar_reference_count": google_wrapper_sidecar_reference_count,
        "files": file_results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Attached Pages Launcher Reference Audit",
        "",
        f"Root: {audit['root']}",
        f"Files scanned: {audit['file_count']}",
        f"Files with raw Python launcher references: {audit['files_with_raw_python']}",
        f"Raw Python launcher references: {audit['raw_python_reference_count']}",
        f"Wrapper references: {audit['wrapper_reference_count']}",
        f"Wrapper sidecar references: {audit['wrapper_sidecar_reference_count']}",
        f"Google-style wrapper sidecar references: {audit['google_wrapper_sidecar_reference_count']}",
        "",
    ]

    for file_result in audit["files"]:
        if not file_result["raw_python_reference_count"] and not file_result["wrapper_reference_count"]:
            continue
        lines.append(f"File: {file_result['display_path']}")
        if file_result["raw_python_reference_count"]:
            lines.append(f"Raw Python references: {file_result['raw_python_reference_count']}")
            for entry in file_result["raw_python_references"][:5]:
                lines.append(f"  line {entry['line_number']}: {entry['line']}")
        else:
            lines.append("Raw Python references: 0")
        if file_result["wrapper_reference_count"]:
            lines.append(f"Wrapper references: {file_result['wrapper_reference_count']}")
        else:
            lines.append("Wrapper references: 0")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Report stale raw-Python attached-pages launcher references and wrapper-backed sidecar coverage."
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
        "--allow-raw-launcher",
        action="store_true",
        help="Return success even when raw Python launcher references remain.",
    )
    args = parser.parse_args()

    selected_files = [Path(path) for path in args.selected_files] if args.selected_files else None
    root = Path(args.root) if args.root else None
    audit = build_reference_audit(root, selected_files=selected_files)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    if audit["raw_python_reference_count"] > 0 and not args.allow_raw_launcher:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())