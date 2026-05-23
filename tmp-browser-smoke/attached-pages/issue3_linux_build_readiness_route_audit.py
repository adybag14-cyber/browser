import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/HEADED_MODE_ROADMAP.md",
        "snippet": "bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "purpose": "The headed roadmap keeps the Linux build-readiness surface check visible in the top-level validation router.",
    },
    {
        "path": "docs/HEADED_MODE_ROADMAP.md",
        "snippet": "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "purpose": "The headed roadmap keeps the Linux build-readiness helper visible in the top-level validation router.",
    },
    {
        "path": "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
        "snippet": "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "purpose": "The production guide keeps the Linux build-readiness note in the direct issue #3 runtime route.",
    },
    {
        "path": "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
        "snippet": "bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "purpose": "The production guide keeps the Linux build-readiness surface check visible before focused Zig validation.",
    },
    {
        "path": "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
        "snippet": "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "purpose": "The production guide keeps the Linux build-readiness helper visible before focused Zig validation.",
    },
    {
        "path": "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "snippet": "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "purpose": "The runtime re-entry gates note points blocked Linux or WSL reruns at the build-readiness route note.",
    },
    {
        "path": "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "snippet": "bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "purpose": "The runtime re-entry gates note keeps the Linux build-readiness surface check visible before focused Zig validation.",
    },
    {
        "path": "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "snippet": "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "purpose": "The runtime re-entry gates note keeps the Linux build-readiness helper visible before focused Zig validation.",
    },
    {
        "path": "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "snippet": "check_issue3_linux_build_readiness_route_surface.sh",
        "purpose": "The Linux build-readiness note keeps its own fail-fast surface checker visible.",
    },
    {
        "path": "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "snippet": "scripts/check_linux_build_readiness.py",
        "purpose": "The Linux build-readiness note keeps the readiness helper named explicitly.",
    },
    {
        "path": "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "snippet": "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "purpose": "The Linux build-readiness note keeps the route printer named explicitly.",
    },
    {
        "path": "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "snippet": "saved Rust `1.79.0` restore command",
        "purpose": "The Linux build-readiness note keeps the saved Rust restore step visible before trusting Linux or WSL Zig output.",
    },
    {
        "path": "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "snippet": "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        "purpose": "The Linux build-readiness note keeps the attached fallback Zig archive visible as a surfaced input.",
    },
    {
        "path": "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "snippet": "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "purpose": "The Linux surface checker keeps the runtime gate note in its reference set.",
    },
    {
        "path": "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "snippet": "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "purpose": "The Linux surface checker keeps the build-readiness note in its reference set.",
    },
    {
        "path": "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "snippet": "scripts/check_linux_build_readiness.py",
        "purpose": "The Linux surface checker keeps the readiness helper in its reference set.",
    },
    {
        "path": "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "snippet": "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "purpose": "The Linux surface checker keeps the route printer in its reference set.",
    },
    {
        "path": "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "snippet": "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        "purpose": "The Linux surface checker keeps the fallback Zig archive contract visible.",
    },
    {
        "path": "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "snippet": "check_issue3_linux_build_readiness_route_surface.sh",
        "purpose": "The Linux route printer points back to the fail-fast surface checker.",
    },
    {
        "path": "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "snippet": "scripts/check_linux_build_readiness.py",
        "purpose": "The Linux route printer still points at the readiness helper.",
    },
    {
        "path": "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "snippet": "restore_saved_rust_toolchain.sh",
        "purpose": "The Linux route printer still points at the saved Rust restore helper.",
    },
    {
        "path": "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "snippet": "fallback-zig-archive",
        "purpose": "The Linux route printer still supports an explicit attached fallback Zig archive override.",
    },
    {
        "path": "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "snippet": "Fallback Zig archive:",
        "purpose": "The Linux route printer still prints the attached fallback Zig archive surface.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_repo_root_error_audit(root: str | None, message: str) -> dict[str, object]:
    repo_root = str((Path.cwd() if root is None else Path(root)).expanduser().resolve())
    return {
        "repo_root": repo_root,
        "expectation_count": len(EXPECTATIONS),
        "missing_count": None,
        "missing_path_count": None,
        "missing_paths": [],
        "results": [],
        "error_type": "repo_root_not_found",
        "error": message,
    }


def summarize_missing_paths(results: list[dict[str, object]]) -> list[dict[str, object]]:
    missing_by_path: dict[str, list[dict[str, object]]] = {}

    for result in results:
        if result["exists"]:
            continue
        missing_by_path.setdefault(result["path"], []).append(result)

    summary: list[dict[str, object]] = []
    for path in sorted(missing_by_path):
        entries = missing_by_path[path]
        summary.append(
            {
                "path": path,
                "missing_expectation_count": len(entries),
                "first_missing_purpose": entries[0]["purpose"],
                "first_missing_snippet": entries[0]["snippet"],
            }
        )

    return summary


def build_linux_build_readiness_route_audit(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    missing_count = 0

    for expectation in EXPECTATIONS:
        full_path = repo_root / expectation["path"]
        if not full_path.is_file():
            exists = False
        else:
            exists = expectation["snippet"] in full_path.read_text(
                encoding="utf-8", errors="ignore"
            )

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

    missing_paths = summarize_missing_paths(results)
    return {
        "repo_root": str(repo_root),
        "expectation_count": len(results),
        "missing_count": missing_count,
        "missing_path_count": len(missing_paths),
        "missing_paths": missing_paths,
        "results": results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    if audit.get("error"):
        return "\n".join(
            [
                "Issue #3 Linux Build-Readiness Route Audit",
                "",
                f"Repo root: {audit['repo_root']}",
                f"Error: {audit['error']}",
                "",
            ]
        )

    lines = [
        "Issue #3 Linux Build-Readiness Route Audit",
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

    missing_paths = audit.get("missing_paths", [])
    if missing_paths:
        lines.append("")
        lines.append("Missing path summary:")
        for entry in missing_paths:
            lines.append(
                f"- {entry['path']}: {entry['missing_expectation_count']} missing expectation(s)"
            )
            lines.append(f"  first gap: {entry['first_missing_purpose']}")
            lines.append(f"  first snippet: {entry['first_missing_snippet']}")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit the issue #3 Linux build-readiness route for doc and helper drift."
    )
    parser.add_argument(
        "--repo-root",
        help="Lightpanda repo root to inspect. Defaults to the current directory.",
    )
    parser.add_argument(
        "--json", action="store_true", help="Print structured JSON instead of text."
    )
    args = parser.parse_args(argv)

    try:
        repo_root = resolve_repo_root(args.repo_root)
    except FileNotFoundError as err:
        audit = build_repo_root_error_audit(args.repo_root, str(err))
        if args.json:
            print(json.dumps(audit, indent=2))
        else:
            print(render_text_report(audit), end="")
        return 1

    audit = build_linux_build_readiness_route_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())