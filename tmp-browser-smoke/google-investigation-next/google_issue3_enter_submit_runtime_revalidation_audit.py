import argparse
import json
from collections import defaultdict
from pathlib import Path


AUDIT_TITLE = "Google Issue #3 Enter-Submit Runtime Revalidation Audit"

EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note keeps the headed slice goal visible",
        "snippet": "## Goal",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note keeps the current runtime gap visible",
        "snippet": "## Current runtime gap",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note names the Page.zig deferred Enter submit state",
        "snippet": "_defer_native_text_input_enter_submit: bool",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note names the pending native Enter submit pointer",
        "snippet": "_pending_native_enter_submit: ?*Element.Html.Input",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note names the queued suppression shape",
        "snippet": "std.ArrayListUnmanaged(TextInputEvent)",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note points back to the reduced Google fixture",
        "snippet": "src/browser/tests/page/google_home_title_probe.html",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note preserves the Windows headed build replay command",
        "snippet": "zig build -Dtarget=x86_64-windows-msvc --summary all",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note preserves the smaller Chrome title probe replay command",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note preserves the localhost replay URL",
        "snippet": ".\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note keeps the runtime-input backend trace reference",
        "snippet": "runtime-input-backend-*.log",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note keeps the wndproc trace reference",
        "snippet": "wndproc-input-*.log",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note keeps the Page.zig target file nearby",
        "snippet": "`src/browser/Page.zig`",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "purpose": "Runtime note keeps the Win32 backend target file nearby",
        "snippet": "`src/display/win32_backend.zig`",
    },
)


def build_runtime_revalidation_audit(repo_root: Path) -> dict:
    if not repo_root.exists():
        return {
            "title": AUDIT_TITLE,
            "repo_root": str(repo_root),
            "error_type": "repo_root_not_found",
            "error": f"repo root does not exist: {repo_root}",
            "missing_count": None,
            "missing_path_count": None,
            "results": [],
            "missing_paths": [],
        }

    results = []
    missing_groups: dict[str, list[dict]] = defaultdict(list)
    for expectation in EXPECTATIONS:
        path = repo_root / expectation["path"]
        exists = path.exists()
        text = path.read_text(encoding="utf-8") if exists else ""
        present = exists and expectation["snippet"] in text
        result = {
            "path": expectation["path"],
            "purpose": expectation["purpose"],
            "snippet": expectation["snippet"],
            "exists": present,
        }
        results.append(result)
        if not present:
            missing_groups[expectation["path"]].append(result)

    missing_paths = []
    for path, entries in sorted(missing_groups.items()):
        first = entries[0]
        missing_paths.append(
            {
                "path": path,
                "missing_expectation_count": len(entries),
                "first_missing_purpose": first["purpose"],
                "first_missing_snippet": first["snippet"],
                "missing_snippets": [entry["snippet"] for entry in entries],
            }
        )

    missing_count = sum(1 for result in results if not result["exists"])
    return {
        "title": AUDIT_TITLE,
        "repo_root": str(repo_root),
        "error_type": None,
        "error": None,
        "missing_count": missing_count,
        "missing_path_count": len(missing_paths),
        "results": results,
        "missing_paths": missing_paths,
    }


def render_text_report(audit: dict) -> str:
    lines = [
        AUDIT_TITLE,
        f"Repo root: {audit['repo_root']}",
    ]
    if audit["error"]:
        lines.append(f"Error: {audit['error']}")
        return "\n".join(lines)

    lines.append(f"Missing expectations: {audit['missing_count']}")
    lines.append(f"Missing path count: {audit['missing_path_count']}")
    for result in audit["results"]:
        status = "PASS" if result["exists"] else "FAIL"
        lines.append(f"[{status}] {result['path']} :: {result['purpose']}")
        if not result["exists"]:
            lines.append(f"  Snippet: {result['snippet']}")

    if audit["missing_paths"]:
        lines.append("Missing path summary:")
        for entry in audit["missing_paths"]:
            lines.append(
                f"- {entry['path']} ({entry['missing_expectation_count']} missing)"
            )
            lines.append(f"  First purpose: {entry['first_missing_purpose']}")
            lines.append(f"  First snippet: {entry['first_missing_snippet']}")

    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=AUDIT_TITLE)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--json", action="store_true", dest="json_output")
    args = parser.parse_args(argv)

    audit = build_runtime_revalidation_audit(args.repo_root)
    if args.json_output:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit))

    return 0 if not audit["error"] and audit["missing_count"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
