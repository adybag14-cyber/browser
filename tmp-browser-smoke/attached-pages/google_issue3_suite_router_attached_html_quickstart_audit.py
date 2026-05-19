import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_attached_html_quickstart_validation_surface.ps1",
        "purpose": "The suite-router attached HTML quickstart keeps its fail-fast checker visible before the narrower route is trusted.",
    },
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --audit-sidecars --input '<attached-html-root>'",
        "purpose": "The suite-router attached HTML quickstart keeps the attached-pages sidecar audit visible before the deeper Google-specific checks.",
    },
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1",
        "purpose": "The suite-router attached HTML quickstart keeps the broader Google attached HTML surface checker visible.",
    },
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
        "purpose": "The suite-router attached HTML quickstart keeps the issue-specific Google attached HTML surface checker visible.",
    },
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
        "purpose": "The suite-router attached HTML quickstart keeps the compact bundle-suite surface visible for pinned bundle replay.",
    },
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1",
        "purpose": "The suite-router attached HTML quickstart keeps the suite-catalog guide visible before the route narrows again.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`",
        "purpose": "The replay-attached quickstart keeps the suite-router attached HTML note visible before the route narrows back into the sidecar-first branch.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1",
        "purpose": "The replay-attached quickstart keeps the suite-router attached HTML helper visible before the route narrows back into the sidecar-first branch.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1",
        "snippet": "$command = 'python .\\\\tmp-browser-smoke\\\\attached-pages\\\\start_attached_pages_catalog.py --audit-sidecars'",
        "purpose": "The helper keeps the attached-pages sidecar audit command builder wired into the compact surface.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1",
        "snippet": "attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand",
        "purpose": "The helper exposes the attached-pages sidecar audit in its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1",
        "snippet": "suite_router_attached_html_surface_check = $suiteRouterAttachedHtmlSurfaceCheckCommand",
        "purpose": "The helper exposes the suite-router attached HTML surface checker in its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1",
        "snippet": "google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand",
        "purpose": "The helper exposes the broader Google attached HTML surface checker in its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1",
        "snippet": "google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand",
        "purpose": "The helper exposes the issue-specific Google attached HTML surface checker in its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1",
        "snippet": "google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments",
        "purpose": "The helper keeps the issue-specific Google attached HTML bridge visible from the compact route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments",
        "purpose": "The replay-attached helper keeps the suite-router attached HTML helper wired into its command map before the route narrows again.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Suite-router sidecar:     {0}") -f $helper.commands.suite_router_attached_html_quickstart)',
        "purpose": "The replay-attached helper prints the suite-router attached HTML helper before the route narrows back into the sidecar-first branch.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Attached pages audit:        {0}") -f $helper.commands.attached_pages_sidecar_audit)',
        "purpose": "The broader attached-page handoff output prints the attached-pages sidecar audit.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Issue-specific Google check: {0}") -f $helper.commands.google_issue3_attached_html_surface_check)',
        "purpose": "The broader attached-page handoff output prints the issue-specific Google checker.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Google attached bridge:       {0}") -f $helper.commands.google_attached_html_entrypoint)',
        "purpose": "The attached-page follow-up output prints the issue-specific Google bridge.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_suite_router_attached_html_quickstart_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Suite-Router Attached HTML Quickstart Audit",
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
        description="Audit the suite-router attached HTML quickstart note and helper for Linux-runnable contract drift."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_suite_router_attached_html_quickstart_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())