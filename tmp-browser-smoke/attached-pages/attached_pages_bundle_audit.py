import argparse
import json
from pathlib import Path

import attached_pages_server as server_module
import attached_pages_sidecar_audit as sidecar_module


def render_text_report(sidecar_audit: dict[str, object], asset_audit: dict[str, object]) -> str:
    return (
        "Attached Pages Bundle Audit\n\n"
        + sidecar_module.render_text_report(sidecar_audit).rstrip()
        + "\n\n"
        + server_module.render_asset_audit_text(asset_audit)
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run both sibling-sidecar and local-asset audits for an attached HTML bundle."
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
        help="Return success even when expected sibling _files directories are missing.",
    )
    parser.add_argument(
        "--allow-missing-assets",
        action="store_true",
        help="Return success even when referenced local assets are missing.",
    )
    args = parser.parse_args()

    selected_files = [Path(path) for path in args.selected_files] if args.selected_files else None
    root = Path(args.root) if args.root else None

    sidecar_audit = sidecar_module.build_sidecar_audit(root, selected_files=selected_files)
    asset_audit = server_module.build_asset_audit(root, selected_files=selected_files)

    if args.json:
        print(
            json.dumps(
                {
                    "sidecars": sidecar_audit,
                    "assets": asset_audit,
                },
                indent=2,
            )
        )
    else:
        print(render_text_report(sidecar_audit, asset_audit), end="")

    if sidecar_audit["fixtures_with_missing_sidecars"] > 0 and not args.allow_missing_sidecars:
        return 1
    if asset_audit["fixtures_with_missing_assets"] > 0 and not args.allow_missing_assets:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
