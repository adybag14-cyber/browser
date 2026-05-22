import argparse
import json
from pathlib import Path


REFERENCES = (
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "kind": "file",
        "purpose": "Read-first handoff note for the issue #3 Enter-submit runtime slice.",
    },
    {
        "path": "docs/WINDOWS_FULL_USE.md",
        "kind": "file",
        "purpose": "Windows headed runbook used before the reduced Google probe widens back out.",
    },
    {
        "path": "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
        "kind": "file",
        "purpose": "Production execution guide kept beside the smaller issue #3 runtime note.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "kind": "file",
        "purpose": "Reduced Google homepage probe for typed-text and Enter-submit ordering.",
    },
    {
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "kind": "file",
        "purpose": "Reduced Google fixture used by the runtime note and probe flow.",
    },
)


CONTENT_EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "- `src/browser/Page.zig`",
        "purpose": "Runtime note keeps the Page.zig target visible.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "- `src/display/win32_backend.zig`",
        "purpose": "Runtime note keeps the Win32 backend target visible.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "beginDeferredNativeTextInputEnterSubmit()",
        "purpose": "Runtime note preserves the deferred Enter-submit helper contract.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "pending_text_input_suppressions",
        "purpose": "Runtime note preserves the stale suppression queue gap description.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1",
        "purpose": "Runtime note keeps the reduced Google probe command visible.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": ".\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1",
        "purpose": "Runtime note keeps the direct reduced probe browse command visible.",
    },
    {
        "path": "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "snippet": "later `text_input` remains available when stale suppression bytes do not match",
        "purpose": "Runtime note preserves the stale-suppression expected signal.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "snippet": "google_home_title_probe.html?google-home-probe=1",
        "purpose": "Probe helper still targets the reduced Google fixture.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "snippet": "-ExpectedTypedTitleContains (\"TYPED:{0}\" -f $InputText)",
        "purpose": "Probe helper still asserts that typed text committed.",
    },
    {
        "path": "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "snippet": "-ExpectedEnterTitleContains (\"SUBMIT:{0}\" -f $InputText)",
        "purpose": "Probe helper still asserts that Enter reached submit-time state.",
    },
    {
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": "mark('TYPED:' + q.value);",
        "purpose": "Reduced Google fixture still exposes typed-text markers.",
    },
    {
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": "mark('SUBMIT:' + q.value);",
        "purpose": "Reduced Google fixture still exposes submit markers.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_repo_root_error(root: str | None, message: str) -> dict[str, object]:
    repo_root = str(Path.cwd()) if root is None else str(Path(root).expanduser())
    return {
        "repo_root": repo_root,
        "checked_count": 0,
        "missing_count": None,
        "missing_path_count": None,
        "results": [],
        "missing_paths": [],
        "error_type": "repo_root_not_found",
        "error": message,
    }


def summarize_missing_paths(results: list[dict[str, object]]) -> list[dict[str, object]]:
    grouped: dict[str, dict[str, object]] = {}
    for result in results:
        if result["exists"]:
            continue
        entry = grouped.setdefault(
            str(result["path"]),
            {
                "path": result["path"],
                "missing_expectation_count": 0,
                "first_missing_purpose": result["purpose"],
                "first_missing_snippet": result.get("snippet"),
                "missing_snippets": [],
            },
        )
        entry["missing_expectation_count"] += 1
        snippet = result.get("snippet")
        if snippet and snippet not in entry["missing_snippets"]:
            entry["missing_snippets"].append(snippet)
    return sorted(grouped.values(), key=lambda item: str(item["path"]))


def build_runtime_revalidation_audit(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    content_cache: dict[Path, str] = {}

    for reference in REFERENCES:
        full_path = repo_root / str(reference["path"])
        exists = full_path.is_file() if reference["kind"] == "file" else full_path.is_dir()
        results.append(
            {
                "check_type": "reference",
                "path": reference["path"],
                "purpose": reference["purpose"],
                "exists": exists,
            }
        )

    for expectation in CONTENT_EXPECTATIONS:
        full_path = repo_root / str(expectation["path"])
        if full_path.is_file():
            if full_path not in content_cache:
                content_cache[full_path] = full_path.read_text(encoding="utf-8")
            exists = str(expectation["snippet"]) in content_cache[full_path]
        else:
            exists = False
        results.append(
            {
                "check_type": "content",
                "path": expectation["path"],
                "purpose": expectation["purpose"],
                "snippet": expectation["snippet"],
                "exists": exists,
            }
        )

    missing = [result for result in results if not result["exists"]]
    missing_paths = summarize_missing_paths(results)
    return {
        "repo_root": str(repo_root),
        "checked_count": len(results),
        "missing_count": len(missing),
        "missing_path_count": len(missing_paths),
        "results": results,
        "missing_paths": missing_paths,
    }


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Google Issue #3 Enter-Submit Runtime Revalidation Audit",
        "",
        f"Repo root: {audit['repo_root']}",
    ]
    if audit.get("error_type"):
        lines.extend([f"Error: {audit['error']}", ""])
        return "\n".join(lines).rstrip() + "\n"

    lines.extend(
        [
            f"Checked expectations: {audit['checked_count']}",
            f"Missing expectations: {audit['missing_count']}",
            f"Missing paths: {audit['missing_path_count']}",
            "",
        ]
    )

    if audit["missing_paths"]:
        lines.append("Missing path summary:")
        for entry in audit["missing_paths"]:
            lines.append(
                f"[FAIL] {entry['path']}: {entry['missing_expectation_count']} missing expectation(s)"
            )
            if entry.get("first_missing_purpose"):
                lines.append(f"  First purpose: {entry['first_missing_purpose']}")
            if entry.get("first_missing_snippet"):
                lines.append(f"  First snippet: {entry['first_missing_snippet']}")
        lines.append("")

    for result in audit["results"]:
        status = "PASS" if result["exists"] else "FAIL"
        lines.append(f"[{status}] {result['path']}")
        lines.append(f"  {result['purpose']}")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #3 runtime revalidation note, reduced Google "
            "probe, and reduced fixture still line up before reopening the "
            "Page.zig and win32_backend.zig Enter-submit patch."
        )
    )
    parser.add_argument(
        "--repo-root",
        help="Browser repo root to inspect. Defaults to the current directory.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print structured JSON instead of text.",
    )
    args = parser.parse_args(argv)

    try:
        repo_root = resolve_repo_root(args.repo_root)
        audit = build_runtime_revalidation_audit(repo_root)
    except FileNotFoundError as exc:
        audit = build_repo_root_error(args.repo_root, str(exc))

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 0 if not audit.get("error_type") and not audit.get("missing_count") else 1


if __name__ == "__main__":
    raise SystemExit(main())
