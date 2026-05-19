#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ReferenceCheck:
    path: str
    kind: str
    purpose: str


@dataclass(frozen=True)
class ContentCheck:
    path: str
    snippet: str
    purpose: str


REFERENCE_CHECKS: tuple[ReferenceCheck, ...] = (
    ReferenceCheck(
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "file",
        "Replay-side attached-html quickstart note for issue #3.",
    ),
    ReferenceCheck(
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "file",
        "Replay-side attached-html quickstart helper.",
    ),
    ReferenceCheck(
        "scripts/windows/check_google_issue3_windows_replay_quickstart_validation_surface.ps1",
        "file",
        "Broader replay quickstart checker reopened before the attached-html ladder narrows.",
    ),
    ReferenceCheck(
        "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "file",
        "Route-level checker reopened before the replay-side attached-html ladder narrows.",
    ),
    ReferenceCheck(
        "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "file",
        "Launcher companion checker kept visible on the replay-side attached-html ladder.",
    ),
    ReferenceCheck(
        "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "file",
        "Launcher companion helper kept visible on the replay-side attached-html ladder.",
    ),
    ReferenceCheck(
        "scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
        "file",
        "Pinned bundle proof-route checker kept visible before the route narrows into proof-only follow-up.",
    ),
    ReferenceCheck(
        "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "file",
        "Pinned bundle proof-route helper kept visible before the route narrows into proof-only follow-up.",
    ),
    ReferenceCheck(
        "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1",
        "file",
        "Top-level shortcut bridge kept visible before the replay-route shortcut narrows the ladder again.",
    ),
    ReferenceCheck(
        "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "file",
        "Replay-route shortcut bridge kept visible before the shortest replay shortcuts take over.",
    ),
    ReferenceCheck(
        "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
        "file",
        "Tightest replay shortcuts helper reached from the replay-attached ladder.",
    ),
)


CONTENT_CHECKS: tuple[ContentCheck, ...] = (
    ContentCheck(
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        r"powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "Replay-attached note keeps the launcher companion checker visible.",
    ),
    ContentCheck(
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        r"powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'",
        "Replay-attached note keeps the launcher companion helper visible.",
    ),
    ContentCheck(
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        r"powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
        "Replay-attached note keeps the pinned bundle proof-route checker visible.",
    ),
    ContentCheck(
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        r"powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "Replay-attached note keeps the pinned bundle proof-route helper visible.",
    ),
    ContentCheck(
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        r"powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1",
        "Replay-attached note keeps the top-level shortcut bridge visible.",
    ),
    ContentCheck(
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        r"powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "Replay-attached note keeps the replay-route shortcut bridge visible.",
    ),
    ContentCheck(
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "attached_pages_launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "Replay-attached helper wires the launcher companion checker into its command map.",
    ),
    ContentCheck(
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments",
        "Replay-attached helper wires the launcher companion helper into its command map.",
    ),
    ContentCheck(
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "attached_bundle_proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "Replay-attached helper wires the pinned proof-route checker into its command map.",
    ),
    ContentCheck(
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments",
        "Replay-attached helper wires the pinned proof-route helper into its command map.",
    ),
    ContentCheck(
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments",
        "Replay-attached helper wires the replay-route shortcut bridge into its command map.",
    ),
    ContentCheck(
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Launcher surface check:   {0}") -f $helper.commands.attached_pages_launcher_companion_surface_check)',
        "Replay-attached helper prints the launcher companion checker on the ladder.",
    ),
    ContentCheck(
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Launcher companion:       {0}") -f $helper.commands.attached_pages_launcher_companion)',
        "Replay-attached helper prints the launcher companion helper on the ladder.",
    ),
    ContentCheck(
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Bundle proof check:       {0}") -f $helper.commands.attached_bundle_proof_surface_check)',
        "Replay-attached helper prints the pinned proof-route checker on the ladder.",
    ),
    ContentCheck(
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Bundle proof helper:      {0}") -f $helper.commands.attached_bundle_proof_entrypoint)',
        "Replay-attached helper prints the pinned proof-route helper on the ladder.",
    ),
    ContentCheck(
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Replay-route shortcut:    {0}") -f $helper.commands.replay_route_shortcut)',
        "Replay-attached helper prints the replay-route shortcut bridge on the ladder.",
    ),
)


def find_repo_root(start: Path) -> Path:
    current = start.resolve()
    while True:
        if (current / "build.zig").is_file():
            return current
        if current.parent == current:
            raise FileNotFoundError("Could not resolve repo root from current working directory.")
        current = current.parent


def _check_reference(repo_root: Path, check: ReferenceCheck) -> dict:
    target = repo_root / check.path
    exists = target.is_file() if check.kind == "file" else target.is_dir()
    return {
        "check_type": "reference",
        "path": check.path,
        "kind": check.kind,
        "purpose": check.purpose,
        "exists": exists,
    }


def _check_content(repo_root: Path, check: ContentCheck, cache: dict[Path, str]) -> dict:
    target = repo_root / check.path
    if not target.is_file():
        return {
            "check_type": "content",
            "path": check.path,
            "kind": "content-snippet",
            "purpose": check.purpose,
            "exists": False,
            "snippet": check.snippet,
        }
    if target not in cache:
        cache[target] = target.read_text(encoding="utf-8")
    return {
        "check_type": "content",
        "path": check.path,
        "kind": "content-snippet",
        "purpose": check.purpose,
        "exists": check.snippet in cache[target],
        "snippet": check.snippet,
    }


def run_audit(repo_root: Path) -> dict:
    repo_root = repo_root.resolve()
    reference_results = [_check_reference(repo_root, check) for check in REFERENCE_CHECKS]
    cache: dict[Path, str] = {}
    content_results = [_check_content(repo_root, check, cache) for check in CONTENT_CHECKS]
    missing = [result for result in [*reference_results, *content_results] if not result["exists"]]
    return {
        "profile": "google-issue3-windows-replay-attached-html-quickstart",
        "repo_root": str(repo_root),
        "checked_count": len(reference_results) + len(content_results),
        "reference_count": len(reference_results),
        "content_check_count": len(content_results),
        "missing_count": len(missing),
        "references": reference_results,
        "content_checks": content_results,
    }


def format_text_report(report: dict) -> str:
    lines = [
        "Google issue #3 Windows replay attached HTML quickstart audit",
        "",
        f"Repo root: {report['repo_root']}",
        "",
    ]
    for result in report["references"]:
        status = "PASS" if result["exists"] else "FAIL"
        lines.append(f"[{status}] {result['path']}")
        lines.append(f"  {result['purpose']}")
    if report["content_checks"]:
        lines.extend(["", "Helper source expectations:"])
        for result in report["content_checks"]:
            status = "PASS" if result["exists"] else "FAIL"
            lines.append(f"[{status}] {result['path']}")
            lines.append(f"  {result['purpose']}")
    lines.append("")
    if report["missing_count"] == 0:
        lines.append(
            "Google issue #3 Windows replay attached HTML quickstart surface is intact."
        )
    else:
        lines.append(
            f"Missing {report['missing_count']} Windows replay attached HTML quickstart path or source contract check(s)."
        )
        lines.append(
            "Repair the replay-attached note, launcher companion surface, pinned proof-route surface, or replay-route shortcut bridge before trusting this replay ladder."
        )
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=None)
    parser.add_argument("--json", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root or find_repo_root(Path.cwd())
    report = run_audit(repo_root)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(format_text_report(report))
    return 0 if report["missing_count"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
