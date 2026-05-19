import argparse
import importlib.util
import json
import shlex
from pathlib import Path
from types import ModuleType


DEFAULT_BIND = "127.0.0.1"
DEFAULT_PORT = 8235


def load_launcher_module(repo_root: Path) -> ModuleType:
    launcher_path = repo_root / "tmp-browser-smoke" / "attached-pages" / "start_attached_pages_catalog.py"
    if not launcher_path.is_file():
        raise FileNotFoundError(f"attached pages launcher not found: {launcher_path}")

    spec = importlib.util.spec_from_file_location("start_attached_pages_catalog", launcher_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"could not load attached pages launcher from {launcher_path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def select_inputs(
    repo_root: Path,
    *,
    explicit_inputs: list[str] | None = None,
    google_style: bool = False,
    launcher_module: ModuleType | None = None,
) -> tuple[ModuleType, list[Path]]:
    module = launcher_module or load_launcher_module(repo_root)
    selected_files = module.select_attached_html_inputs(
        repo_root,
        explicit_inputs=explicit_inputs,
        google_style=google_style,
    )
    return module, selected_files


def choose_preferred_manifest_entry(
    manifest: list[dict[str, str]],
    *,
    selected_files: list[Path],
    launcher_module: ModuleType,
) -> dict[str, str] | None:
    if not selected_files:
        return None

    return launcher_module.find_manifest_entry_for_path(
        manifest,
        selected_files[0],
        selected_files=selected_files,
    )


def build_route_url(bind: str, port: int, route: str) -> str:
    if not route.startswith("/"):
        route = f"/{route}"
    return f"http://{bind}:{port}{route}"


