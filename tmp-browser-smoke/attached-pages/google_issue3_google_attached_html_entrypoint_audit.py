import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars",
        "purpose": "The Google attached-html entrypoint note keeps the sidecar-bundle audit visible before deeper asset checks.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
        "purpose": "The Google attached-html entrypoint note keeps the issue-specific surface checker visible before the route narrows again.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1",
        "purpose": "The Google attached-html entrypoint note keeps the issue-specific helper visible in its default route.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
        "purpose": "The Google attached-html entrypoint note keeps the compact bundle-suite helper visible when the pinned three-page bundle is already in play.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_sidecar_audit = $googleAttachedHtmlSidecarAuditCommand",
        "purpose": "The entrypoint helper keeps the sidecar-bundle audit wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "broader_google_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_attached_html_validation_surface.ps1' -Arguments $googleAttachedHtmlSurfaceCheckArguments",
        "purpose": "The entrypoint helper keeps the broader Google-shaped surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_asset_closure = Format-HelperCommand -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments $googleAttachedHtmlAssetAuditArguments -Switches @('GoogleStyle')",
        "purpose": "The entrypoint helper keeps the deeper local asset-closure audit wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -RepoRootOverride $RepoRoot",
        "purpose": "The entrypoint helper keeps the issue-specific surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_validation_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments",
        "purpose": "The entrypoint helper keeps the broader Google attached-page validation flow wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleArguments",
        "purpose": "The entrypoint helper keeps the compact bundle-suite helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments",
        "purpose": "The entrypoint helper keeps the bundle-first route wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  6. Sidecar audit:        {0}") -f $entrypoint.helper_commands.google_attached_html_sidecar_audit)',
        "purpose": "The entrypoint helper prints the sidecar-bundle audit in its top-level bridge output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  9. Issue-specific check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)',
        "purpose": "The entrypoint helper prints the issue-specific surface checker in its top-level bridge output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host ((" 10. Google attached flow: {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)',
        "purpose": "The entrypoint helper prints the broader Google attached-page flow in its top-level bridge output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  15. Bundle suite helper:  {0}") -f $entrypoint.helper_commands.attached_bundle_suite_surface)',
        "purpose": "The entrypoint helper prints the compact bundle-suite helper before the narrower bundle-first branch.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  16. Bundle first:         {0}") -f $entrypoint.helper_commands.attached_bundle_first)',
        "purpose": "The entrypoint helper prints the bundle-first route once inputs are pinned to the known three-page compatibility bundle.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "Use google_attached_html_surface_check when the replay is already narrowed to the issue-specific attached-page route and you want the dedicated fail-fast entrypoint surface reprinted after the sidecar audit, broader Google-shaped surface check, and asset audit but before the broader flow helper or its downstream runner handoff.",
        "purpose": "The entrypoint helper notes preserve when to rerun the issue-specific surface checker.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "Use attached_bundle_change_area, attached_bundle_suite_surface, or attached_bundle_first when the current saved or attached pages are already the known three-page compatibility bundle and that pinned branch should stay visible before widening back into the broader issue #3 helpers.",
        "purpose": "The entrypoint helper notes preserve when to keep the compact bundle-suite helper visible before the narrower bundle-first branch.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_google_attached_entrypoint_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Google Attached HTML Entrypoint Audit",
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
        description="Audit the Google attached-html entrypoint note and helper for sidecar, surface-check, and bundle-route drift."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_google_attached_entrypoint_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())