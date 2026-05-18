import argparse
import json
import os
import sys
from pathlib import Path


TARGET_DOCS = (
    "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
    "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
    "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md",
)
RAW_LAUNCHER_NEEDLE = "start_attached_pages_catalog.py"
WRAPPER_LAUNCHER_NEEDLE = r"scripts\windows\start_attached_pages_catalog.ps1"
LAUNCHER_COMPANION_NEEDLE = (
    r"scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1"
)
LAUNCHER_COMPANION_SURFACE_CHECK_NEEDLE = (
    r"scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1"
)
SIDECAR_SWITCH_NEEDLE = "AuditSidecars"
GOOGLE_STYLE_NEEDLE = "GoogleStyle"


def resolve_repo_root(start_path: Path) -> Path:
    override = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
    if override:
        return Path(override).expanduser().resolve()

    cursor = start_path.expanduser().resolve()
    if cursor.is_file():
        cursor = cursor.parent

    while True:
        if (cursor / "build.zig").is_file():
            return cursor
        parent = cursor.parent
        if parent == cursor:
            raise FileNotFoundError(
                f"could not resolve the Lightpanda repo root from {start_path}"
            )
        cursor = parent


def build_replay_doc_audit(repo_root: Path) -> dict[str, object]:
    resolved_root = repo_root.expanduser().resolve()
    file_results: list[dict[str, object]] = []
    raw_reference_count = 0
    wrapper_reference_count = 0
    wrapper_sidecar_reference_count = 0
    google_wrapper_sidecar_reference_count = 0
    launcher_companion_reference_count = 0
    launcher_companion_surface_check_reference_count = 0

    for relative_path in TARGET_DOCS:
        path = resolved_root / relative_path
        if not path.is_file():
            raise FileNotFoundError(f"required replay note not found: {path}")

        raw_lines: list[dict[str, object]] = []
        wrapper_lines: list[dict[str, object]] = []
        launcher_companion_lines: list[dict[str, object]] = []
        launcher_companion_surface_check_lines: list[dict[str, object]] = []

        text = path.read_text(encoding="utf-8", errors="ignore")
        for line_number, line in enumerate(text.splitlines(), start=1):
            if RAW_LAUNCHER_NEEDLE in line:
                raw_lines.append({"line_number": line_number, "line": line.rstrip()})
            if WRAPPER_LAUNCHER_NEEDLE in line:
                wrapper_line = {
                    "line_number": line_number,
                    "line": line.rstrip(),
                    "mentions_sidecars": SIDECAR_SWITCH_NEEDLE in line,
                    "mentions_google_style": GOOGLE_STYLE_NEEDLE in line,
                }
                wrapper_lines.append(wrapper_line)
            if LAUNCHER_COMPANION_NEEDLE in line:
                launcher_companion_lines.append(
                    {"line_number": line_number, "line": line.rstrip()}
                )
            if LAUNCHER_COMPANION_SURFACE_CHECK_NEEDLE in line:
                launcher_companion_surface_check_lines.append(
                    {"line_number": line_number, "line": line.rstrip()}
                )

        file_wrapper_sidecar_reference_count = sum(
            1 for line in wrapper_lines if line["mentions_sidecars"]
        )
        file_google_wrapper_sidecar_reference_count = sum(
            1
            for line in wrapper_lines
            if line["mentions_sidecars"] and line["mentions_google_style"]
        )

        raw_reference_count += len(raw_lines)
        wrapper_reference_count += len(wrapper_lines)
        wrapper_sidecar_reference_count += file_wrapper_sidecar_reference_count
        google_wrapper_sidecar_reference_count += (
            file_google_wrapper_sidecar_reference_count
        )
        launcher_companion_reference_count += len(launcher_companion_lines)
        launcher_companion_surface_check_reference_count += len(
            launcher_companion_surface_check_lines
        )

        file_results.append(
            {
                "path": str(path),
                "display_path": relative_path,
                "raw_python_references": raw_lines,
                "raw_python_reference_count": len(raw_lines),
                "wrapper_references": wrapper_lines[:20],
                "wrapper_reference_count": len(wrapper_lines),
                "wrapper_sidecar_reference_count": file_wrapper_sidecar_reference_count,
                "google_wrapper_sidecar_reference_count": (
                    file_google_wrapper_sidecar_reference_count
                ),
                "launcher_companion_references": launcher_companion_lines[:20],
                "launcher_companion_reference_count": len(launcher_companion_lines),
                "launcher_companion_surface_check_references": (
                    launcher_companion_surface_check_lines[:20]
                ),
                "launcher_companion_surface_check_reference_count": len(
                    launcher_companion_surface_check_lines
                ),
            }
        )

    return {
        "repo_root": str(resolved_root),
        "target_doc_count": len(file_results),
        "target_docs": list(TARGET_DOCS),
        "raw_python_reference_count": raw_reference_count,
        "wrapper_reference_count": wrapper_reference_count,
        "wrapper_sidecar_reference_count": wrapper_sidecar_reference_count,
        "google_wrapper_sidecar_reference_count": (
            google_wrapper_sidecar_reference_count
        ),
        "launcher_companion_reference_count": launcher_companion_reference_count,
        "launcher_companion_surface_check_reference_count": (
            launcher_companion_surface_check_reference_count
        ),
        "files": file_results,
    }


