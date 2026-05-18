import argparse
import json
from pathlib import Path

import attached_pages_sidecar_audit as sidecar_audit


def build_missing_sidecar_summary(root: Path | None = None, *, selected_files: list[Path] | None = None) -> dict[str, object]:
    audit = sidecar_audit.build_sidecar_audit(root, selected_files=selected_files)
    missing_fixtures: list[dict[str, object]] = []

    for fixture in audit["fixtures"]:
        missing_sidecars = fixture["missing_sidecar_directories"]
        if not missing_sidecars:
            continue
        missing_fixtures.append(
            {
                "path": fixture["path"],
                "display_path": fixture["display_path"],
                "missing_sidecar_count": fixture["missing_sidecar_directory_count"],
                "missing_sidecar_dirs": [entry["sidecar_dir"] for entry in missing_sidecars],
                "referenced_asset_count": sum(entry["referenced_asset_count"] for entry in missing_sidecars),
            }
        )

    return {
        "bundle_root": audit["bundle_root"],
        "fixture_count": audit["fixture_count"],
        "fixtures_with_missing_sidecars": audit["fixtures_with_missing_sidecars"],
        "missing_fixtures": missing_fixtures,
    }


def render_text_report(summary: dict[str, object]) -> str:
    lines = [
        "Attached Pages Missing Sidecar Summary",
        "",
        f"Bundle root: {summary['bundle_root']}",
        f"Fixtures inspected: {summary['fixture_count']}",
        f"Fixtures with missing sidecars: {summary['fixtures_with_missing_sidecars']}",
        "",
    ]
    if not summary["missing_fixtures"]:
        lines.append("All inspected fixtures still have their referenced sidecar directories.")
        return "\n".join(lines).rstrip() + "\n"

    for fixture in summary["missing_fixtures"]:
        lines.append(f"Fixture: {fixture['display_path']}")
        lines.append(f"Missing sidecar directories: {fixture['missing_sidecar_count']}")
        lines.append(f"Referenced assets behind missing sidecars: {fixture['referenced_asset_count']}")
        for sidecar_dir in fixture["missing_sidecar_dirs"]:
            lines.append(f"- {sidecar_dir}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Print a compact list of attached HTML exports whose referenced sibling _files directories are missing."
    )
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument("--root", help="Directory or single HTML file to inspect.")
    input_group.add_argument(
        "--input",
        action="append",
        dest="selected_files",
        help="Explicit HTML export to inspect. Repeat to pin the summary to a file list.",
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
    summary = build_missing_sidecar_summary(root, selected_files=selected_files)

    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print(render_text_report(summary), end="")

    if summary["fixtures_with_missing_sidecars"] > 0 and not args.allow_missing_sidecars:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())