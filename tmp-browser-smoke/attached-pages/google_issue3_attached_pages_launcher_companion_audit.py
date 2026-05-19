import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the launcher companion checker visible before the helper is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'",
        "purpose": "The replay-attached quickstart keeps the launcher companion helper visible with an attached-page input path.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'",
        "purpose": "The replay-attached quickstart keeps the repo-root-preserving launcher companion helper visible.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "surface_check_command = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $surfaceCheckArguments",
        "purpose": "The launcher companion helper wires its dedicated fail-fast checker into the surfaced command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "wrapper_strict_bundle = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('RequireCompleteSidecars', 'RequireCompleteAssets')",
        "purpose": "The launcher companion helper surfaces the strict sidecar-plus-asset wrapper path.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "wrapper_google_strict_bundle = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle', 'RequireCompleteSidecars', 'RequireCompleteAssets')",
        "purpose": "The launcher companion helper surfaces the strict Google-style wrapper path.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $surfaceCheckArguments",
        "purpose": "The launcher companion helper keeps the pinned proof-entrypoint surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $wrapperArguments",
        "purpose": "The launcher companion helper keeps the pinned proof-entrypoint helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "python_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -Flags @('--require-complete-sidecars', '--require-complete-assets')",
        "purpose": "The launcher companion helper surfaces the strict sidecar-plus-asset Python path.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "python_google_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -Flags @('--google-style', '--require-complete-sidecars', '--require-complete-assets')",
        "purpose": "The launcher companion helper surfaces the strict Google-style Python path.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": 'Write-Host (("  6. Strict bundle:      {0}") -f $helper.helper_commands.wrapper_strict_bundle)',
        "purpose": "The launcher companion helper prints the strict wrapper bundle route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": 'Write-Host (("  10. Google strict:     {0}") -f $helper.helper_commands.wrapper_google_strict_bundle)',
        "purpose": "The launcher companion helper prints the strict Google-style wrapper route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": 'Write-Host (("  6. Strict bundle:      {0}") -f $helper.helper_commands.python_strict_bundle)',
        "purpose": "The launcher companion helper prints the strict Python bundle route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": 'Write-Host (("  10. Google strict:     {0}") -f $helper.helper_commands.python_google_strict_bundle)',
        "purpose": "The launcher companion helper prints the strict Google-style Python route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": 'Write-Host (("  Surface check:      {0}") -f $helper.helper_commands.proof_surface_check)',
        "purpose": "The launcher companion helper prints the pinned proof-entrypoint surface checker.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": 'Write-Host (("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint)',
        "purpose": "The launcher companion helper prints the pinned proof-entrypoint helper.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Use the strict bundle commands when both sidecars and referenced local assets must be complete before a manifest print or localhost launch is trusted.",
        "purpose": "The launcher companion helper explains when to prefer the strict bundle commands.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.",
        "purpose": "The launcher companion helper explains when to bridge from launcher preflight into the pinned proof route.",
    },
    {
        "path": "tmp-browser-smoke/attached-pages/README.md",
        "snippet": "scripts/windows/start_attached_pages_catalog.ps1",
        "purpose": "The attached-pages README keeps the Windows wrapper visible.",
    },
    {
        "path": "tmp-browser-smoke/attached-pages/README.md",
        "snippet": "--audit-sidecars",
        "purpose": "The attached-pages README keeps the sidecar-audit mode visible.",
    },
    {
        "path": "tmp-browser-smoke/attached-pages/README.md",
        "snippet": "--require-complete-sidecars \\\n  --require-complete-assets",
        "purpose": "The attached-pages README keeps the strict sidecar-plus-asset mode visible.",
    },
    {
        "path": "scripts/windows/start_attached_pages_catalog.ps1",
        "snippet": '$launcherArgs += "--audit-sidecars"',
        "purpose": "The Windows wrapper still forwards the sidecar-audit mode.",
    },
    {
        "path": "scripts/windows/start_attached_pages_catalog.ps1",
        "snippet": '$launcherArgs += "--require-complete-sidecars"',
        "purpose": "The Windows wrapper still forwards the strict sidecar gate.",
    },
    {
        "path": "scripts/windows/start_attached_pages_catalog.ps1",
        "snippet": '$launcherArgs += "--require-complete-assets"',
        "purpose": "The Windows wrapper still forwards the strict asset gate.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_launcher_companion_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Attached-Pages Launcher Companion Audit",
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
        description="Audit the issue #3 attached-pages launcher companion surface for Linux-side drift checks."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_launcher_companion_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())