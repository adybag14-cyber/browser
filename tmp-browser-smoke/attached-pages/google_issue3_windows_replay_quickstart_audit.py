import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "purpose": "The replay quickstart keeps the replay-attached fail-fast checker visible before the narrower attached-page ladder is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "purpose": "The replay quickstart keeps the narrower replay-attached helper visible once the route narrows into attached localhost follow-up.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "purpose": "The replay quickstart keeps the launcher-companion checker visible when the route needs the smaller wrapper-backed preflight surface.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1",
        "purpose": "The replay quickstart keeps the launcher-companion helper visible when the route needs the smaller wrapper-backed preflight surface.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the launcher-companion checker visible before the helper is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'",
        "purpose": "The replay-attached quickstart keeps the launcher-companion helper visible with an attached-page input path.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'",
        "purpose": "The replay-attached quickstart keeps the repo-root-preserving launcher-companion helper visible.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "windows_replay_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay quickstart helper wires the replay-attached fail-fast checker into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments",
        "purpose": "The replay quickstart helper wires the narrower replay-attached helper into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "attached_pages_launcher_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay quickstart helper wires the launcher-companion checker into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments",
        "purpose": "The replay quickstart helper wires the launcher-companion helper into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "Treat replay_attached_html_note_path as the read-first written companion to windows_replay_attached_html_quickstart",
        "purpose": "The replay quickstart helper keeps the narrowed replay-attached note paired with its helper surface.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "Use attached_pages_launcher_surface_check and attached_pages_launcher_companion when the replay has already narrowed into attached localhost follow-up",
        "purpose": "The replay quickstart helper explains when to switch to the smaller launcher-companion surface.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "Write-Host ((\"  Launcher surface check:    {0}\") -f $helper.commands.attached_pages_launcher_surface_check)",
        "purpose": "The replay quickstart helper prints the launcher-companion checker on the surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "Write-Host ((\"  Launcher companion:        {0}\") -f $helper.commands.attached_pages_launcher_companion)",
        "purpose": "The replay quickstart helper prints the launcher-companion helper on the surfaced ladder.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_replay_quickstart_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Windows Replay Quickstart Audit",
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
        description="Audit the issue #3 Windows replay quickstart route for Linux-side drift checks."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_replay_quickstart_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())