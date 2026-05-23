import argparse
import json
from collections import defaultdict
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/WINDOWS_FULL_USE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "purpose": "The Windows full-use runbook keeps the attached-bundle bridge visible once attached localhost replay is narrowed to the pinned three-page branch.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1",
        "purpose": "The attached-bundle bridge note keeps its own fail-fast surface checker visible before the narrower bundle route is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1",
        "purpose": "The attached-bundle bridge note keeps the broader Windows full-use attached HTML route visible for read-first re-entry.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "purpose": "The attached-bundle bridge note keeps the broader Windows-route surface checker visible beside the pinned bundle route.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1",
        "purpose": "The attached-bundle bridge note keeps the Windows-to-validation-router bridge visible before the route narrows again.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "purpose": "The attached-bundle bridge note keeps the Windows replay quickstart visible before the route locks onto the pinned bundle.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle",
        "purpose": "The attached-bundle bridge note keeps the top-level bundle change area visible when the route is rediscovered from the higher-level validation catalog.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'",
        "purpose": "The attached-bundle bridge note keeps the compact bundle-suite helper visible before the narrower bundle-first route.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_bundle_first_bridge.ps1 -InputPath '<bundle-html-or-folder>'",
        "purpose": "The attached-bundle bridge note keeps the replay-route bundle bridge visible when the replay is already inside the narrower helper family.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'",
        "purpose": "The attached-bundle bridge note keeps the bundle-first helper visible once the exact three-page bundle is confirmed.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_target_bundle_validation_flow.ps1",
        "purpose": "The attached-bundle bridge note keeps the bundle validation flow visible immediately before direct launch.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait",
        "purpose": "The attached-bundle bridge note keeps the delegated bundle runner visible for direct execution once the route is green.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": "windows_full_use_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedBrowserArguments",
        "purpose": "The bridge helper keeps the broader Windows full-use attached HTML route wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": "windows_validation_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $sharedBrowserArguments",
        "purpose": "The bridge helper keeps the Windows-to-validation-router bridge wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": "attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedBundleChangeAreaArguments -RepoRootOverride $RepoRoot",
        "purpose": "The bridge helper keeps the top-level attached bundle change area wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": "bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedBrowserArguments",
        "purpose": "The bridge helper keeps the compact bundle-suite helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": "replay_route_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_bundle_first_bridge.ps1' -Arguments $sharedBrowserArguments",
        "purpose": "The bridge helper keeps the replay-route bundle bridge wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": "bundle_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedBrowserArguments",
        "purpose": "The bridge helper keeps the bundle-first entrypoint wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": "bundle_surface_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $sharedArguments",
        "purpose": "The bridge helper keeps the pinned bundle surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": "bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleBrowserArguments",
        "purpose": "The bridge helper keeps the delegated bundle flow wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": "bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleBrowserArguments -Switches @('Wait')",
        "purpose": "The bridge helper keeps the delegated bundle runner wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": 'Write-Host (("  Bundle-suite helper:  {0}") -f $bridge.commands.bundle_suite_surface)',
        "purpose": "The bridge helper prints the compact bundle-suite helper in its read-first route output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": 'Write-Host (("  Replay bundle bridge: {0}") -f $bridge.commands.replay_route_bundle_first)',
        "purpose": "The bridge helper prints the replay-route bundle bridge in its read-first route output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": 'Write-Host (("  Bundle-first helper:  {0}") -f $bridge.commands.bundle_first_entrypoint)',
        "purpose": "The bridge helper prints the bundle-first helper in its read-first route output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": 'Write-Host (("  Bundle surface check: {0}") -f $bridge.commands.bundle_surface_check)',
        "purpose": "The bridge helper prints the bundle surface checker in its read-first route output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "snippet": 'Write-Host (("  Bundle runner:        {0}") -f $bridge.commands.bundle_runner)',
        "purpose": "The bridge helper prints the delegated bundle runner in its read-first route output.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1",
        "snippet": '(New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md" -Kind "file" -Purpose "Pinned three-page bundle bridge note for the Windows full-use route.")',
        "purpose": "The bridge surface checker verifies the pinned attached-bundle bridge note itself.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1",
        "snippet": '(New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1" -Kind "file" -Purpose "Pinned three-page bundle bridge helper for the Windows full-use route.")',
        "purpose": "The bridge surface checker verifies the attached-bundle bridge helper itself.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1",
        "snippet": '(New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact bundle-suite helper surfaced before the narrower bundle-first helper.")',
        "purpose": "The bridge surface checker verifies the compact bundle-suite helper path.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1",
        "snippet": '(New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle-aware localhost runner for the pinned three-page route.")',
        "purpose": "The bridge surface checker verifies the delegated bundle runner path.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_repo_root_error_audit(root: str | None, message: str) -> dict[str, object]:
    repo_root = str(Path.cwd()) if root is None else str(Path(root).expanduser())
    return {
        "repo_root": repo_root,
        "expectation_count": len(EXPECTATIONS),
        "missing_count": None,
        "missing_path_count": None,
        "missing_paths": [],
        "results": [],
        "error_type": "repo_root_not_found",
        "error": message,
    }


