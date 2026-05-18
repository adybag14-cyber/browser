import argparse
import json
from pathlib import Path

import attached_pages_server as server_module


STATUS_OFFLINE_READY = "offline-ready"
STATUS_MISSING_LOCAL = "missing-local-assets"
STATUS_NEEDS_NETWORK = "needs-network"
STATUS_MISSING_AND_NETWORK = "missing-local-assets-and-needs-network"


def classify_fixture(fixture: dict[str, object]) -> str:
    has_missing = int(fixture["missing_asset_count"]) > 0
    has_external = int(fixture["external_asset_count"]) > 0
    if has_missing and has_external:
        return STATUS_MISSING_AND_NETWORK
    if has_missing:
        return STATUS_MISSING_LOCAL
    if has_external:
        return STATUS_NEEDS_NETWORK
    return STATUS_OFFLINE_READY


def build_offline_readiness(root: Path | None = None, *, selected_files: list[Path] | None = None) -> dict[str, object]:
    audit = server_module.build_asset_audit(root, selected_files=selected_files)
    fixtures: list[dict[str, object]] = []

    for fixture in audit["fixtures"]:
        status = classify_fixture(fixture)
        fixtures.append(
            {
                "display_path": fixture["display_path"],
                "status": status,
                "missing_asset_count": fixture["missing_asset_count"],
                "external_asset_count": fixture["external_asset_count"],
                "missing_assets_preview": fixture["missing_assets"][:5],
                "external_assets_preview": fixture["external_assets"][:5],
            }
        )

    offline_ready = (
        int(audit["fixtures_with_missing_assets"]) == 0
        and int(audit["fixtures_with_external_assets"]) == 0
    )

    return {
        "bundle_root": audit["bundle_root"],
        "fixture_count": audit["fixture_count"],
        "fixtures_with_missing_assets": audit["fixtures_with_missing_assets"],
        "fixtures_with_external_assets": audit["fixtures_with_external_assets"],
        "offline_ready": offline_ready,
        "fixtures": fixtures,
    }


def render_offline_readiness_text(summary: dict[str, object]) -> str:
    lines = [
        "Attached Pages Offline Readiness",
        "",
        f"Bundle root: {summary['bundle_root']}",
        f"Fixtures: {summary['fixture_count']}",
        f"Fixtures with missing local assets: {summary['fixtures_with_missing_assets']}",
        f"Fixtures with external assets: {summary['fixtures_with_external_assets']}",
        f"Offline ready: {'yes' if summary['offline_ready'] else 'no'}",
        "",
    ]

    for fixture in summary["fixtures"]:
        lines.append(f"Fixture: {fixture['display_path']}")
        lines.append(f"Status: {fixture['status']}")
        lines.append(f"Missing local assets: {fixture['missing_asset_count']}")
        lines.append(f"External assets: {fixture['external_asset_count']}")
        if fixture["missing_assets_preview"]:
            for asset in fixture["missing_assets_preview"]:
                lines.append(f"- missing: {asset}")
        if fixture["external_assets_preview"]:
            for asset in fixture["external_assets_preview"]:
                lines.append(f"- external: {asset}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check whether an attached HTML bundle is self-contained enough for offline localhost replay."
    )
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument("--root", help="Directory or single HTML file to inspect.")
    input_group.add_argument(
        "--input",
        action="append",
        dest="selected_files",
        help="Explicit HTML export to inspect. Repeat to pin the check to a file list.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print structured JSON instead of the text summary.",
    )
    args = parser.parse_args()

    selected_files = [Path(path) for path in args.selected_files] if args.selected_files else None
    root = Path(args.root) if args.root else None

    summary = build_offline_readiness(root, selected_files=selected_files)
    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print(render_offline_readiness_text(summary), end="")

    return 0 if summary["offline_ready"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
