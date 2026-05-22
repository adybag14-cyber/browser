import argparse
import importlib
import json
from pathlib import Path


DEFAULT_AUDIT_SPECS = (
    {
        "name": "launcher-companion",
        "label": "Launcher companion",
        "module": "google_issue3_attached_pages_launcher_companion_audit",
        "builder_name": "build_launcher_companion_audit",
    },
    {
        "name": "windows-replay-quickstart",
        "label": "Windows replay quickstart",
        "module": "google_issue3_windows_replay_attached_html_quickstart_audit",
        "builder_name": "build_replay_attached_quickstart_audit",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_repo_root_error_matrix(root: str | None, message: str) -> dict[str, object]:
    repo_root = str(Path.cwd()) if root is None else str(Path(root).expanduser())
    return {
        "repo_root": repo_root,
        "surface_count": 0,
        "failing_surface_count": 0,
        "total_missing_count": None,
        "recommended_focus": None,
        "surfaces": [],
        "error_type": "repo_root_not_found",
        "error": message,
    }


def load_audits(
    audit_specs: tuple[dict[str, object], ...] | list[dict[str, object]] | None = None,
) -> list[dict[str, object]]:
    specs = DEFAULT_AUDIT_SPECS if audit_specs is None else audit_specs
    audits: list[dict[str, object]] = []
    for spec in specs:
        builder = spec.get("builder")
        if not callable(builder):
            module = importlib.import_module(str(spec["module"]))
            builder = getattr(module, str(spec["builder_name"]))
        audits.append(
            {
                "name": str(spec["name"]),
                "label": str(spec["label"]),
                "builder": builder,
            }
        )
    return audits


def summarize_surface(name: str, label: str, audit: dict[str, object]) -> dict[str, object]:
    missing_paths = audit.get("missing_paths", []) or []
    missing_count = audit.get("missing_count")
    missing_path_count = audit.get("missing_path_count")
    first_missing = missing_paths[0] if missing_paths else None

    if audit.get("error_type"):
        status = "error"
    elif missing_count:
        status = "drift"
    else:
        status = "clean"

    return {
        "name": name,
        "label": label,
        "status": status,
        "expectation_count": audit.get("expectation_count"),
        "missing_count": missing_count,
        "missing_path_count": missing_path_count,
        "first_missing_path": None if first_missing is None else first_missing.get("path"),
        "first_missing_purpose": None
        if first_missing is None
        else first_missing.get("first_missing_purpose"),
        "first_missing_snippet": None
        if first_missing is None
        else first_missing.get("first_missing_snippet"),
    }


def build_attached_pages_audit_matrix(
    repo_root: Path,
    audits: tuple[dict[str, object], ...] | list[dict[str, object]] | None = None,
) -> dict[str, object]:
    surfaces: list[dict[str, object]] = []
    total_missing_count = 0
    failing_surface_count = 0

    for audit_spec in load_audits(audits):
        audit = audit_spec["builder"](repo_root)
        surface = summarize_surface(audit_spec["name"], audit_spec["label"], audit)
        surfaces.append(surface)
        if surface["status"] != "clean":
            failing_surface_count += 1
        total_missing_count += int(surface["missing_count"] or 0)

    drifted = [surface for surface in surfaces if surface["status"] == "drift"]
    recommended_focus = None
    if drifted:
        recommended_focus = max(
            drifted,
            key=lambda surface: (
                int(surface["missing_count"] or 0),
                int(surface["missing_path_count"] or 0),
                surface["name"],
            ),
        )

    return {
        "repo_root": str(repo_root),
        "surface_count": len(surfaces),
        "failing_surface_count": failing_surface_count,
        "total_missing_count": total_missing_count,
        "recommended_focus": None
        if recommended_focus is None
        else {
            "name": recommended_focus["name"],
            "label": recommended_focus["label"],
            "missing_count": recommended_focus["missing_count"],
            "missing_path_count": recommended_focus["missing_path_count"],
            "first_missing_path": recommended_focus["first_missing_path"],
            "first_missing_purpose": recommended_focus["first_missing_purpose"],
        },
        "surfaces": surfaces,
    }


def render_text_report(matrix: dict[str, object]) -> str:
    lines = [
        "Google Issue #3 Attached-Pages Audit Matrix",
        "",
        f"Repo root: {matrix['repo_root']}",
    ]

    if matrix.get("error_type"):
        lines.extend([f"Error: {matrix['error']}", ""])
        return "\n".join(lines).rstrip() + "\n"

    lines.extend(
        [
            f"Audited surfaces: {matrix['surface_count']}",
            f"Drifted surfaces: {matrix['failing_surface_count']}",
            f"Missing expectations: {matrix['total_missing_count']}",
            "",
        ]
    )

    recommended_focus = matrix.get("recommended_focus")
    if recommended_focus:
        lines.extend(
            [
                "Recommended focus:",
                (
                    f"- {recommended_focus['label']} "
                    f"({recommended_focus['missing_count']} missing expectations across "
                    f"{recommended_focus['missing_path_count']} path(s))"
                ),
            ]
        )
        if recommended_focus.get("first_missing_path"):
            lines.append(f"  First path: {recommended_focus['first_missing_path']}")
        if recommended_focus.get("first_missing_purpose"):
            lines.append(f"  First purpose: {recommended_focus['first_missing_purpose']}")
        lines.append("")

    for surface in matrix["surfaces"]:
        lines.append(
            f"[{surface['status'].upper()}] {surface['label']}: "
            f"{surface['missing_count']} missing expectation(s)"
        )
        if surface.get("first_missing_path"):
            lines.append(f"  First path: {surface['first_missing_path']}")
        if surface.get("first_missing_purpose"):
            lines.append(f"  First purpose: {surface['first_missing_purpose']}")
        if surface.get("first_missing_snippet"):
            lines.append(f"  First snippet: {surface['first_missing_snippet']}")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Summarize the issue #3 attached-pages audit surfaces so the next "
            "headed replay slice can target the largest real drift first."
        )
    )
    parser.add_argument(
        "--repo-root",
        help="Lightpanda repo root to inspect. Defaults to the current directory.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print structured JSON instead of text.",
    )
    args = parser.parse_args(argv)

    try:
        repo_root = resolve_repo_root(args.repo_root)
        matrix = build_attached_pages_audit_matrix(repo_root)
    except FileNotFoundError as exc:
        matrix = build_repo_root_error_matrix(args.repo_root, str(exc))

    if args.json:
        print(json.dumps(matrix, indent=2))
    else:
        print(render_text_report(matrix), end="")

    return 0 if not matrix.get("error_type") and not matrix.get("failing_surface_count") else 1


if __name__ == "__main__":
    raise SystemExit(main())