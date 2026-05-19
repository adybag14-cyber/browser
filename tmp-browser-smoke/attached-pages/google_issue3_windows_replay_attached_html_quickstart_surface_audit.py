import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
        "purpose": "The replay-attached quickstart keeps the pinned proof note visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the launcher-companion checker visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'",
        "purpose": "The replay-attached quickstart keeps the launcher-companion helper visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the proof checker visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "purpose": "The replay-attached quickstart keeps the proof helper visible.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "snippet": '(New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md"',
        "purpose": "The PowerShell surface checker tracks the proof note as a required reference.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "snippet": '(New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1"',
        "purpose": "The PowerShell surface checker tracks the launcher-companion checker as a required reference.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "snippet": '(New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1"',
        "purpose": "The PowerShell surface checker tracks the launcher-companion helper as a required reference.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "snippet": '(New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet \'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md\'',
        "purpose": "The PowerShell surface checker fails if the replay note drops the proof note.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "snippet": "show_google_issue3_attached_pages_launcher_companion.ps1",
        "purpose": "The PowerShell surface checker fails if the replay note drops the launcher-companion helper route.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "snippet": "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "purpose": "The PowerShell surface checker fails if the replay note or helper drops the proof helper route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_pages_launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay helper wires the launcher-companion checker into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments",
        "purpose": "The replay helper wires the launcher-companion helper into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_bundle_proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay helper wires the proof checker into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments",
        "purpose": "The replay helper wires the proof helper into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host ((\"  Launcher surface check:   {0}\") -f $helper.commands.attached_pages_launcher_companion_surface_check)',
        "purpose": "The replay helper prints the launcher-companion checker command.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host ((\"  Launcher companion:       {0}\") -f $helper.commands.attached_pages_launcher_companion)',
        "purpose": "The replay helper prints the launcher-companion helper command.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host ((\"  Bundle proof check:       {0}\") -f $helper.commands.attached_bundle_proof_surface_check)',
        "purpose": "The replay helper prints the proof checker command.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host ((\"  Bundle proof helper:      {0}\") -f $helper.commands.attached_bundle_proof_entrypoint)',
        "purpose": "The replay helper prints the proof helper command.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_surface_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Windows Replay Attached HTML Quickstart Surface Audit",
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
        description="Audit the issue #3 Windows replay attached-html quickstart surface from Linux."
    )
    parser.add_argument("--repo-root", help="Repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_surface_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())