import argparse
import json
from pathlib import Path


RAW_LAUNCHER = "start_attached_pages_catalog.py"
WRAPPER_LAUNCHER = "start_attached_pages_catalog.ps1"
SIDECAR_FLAG = "AuditSidecars"
GOOGLE_FLAG = "GoogleStyle"
DEFAULT_RELATIVE_PATHS = (
    "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
)


def resolve_paths(repo_root: Path, explicit_paths: list[str] | None) -> list[Path]:
    selected = explicit_paths or list(DEFAULT_RELATIVE_PATHS)
    paths: list[Path] = []
    for candidate in selected:
        candidate_path = Path(candidate)
        path = (repo_root / candidate).resolve() if not candidate_path.is_absolute() else candidate_path.resolve()
        if not path.is_file():
            raise FileNotFoundError(f"missing replay-note source: {path}")
        paths.append(path)
    return paths


def audit_paths(paths: list[Path], repo_root: Path) -> dict[str, object]:
    file_results: list[dict[str, object]] = []
    raw_count = 0
    wrapper_count = 0
    wrapper_sidecar_count = 0
    google_wrapper_sidecar_count = 0

    for path in paths:
        text = path.read_text(encoding="utf-8", errors="ignore")
        relative_path = path.relative_to(repo_root).as_posix()
        raw_hits: list[dict[str, object]] = []
        wrapper_hits: list[dict[str, object]] = []

        for line_number, line in enumerate(text.splitlines(), start=1):
            if RAW_LAUNCHER in line:
                raw_hits.append({"line_number": line_number, "line": line.rstrip()})
            if WRAPPER_LAUNCHER in line:
                wrapper_hits.append(
                    {
                        "line_number": line_number,
                        "line": line.rstrip(),
                        "mentions_sidecars": SIDECAR_FLAG in line,
                        "mentions_google_style": GOOGLE_FLAG in line,
                    }
                )

        raw_count += len(raw_hits)
        wrapper_count += len(wrapper_hits)
        wrapper_sidecar_count += sum(1 for hit in wrapper_hits if hit["mentions_sidecars"])
        google_wrapper_sidecar_count += sum(
            1 for hit in wrapper_hits if hit["mentions_sidecars"] and hit["mentions_google_style"]
        )

        file_results.append(
            {
                "path": str(path),
                "display_path": relative_path,
                "raw_python_reference_count": len(raw_hits),
                "raw_python_references": raw_hits,
                "wrapper_reference_count": len(wrapper_hits),
                "wrapper_references": wrapper_hits,
            }
        )

    return {
        "repo_root": str(repo_root),
        "file_count": len(file_results),
        "raw_python_reference_count": raw_count,
        "wrapper_reference_count": wrapper_count,
        "wrapper_sidecar_reference_count": wrapper_sidecar_count,
        "google_wrapper_sidecar_reference_count": google_wrapper_sidecar_count,
        "files": file_results,
    }


def failure_reasons(audit: dict[str, object]) -> list[str]:
    reasons: list[str] = []
    if audit["raw_python_reference_count"] > 0:
        reasons.append("raw Python attached-pages launcher references remain in replay notes")
    if audit["wrapper_reference_count"] == 0:
        reasons.append("replay notes do not mention the wrapper-backed attached-pages launcher")
    if audit["wrapper_sidecar_reference_count"] == 0:
        reasons.append("replay notes do not keep the wrapper-backed sidecar audit visible")
    if audit["google_wrapper_sidecar_reference_count"] == 0:
        reasons.append("replay notes do not keep the Google-style wrapper-backed sidecar audit visible")
    return reasons


def render_text(audit: dict[str, object], reasons: list[str]) -> str:
    lines = [
        "Issue #3 Replay Note Launcher Contract",
        "",
        f"Repo root: {audit['repo_root']}",
        f"Files scanned: {audit['file_count']}",
        f"Raw Python references: {audit['raw_python_reference_count']}",
        f"Wrapper references: {audit['wrapper_reference_count']}",
        f"Wrapper sidecar references: {audit['wrapper_sidecar_reference_count']}",
        f"Google-style wrapper sidecar references: {audit['google_wrapper_sidecar_reference_count']}",
        "",
    ]

    for file_result in audit["files"]:
        lines.append(f"File: {file_result['display_path']}")
        lines.append(f"  Raw Python references: {file_result['raw_python_reference_count']}")
        lines.append(f"  Wrapper references: {file_result['wrapper_reference_count']}")
        for hit in file_result["raw_python_references"][:5]:
            lines.append(f"  Raw line {hit['line_number']}: {hit['line']}")
        for hit in file_result["wrapper_references"][:5]:
            lines.append(f"  Wrapper line {hit['line_number']}: {hit['line']}")
        lines.append("")

    for reason in reasons:
        lines.append(f"FAIL: {reason}")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Fail if the issue #3 replay notes drift back to raw attached-pages launcher commands."
    )
    parser.add_argument("--repo-root", default=".", help="Repo root that contains the replay-note docs.")
    parser.add_argument(
        "--path",
        action="append",
        dest="paths",
        help="Explicit replay-note path to inspect. Repeat to override the default note pair.",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of the text report.")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    paths = resolve_paths(repo_root, args.paths)
    audit = audit_paths(paths, repo_root)
    reasons = failure_reasons(audit)

    if args.json:
        payload = dict(audit)
        payload["failure_reasons"] = reasons
        print(json.dumps(payload, indent=2))
    else:
        print(render_text(audit, reasons), end="")

    return 1 if reasons else 0


if __name__ == "__main__":
    raise SystemExit(main())