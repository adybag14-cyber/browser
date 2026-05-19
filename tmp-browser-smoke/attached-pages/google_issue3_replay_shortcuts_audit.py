import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_REPLAY_SHORTCUTS.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1",
        "purpose": "The replay-shortcuts note keeps the broader Windows full-use attached-page route visible.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_SHORTCUTS.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "purpose": "The replay-shortcuts note keeps the Windows-side attached-page catalog quickstart visible.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_SHORTCUTS.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1",
        "purpose": "The replay-shortcuts note keeps the attached-html change-area quickstart visible.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_SHORTCUTS.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "purpose": "The replay-shortcuts note keeps the suite-router shortcut-first helper visible.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_SHORTCUTS.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1",
        "purpose": "The replay-shortcuts note keeps the suite-catalog guide helper visible.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_SHORTCUTS.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'",
        "purpose": "The replay-shortcuts note keeps the pinned bundle-first helper visible.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_SHORTCUTS.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1",
        "purpose": "The replay-shortcuts note keeps the fresh safe-route replay visible when outputs may be stale.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": "windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleFirstArguments",
        "purpose": "The replay-shortcuts helper keeps the broader Windows full-use attached-page route in its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": "replay_shortcuts_windows_replay_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1' -Arguments $bundleFirstArguments",
        "purpose": "The replay-shortcuts helper keeps the replay-to-Windows attached-page bridge in its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": "attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot",
        "purpose": "The replay-shortcuts helper keeps the broader attached-html flow helper in its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": "google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot",
        "purpose": "The replay-shortcuts helper keeps the narrower Google attached-html flow helper in its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": "runner_patch_next_step = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{",
        "purpose": "The replay-shortcuts helper keeps the runner next-step helper in its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": "fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments",
        "purpose": "The replay-shortcuts helper keeps the fresh safe-route replay command in its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": "reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments",
        "purpose": "The replay-shortcuts helper keeps the reuse-current-outputs wrapper in its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": 'Write-Host (("Recommended first helper: {0}") -f $shortcuts.recommended_first_helper_command)',
        "purpose": "The replay-shortcuts helper prints its recommended-first helper.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": 'Write-Host (("  Windows full-use route:      {0}") -f $shortcuts.read_first_commands.windows_full_use_attached_html_route)',
        "purpose": "The replay-shortcuts helper prints the Windows full-use route in read-first discovery output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": 'Write-Host (("  Replay->Windows bridge:      {0}") -f $shortcuts.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)',
        "purpose": "The replay-shortcuts helper prints the replay-to-Windows bridge in shortcut output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": 'Write-Host (("  Runner next-step helper:     {0}") -f $shortcuts.helper_commands.runner_patch_next_step)',
        "purpose": "The replay-shortcuts helper prints the runner next-step helper in shortcut output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": 'Write-Host (("  Fresh safe replay:           {0}") -f $shortcuts.helper_commands.fresh_safe_route_replay)',
        "purpose": "The replay-shortcuts helper prints the fresh safe-route replay in shortcut output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": 'Write-Host (("  Reuse current outputs:       {0}") -f $shortcuts.helper_commands.reuse_current_outputs)',
        "purpose": "The replay-shortcuts helper prints the reuse-current-outputs wrapper in shortcut output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": "Use runner_patch_next_step after the safe-route wrapper or reuse-current-outputs helper names one of the three current runner-patch states; when RepoRoot or SummaryPath is already in play, this command now keeps that same replay context attached to the next-step helper.",
        "purpose": "The replay-shortcuts helper notes explain when to use the runner next-step helper.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "snippet": "Use fresh_safe_route_replay when current issue #3 outputs may be stale or missing and no explicit bundle inputs are already pinned. Use reuse_current_outputs only when the current saved outputs are already trusted.",
        "purpose": "The replay-shortcuts helper notes explain when to choose fresh replay versus current outputs.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_replay_shortcuts_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Replay Shortcuts Audit",
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
        description="Audit the issue #3 replay-shortcuts note and helper surface for Linux-side route drift checks."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_replay_shortcuts_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())