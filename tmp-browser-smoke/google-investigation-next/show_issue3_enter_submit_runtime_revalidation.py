#!/usr/bin/env python3
"""Summarize the issue #3 Enter-submit runtime revalidation surface.

This helper is intentionally checkout-friendly for Linux and other lightweight
agent environments where the Windows PowerShell helpers are not directly
executable. It reports whether the runtime note and related replay surfaces are
present, and it also evaluates whether the direct Page.zig plus win32_backend.zig
runtime bridge appears landed yet.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from check_issue3_enter_submit_runtime_contract import evaluate_sources


REFERENCES = (
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Read-first note for the direct Page.zig plus win32_backend.zig Enter-submit slice.",
    },
    {
        "path": "docs/WINDOWS_FULL_USE.md",
        "purpose": "Windows runbook that stays nearby when the reduced probe widens back into headed replay.",
    },
    {
        "path": "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
        "purpose": "Windows-first helper that prints the runtime re-entry ladder.",
    },
    {
        "path": "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "purpose": "Windows-first surface checker that keeps the runtime helper honest after branch moves.",
    },
    {
        "path": "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
        "purpose": "Shared Enter-submit probe ladder used before the reduced Google fixture.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "purpose": "Reduced Google title probe used before reopening live Google.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
        "purpose": "Source-based contract checker for the direct runtime bridge.",
    },
    {
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "purpose": "Reduced Google-shaped fixture used by the direct runtime slice.",
    },
    {
        "path": "src/browser/Page.zig",
        "purpose": "Browser runtime source targeted by the deferred native Enter-submit change.",
    },
    {
        "path": "src/display/win32_backend.zig",
        "purpose": "Win32 backend source targeted by the text-input suppression and deferred-submit change.",
    },
)

CONTENT_EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "src/browser/Page.zig",
        "purpose": "Runtime note keeps Page.zig visible as one of the two direct source targets.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "src/display/win32_backend.zig",
        "purpose": "Runtime note keeps win32_backend.zig visible as the other direct source target.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "beginDeferredNativeTextInputEnterSubmit()",
        "purpose": "Runtime note still names the deferred native Enter-submit helper shape expected in Page.zig.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "pending_text_input_suppressions",
        "purpose": "Runtime note still names the stale scalar suppression anchor that the Win32 backend slice needs to replace.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "chrome-google-home-title-probe.ps1",
        "purpose": "Runtime note still points the reduced replay through the Google title probe before live Google is retried.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "google_home_title_probe.html",
        "purpose": "Runtime note still points the reduced replay through the Google-shaped local fixture before live Google is retried.",
    },
    {
        "path": "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
        "snippet": 'contract_check = $runtimeContractCheckCommand',
        "purpose": "Windows runtime helper still prints the source-based contract checker command.",
    },
    {
        "path": "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
        "snippet": 'shared_enter_google_click = Format-RepoRootCommand -ScriptPath \"tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1\"',
        "purpose": "Windows runtime helper still prints the click-first Google ordering route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
        "snippet": 'reduced_google_probe = Format-RepoRootCommand -ScriptPath \"tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1\"',
        "purpose": "Windows runtime helper still prints the reduced Google title probe command.",
    },
)


def resolve_repo_root(start: Path) -> Path:
    env_override = Path.cwd().joinpath()
    override = None
    if "LIGHTPANDA_REPO_ROOT" in __import__("os").environ:
        override = __import__("os").environ["LIGHTPANDA_REPO_ROOT"].strip()
    if override:
        return Path(override).resolve()

    cursor = start.resolve()
    for candidate in (cursor, *cursor.parents):
        if (candidate / "build.zig").exists():
            return candidate
    raise SystemExit(f"Could not resolve the Lightpanda repo root from {start}")


def check_surface(repo_root: Path) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    reference_results: list[dict[str, object]] = []
    for reference in REFERENCES:
        path = repo_root / reference["path"]
        reference_results.append(
            {
                "path": reference["path"],
                "purpose": reference["purpose"],
                "exists": path.is_file(),
            }
        )

    cache: dict[Path, str] = {}
    content_results: list[dict[str, object]] = []
    for expectation in CONTENT_EXPECTATIONS:
        path = repo_root / expectation["path"]
        if not path.is_file():
            content_results.append(
                {
                    "path": expectation["path"],
                    "purpose": expectation["purpose"],
                    "snippet": expectation["snippet"],
                    "exists": False,
                }
            )
            continue
        if path not in cache:
            cache[path] = path.read_text(encoding="utf-8")
        content_results.append(
            {
                "path": expectation["path"],
                "purpose": expectation["purpose"],
                "snippet": expectation["snippet"],
                "exists": expectation["snippet"] in cache[path],
            }
        )

    return reference_results, content_results


def build_commands(browser_exe: str) -> dict[str, str]:
    return {
        "windows_surface_check": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "windows_runtime_helper": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1",
        "source_contract": "python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --page src/browser/Page.zig --win32 src/display/win32_backend.zig",
        "source_contract_self_test": "python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test",
        "windows_build": "zig build -Dtarget=x86_64-windows-msvc --summary all",
        "shared_enter_baseline": "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1",
        "shared_enter_deferred": "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1 -DeferredEnter",
        "shared_enter_google": "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1 -GoogleEnterOrder",
        "shared_enter_google_click": "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus",
        "reduced_google_probe": "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1",
        "reduced_google_fixture": f'{browser_exe} browse --browser_mode headed "http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"',
        "live_google": f'{browser_exe} browse --browser_mode headed "https://www.google.com/"',
    }


def format_browser_exe(raw: str) -> str:
    if raw.startswith("."):
        return raw
    return f'"{raw}"'


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Summarize the issue #3 Enter-submit runtime revalidation surface and "
            "report whether the direct runtime bridge appears landed on the current checkout."
        )
    )
    parser.add_argument("--repo-root", type=Path, help="Path to the Lightpanda checkout")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of text")
    parser.add_argument(
        "--surface-check-only",
        action="store_true",
        help="Exit non-zero only when the runtime note or companion replay surfaces are missing",
    )
    args = parser.parse_args()

    repo_root = args.repo_root.resolve() if args.repo_root else resolve_repo_root(Path(__file__).resolve().parent)
    browser_exe = format_browser_exe(str(repo_root / "zig-out" / "bin" / "lightpanda.exe"))

    reference_results, content_results = check_surface(repo_root)
    missing_surface = [
        result for result in [*reference_results, *content_results] if not bool(result["exists"])
    ]

    page_path = repo_root / "src/browser/Page.zig"
    win32_path = repo_root / "src/display/win32_backend.zig"
    contract_ok = False
    contract_details: list[str] = []
    if page_path.is_file() and win32_path.is_file():
        contract_ok, contract_details = evaluate_sources(
            page_path.read_text(encoding="utf-8"),
            win32_path.read_text(encoding="utf-8"),
        )
    else:
        contract_details = [
            "PAGE_RUNTIME_CONTRACT=fail",
            "PAGE_DETAIL=Page.zig or win32_backend.zig is missing from the checkout",
            "WIN32_RUNTIME_CONTRACT=fail",
            "WIN32_DETAIL=Page.zig or win32_backend.zig is missing from the checkout",
        ]

    data = {
        "profile": "google-issue3-enter-submit-runtime-revalidation",
        "repo_root": str(repo_root),
        "runtime_note_path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "target_files": ["src/browser/Page.zig", "src/display/win32_backend.zig"],
        "surface_missing_count": len(missing_surface),
        "surface_missing": missing_surface,
        "runtime_contract_status": "pass" if contract_ok else "fail",
        "runtime_contract_details": contract_details,
        "commands": build_commands(browser_exe),
        "notes": [
            "Use this reporter from Linux or other lightweight agent environments when the Windows PowerShell helper cannot be executed directly.",
            "Treat a failing runtime contract as evidence that the direct Page.zig plus win32_backend.zig patch is still pending, not that the replay surface itself is broken.",
            "Treat missing surface references as a stronger failure because that means the branch-local replay route or its note chain drifted.",
            "Reopen the Windows runtime helper after this report when you move back into a writable Windows checkout for the actual runtime patch landing.",
        ],
    }

    if args.json:
        print(json.dumps(data, indent=2))
    else:
        print("Google issue #3 Enter-submit runtime revalidation")
        print()
        print(f"Repo root:              {data['repo_root']}")
        print(f"Runtime note:           {data['runtime_note_path']}")
        print(f"Surface gaps:           {data['surface_missing_count']}")
        print(f"Runtime contract:       {data['runtime_contract_status']}")
        print()
        print("Target files")
        print("============")
        for path in data["target_files"]:
            print(f"  {path}")
        print()
        print("Commands")
        print("========")
        for label, command in data["commands"].items():
            print(f"  {label}: {command}")
        print()
        print("Runtime contract details")
        print("========================")
        for detail in data["runtime_contract_details"]:
            print(f"  {detail}")
        if data["surface_missing"]:
            print()
            print("Surface gaps")
            print("============")
            for item in data["surface_missing"]:
                print(f"  {item['path']}: {item['purpose']}")
        print()
        print("Notes")
        print("=====")
        for note in data["notes"]:
            print(f"  - {note}")

    if args.surface_check_only:
        return 1 if missing_surface else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
