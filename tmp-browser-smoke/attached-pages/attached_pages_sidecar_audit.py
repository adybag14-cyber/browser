import argparse
import json
import os
import re
from pathlib import Path, PurePosixPath
from urllib.parse import unquote, urlsplit


HTML_EXPORT_EXTENSIONS = {".html", ".htm"}
QUOTED_VALUE_PATTERN = re.compile(r'["\']([^"\']+)["\']')
REFERENCE_PATTERNS = (
    re.compile(r"\b(?:src|href|poster)\s*=\s*['\"]([^'\"]+)['\"]", re.IGNORECASE),
    re.compile(r"\bsrcset\s*=\s*['\"]([^'\"]+)['\"]", re.IGNORECASE),
    re.compile(r"@import\s+(?:url\()?['\"]?([^\"')\s;]+)", re.IGNORECASE),
    re.compile(r"url\(\s*['\"]?([^\"')]+)['\"]?\s*\)", re.IGNORECASE),
)


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


def build_input_error_audit(
    root: Path | None,
    selected_files: list[Path] | None,
    error_type: str,
    error: FileNotFoundError | ValueError,
) -> dict[str, object]:
    bundle_root = ""
    if root is not None:
        bundle_root = str(Path(root).expanduser().resolve(strict=False))
    elif selected_files:
        bundle_root = str(Path(selected_files[0]).expanduser().resolve(strict=False))
    return {
        "bundle_root": bundle_root,
        "fixture_count": 0,
        "fixtures_with_missing_sidecars": 0,
        "missing_sidecar_path_count": 0,
        "missing_sidecar_paths": [],
        "fixtures": [],
        "error_type": error_type,
        "error": str(error),
    }


def extract_reference_candidates(text: str) -> list[str]:
    candidates: list[str] = []
    seen: set[str] = set()

    def add_candidate(value: str) -> None:
        stripped = value.strip()
        if not stripped or stripped in seen:
            return
        seen.add(stripped)
        candidates.append(stripped)

    for pattern in REFERENCE_PATTERNS:
        for match in pattern.finditer(text):
            value = match.group(1)
            if "srcset" in pattern.pattern:
                for entry in value.split(","):
                    candidate = entry.strip().split()[0] if entry.strip() else ""
                    if candidate:
                        add_candidate(candidate)
            else:
                add_candidate(value)

    for raw_reference in QUOTED_VALUE_PATTERN.findall(text):
        if "," in raw_reference:
            continue
        add_candidate(raw_reference)

    return candidates


def parse_sidecar_reference(reference: str) -> tuple[PurePosixPath, str, PurePosixPath] | None:
    stripped = reference.strip()
    if not stripped or "_files/" not in stripped:
        return None
    if stripped.startswith(("data:", "javascript:", "mailto:", "tel:", "#")):
        return None

    parts = urlsplit(stripped)
    if parts.scheme or parts.netloc:
        return None

    raw_path = unquote(parts.path.strip())
    if not raw_path or "_files/" not in raw_path:
        return None

    candidate_path = PurePosixPath(raw_path.lstrip("/")) if raw_path.startswith("/") else PurePosixPath(raw_path)
    segments = [segment for segment in candidate_path.parts if segment not in ("", ".")]
    for index, segment in enumerate(segments):
        if segment == "..":
            continue
        if not segment.endswith("_files"):
            continue
        asset_segments = [part for part in segments[index + 1 :] if part not in ("", ".", "..")]
        if not asset_segments:
            return None
        reference_dir = PurePosixPath(*segments[: index + 1])
        return reference_dir, segment, PurePosixPath(*asset_segments)
    return None


def resolve_expected_sidecar_dir(bundle_root: Path, html_path: Path, reference_dir: PurePosixPath, reference: str) -> Path:
    parsed = urlsplit(reference.strip())
    raw_path = unquote(parsed.path.strip())
    if raw_path.startswith("/"):
        resolved_dir = (bundle_root / reference_dir.as_posix()).resolve(strict=False)
    else:
        resolved_dir = (html_path.parent / reference_dir.as_posix()).resolve(strict=False)
    return resolved_dir