def build_bridge_audit(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    missing_count = 0
    missing_by_path: dict[str, list[dict[str, object]]] = defaultdict(list)

    for expectation in EXPECTATIONS:
        full_path = repo_root / expectation["path"]
        if not full_path.is_file():
            exists = False
        else:
            exists = expectation["snippet"] in full_path.read_text(encoding="utf-8", errors="ignore")

        result = {
            "path": expectation["path"],
            "purpose": expectation["purpose"],
            "exists": exists,
            "snippet": expectation["snippet"],
        }
        results.append(result)

        if not exists:
            missing_count += 1
            missing_by_path[expectation["path"]].append(result)

    missing_paths = [
        {
            "path": path,
            "missing_expectation_count": len(entries),
            "first_missing_purpose": entries[0]["purpose"],
            "first_missing_snippet": entries[0]["snippet"],
            "missing_snippets": [entry["snippet"] for entry in entries],
        }
        for path, entries in sorted(missing_by_path.items())
    ]

    return {
        "repo_root": str(repo_root),
        "expectation_count": len(results),
        "missing_count": missing_count,
        "missing_path_count": len(missing_paths),
        "missing_paths": missing_paths,
        "results": results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Google Issue #3 Windows Full-Use Attached Bundle Bridge Audit",
        "",
        f"Repo root: {audit['repo_root']}",
    ]

    if audit.get("error_type"):
        lines.extend(
            [
                f"Error: {audit['error']}",
                "",
            ]
        )
        return "\n".join(lines).rstrip() + "\n"

    lines.extend(
        [
            f"Expectations checked: {audit['expectation_count']}",
            f"Missing expectations: {audit['missing_count']}",
            "",
        ]
    )

    if audit["missing_paths"]:
        lines.append("Missing path summary:")
        for entry in audit["missing_paths"]:
            lines.append(
                f"  - {entry['path']} ({entry['missing_expectation_count']} missing expectations)"
            )
            lines.append(f"    First missing purpose: {entry['first_missing_purpose']}")
            lines.append(f"    First snippet: {entry['first_missing_snippet']}")
        lines.append("")

    for result in audit["results"]:
        status = "PASS" if result["exists"] else "FAIL"
        lines.append(f"[{status}] {result['path']}")
        lines.append(f"  {result['purpose']}")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit the issue #3 Windows full-use attached bundle bridge surface for drift."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    try:
        repo_root = resolve_repo_root(args.repo_root)
        audit = build_bridge_audit(repo_root)
    except FileNotFoundError as exc:
        audit = build_repo_root_error_audit(args.repo_root, str(exc))

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    if audit.get("error_type"):
        return 1

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())