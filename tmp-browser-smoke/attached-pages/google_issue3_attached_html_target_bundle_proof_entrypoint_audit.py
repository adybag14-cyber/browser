import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
        "snippet": "check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
        "purpose": "The proof-entrypoint note keeps the dedicated fail-fast checker visible before the proof-only route is trusted.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "snippet": "bundle_surface_check_command = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleArguments",
        "purpose": "The proof-entrypoint helper still reprints the pinned bundle surface checker before proof runs.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "snippet": "local_html_fixture_surface_check_command = Format-HelperCommand -ScriptName 'check_local_html_fixture_validation_surface.ps1' -Arguments $fixtureSurfaceArguments",
        "purpose": "The proof-entrypoint helper still reprints the fixed-list local HTML fixture checker before the screenshot-and-title probe runs.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "snippet": "bundle_suite_surface_command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $reentryArguments",
        "purpose": "The proof-entrypoint helper still keeps the compact suite-level bundle surface visible for re-entry before or after proof.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "snippet": 'Write-Host (("  Surface check: {0}") -f $entrypoint.bundle_surface_check_command)',
        "purpose": "Printed proof-entrypoint output still keeps the bundle surface checker visible before the delegated replay.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "snippet": 'Write-Host (("  Surface check: {0}") -f $entrypoint.local_html_fixture_surface_check_command)',
        "purpose": "Printed proof-entrypoint output still keeps the fixed-list proof surface checker visible before the screenshot-and-title probe.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "snippet": 'Write-Host (("  Suite surface: {0}") -f $entrypoint.bundle_suite_surface_command)',
        "purpose": "Printed proof-entrypoint output still keeps the compact suite-level bundle surface visible for nearby re-entry.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "snippet": 'Write-Host (("  Probe:         {0}") -f $entrypoint.local_html_fixture_probe_command)',
        "purpose": "Printed proof-entrypoint output still exposes the fixed-list screenshot-and-title probe command.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "snippet": "Use bundle_surface_check_command and bundle_check_command first when you want one last fail-fast confirmation that the current pages still match the known three-page compatibility bundle before you collect proof.",
        "purpose": "Usage notes preserve the fail-fast order before proof is collected.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_proof_entrypoint_audit(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    missing_count = 0

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
        "Google Issue #3 Attached HTML Target-Bundle Proof Entrypoint Audit",
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
            "Audit the issue #3 attached-html target-bundle proof entrypoint note "
            "and helper surface for Linux-side route-drift checks."
        )
    )
    parser.add_argument(
        "--repo-root",
        help="Lightpanda repo root to inspect. Defaults to the current directory.",
    )
    parser.add_argument("--json", action="store_true", help="Print JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_proof_entrypoint_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())