def shell_join(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def build_command_hints(
    repo_root: Path,
    *,
    selected_files: list[Path],
    google_style: bool,
    bind: str,
    port: int,
) -> dict[str, str]:
    launcher_rel = Path("tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py")
    preflight_rel = Path("tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py")

    common_flags = ["--repo-root", str(repo_root)]
    if google_style:
        common_flags.append("--google-style")
    common_flags.extend(["--bind", bind, "--port", str(port)])
    for path in selected_files:
        common_flags.extend(["--input", str(path)])

    preflight_parts = ["python", str(preflight_rel), *common_flags]
    launch_parts = ["python", str(launcher_rel), *common_flags]

    return {
        "preflight_report_command": shell_join(preflight_parts),
        "sidecar_audit_command": shell_join([*launch_parts, "--audit-sidecars"]),
        "asset_audit_command": shell_join([*launch_parts, "--audit-assets"]),
        "manifest_command": shell_join([*launch_parts, "--print-manifest"]),
        "launch_command": shell_join(launch_parts),
    }


def choose_recommended_command(
    recommended_next_step: str,
    command_hints: dict[str, str],
) -> str:
    if recommended_next_step == "restore-missing-sidecar-bundles":
        return command_hints["sidecar_audit_command"]
    if recommended_next_step == "restore-missing-local-assets":
        return command_hints["asset_audit_command"]
    return command_hints["manifest_command"]


def assemble_preflight_report(
    repo_root: Path,
    *,
    selected_files: list[Path],
    google_style: bool,
    bind: str,
    port: int,
    launcher_module: ModuleType,
    sidecar_module: ModuleType,
    server_module: ModuleType,
) -> dict[str, object]:
    manifest = server_module.build_manifest(selected_files=selected_files)
    sidecar_audit = sidecar_module.build_sidecar_audit(selected_files=selected_files)
    asset_audit = server_module.build_asset_audit(selected_files=selected_files)

    preferred_manifest_entry = choose_preferred_manifest_entry(
        manifest,
        selected_files=selected_files,
        launcher_module=launcher_module,
    )

    missing_sidecars = int(sidecar_audit["fixtures_with_missing_sidecars"])
    missing_assets = int(asset_audit["fixtures_with_missing_assets"])
    selected_fixture_lines = launcher_module.describe_fixture_selection(
        selected_files,
        repo_root=repo_root,
        google_style=google_style,
    )

    if missing_sidecars > 0:
        recommended_next_step = "restore-missing-sidecar-bundles"
    elif missing_assets > 0:
        recommended_next_step = "restore-missing-local-assets"
    else:
        recommended_next_step = "print-manifest-or-start-server"

    command_hints = build_command_hints(
        repo_root,
        selected_files=selected_files,
        google_style=google_style,
        bind=bind,
        port=port,
    )
    recommended_command = choose_recommended_command(recommended_next_step, command_hints)

    return {
        "repo_root": str(repo_root),
        "google_style": google_style,
        "bind": bind,
        "port": port,
        "catalog_url": build_route_url(bind, port, "/"),
        "manifest_url": build_route_url(bind, port, "/manifest.json"),
        "audit_json_url": build_route_url(bind, port, "/audit.json"),
        "audit_text_url": build_route_url(bind, port, "/audit.txt"),
        "input_count": len(selected_files),
        "selected_fixtures": [str(path) for path in selected_files],
        "selected_fixture_lines": selected_fixture_lines,
        "fixture_count": len(manifest),
        "preferred_display_path": preferred_manifest_entry["file"] if preferred_manifest_entry else None,
        "preferred_title": preferred_manifest_entry["title"] if preferred_manifest_entry else None,
        "preferred_route": preferred_manifest_entry["route"] if preferred_manifest_entry else None,
        "preferred_alias_route": preferred_manifest_entry["alias_route"] if preferred_manifest_entry else None,
        "preferred_named_route": preferred_manifest_entry["slug_route"] if preferred_manifest_entry else None,
        "preferred_url": build_route_url(bind, port, f"{preferred_manifest_entry['route']}/")
        if preferred_manifest_entry
        else None,
        "preferred_alias_url": build_route_url(bind, port, f"{preferred_manifest_entry['alias_route']}/")
        if preferred_manifest_entry
        else None,
        "preferred_named_url": build_route_url(bind, port, f"{preferred_manifest_entry['slug_route']}/")
        if preferred_manifest_entry
        else None,
        "missing_sidecar_fixture_count": missing_sidecars,
        "missing_asset_fixture_count": missing_assets,
        "fixtures_with_external_assets": int(asset_audit["fixtures_with_external_assets"]),
        "ready_for_launch": missing_sidecars == 0 and missing_assets == 0,
        "recommended_next_step": recommended_next_step,
        "recommended_command": recommended_command,
        "command_hints": command_hints,
        "sidecar_audit": sidecar_audit,
        "asset_audit": asset_audit,
        "manifest": manifest,
    }


def build_preflight_report(
    repo_root: Path,
    *,
    explicit_inputs: list[str] | None = None,
    google_style: bool = False,
    bind: str = DEFAULT_BIND,
    port: int = DEFAULT_PORT,
) -> dict[str, object]:
    launcher_module, selected_files = select_inputs(
        repo_root,
        explicit_inputs=explicit_inputs,
        google_style=google_style,
    )
    sidecar_module = launcher_module.load_sidecar_module(repo_root)
    server_module = launcher_module.load_server_module(repo_root)
    return assemble_preflight_report(
        repo_root,
        selected_files=selected_files,
        google_style=google_style,
        bind=bind,
        port=port,
        launcher_module=launcher_module,
        sidecar_module=sidecar_module,
        server_module=server_module,
    )


def exit_code_for_report(
    report: dict[str, object],
    *,
    allow_missing_sidecars: bool = False,
    allow_missing_assets: bool = False,
) -> int:
    if report["missing_sidecar_fixture_count"] > 0 and not allow_missing_sidecars:
        return 1
    if report["missing_asset_fixture_count"] > 0 and not allow_missing_assets:
        return 1
    return 0


def render_text_report(report: dict[str, object]) -> str:
    lines = [
        "Attached Pages Preflight Report",
        "",
        f"Repo root: {report['repo_root']}",
        f"Google-style ranking: {'enabled' if report['google_style'] else 'disabled'}",
        f"Inputs pinned: {report['input_count']}",
        f"Manifest pages: {report['fixture_count']}",
        f"Missing-sidecar fixtures: {report['missing_sidecar_fixture_count']}",
        f"Missing-asset fixtures: {report['missing_asset_fixture_count']}",
        f"Fixtures with external assets: {report['fixtures_with_external_assets']}",
        f"Ready for launch: {'yes' if report['ready_for_launch'] else 'no'}",
        f"Recommended next step: {report['recommended_next_step']}",
        f"Recommended command: {report['recommended_command']}",
        f"Catalog URL: {report['catalog_url']}",
        f"Manifest URL: {report['manifest_url']}",
        f"Audit JSON URL: {report['audit_json_url']}",
        f"Audit text URL: {report['audit_text_url']}",
    ]
    if report["preferred_route"] is not None:
        lines.append(f"Preferred fixture: {report['preferred_display_path']}")
        lines.append(f"Preferred title: {report['preferred_title']}")
        lines.append(f"Preferred route: {report['preferred_route']}/")
        lines.append(f"Preferred alias route: {report['preferred_alias_route']}/")
        lines.append(f"Preferred named route: {report['preferred_named_route']}/")
        lines.append(f"Preferred URL: {report['preferred_url']}")
        lines.append(f"Preferred alias URL: {report['preferred_alias_url']}")
        lines.append(f"Preferred named URL: {report['preferred_named_url']}")
    lines.extend(
        [
            "",
            "Command hints:",
            f"- rerun preflight: {report['command_hints']['preflight_report_command']}",
            f"- sidecar audit: {report['command_hints']['sidecar_audit_command']}",
            f"- asset audit: {report['command_hints']['asset_audit_command']}",
            f"- manifest: {report['command_hints']['manifest_command']}",
            f"- launch catalog: {report['command_hints']['launch_command']}",
            "",
        ]
    )
    lines.extend(report["selected_fixture_lines"])
    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Summarize whether an attached-pages bundle is ready for manifest printing or localhost launch."
    )
    parser.add_argument(
        "--input",
        action="append",
        dest="explicit_inputs",
        help="Explicit HTML file or directory to include. Repeat to pin the report to selected inputs.",
    )
    parser.add_argument("--repo-root", help="Override the Lightpanda repo root.")
    parser.add_argument("--bind", default=DEFAULT_BIND, help="Address that the localhost catalog will bind to. Defaults to 127.0.0.1.")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="TCP port that the localhost catalog will use. Defaults to 8235.")
    parser.add_argument(
        "--google-style",
        action="store_true",
        help="Prefer the strongest Google-like attached page first when auto-discovering fixtures.",
    )
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of the text summary.")
    parser.add_argument(
        "--allow-missing-sidecars",
        action="store_true",
        help="Return success even when some selected fixtures are missing sibling _files bundles.",
    )
    parser.add_argument(
        "--allow-missing-assets",
        action="store_true",
        help="Return success even when some selected fixtures still have missing local assets.",
    )
    args = parser.parse_args(argv)

    explicit_repo_root = Path(args.repo_root) if args.repo_root else None
    if explicit_repo_root is not None:
        repo_root = explicit_repo_root.expanduser().resolve()
    else:
        repo_root = Path(__file__).resolve().parents[2]
    report = build_preflight_report(
        repo_root,
        explicit_inputs=args.explicit_inputs,
        google_style=args.google_style,
        bind=args.bind,
        port=args.port,
    )

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(render_text_report(report), end="")

    return exit_code_for_report(
        report,
        allow_missing_sidecars=args.allow_missing_sidecars,
        allow_missing_assets=args.allow_missing_assets,
    )


if __name__ == "__main__":
    raise SystemExit(main())