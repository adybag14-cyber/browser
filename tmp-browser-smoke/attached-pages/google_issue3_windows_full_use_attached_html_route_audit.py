import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/WINDOWS_FULL_USE.md",
        "snippet": 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -AuditSidecars',
        "purpose": "The Windows full-use runbook keeps the wrapper-backed sidecar audit visible before headed replay is blamed.",
    },
    {
        "path": "docs/WINDOWS_FULL_USE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1",
        "purpose": "The Windows full-use runbook keeps the pinned bundle bridge checker visible.",
    },
    {
        "path": "docs/WINDOWS_FULL_USE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "purpose": "The Windows full-use runbook keeps the pinned bundle bridge helper visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1",
        "purpose": "The route note keeps the catalog checker visible before the narrower Windows-first ladder is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "purpose": "The route note keeps the Windows-first catalog quickstart visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "purpose": "The route note keeps the replay-attached quickstart visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars",
        "purpose": "The route note keeps the wrapper-backed sidecar audit visible in the attached-html follow-up ladder.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'",
        "purpose": "The route note keeps the compact bundle suite surface visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'",
        "purpose": "The route note keeps the bundle-first helper visible once replay is pinned to the known three-page set.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "windows_full_use_attached_html_route_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -RepoRootOverride $RepoRoot",
        "purpose": "The route helper wires the route-level fail-fast checker into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "windows_full_use_attached_html_catalog_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1' -RepoRootOverride $RepoRoot",
        "purpose": "The route helper wires the catalog-level fail-fast checker into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments",
        "purpose": "The route helper keeps the replay-attached quickstart wired into the route stack.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot",
        "purpose": "The route helper keeps the broader attached-html flow wired into the route stack.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "google_attached_html_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments",
        "purpose": "The route helper keeps the issue-specific Google attached-html flow wired into the route stack.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments",
        "purpose": "The route helper keeps the shorter Google attached-html entrypoint wired into the route stack.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $browserAwareBundleArguments",
        "purpose": "The route helper keeps the compact bundle suite surface wired into the route stack.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $browserAwareBundleArguments",
        "purpose": "The route helper keeps the bundle-first helper wired into the route stack.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": 'Write-Host (("  1. Surface checker:       {0}") -f $route.helper_commands.windows_full_use_attached_html_route_surface_check)',
        "purpose": "The route helper prints the route-level checker in its numbered route output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": 'Write-Host (("  3. Catalog checker:       {0}") -f $route.helper_commands.windows_full_use_attached_html_catalog_surface_check)',
        "purpose": "The route helper prints the catalog-level checker in its numbered route output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": 'Write-Host (("  5. Replay attached qk:    {0}") -f $route.helper_commands.windows_replay_attached_html_quickstart)',
        "purpose": "The route helper prints the replay-attached quickstart in its numbered route output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": 'Write-Host (("  13. Bundle suite surface:  {0}") -f $route.helper_commands.attached_bundle_suite_surface)',
        "purpose": "The route helper prints the bundle suite surface in its numbered route output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": 'Write-Host (("  28. Bundle-first route:    {0}") -f $route.helper_commands.attached_bundle_first)',
        "purpose": "The route helper prints the bundle-first helper in its numbered route output.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_route_audit(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    missing_count = 0

    for expectation in EXPECTATIONS:
        full_path = repo_root / expectation["path"]
        if not full_path.is_file():
            exists = False
        else:
            exists = expectation["snippet"] in full_path.read_text(encoding="utf-8", errors="ignore")

        if not exists:
            missing_count += 1

        results.append(
            {
                "path": expectation["path"],
                "purpose": expectation["purpose"],
                "exists": exists,
                "snippet": expectation["snippet"],
            }
        )

    return {
        "repo_root": str(repo_root),
        "expectation_count": len(results),
        "missing_count": missing_count,
        "results": results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Google Issue #3 Windows Full-Use Attached HTML Route Audit",
        "",
        f"Repo root: {audit['repo_root']}",
        f"Expectations checked: {audit['expectation_count']}",
        f"Missing expectations: {audit['missing_count']}",
        "",
    ]

    for result in audit["results"]:
        status = "PASS" if result["exists"] else "FAIL"
        lines.append(f"[{status}] {result['path']}")
        lines.append(f"  {result['purpose']}")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit the issue #3 Windows full-use attached-html route for Linux-side drift checks."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_route_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