def build_sidecar_audit(root: Path | None = None, *, selected_files: list[Path] | None = None) -> dict[str, object]:
    bundle_root, html_files = normalize_inputs(root, selected_files)
    fixture_results: list[dict[str, object]] = []
    fixtures_with_missing_sidecars = 0
    missing_sidecar_summary: dict[str, dict[str, object]] = {}

    for html_path in html_files:
        text = html_path.read_text(encoding="utf-8", errors="ignore")
        rel_path = html_path.relative_to(bundle_root).as_posix()
        references_by_dir: dict[str, dict[str, object]] = {}
        for raw_reference in extract_reference_candidates(text):
            parsed_reference = parse_sidecar_reference(raw_reference)
            if parsed_reference is None:
                continue
            reference_dir, sidecar_dir, asset_path = parsed_reference
            key = reference_dir.as_posix()
            bucket = references_by_dir.setdefault(
                key,
                {
                    "sidecar_dir": sidecar_dir,
                    "reference_dir": key,
                    "assets": set(),
                    "expected_path": resolve_expected_sidecar_dir(bundle_root, html_path, reference_dir, raw_reference),
                },
            )
            bucket["assets"].add(asset_path.as_posix())

        sidecar_entries: list[dict[str, object]] = []
        for reference_dir in sorted(references_by_dir):
            entry = references_by_dir[reference_dir]
            expected_dir = entry["expected_path"]
            referenced_assets = sorted(entry["assets"])
            exists = expected_dir.is_dir()
            sidecar_entries.append(
                {
                    "sidecar_dir": entry["sidecar_dir"],
                    "reference_dir": reference_dir,
                    "expected_path": expected_dir.as_posix(),
                    "exists": exists,
                    "referenced_asset_count": len(referenced_assets),
                    "sample_assets": referenced_assets[:10],
                }
            )

        missing_sidecars = [entry for entry in sidecar_entries if not entry["exists"]]
        if missing_sidecars:
            fixtures_with_missing_sidecars += 1
            for entry in missing_sidecars:
                summary = missing_sidecar_summary.setdefault(
                    entry["expected_path"],
                    {
                        "expected_path": entry["expected_path"],
                        "sidecar_dir": entry["sidecar_dir"],
                        "fixtures": set(),
                        "assets": set(),
                    },
                )
                summary["fixtures"].add(rel_path)
                summary["assets"].update(entry["sample_assets"])

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

    missing_sidecar_paths = []
    for expected_path in sorted(missing_sidecar_summary):
        entry = missing_sidecar_summary[expected_path]
        fixtures = sorted(entry["fixtures"])
        missing_sidecar_paths.append(
            {
                "expected_path": expected_path,
                "sidecar_dir": entry["sidecar_dir"],
                "missing_fixture_count": len(fixtures),
                "first_missing_fixture": fixtures[0],
                "sample_assets": sorted(entry["assets"])[:10],
            }
        )

    return {
        "bundle_root": str(bundle_root),
        "fixture_count": len(fixture_results),
        "fixtures_with_missing_sidecars": fixtures_with_missing_sidecars,
        "missing_sidecar_path_count": len(missing_sidecar_paths),
        "missing_sidecar_paths": missing_sidecar_paths,
        "fixtures": fixture_results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    if audit.get("error_type"):
        return "\n".join(
            [
                "Attached Pages Sidecar Audit",
                "",
                f"Bundle root: {audit['bundle_root']}",
                f"Error: {audit['error_type']}",
                str(audit["error"]),
                "",
            ]
        )

    lines = [
        "Attached Pages Sidecar Audit",
        "",
        f"Bundle root: {audit['bundle_root']}",
        f"Fixtures: {audit['fixture_count']}",
        f"Fixtures with missing sidecars: {audit['fixtures_with_missing_sidecars']}",
        "",
    ]
    if audit["missing_sidecar_paths"]:
        lines.append("Missing sidecar paths:")
        for entry in audit["missing_sidecar_paths"]:
            lines.append(f"- {entry['expected_path']} ({entry['missing_fixture_count']} fixtures)")
            lines.append(f"  first fixture: {entry['first_missing_fixture']}")
            for sample in entry["sample_assets"][:3]:
                lines.append(f"  sample: {sample}")
        lines.append("")
    for fixture in audit["fixtures"]:
        lines.append(f"Fixture: {fixture['display_path']}")
        if fixture["sidecar_directory_count"] == 0:
            lines.append("Sidecar directories referenced: none")
            lines.append("")
            continue
        lines.append(f"Sidecar directories referenced: {fixture['sidecar_directory_count']}")
        for entry in fixture["sidecar_directories"]:
            status = "present" if entry["exists"] else "missing"
            lines.append(f"- {entry['sidecar_dir']} ({status}, referenced assets: {entry['referenced_asset_count']})")
            for sample in entry["sample_assets"][:3]:
                lines.append(f"  sample: {sample}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
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
    args = parser.parse_args(argv)

    selected_files = [Path(path) for path in args.selected_files] if args.selected_files else None
    root = Path(args.root) if args.root else None
    try:
        audit = build_sidecar_audit(root, selected_files=selected_files)
    except FileNotFoundError as error:
        audit = build_input_error_audit(root, selected_files, "repo_root_not_found", error)
    except ValueError as error:
        audit = build_input_error_audit(root, selected_files, "invalid_input", error)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    if audit.get("error_type"):
        return 1
    if audit["fixtures_with_missing_sidecars"] > 0 and not args.allow_missing_sidecars:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())