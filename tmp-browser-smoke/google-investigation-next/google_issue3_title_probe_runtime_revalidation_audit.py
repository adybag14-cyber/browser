import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "src/browser/Page.zig",
        "purpose": "The runtime revalidation note keeps the Page.zig target visible.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "src/display/win32_backend.zig",
        "purpose": "The runtime revalidation note keeps the Win32 backend target visible.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "beginDeferredNativeTextInputEnterSubmit()",
        "purpose": "The runtime revalidation note keeps the deferred native Enter helper visible.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "std.ArrayListUnmanaged(TextInputEvent)",
        "purpose": "The runtime revalidation note keeps the queued text-input suppression shape visible.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "runtime-input-backend-*.log",
        "purpose": "The runtime revalidation note keeps the backend trace artifacts visible.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "wndproc-input-*.log",
        "purpose": "The runtime revalidation note keeps the wndproc trace artifacts visible.",
    },
    {
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": "window.__lpEarlyEvents=[];",
        "purpose": "The reduced Google fixture keeps the early-event capture bootstrap visible.",
    },
    {
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": "window.__lpPostMessages=[];",
        "purpose": "The reduced Google fixture keeps the postMessage capture bootstrap visible.",
    },
    {
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": "document.addEventListener('keydown'",
        "purpose": "The reduced Google fixture keeps the keydown probe listener visible.",
    },
    {
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": "document.addEventListener('keypress'",
        "purpose": "The reduced Google fixture keeps the keypress probe listener visible.",
    },
    {
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": "document.addEventListener('beforeinput'",
        "purpose": "The reduced Google fixture keeps the beforeinput probe listener visible.",
    },
    {
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": "document.addEventListener('input'",
        "purpose": "The reduced Google fixture keeps the input probe listener visible.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "snippet": "scripts\\windows\\watch_headed_probe.ps1",
        "purpose": "The probe runner keeps the headed probe helper wired in.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "snippet": "-ExpectedTitleContainsAny @(\"A=INPUT:q::1\", \"FOCUSED|\")",
        "purpose": "The probe runner keeps the ready-state title markers visible.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "snippet": "-ExpectedTypedTitleContains (\"TYPED:{0}\" -f $InputText)",
        "purpose": "The probe runner keeps the typed-state title marker visible.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "snippet": "-ExpectedEnterTitleContains (\"SUBMIT:{0}\" -f $InputText)",
        "purpose": "The probe runner keeps the submit-state title marker visible.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "snippet": "\"runtime-input-backend-*.log\"",
        "purpose": "The probe runner keeps the backend trace collection visible.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "snippet": "\"wndproc-input-*.log\"",
        "purpose": "The probe runner keeps the wndproc trace collection visible.",
    },
)


def build_audit(repo_root: Path) -> dict:
    results = []
    for expectation in EXPECTATIONS:
        target = repo_root / expectation["path"]
        if target.exists():
            content = target.read_text(encoding="utf-8")
            exists = expectation["snippet"] in content
        else:
            exists = False
        results.append(
            {
                "path": expectation["path"],
                "snippet": expectation["snippet"],
                "purpose": expectation["purpose"],
                "exists": exists,
            }
        )

    missing = [result for result in results if not result["exists"]]
    return {
        "missing_count": len(missing),
        "results": results,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit the reduced Google title-probe runtime revalidation surface."
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="Repository root to audit.",
    )
    args = parser.parse_args()

    audit = build_audit(args.repo_root)
    print(json.dumps(audit, indent=2))
    return 0 if audit["missing_count"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
