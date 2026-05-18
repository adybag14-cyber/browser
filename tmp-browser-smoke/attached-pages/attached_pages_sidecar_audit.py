import argparse
import json
import os
import re
from pathlib import Path


HTML_EXPORT_EXTENSIONS = {".html", ".htm"}
QUOTED_VALUE_PATTERN = re.compile(r'["\']([^"\']+)["\']')


def normalize_inputs(root: Path | None = None, selected_files: list[Path] | None = None) -> tuple[Path, list[Path]]:
    if selected_files:
        resolved_files: list[Path] = []
        seen: set[Path] = set()
        for candidate in selected_files:
            resolved = Path(candidate).expanduser().resolve()
            if not resolved.is_file():
                raise FileNotFoundError(f"selected HTML file does not exist: {resolved}")
            if resolved.suffix.lower() not in HTML_EXPORT_EXTENSIONS:
                raise ValueError(f"selected file is not an attached HTML export (.html or .htm): {resolved}")
            if resolved in seen:
                continue
            seen.add(resolved)
            resolved_files.append(resolved)
        if not resolved_files:
            raise ValueError("selected HTML file list must not be empty")
        common_root = (
            resolved_files[0].parent
            if len(resolved_files) == 1
            else Path(os.path.commonpath([str(path.parent) for path in resolved_files]))
        )
        return common_root, resolved_files

    if root is None:
        raise ValueError("either a bundle root or selected HTML files are required")

    resolved_root = Path(root).expanduser().resolve()
    if resolved_root.is_file() and resolved_root.suffix.lower() in HTML_EXPORT_EXTENSIONS:
        return resolved_root.parent, [resolved_root]
    if resolved_root.is_dir():
        html_files = sorted(
            path for path in resolved_root.rglob("*") if path.is_file() and path.suffix.lower() in HTML_EXPORT_EXTENSIONS
        )
        return resolved_root, html_files
    raise FileNotFoundError(f"bundle root does not exist: {resolved_root}")


def build_sidecar_audit(root: Path | None = None, *, selected_files: list[Path] | None = None) -> dict[str, object]:
    bundle_root, html_files = normalize_inputs(root, selected_files)
    fixture_results: list[dict[str, object]] = []
    fixtures_with_missing_sidecars = 0

    for html_path in html_files:
        text = html_path.read_text(encoding="utf-8", errors="ignore")
        rel_path = html_path.relative_to(bundle_root).as_posix()
        references_by_dir: dict[str, set[str]] = {}
        for raw_reference in QUOTED_VALUE_PATTERN.findall(text):
            if "_files/" not in raw_reference:
                continue
            normalized = raw_reference.lstrip("./")
            if "/" not in normalized:
                continue
            sidecar_dir, remainder = normalized.split("/", 1)
            if not sidecar_dir.endswith("_files") or not remainder:
                continue
            references_by_dir.setdefault(sidecar_dir, set()).add(remainder)

        sidecar_entries: list[dict[str, object]] = []
        for sidecar_dir in sorted(references_by_dir):
            expected_dir = html_path.parent / sidecar_dir
            referenced_assets = sorted(references_by_dir[sidecar_dir])
            exists = expected_dir.is_dir()
            sidecar_entries.append(
                {
                    "sidecar_dir": sidecar_dir,
                    "expected_path": expected_dir.as_posix(),
                    "exists": exists,
                    "referenced_asset_count": len(referenced_assets),
                    "sample_assets": referenced_assets[:10],
                }
            )

        missing_sidecars = [entry for entry in sidecar_entries if not entry["exists"]]
        if missing_sidecars:
            fixtures_with_missing_sidecars += 1

        fixture_results.append(
            {
                "path": str(html_path),
                "display_path": rel_path,
                "sidecar_directories": sidecar_entries,
                "sidecar_directory_count": len(sidecar_entries),
                "missing_sidecar_directories": missing_sidecars,
                "missing_sidecar_directory_count": len(missing_sidecars),
            }
        )

    return {
        "bundle_root": str(bundle_root),
        "fixture_count": len(fixture_results),
        "fixtures_with_missing_sidecars": fixtures_with_missing_sidecars,
        "fixtures": fixture_results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Attached Pages Sidecar Audit",
        "",
        f"Bundle root: {audit['bundle_root']}",
        f"Fixtures: {audit['fixture_count']}",
        f"Fixtures with missing sidecars: {audit['fixtures_with_missing_sidecars']}",
        "",
    ]
    for fixture in audit["fixtures"]:
        lines.append(f"Fixture: {fixture['display_path']}")
        if fixture["sidecar_directory_count"] == 0:
            lines.append("Sidecar directories referenced: none")
            lines.append("")
            continue
        lines.append(f"Sidecar directories referenced: {fixture['sidecar_directory_count']}")
        for entry in fixture["sidecar_directories"]:
            status = "present" if entry["exists"] else "missing"
            lines.append(
                f"- {entry['sidecar_dir']} ({status}, referenced assets: {entry['referenced_asset_count']})"
            )
            for sample in entry["sample_assets"][:3]:
                lines.append(f"  sample: {sample}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Report whether attached HTML exports still have their expected sibling _files directories."
    )
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument("--root", help="Directory or single HTML file to inspect.")
    input_group.add_argument(
        "--input",
        action="append",
        dest="selected_files",
        help="Explicit HTML export to inspect. Repeat to pin the audit to a file list.",
    )
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of the text report.")
    parser.add_argument(
        "--allow-missing-sidecars",
        action="store_true",
        help="Return success even when one or more expected sidecar directories are missing.",
    )
    args = parser.parse_args()

    selected_files = [Path(path) for path in args.selected_files] if args.selected_files else None
    root = Path(args.root) if args.root else None
    audit = build_sidecar_audit(root, selected_files=selected_files)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    if audit["fixtures_with_missing_sidecars"] > 0 and not args.allow_missing_sidecars:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())