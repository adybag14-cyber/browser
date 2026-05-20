import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
        "purpose": "The note keeps the issue-specific Google attached-html checker visible before the route narrows again.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars",
        "purpose": "The note keeps the wrapper-backed Google-style sidecar audit visible before the deeper asset crawl.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1",
        "purpose": "The note keeps the broader Google attached-html surface check visible before the narrower issue-specific bridge.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle",
        "purpose": "The note keeps the deeper asset-closure audit visible on the Google-style path.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1",
        "purpose": "The note keeps the broader Google attached-html flow helper visible before the issue-specific entrypoint takes over.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1",
        "purpose": "The note keeps the issue-specific Google attached-html entrypoint visible in the default route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_sidecar_audit = $googleAttachedHtmlSidecarAuditCommand",
        "purpose": "The helper wires the wrapper-backed Google-style sidecar audit into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "broader_google_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_attached_html_validation_surface.ps1' -Arguments $googleAttachedHtmlSurfaceCheckArguments",
        "purpose": "The helper wires the broader Google attached-html surface check into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_asset_closure = Format-HelperCommand -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments $googleAttachedHtmlAssetAuditArguments -Switches @('GoogleStyle')",
        "purpose": "The helper wires the Google-style asset-closure audit into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -RepoRootOverride $RepoRoot",
        "purpose": "The helper wires the issue-specific Google attached-html checker into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_validation_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments",
        "purpose": "The helper keeps the broader Google attached-html flow helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleArguments",
        "purpose": "The helper keeps the compact bundle-suite helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments",
        "purpose": "The helper keeps the narrower bundle-first route wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  6. Sidecar audit:        {0}") -f $entrypoint.helper_commands.google_attached_html_sidecar_audit)',
        "purpose": "The helper output prints the wrapper-backed Google-style sidecar audit.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  7. Broader surface:      {0}") -f $entrypoint.helper_commands.broader_google_attached_html_surface_check)',
        "purpose": "The helper output prints the broader Google attached-html surface check.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  8. Asset closure:        {0}") -f $entrypoint.helper_commands.google_attached_html_asset_closure)',
        "purpose": "The helper output prints the deeper Google-style asset-closure audit.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  9. Issue-specific check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)',
        "purpose": "The helper output prints the issue-specific Google attached-html checker.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host ((" 10. Google attached flow: {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)',
        "purpose": "The helper output prints the broader Google attached-html flow helper.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host ((" 15. Bundle suite helper:  {0}") -f $entrypoint.helper_commands.attached_bundle_suite_surface)',
        "purpose": "The helper output prints the compact bundle-suite helper before the bundle-first branch.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host ((" 16. Bundle first:         {0}") -f $entrypoint.helper_commands.attached_bundle_first)',
        "purpose": "The helper output prints the narrower bundle-first route once inputs are pinned.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "Use google_attached_html_sidecar_audit when the current saved export may be missing its whole sibling `_files` bundle and you want that simpler failure mode ruled in or out before the broader surface check or the deeper asset audit.",
        "purpose": "The helper explains when to prefer the wrapper-backed Google-style sidecar audit first.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "Use broader_google_attached_html_surface_check when the replay is already narrowed to the Google-shaped attached-page route and you want the wider fail-fast helper surface reprinted after the sidecar audit but before the deeper asset audit or the narrower issue-specific checker.",
        "purpose": "The helper explains when to keep the broader surface check visible before narrowing again.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "Use google_attached_html_asset_closure when local asset drift might explain the current Google-shaped attached-page failure and you want the deeper asset audit reprinted after the sidecar audit and broader surface check but before the route narrows into the issue-specific checker or shortcut ladder.",
        "purpose": "The helper explains when to keep the deeper asset audit visible before narrowing again.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "Use attached_bundle_change_area, attached_bundle_suite_surface, or attached_bundle_first when the current saved or attached pages are already the known three-page compatibility bundle and that pinned branch should stay visible before widening back into the broader issue #3 helpers.",
        "purpose": "The helper explains when to keep the pinned bundle branch visible.",
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


def build_google_attached_entrypoint_audit(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    missing_count = 0
    missing_paths: dict[str, dict[str, object]] = {}

    for expectation in EXPECTATIONS:
        full_path = repo_root / expectation["path"]
        if not full_path.is_file():
            exists = False
        else:
            exists = expectation["snippet"] in full_path.read_text(
                encoding="utf-8", errors="ignore"
            )

        if not exists:
            missing_count += 1
            missing_path = missing_paths.get(expectation["path"])
            if missing_path is None:
                missing_path = {
                    "path": expectation["path"],
                    "missing_expectation_count": 0,
                    "first_missing_purpose": expectation["purpose"],
                    "missing_snippets": [],
                }
                missing_paths[expectation["path"]] = missing_path
            missing_path["missing_expectation_count"] += 1
            missing_path["missing_snippets"].append(expectation["snippet"])

        results.append(
            {
                "path": expectation["path"],
                "purpose": expectation["purpose"],
                "exists": exists,
                "snippet": expectation["snippet"],
            }
        )

    missing_path_results = list(missing_paths.values())

    return {
        "repo_root": str(repo_root),
        "expectation_count": len(results),
        "missing_count": missing_count,
        "missing_path_count": len(missing_path_results),
        "missing_paths": missing_path_results,
        "results": results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    if audit.get("error"):
        lines = [
            "Google Issue #3 Google Attached HTML Entrypoint Audit",
            "",
            f"Repo root: {audit['repo_root']}",
            f"Error: {audit['error']}",
        ]
        return "\n".join(lines).rstrip() + "\n"

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
        description=(
            "Audit the issue #3 Google attached-html entrypoint note and helper "
            "surface for Linux-side route-drift checks."
        )
    )
    parser.add_argument(
        "--repo-root",
        help="Lightpanda repo root to inspect. Defaults to the current directory.",
    )
    parser.add_argument("--json", action="store_true", help="Print JSON instead of text.")
    args = parser.parse_args(argv)

    try:
        repo_root = resolve_repo_root(args.repo_root)
        audit = build_google_attached_entrypoint_audit(repo_root)
    except FileNotFoundError as err:
        audit = build_repo_root_error_audit(args.repo_root, str(err))

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit.get("error") or audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())