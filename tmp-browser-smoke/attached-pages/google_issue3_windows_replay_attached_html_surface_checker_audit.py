import argparse
import json
from pathlib import Path


CHECKER_PATH = "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1"

EXPECTATIONS = (
    {
        "snippet": '(New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Kind "file"',
        "purpose": "The replay-attached surface checker keeps the pinned bundle proof companion note in its reference set.",
    },
    {
        "snippet": '(New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1" -Kind "file"',
        "purpose": "The replay-attached surface checker keeps the launcher companion surface checker in its reference set.",
    },
    {
        "snippet": '(New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Kind "file"',
        "purpose": "The replay-attached surface checker keeps the launcher companion helper in its reference set.",
    },
    {
        "snippet": '(New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1" -Kind "file"',
        "purpose": "The replay-attached surface checker keeps the pinned bundle proof checker in its reference set.",
    },
    {
        "snippet": '(New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Kind "file"',
        "purpose": "The replay-attached surface checker keeps the pinned bundle proof helper in its reference set.",
    },
    {
        "snippet": '(New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet \'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md\'',
        "purpose": "The replay-attached surface checker verifies the quickstart note still mentions the pinned bundle proof companion note.",
    },
    {
        "snippet": '(New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet \'powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1\'',
        "purpose": "The replay-attached surface checker verifies the quickstart note still mentions the proof-entrypoint surface checker.",
    },
    {
        "snippet": '(New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "attached_pages_launcher_companion_surface_check = Format-HelperCommand -ScriptName \'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1\' -Arguments $routeSurfaceArguments"',
        "purpose": "The replay-attached surface checker verifies the replay helper still prints the launcher companion surface checker.",
    },
    {
        "snippet": '(New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName \'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1\' -Arguments $sharedArguments"',
        "purpose": "The replay-attached surface checker verifies the replay helper still prints the proof-entrypoint helper.",
    },
    {
        "snippet": '(New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet "proof_surface_check = Format-HelperCommand -ScriptName \'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1\' -Arguments $surfaceCheckArguments"',
        "purpose": "The replay-attached surface checker verifies the launcher companion helper still bridges directly into the proof checker.",
    },
    {
        "snippet": '(New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet \'Write-Host ((\\\"  Proof entrypoint:   {0}\\\") -f $helper.helper_commands.proof_entrypoint)\'',
        "purpose": "The replay-attached surface checker verifies the launcher companion helper still prints the proof-entrypoint helper.",
    },
    {
        "snippet": 'Write-Host "Google issue #3 Windows replay attached-html quickstart surface is intact, including the suite-catalog fail-fast discovery block, the replay-side helper contract, the compact attached-bundle surface, the executable proof-entrypoint checker/helper pair, the launcher-companion proof bridge, the pinned proof-only bundle follow-up, the bundle-first replay branch, and the broader attached-page fallbacks that keep the shorter replay note honest."',
        "purpose": "The replay-attached surface checker keeps a success summary that explicitly mentions the proof route and launcher-companion bridge.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_surface_checker_audit(repo_root: Path) -> dict[str, object]:
    checker = repo_root / CHECKER_PATH
    if not checker.is_file():
        raise FileNotFoundError(f"missing checker source: {checker}")

    text = checker.read_text(encoding="utf-8", errors="ignore")
    results: list[dict[str, object]] = []
    missing_count = 0

    for expectation in EXPECTATIONS:
        exists = expectation["snippet"] in text
        if not exists:
            missing_count += 1
        results.append(
            {
                "path": CHECKER_PATH,
                "purpose": expectation["purpose"],
                "exists": exists,
                "snippet": expectation["snippet"],
            }
        )

    return {
        "repo_root": str(repo_root),
        "checker_path": CHECKER_PATH,
        "expectation_count": len(results),
        "missing_count": missing_count,
        "results": results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Google Issue #3 Windows Replay Attached HTML Surface Checker Audit",
        "",
        f"Repo root: {audit['repo_root']}",
        f"Checker: {audit['checker_path']}",
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
        description="Audit the replay-attached PowerShell surface checker for proof-route and launcher-companion contract drift."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_surface_checker_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
