import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`",
        "purpose": "The replay-attached quickstart keeps the pinned bundle proof companion note visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the proof-entrypoint surface checker visible before the proof-only follow-up is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "purpose": "The replay-attached quickstart keeps the proof-entrypoint helper visible beside the compact bundle route.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the launcher companion surface checker visible before the sidecar-first route is reused.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'",
        "purpose": "The replay-attached quickstart keeps the launcher companion helper visible with an attached-page input path.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments",
        "purpose": "The replay-attached helper keeps the compact bundle-suite surface wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_pages_launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay-attached helper keeps the launcher companion surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments",
        "purpose": "The replay-attached helper keeps the launcher companion helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "Write-Host ((\"  Bundle suite surface:     {0}\") -f $helper.commands.attached_bundle_suite_surface)",
        "purpose": "The replay-attached helper prints the compact bundle-suite surface before the route narrows into bundle-first follow-up.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "Write-Host ((\"  Launcher surface check:   {0}\") -f $helper.commands.attached_pages_launcher_companion_surface_check)",
        "purpose": "The replay-attached helper prints the launcher companion surface checker in its attached-page ladder output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "Write-Host ((\"  Launcher companion:       {0}\") -f $helper.commands.attached_pages_launcher_companion)",
        "purpose": "The replay-attached helper prints the launcher companion helper in its attached-page ladder output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "Use attached_bundle_suite_surface when the replay is already close to the known three-page compatibility bundle but you still want the compact suite-level surface printed before the narrower bundle-first helper or the delegated bundle flow takes over.",
        "purpose": "The replay-attached helper notes preserve when to prefer the compact bundle-suite surface before the narrower bundle-first branch.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_replay_attached_quickstart_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Windows Replay Attached HTML Quickstart Audit",
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
        description="Audit the replay-attached quickstart note and helper for launcher-companion and bundle-proof route drift."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_replay_attached_quickstart_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())