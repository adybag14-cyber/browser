#!/usr/bin/env python3
"""Check the issue #3 runtime re-entry route contract from source text.

This helper guards the smaller diagnostics surface around the blocked issue #3
runtime patch. It checks that the re-entry note and the Windows route helper
still advertise the same gate sequence, contract checks, and replay commands
before future runs reopen the large runtime files.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


DOC_REQUIRED_MARKERS = (
    "### Gate 1: Writable publication path",
    "### Gate 2: Branch-compatible validation toolchain",
    "python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test",
    "python scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot",
    "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
    "bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
    "bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
    "Only after those gates are green, reopen the direct code patch and the",
)

HELPER_REQUIRED_MARKERS = (
    'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
    "saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand",
    "saved_archive_integrity = $savedArchiveIntegrityCommand",
    "saved_memory_preflight = $savedMemoryPreflightCommand",
    "linux_runtime_route = $linuxRuntimeRouteCommand",
    "linux_build_readiness = $linuxBuildReadinessFullCommand",
    "contract_self_test = $runtimeContractSelfTestCommand",
    'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments -Switches @("GoogleEnterOrder", "ClickFocus")',
    'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1" -Arguments $sharedBrowserArguments',
)


def find_missing_markers(source: str, markers: tuple[str, ...]) -> list[str]:
    return [marker for marker in markers if marker not in source]


def summarize_markers(markers: list[str], limit: int) -> str:
    return " | ".join(markers[:limit])


def build_result(
    *,
    label: str,
    markers: tuple[str, ...],
    source: str,
    success_detail: str,
) -> dict[str, object]:
    missing_markers = find_missing_markers(source, markers)
    ok = not missing_markers
    detail = (
        success_detail
        if ok
        else f"{label} missing markers: {summarize_markers(missing_markers, 3)}"
    )
    return {
        "ok": ok,
        "detail": detail,
        "missing_markers": missing_markers,
        "marker_count": len(markers),
        "matched_marker_count": len(markers) - len(missing_markers),
    }


def evaluate_doc_source(source: str) -> dict[str, object]:
    return build_result(
        label="ISSUE3 runtime re-entry gate note",
        markers=DOC_REQUIRED_MARKERS,
        source=source,
        success_detail="runtime re-entry gate note retains the guarded re-entry sequence",
    )


def evaluate_helper_source(source: str) -> dict[str, object]:
    return build_result(
        label="issue #3 Windows route helper",
        markers=HELPER_REQUIRED_MARKERS,
        source=source,
        success_detail="Windows route helper retains the saved-input, contract, and replay commands",
    )


def evaluate_sources(doc_source: str, helper_source: str) -> dict[str, object]:
    doc = evaluate_doc_source(doc_source)
    helper = evaluate_helper_source(helper_source)
    ok = bool(doc["ok"] and helper["ok"])
    return {
        "ok": ok,
        "doc": doc,
        "helper": helper,
    }


def emit_text_result(result: dict[str, object]) -> None:
    doc = result["doc"]
    helper = result["helper"]
    print(f"ISSUE3_RUNTIME_REENTRY_ROUTE_CONTRACT={'pass' if result['ok'] else 'fail'}")
    print(f"DOC_CONTRACT={'pass' if doc['ok'] else 'fail'}")
    print(f"DOC_DETAIL={doc['detail']}")
    print(f"DOC_MISSING_MARKER_COUNT={len(doc['missing_markers'])}")
    for marker in doc["missing_markers"]:
        print(f"DOC_MISSING_MARKER={marker}")
    print(f"HELPER_CONTRACT={'pass' if helper['ok'] else 'fail'}")
    print(f"HELPER_DETAIL={helper['detail']}")
    print(f"HELPER_MISSING_MARKER_COUNT={len(helper['missing_markers'])}")
    for marker in helper["missing_markers"]:
        print(f"HELPER_MISSING_MARKER={marker}")


VULNERABLE_DOC = """
## Practical Re-entry Order

1. Reopen docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md.
2. Try zig test immediately.
3. Reopen the direct code patch.
"""


GUARDED_DOC = """
### Gate 1: Writable publication path
### Gate 2: Branch-compatible validation toolchain
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test
python scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot
python scripts/check_issue3_saved_memory_inputs.py --repo-root .
bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
Only after those gates are green, reopen the direct code patch and the
focused regression tests.
"""


VULNERABLE_HELPER = """
$route = [ordered]@{
    commands = [ordered]@{
        build = "zig build -Dtarget=x86_64-windows-msvc --summary all"
    }
}
"""


GUARDED_HELPER = """
surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand
saved_archive_integrity = $savedArchiveIntegrityCommand
saved_memory_preflight = $savedMemoryPreflightCommand
linux_runtime_route = $linuxRuntimeRouteCommand
linux_build_readiness = $linuxBuildReadinessFullCommand
contract_self_test = $runtimeContractSelfTestCommand
shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments -Switches @("GoogleEnterOrder", "ClickFocus")
reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1" -Arguments $sharedBrowserArguments
"""


def run_self_test(json_output: bool) -> int:
    bad_result = evaluate_sources(VULNERABLE_DOC, VULNERABLE_HELPER)
    good_result = evaluate_sources(GUARDED_DOC, GUARDED_HELPER)
    ok = (not bad_result["ok"]) and bool(good_result["ok"])

    if json_output:
        print(
            json.dumps(
                {
                    "profile": "issue3-runtime-reentry-route-contract-self-test",
                    "self_test": "pass" if ok else "fail",
                    "vulnerable_sample": bad_result,
                    "guarded_sample": good_result,
                },
                indent=2,
            )
        )
        return 0 if ok else 1

    if bad_result["ok"]:
        print("SELF_TEST=fail")
        print("DETAIL=vulnerable samples unexpectedly passed")
        emit_text_result(bad_result)
        return 1
    if not good_result["ok"]:
        print("SELF_TEST=fail")
        print("DETAIL=guarded samples unexpectedly failed")
        emit_text_result(good_result)
        return 1

    print("SELF_TEST=pass")
    print("VULNERABLE_SAMPLE_EXPECTATION=fail")
    emit_text_result(bad_result)
    print("GUARDED_SAMPLE_EXPECTATION=pass")
    emit_text_result(good_result)
    return 0


def main_from_args(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #3 runtime re-entry note and Windows helper "
            "still advertise the same guarded replay route."
        )
    )
    parser.add_argument(
        "--doc",
        type=Path,
        help="Path to docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
    )
    parser.add_argument(
        "--helper",
        type=Path,
        help="Path to scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run embedded vulnerable and guarded samples instead of reading files",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    args = parser.parse_args(argv)

    if args.self_test:
        return run_self_test(args.json)

    if args.doc is None or args.helper is None:
        parser.error("either --self-test or both --doc and --helper are required")

    try:
        doc_source = args.doc.read_text(encoding="utf-8")
        helper_source = args.helper.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        payload = {
            "profile": "issue3-runtime-reentry-route-contract",
            "ok": False,
            "error_type": "file_not_found",
            "error": str(exc),
        }
        if args.json:
            print(json.dumps(payload, indent=2))
        else:
            print("ISSUE3_RUNTIME_REENTRY_ROUTE_CONTRACT=fail")
            print(f"ERROR={exc}")
        return 1

    result = evaluate_sources(doc_source, helper_source)
    if args.json:
        print(
            json.dumps(
                {"profile": "issue3-runtime-reentry-route-contract", **result},
                indent=2,
            )
        )
    else:
        emit_text_result(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main_from_args())