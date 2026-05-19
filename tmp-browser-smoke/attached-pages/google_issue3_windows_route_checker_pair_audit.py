import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "purpose": "The Windows full-use attached HTML route note keeps its route-level fail-fast checker visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1",
        "purpose": "The Windows full-use attached HTML route note keeps the catalog-level checker visible before the narrower ladder is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "purpose": "The Windows full-use attached HTML route note keeps the replay attached-HTML quickstart helper visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars",
        "purpose": "The Windows full-use attached HTML route note keeps the wrapper-backed sidecar audit visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "purpose": "The replay attached HTML quickstart note keeps the launcher companion checker visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'",
        "purpose": "The replay attached HTML quickstart note keeps the launcher companion helper visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
        "purpose": "The replay attached HTML quickstart note keeps the pinned proof-route checker visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "purpose": "The replay attached HTML quickstart note keeps the pinned proof-route helper visible.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "snippet": "(New-ValidationReference -Path \"docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md\" -Kind \"file\" -Purpose \"Replay-side attached-page quickstart note kept beside the broader Windows full-use route.\")",
        "purpose": "The Windows full-use route checker keeps the replay attached HTML quickstart note in its guarded surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "snippet": "(New-ValidationReference -Path \"scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1\" -Kind \"file\" -Purpose \"Replay-side attached-page quickstart helper referenced by the newer Windows replay route notes.\")",
        "purpose": "The Windows full-use route checker keeps the replay attached HTML quickstart helper in its guarded surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "snippet": "start_attached_pages_catalog.ps1 -InputPath ''<attached-html-root>'' -AuditSidecars",
        "purpose": "The Windows full-use route checker enforces the wrapper-backed sidecar audit contract in the route note.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "snippet": "(New-ValidationReference -Path \"scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1\" -Kind \"file\" -Purpose \"Fail-fast launcher companion checker that should stay visible once the replay helper surfaces the sidecar-first attached-pages route.\")",
        "purpose": "The replay attached HTML quickstart checker keeps the launcher companion checker in its guarded surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "snippet": "(New-ValidationReference -Path \"scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1\" -Kind \"file\" -Purpose \"Launcher companion helper that keeps the wrapper-backed sidecar audit route and the pinned proof-only bundle follow-up visible from the replay ladder.\")",
        "purpose": "The replay attached HTML quickstart checker keeps the launcher companion helper in its guarded surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "snippet": "(New-ValidationReference -Path \"scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1\" -Kind \"file\" -Purpose \"Proof-entrypoint surface checker surfaced directly from the replay-side ladder when proof-only bundle follow-up matters.\")",
        "purpose": "The replay attached HTML quickstart checker keeps the pinned proof-route checker in its guarded surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "snippet": "(New-ValidationReference -Path \"scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1\" -Kind \"file\" -Purpose \"Proof-entrypoint helper surfaced directly from the replay-side ladder when proof-only bundle follow-up matters.\")",
        "purpose": "The replay attached HTML quickstart checker keeps the pinned proof-route helper in its guarded surface.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_route_checker_pair_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Windows Route Checker Pair Audit",
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
        description="Audit the issue #3 Windows replay/full-use route checker pair for Linux-side drift checks."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_route_checker_pair_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())