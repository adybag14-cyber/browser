import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md",
        "snippet": "4. `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`\n   Next helper:\n   `powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_google_attached_html_entrypoint.ps1`",
        "purpose": "The written next-step matrix keeps the google-attached-html route pinned to the issue-specific entrypoint helper.",
    },
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md",
        "snippet": "- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md` for the Google-shaped attached-page bridge that stays available before the route collapses into the narrower issue `#3` helpers",
        "purpose": "The written next-step matrix keeps the Google attached-page companion note visible beside the narrower issue-specific branch.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_next_steps.ps1",
        "snippet": "start_point = 'show_headed_validation_suites.ps1 -ChangeArea google-attached-html'",
        "purpose": "The executable matrix still exposes the dedicated google-attached-html branch.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_next_steps.ps1",
        "snippet": "default_next_helper = 'show_google_issue3_google_attached_html_entrypoint.ps1'",
        "purpose": "The executable matrix keeps the google-attached-html branch routed to the issue-specific entrypoint helper.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_next_steps.ps1",
        "snippet": "command = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments",
        "purpose": "The executable matrix still prints the issue-specific Google attached-page helper command.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_next_steps.ps1",
        "snippet": "google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'",
        "purpose": "The executable matrix still surfaces the Google attached-page companion note path.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    if root is None:
        root_path = Path.cwd()
    else:
        root_path = Path(root)
    resolved = root_path.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_suite_router_audit(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    missing_count = 0

    for expectation in EXPECTATIONS:
        full_path = repo_root / expectation["path"]
        if not full_path.is_file():
            exists = False
            actual = None
        else:
            actual = full_path.read_text(encoding="utf-8", errors="ignore")
            exists = expectation["snippet"] in actual

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
        "Google Issue #3 Suite-Router Next-Steps Audit",
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
        description="Audit the google-attached-html route in the issue #3 suite-router next-steps note and helper."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_suite_router_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
