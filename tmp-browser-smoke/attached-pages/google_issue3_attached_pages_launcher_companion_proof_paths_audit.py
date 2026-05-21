import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the proof-entrypoint surface checker visible before the launcher companion replay lane narrows further.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "purpose": "The replay-attached quickstart keeps the proof-entrypoint helper visible before the launcher companion replay lane narrows further.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $surfaceCheckArguments",
        "purpose": "The launcher companion helper wires the pinned proof-entrypoint surface checker into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $wrapperArguments",
        "purpose": "The launcher companion helper wires the pinned proof-entrypoint helper into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "attached_html_target_bundle_proof_surface_check = 'scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1'",
        "purpose": "The launcher companion helper keeps the raw proof checker path visible in its companion paths map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "attached_html_target_bundle_proof_entrypoint = 'scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1'",
        "purpose": "The launcher companion helper keeps the raw proof helper path visible in its companion paths map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "attached_html_target_bundle_proof_entrypoint_note = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'",
        "purpose": "The launcher companion helper keeps the raw proof note path visible in its companion paths map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"Bundle proof checker:    {0}\") -f $helper.companion_paths.attached_html_target_bundle_proof_surface_check)",
        "purpose": "The launcher companion helper prints the raw proof checker path beside the rest of the replay companion paths.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"Bundle proof helper:     {0}\") -f $helper.companion_paths.attached_html_target_bundle_proof_entrypoint)",
        "purpose": "The launcher companion helper prints the raw proof helper path beside the rest of the replay companion paths.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"Bundle proof note:       {0}\") -f $helper.companion_paths.attached_html_target_bundle_proof_entrypoint_note)",
        "purpose": "The launcher companion helper prints the raw proof note path beside the rest of the replay companion paths.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Keep the raw proof checker and proof helper paths visible beside the proof note so the pinned-bundle follow-up can still be reopened quickly when only the script references are needed.",
        "purpose": "The launcher companion helper explains why the raw proof checker and helper paths stay printed beside the note.",
    },
)


def audit_repo_root(repo_root: Path) -> list[dict[str, str]]:
    missing: list[dict[str, str]] = []
    content_cache: dict[Path, str] = {}

    for expectation in EXPECTATIONS:
        target = repo_root / expectation["path"]
        if not target.is_file():
            missing.append(
                {
                    "path": expectation["path"],
                    "purpose": expectation["purpose"],
                    "reason": "missing-file",
                }
            )
            continue

        content = content_cache.setdefault(target, target.read_text(encoding="utf-8"))
        if expectation["snippet"] not in content:
            missing.append(
                {
                    "path": expectation["path"],
                    "purpose": expectation["purpose"],
                    "reason": "missing-snippet",
                }
            )

    return missing


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit the issue #3 launcher companion proof-path surface."
    )
    parser.add_argument("--repo-root", default=".", help="Repository root to audit.")
    parser.add_argument("--json", action="store_true", help="Print JSON output.")
    args = parser.parse_args()

    missing = audit_repo_root(Path(args.repo_root).resolve())
    if args.json:
        print(
            json.dumps(
                {
                    "profile": "google-issue3-launcher-companion-proof-paths",
                    "repo_root": str(Path(args.repo_root).resolve()),
                    "checked_count": len(EXPECTATIONS),
                    "missing_count": len(missing),
                    "missing": missing,
                },
                indent=2,
            )
        )
    else:
        if missing:
            for item in missing:
                print(f"FAIL {item['path']}: {item['purpose']} ({item['reason']})")
        else:
            print(
                "Launcher companion proof-path surface is intact across the quickstart note and helper."
            )

    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
