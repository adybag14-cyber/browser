import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/WINDOWS_FULL_USE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath \"<saved-html-or-folder>\" -AuditSidecars",
        "purpose": "The Windows full-use runbook keeps the wrapper-backed sidecar audit visible before attached-page replay is blamed.",
    },
    {
        "path": "docs/WINDOWS_FULL_USE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
        "purpose": "The Windows full-use runbook keeps the pinned bundle bridge visible before the route narrows into the locked three-page branch.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1",
        "purpose": "The Windows full-use attached HTML route note keeps the catalog checker visible before the narrower Windows-first ladder is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "purpose": "The Windows full-use attached HTML route note keeps the replay-attached quickstart visible beside the broader Windows-first ladder.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars",
        "purpose": "The Windows full-use attached HTML route note keeps the wrapper-backed sidecar audit surfaced in the attached-page follow-up ladder.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'",
        "purpose": "The Windows full-use attached HTML route note keeps the compact attached-bundle suite surface visible before the replay narrows into the locked three-page branch.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "windows_full_use_attached_html_route_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -RepoRootOverride $RepoRoot",
        "purpose": "The route helper keeps the route-level fail-fast checker wired into its helper map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "windows_full_use_attached_html_catalog_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1' -RepoRootOverride $RepoRoot",
        "purpose": "The route helper keeps the catalog-level fail-fast checker wired into its helper map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments",
        "purpose": "The route helper keeps the replay-attached quickstart wired into its helper map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $browserAwareBundleArguments",
        "purpose": "The route helper keeps the compact attached-bundle suite surface wired into its helper map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": "attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $browserAwareBundleArguments",
        "purpose": "The route helper keeps the bundle-first helper wired into its helper map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": 'Write-Host (("  Surface checker:          {0}") -f $route.helper_commands.windows_full_use_attached_html_route_surface_check)',
        "purpose": "The route helper prints the route-level fail-fast checker in its summary output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": 'Write-Host (("  4. Windows catalog qk:    {0}") -f $route.helper_commands.windows_full_use_attached_html_catalog_quickstart)',
        "purpose": "The route helper prints the Windows-first catalog quickstart in its route ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": 'Write-Host (("  5. Replay attached qk:    {0}") -f $route.helper_commands.windows_replay_attached_html_quickstart)',
        "purpose": "The route helper prints the replay-attached quickstart in its route ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": 'Write-Host ((" 13. Bundle suite surface:  {0}") -f $route.helper_commands.attached_bundle_suite_surface)',
        "purpose": "The route helper prints the compact attached-bundle suite surface in its route ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "snippet": 'Write-Host ((" 28. Bundle-first route:    {0}") -f $route.helper_commands.attached_bundle_first)',
        "purpose": "The route helper prints the bundle-first helper in its route ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand",
        "purpose": "The Windows-first catalog helper keeps the wrapper-backed sidecar audit wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "recommended_next_key = 'attached_pages_sidecar_audit'",
        "purpose": "The Windows-first catalog helper keeps the wrapper-backed sidecar audit as the default next step.",
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
        description="Audit the issue #3 Windows full-use attached HTML route surface for Linux-side drift checks."
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