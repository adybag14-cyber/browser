import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars",
        "purpose": "The Windows full-use attached-html catalog quickstart keeps the wrapper-backed sidecar audit visible as the first attached-pages preflight step.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars",
        "purpose": "The Windows full-use attached-html catalog quickstart keeps the Google-style wrapper-backed sidecar audit visible for Google-shaped follow-up.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -AuditSidecars",
        "purpose": "The Windows full-use attached-html catalog quickstart preserves the repo-root-aware wrapper-backed sidecar audit for pinned bundle inputs.",
    },
    {
        "path": "tmp-browser-smoke/attached-pages/README.md",
        "snippet": "The intended order is sidecars first, broader asset audit second, manifest or server startup last.",
        "purpose": "The attached-pages launcher guide keeps the sidecar-first replay order aligned with the Windows-first catalog route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "recommended_next_key = 'attached_pages_sidecar_audit'",
        "purpose": "The Windows-first catalog helper keeps the wrapper-backed sidecar audit as its default next step.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand",
        "purpose": "The Windows-first catalog helper wires the wrapper-backed sidecar audit into its helper command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "attached_pages_google_sidecar_audit = $attachedPagesGoogleSidecarAuditCommand",
        "purpose": "The Windows-first catalog helper wires the Google-style wrapper-backed sidecar audit into its helper command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "attached_pages_asset_audit = $attachedPagesAssetAuditCommand",
        "purpose": "The Windows-first catalog helper wires the wrapper-backed asset audit into its helper command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "attached_pages_print_manifest = $attachedPagesManifestPrintCommand",
        "purpose": "The Windows-first catalog helper wires the wrapper-backed manifest print into its helper command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "attached_pages_strict_launch = $attachedPagesStrictLaunchCommand",
        "purpose": "The Windows-first catalog helper wires the strict sidecar-gated wrapper launch into its helper command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "Write-Host ((\" 10. Sidecar audit:         {0}\") -f $entrypoint.helper_commands.attached_pages_sidecar_audit)",
        "purpose": "The Windows-first catalog helper prints the wrapper-backed sidecar audit in the surfaced command ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "Write-Host ((\" 11. Asset audit:           {0}\") -f $entrypoint.helper_commands.attached_pages_asset_audit)",
        "purpose": "The Windows-first catalog helper prints the wrapper-backed asset audit in the surfaced command ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "Write-Host ((\" 12. Print manifest:        {0}\") -f $entrypoint.helper_commands.attached_pages_print_manifest)",
        "purpose": "The Windows-first catalog helper prints the wrapper-backed manifest step in the surfaced command ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "Write-Host ((\" 13. Strict launch:         {0}\") -f $entrypoint.helper_commands.attached_pages_strict_launch)",
        "purpose": "The Windows-first catalog helper prints the strict sidecar-gated wrapper launch in the surfaced command ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "snippet": "Write-Host ((\" 26. Google sidecars:       {0}\") -f $entrypoint.helper_commands.attached_pages_google_sidecar_audit)",
        "purpose": "The Windows-first catalog helper prints the Google-style wrapper-backed sidecar audit in the surfaced command ladder.",
    },
)


def build_catalog_quickstart_audit(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    for expectation in EXPECTATIONS:
        path = repo_root / expectation["path"]
        exists = path.is_file() and expectation["snippet"] in path.read_text(encoding="utf-8")
        results.append(
            {
                "path": expectation["path"],
                "purpose": expectation["purpose"],
                "exists": exists,
                "snippet": expectation["snippet"],
            }
        )

    missing_count = sum(1 for result in results if not result["exists"])
    return {
        "profile": "google-issue3-windows-full-use-attached-html-catalog-quickstart",
        "repo_root": str(repo_root),
        "checked_count": len(results),
        "missing_count": missing_count,
        "results": results,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit the issue #3 Windows full-use attached-html catalog quickstart contract."
    )
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    audit = build_catalog_quickstart_audit(args.repo_root)
    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print("Google issue #3 Windows full-use attached HTML catalog quickstart audit")
        print(f"Repo root: {audit['repo_root']}")
        for result in audit["results"]:
            status = "PASS" if result["exists"] else "FAIL"
            print(f"[{status}] {result['path']}")
            print(f"  {result['purpose']}")
        if audit["missing_count"] == 0:
            print("Catalog quickstart contract is intact.")
        else:
            print(
                f"Missing {audit['missing_count']} catalog quickstart contract snippet(s)."
            )

    return 0 if audit["missing_count"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
