import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_handoff_validation_surface.ps1",
        "purpose": "The Windows replay quickstart keeps the suite-router handoff checker visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_handoff.ps1",
        "purpose": "The Windows replay quickstart keeps the suite-router handoff helper visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "- `docs/ISSUE3_SUITE_ROUTER_HANDOFF.md`",
        "purpose": "The Windows replay quickstart keeps the written suite-router handoff note nearby.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_handoff_validation_surface.ps1",
        "purpose": "The replay-discovery handoff keeps the suite-router handoff checker visible.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_handoff.ps1",
        "purpose": "The replay-discovery handoff keeps the suite-router handoff helper visible.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1",
        "purpose": "The replay-discovery handoff keeps the replay-route shortcut checker visible beside the handoff route.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "purpose": "The replay-discovery handoff keeps the replay-route shortcut helper visible beside the handoff route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_handoff.ps1",
        "snippet": "suite_router_surface_check = $handoffSurfaceCheckCommand",
        "purpose": "The handoff helper keeps its fail-fast checker in the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_handoff.ps1",
        "snippet": "google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand",
        "purpose": "The handoff helper keeps the Google attached-html surface checker in the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_handoff.ps1",
        "snippet": "google_attached_html_flow = $googleAttachedHtmlFlowCommand",
        "purpose": "The handoff helper keeps the Google attached-html flow helper in the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_handoff.ps1",
        "snippet": "google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments",
        "purpose": "The handoff helper keeps the issue-specific Google attached-html bridge in the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_handoff.ps1",
        "snippet": 'Write-Host (("  5. Handoff surface check:         {0}") -f $handoff.bridge_sequence.suite_router_surface_check)',
        "purpose": "The read-first bridge output prints the suite-router handoff checker.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_handoff.ps1",
        "snippet": 'Write-Host (("  6. Google attached surface check: {0}") -f $handoff.bridge_sequence.google_attached_html_surface_check)',
        "purpose": "The read-first bridge output prints the Google attached-html surface checker.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_handoff.ps1",
        "snippet": 'Write-Host (("  7. Google attached flow:          {0}") -f $handoff.bridge_sequence.google_attached_html_flow)',
        "purpose": "The read-first bridge output prints the Google attached-html flow helper.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_handoff.ps1",
        "snippet": 'Write-Host (("  9. Google attached bridge:        {0}") -f $handoff.bridge_sequence.google_attached_html_entrypoint)',
        "purpose": "The read-first bridge output prints the issue-specific Google attached-html bridge.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_suite_router_handoff_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Suite-Router Handoff Audit",
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
        description="Audit the suite-router handoff note and helper for replay-note and Google-bridge drift."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_suite_router_handoff_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())