def collect_failure_reasons(
    audit: dict[str, object],
    *,
    allow_raw_launcher: bool,
    require_wrapper_sidecar: bool,
    require_google_wrapper_sidecar: bool,
    require_launcher_companion: bool,
    require_launcher_companion_surface_check: bool,
) -> list[str]:
    failure_reasons: list[str] = []
    if audit["raw_python_reference_count"] > 0 and not allow_raw_launcher:
        failure_reasons.append("raw Python attached-pages launcher references remain")
    if require_wrapper_sidecar and audit["wrapper_sidecar_reference_count"] == 0:
        failure_reasons.append(
            "no wrapper-backed sidecar audit references were found in the replay notes"
        )
    if (
        require_google_wrapper_sidecar
        and audit["google_wrapper_sidecar_reference_count"] == 0
    ):
        failure_reasons.append(
            "no Google-style wrapper-backed sidecar audit references were found in the replay notes"
        )
    if (
        require_launcher_companion
        and audit["launcher_companion_reference_count"] == 0
    ):
        failure_reasons.append(
            "no launcher companion helper references were found in the replay notes"
        )
    if (
        require_launcher_companion_surface_check
        and audit["launcher_companion_surface_check_reference_count"] == 0
    ):
        failure_reasons.append(
            "no launcher companion surface-check references were found in the replay notes"
        )
    return failure_reasons


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Issue #3 Replay Docs Launcher Audit",
        "",
        f"Repo root: {audit['repo_root']}",
        f"Target docs: {audit['target_doc_count']}",
        f"Raw Python launcher references: {audit['raw_python_reference_count']}",
        f"Wrapper references: {audit['wrapper_reference_count']}",
        f"Wrapper sidecar references: {audit['wrapper_sidecar_reference_count']}",
        (
            "Google-style wrapper sidecar references: "
            f"{audit['google_wrapper_sidecar_reference_count']}"
        ),
        (
            "Launcher companion references: "
            f"{audit['launcher_companion_reference_count']}"
        ),
        (
            "Launcher companion surface-check references: "
            f"{audit['launcher_companion_surface_check_reference_count']}"
        ),
        "",
    ]

    for file_result in audit["files"]:
        lines.append(f"File: {file_result['display_path']}")
        lines.append(
            f"Raw Python references: {file_result['raw_python_reference_count']}"
        )
        for entry in file_result["raw_python_references"][:5]:
            lines.append(f"  line {entry['line_number']}: {entry['line']}")
        lines.append(f"Wrapper references: {file_result['wrapper_reference_count']}")
        lines.append(
            f"Wrapper sidecar references: {file_result['wrapper_sidecar_reference_count']}"
        )
        lines.append(
            "Google-style wrapper sidecar references: "
            f"{file_result['google_wrapper_sidecar_reference_count']}"
        )
        lines.append(
            "Launcher companion references: "
            f"{file_result['launcher_companion_reference_count']}"
        )
        lines.append(
            "Launcher companion surface-check references: "
            f"{file_result['launcher_companion_surface_check_reference_count']}"
        )
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Audit the issue #3 replay docs for stale raw-Python attached-pages "
            "launcher references, wrapper-backed sidecar coverage, and launcher-"
            "companion surfacing."
        )
    )
    parser.add_argument("--repo-root", help="Override the Lightpanda repo root.")
    parser.add_argument("--json", action="store_true", help="Print JSON output.")
    parser.add_argument(
        "--allow-raw-launcher",
        action="store_true",
        help="Return success even when raw Python launcher references remain.",
    )
    parser.add_argument(
        "--require-wrapper-sidecar",
        action="store_true",
        help="Require at least one wrapper-backed sidecar audit reference.",
    )
    parser.add_argument(
        "--require-google-wrapper-sidecar",
        action="store_true",
        help="Require at least one Google-style wrapper-backed sidecar audit reference.",
    )
    parser.add_argument(
        "--require-launcher-companion",
        action="store_true",
        help="Require at least one launcher companion helper reference.",
    )
    parser.add_argument(
        "--require-launcher-companion-surface-check",
        action="store_true",
        help="Require at least one launcher companion surface-check reference.",
    )
    args = parser.parse_args(argv)

    repo_root = (
        Path(args.repo_root).expanduser().resolve()
        if args.repo_root
        else resolve_repo_root(Path(__file__))
    )
    audit = build_replay_doc_audit(repo_root)
    failure_reasons = collect_failure_reasons(
        audit,
        allow_raw_launcher=args.allow_raw_launcher,
        require_wrapper_sidecar=args.require_wrapper_sidecar,
        require_google_wrapper_sidecar=args.require_google_wrapper_sidecar,
        require_launcher_companion=args.require_launcher_companion,
        require_launcher_companion_surface_check=(
            args.require_launcher_companion_surface_check
        ),
    )

    if args.json:
        payload = dict(audit)
        payload["failure_reasons"] = failure_reasons
        print(json.dumps(payload, indent=2))
    else:
        print(render_text_report(audit), end="")
        for reason in failure_reasons:
            print(f"FAIL: {reason}", file=sys.stderr)

    return 1 if failure_reasons else 0


if __name__ == "__main__":
    raise SystemExit(main())