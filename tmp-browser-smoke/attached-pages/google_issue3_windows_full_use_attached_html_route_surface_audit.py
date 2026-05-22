import argparse
import json
from collections import defaultdict
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $googleAttachedHtmlChangeAreaArguments -RepoRootOverride $RepoRoot",
        "purpose": "The route helper keeps the Google-shaped attached-page change-area bridge wired into its top-level command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedBundleChangeAreaArguments -RepoRootOverride $RepoRoot",
        "purpose": "The route helper keeps the pinned bundle change-area bridge wired into its top-level command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "suite_router_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_quickstart.ps1' -Arguments $bundleArguments",
        "purpose": "The route helper keeps the issue-level quickstart bridge wired into its helper map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $bundleArguments",
        "purpose": "The route helper keeps the validation-router attached-page quickstart wired into its helper map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments",
        "purpose": "The route helper keeps the top-level attached-page catalog quickstart wired into its helper map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments",
        "purpose": "The route helper keeps the shortest attached-page shortcut bridge wired into its helper map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments",
        "purpose": "The route helper keeps the context-preserving replay bridge wired into its helper map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments",
        "purpose": "The route helper keeps the safe-route map wired into its helper map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "Write-Host ((\"  Catalog checker:          {0}\") -f $route.helper_commands.windows_full_use_attached_html_catalog_surface_check)",
        "purpose": "The route helper prints the catalog-level guard before narrowing into the Windows-first ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "Write-Host ((\" 11. Validation-router qk:  {0}\") -f $route.helper_commands.validation_router_attached_html_quickstart)",
        "purpose": "The route helper keeps the validation-router attached-page quickstart visible in the numbered route ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "Write-Host ((\" 17. Catalog quickstart:    {0}\") -f $route.helper_commands.top_level_attached_html_catalog_quickstart)",
        "purpose": "The route helper keeps the top-level attached-page catalog quickstart visible in the numbered route ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "Write-Host ((\" 23. Attached shortcut:     {0}\") -f $route.helper_commands.attached_html_shortcut)",
        "purpose": "The route helper keeps the short attached-page shortcut visible in the numbered route ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "Write-Host ((\" 26. Contextual flow:       {0}\") -f $route.helper_commands.contextual_flow)",
        "purpose": "The route helper keeps the context-preserving replay bridge visible in the numbered route ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "Write-Host ((\" 27. Safe-route map:        {0}\") -f $route.helper_commands.safe_route_entrypoints)",
        "purpose": "The route helper keeps the safe-route map visible in the numbered route ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "Write-Host ((\"Validation bridge note:       {0}\") -f $route.windows_full_use_validation_router_attached_html_bridge_note_path)",
        "purpose": "The route helper prints the validation-bridge note path beside the ladder output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "Write-Host ((\"Bundle suite note:            {0}\") -f $route.attached_html_target_bundle_suite_surface_note_path)",
        "purpose": "The route helper prints the attached-bundle suite note path beside the ladder output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "$route.recommended_next_key = if ($route.explicit_input_path_count -gt 0) {",
        "purpose": "The route helper chooses the bundle-first recommendation when explicit attached-page inputs are already pinned.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "} elseif (-not [string]::IsNullOrWhiteSpace($route.repo_root) -or -not [string]::IsNullOrWhiteSpace($route.summary_path)) {",
        "purpose": "The route helper chooses the contextual-flow recommendation when replay context is already pinned.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "'windows_full_use_validation_router_attached_html_bridge'",
        "purpose": "The route helper falls back to the validation-router bridge when neither pinned inputs nor saved replay context are present.",
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


def build_route_surface_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Windows Full-Use Attached HTML Route Surface Audit",
        "",
        f"Repo root: {audit['repo_root']}",
    ]

    if audit.get("error_type"):
        lines.extend([f"Error: {audit['error']}", ""])
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
            lines.append(f"  - {entry['path']} ({entry['missing_expectation_count']} missing expectations)")
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
        description="Audit the richer issue #3 Windows full-use attached HTML route helper surface for Linux-side drift checks."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    try:
        repo_root = resolve_repo_root(args.repo_root)
        audit = build_route_surface_audit(repo_root)
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
