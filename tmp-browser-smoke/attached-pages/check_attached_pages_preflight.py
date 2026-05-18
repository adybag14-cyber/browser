import argparse
import importlib.util
import json
import os
from pathlib import Path
from types import ModuleType


def resolve_repo_root(start_path: Path) -> Path:
    override = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
    if override:
        return Path(override).expanduser().resolve()

    cursor = start_path.expanduser().resolve()
    if cursor.is_file():
        cursor = cursor.parent

    while True:
        if (cursor / "build.zig").is_file():
            return cursor
        parent = cursor.parent
        if parent == cursor:
            raise FileNotFoundError(
                f"could not resolve the Lightpanda repo root from {start_path}"
            )
        cursor = parent


def load_module(name: str, path: Path) -> ModuleType:
    if not path.is_file():
        raise FileNotFoundError(f"required helper module not found: {path}")
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"could not load helper module from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_launcher_module(repo_root: Path) -> ModuleType:
    launcher_path = (
        repo_root / "tmp-browser-smoke" / "attached-pages" / "start_attached_pages_catalog.py"
    )
    return load_module("start_attached_pages_catalog", launcher_path)


def describe_selection(
    launcher: ModuleType, selected_files: list[Path], repo_root: Path, google_style: bool
) -> list[str]:
    if hasattr(launcher, "describe_fixture_selection"):
        return launcher.describe_fixture_selection(
            selected_files, repo_root=repo_root, google_style=google_style
        )

    lines = ["Selected fixtures:"]
    for path in selected_files:
        lines.append(f"- {path}")
    return lines


def build_blocking_reasons(
    sidecar_audit: dict[str, object],
    asset_audit: dict[str, object],
    *,
    allow_missing_sidecars: bool,
    allow_missing_assets: bool,
) -> list[str]:
    reasons: list[str] = []
    if sidecar_audit["fixtures_with_missing_sidecars"] > 0 and not allow_missing_sidecars:
        reasons.append("missing sidecar bundles")
    if asset_audit["fixtures_with_missing_assets"] > 0 and not allow_missing_assets:
        reasons.append("missing local assets")
    return reasons


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Run both attached-pages preflight audits in the recommended order "
            "before headed localhost replay."
        )
    )
    parser.add_argument(
        "--input",
        action="append",
        dest="explicit_inputs",
        help="Explicit HTML file or directory to include. Repeat to pin the preflight to selected inputs.",
    )
    parser.add_argument("--repo-root", help="Override the Lightpanda repo root.")
    parser.add_argument(
        "--google-style",
        action="store_true",
        help="Prefer the strongest Google-like attached page first when auto-discovering fixtures.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print structured JSON instead of the text summary.",
    )
    parser.add_argument(
        "--allow-missing-sidecars",
        action="store_true",
        help="Return success even when one or more selected fixtures are missing sibling _files directories.",
    )
    parser.add_argument(
        "--allow-missing-assets",
        action="store_true",
        help="Return success even when one or more selected fixtures still reference missing local assets.",
    )
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(
        Path(args.repo_root) if args.repo_root else Path(__file__)
    )
    launcher = load_launcher_module(repo_root)
    selected_files = launcher.select_attached_html_inputs(
        repo_root,
        explicit_inputs=args.explicit_inputs,
        google_style=args.google_style,
    )
    sidecar_module = launcher.load_sidecar_module(repo_root)
    server_module = launcher.load_server_module(repo_root)
    sidecar_audit = sidecar_module.build_sidecar_audit(selected_files=selected_files)
    asset_audit = server_module.build_asset_audit(selected_files=selected_files)
    blocking_reasons = build_blocking_reasons(
        sidecar_audit,
        asset_audit,
        allow_missing_sidecars=args.allow_missing_sidecars,
        allow_missing_assets=args.allow_missing_assets,
    )

    if args.json:
        payload = {
            "repo_root": str(repo_root),
            "google_style": args.google_style,
            "selected_fixture_count": len(selected_files),
            "selected_fixtures": [str(path) for path in selected_files],
            "sidecar_audit": sidecar_audit,
            "asset_audit": asset_audit,
            "blocking_reasons": blocking_reasons,
            "ready_for_replay": not blocking_reasons,
        }
        print(json.dumps(payload, indent=2))
        return 0 if not blocking_reasons else 1

    print("Attached pages preflight")
    print("")
    print(
        "Mode: "
        + ("explicit pinned inputs" if args.explicit_inputs else "auto-discovery")
        + (" with google-style ranking" if args.google_style else "")
    )
    print(f"Inputs pinned: {len(selected_files)}")
    print("")
    for line in describe_selection(
        launcher, selected_files, repo_root=repo_root, google_style=args.google_style
    ):
        print(line)
    print("")
    print("Sidecar audit:")
    print(sidecar_module.render_text_report(sidecar_audit).rstrip())
    print("")
    print("Asset audit:")
    print(server_module.render_asset_audit_text(asset_audit).rstrip())
    print("")
    if blocking_reasons:
        print("Replay readiness: blocked")
        print("Blocking reasons: " + ", ".join(blocking_reasons))
    else:
        print("Replay readiness: ready")
        print("Blocking reasons: none")
    return 0 if not blocking_reasons else 1


if __name__ == "__main__":
    raise SystemExit(main())
