import argparse
import importlib
import json
from pathlib import Path


DEFAULT_AUDIT_SPECS = (
    {
        "name": "branch-inventory",
        "label": "Branch inventory",
        "module": "google_issue3_attached_pages_audit_matrix",
        "builder_name": "build_branch_inventory_audit",
    },
    {
        "name": "live-surface-inventory",
        "label": "Live surface inventory",
        "module": "google_issue3_attached_pages_audit_matrix",
        "builder_name": "build_live_surface_inventory_audit",
    },
    {
        "name": "launcher-companion",
        "label": "Launcher companion",
        "module": "google_issue3_attached_pages_launcher_companion_audit",
        "builder_name": "build_launcher_companion_audit",
    },
    {
        "name": "target-bundle-proof-entrypoint",
        "label": "Target bundle proof entrypoint",
        "module": "google_issue3_attached_html_target_bundle_proof_entrypoint_audit",
        "builder_name": "build_proof_entrypoint_audit",
    },
    {
        "name": "windows-replay-quickstart",
        "label": "Windows replay quickstart",
        "module": "google_issue3_windows_replay_attached_html_quickstart_audit",
        "builder_name": "build_replay_attached_quickstart_audit",
    },
    {
        "name": "windows-full-use-route",
        "label": "Windows full-use route",
        "module": "google_issue3_windows_full_use_attached_html_route_audit",
        "builder_name": "build_route_audit",
    },
)


def normalize_selected_surface_names(
    selected_names: set[str] | list[str] | tuple[str, ...] | None,
) -> set[str]:
    if not selected_names:
        return set()
    return {name.strip() for name in selected_names if name and name.strip()}


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_repo_root_error_matrix(
    root: str | None,
    message: str,
    *,
    selected_names: set[str] | list[str] | tuple[str, ...] | None = None,
) -> dict[str, object]:
    repo_root = str(Path.cwd()) if root is None else str(Path(root).expanduser())
    return {
        "repo_root": repo_root,
        "selected_surfaces": sorted(normalize_selected_surface_names(selected_names)),
        "surface_count": 0,
        "failing_surface_count": 0,
        "total_missing_count": None,
        "recommended_focus": None,
        "surfaces": [],
        "error_type": "repo_root_not_found",
        "error": message,
    }


def build_invalid_surface_selection_matrix(
    root: str | None,
    selected_names: set[str] | list[str] | tuple[str, ...],
    available_names: set[str] | list[str] | tuple[str, ...],
) -> dict[str, object]:
    normalized_selected = normalize_selected_surface_names(selected_names)
    normalized_available = normalize_selected_surface_names(available_names)
    unknown_names = sorted(normalized_selected - normalized_available)
    repo_root = str(Path.cwd()) if root is None else str(Path(root).expanduser())
    return {
        "repo_root": repo_root,
        "selected_surfaces": sorted(normalized_selected),
        "available_surfaces": sorted(normalized_available),
        "surface_count": 0,
        "failing_surface_count": 0,
        "total_missing_count": None,
        "recommended_focus": None,
        "surfaces": [],
        "error_type": "invalid_surface_selection",
        "error": "unknown surface selection: " + ", ".join(unknown_names),
    }


def load_audit_specs(
    audit_specs: tuple[dict[str, object], ...] | list[dict[str, object]] | None = None,
    *,
    selected_names: set[str] | list[str] | tuple[str, ...] | None = None,
) -> list[dict[str, object]]:
    specs = DEFAULT_AUDIT_SPECS if audit_specs is None else audit_specs
    normalized_selected = normalize_selected_surface_names(selected_names)
    loaded_specs = [
        {
            "name": str(spec["name"]),
            "label": str(spec["label"]),
            "builder": spec.get("builder"),
            "module": spec.get("module"),
            "builder_name": spec.get("builder_name"),
        }
        for spec in specs
    ]
    if not normalized_selected:
        return loaded_specs
    return [spec for spec in loaded_specs if spec["name"] in normalized_selected]


def resolve_audit_builder(spec: dict[str, object]):
    builder = spec.get("builder")
    if callable(builder):
        return builder
    module = importlib.import_module(str(spec["module"]))
    return getattr(module, str(spec["builder_name"]))


def summarize_inventory_rows(
    rows: list[dict[str, object]],
    *,
    missing_snippet_prefix: str,
) -> dict[str, object]:
    missing_rows = [row for row in rows if not row.get("exists")]
    return {
        "expectation_count": len(rows),
        "missing_count": len(missing_rows),
        "missing_path_count": len(missing_rows),
        "missing_paths": [
            {
                "path": row.get("path"),
                "first_missing_purpose": row.get("purpose"),
                "first_missing_snippet": (
                    f"{missing_snippet_prefix}: {row.get('kind', 'path')} missing"
                ),
            }
            for row in missing_rows
        ],
    }


def build_branch_inventory_audit(repo_root: Path) -> dict[str, object]:
    module = importlib.import_module("google_issue3_attached_pages_branch_inventory_audit")
    inventory = module.build_inventory(
        repo_root,
        [dict(target) for target in module.DEFAULT_TARGETS],
    )
    return summarize_inventory_rows(
        inventory["results"],
        missing_snippet_prefix="Branch inventory drift",
    )


def build_live_surface_inventory_audit(repo_root: Path) -> dict[str, object]:
    module = importlib.import_module("google_issue3_attached_pages_live_surface_inventory")
    inventory = module.build_inventory(repo_root, set())
    return summarize_inventory_rows(
        inventory,
        missing_snippet_prefix="Live surface inventory drift",
    )


def build_error_surface(name: str, label: str, error: Exception) -> dict[str, object]:
    return {
        "name": name,
        "label": label,
        "status": "error",
        "expectation_count": None,
        "missing_count": None,
        "missing_path_count": None,
        "first_missing_path": None,
        "first_missing_purpose": None,
        "first_missing_snippet": None,
        "error_type": type(error).__name__,
        "error": str(error),
    }


def summarize_surface(name: str, label: str, audit: dict[str, object]) -> dict[str, object]:
    missing_paths = audit.get("missing_paths", []) or []
    missing_count = audit.get("missing_count")
    missing_path_count = audit.get("missing_path_count")
    first_missing = missing_paths[0] if missing_paths else None

    if audit.get("error_type"):
        return {
            "name": name,
            "label": label,
            "status": "error",
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
            "error_type": audit.get("error_type"),
            "error": audit.get("error"),
        }

    status = "drift" if missing_count else "clean"
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
        "error_type": None,
        "error": None,
    }


def build_attached_pages_audit_matrix(
    repo_root: Path,
    audits: tuple[dict[str, object], ...] | list[dict[str, object]] | None = None,
    *,
    selected_names: set[str] | list[str] | tuple[str, ...] | None = None,
) -> dict[str, object]:
    normalized_selected = normalize_selected_surface_names(selected_names)
    surfaces: list[dict[str, object]] = []
    total_missing_count = 0
    failing_surface_count = 0

    for audit_spec in load_audit_specs(audits, selected_names=normalized_selected):
        try:
            audit = resolve_audit_builder(audit_spec)(repo_root)
            surface = summarize_surface(audit_spec["name"], audit_spec["label"], audit)
        except Exception as exc:
            surface = build_error_surface(audit_spec["name"], audit_spec["label"], exc)

        surfaces.append(surface)
        if surface["status"] != "clean":
            failing_surface_count += 1
        total_missing_count += int(surface["missing_count"] or 0)

    failing_surfaces = [surface for surface in surfaces if surface["status"] != "clean"]
    recommended_focus = None
    if failing_surfaces:
        recommended_focus = max(
            failing_surfaces,
            key=lambda surface: (
                2 if surface["status"] == "error" else 1,
                int(surface["missing_count"] or 0),
                int(surface["missing_path_count"] or 0),
                surface["name"],
            ),
        )

    return {
        "repo_root": str(repo_root),
        "selected_surfaces": sorted(normalized_selected),
        "surface_count": len(surfaces),
        "failing_surface_count": failing_surface_count,
        "total_missing_count": total_missing_count,
        "recommended_focus": None
        if recommended_focus is None
        else {
            "name": recommended_focus["name"],
            "label": recommended_focus["label"],
            "status": recommended_focus["status"],
            "missing_count": recommended_focus["missing_count"],
            "missing_path_count": recommended_focus["missing_path_count"],
            "first_missing_path": recommended_focus["first_missing_path"],
            "first_missing_purpose": recommended_focus["first_missing_purpose"],
            "error_type": recommended_focus.get("error_type"),
            "error": recommended_focus.get("error"),
        },
        "surfaces": surfaces,
    }


def render_text_report(matrix: dict[str, object]) -> str:
    lines = [
        "Google Issue #3 Attached-Pages Audit Matrix",
        "",
        f"Repo root: {matrix['repo_root']}",
    ]
    selected_surfaces = matrix.get("selected_surfaces") or []
    lines.append(
        "Selected surfaces: all"
        if not selected_surfaces
        else "Selected surfaces: " + ", ".join(selected_surfaces)
    )

    if matrix.get("error_type"):
        if matrix.get("available_surfaces"):
            lines.append("Available surfaces: " + ", ".join(matrix["available_surfaces"]))
        lines.extend([f"Error: {matrix['error']}", ""])
        return "\n".join(lines).rstrip() + "\n"

    lines.extend(
        [
            f"Audited surfaces: {matrix['surface_count']}",
            f"Failing surfaces: {matrix['failing_surface_count']}",
            f"Missing expectations: {matrix['total_missing_count']}",
            "",
        ]
    )

    recommended_focus = matrix.get("recommended_focus")
    if recommended_focus:
        lines.extend(
            [
                "Recommended focus:",
                f"- {recommended_focus['label']} [{recommended_focus['status']}]",
            ]
        )
        if recommended_focus["status"] == "error":
            lines.append(
                f"  Error: {recommended_focus['error_type']}: {recommended_focus['error']}"
            )
        else:
            lines.append(
                f"  Missing expectations: {recommended_focus['missing_count']} across "
                f"{recommended_focus['missing_path_count']} path(s)"
            )
            if recommended_focus.get("first_missing_path"):
                lines.append(f"  First path: {recommended_focus['first_missing_path']}")
            if recommended_focus.get("first_missing_purpose"):
                lines.append(
                    f"  First purpose: {recommended_focus['first_missing_purpose']}"
                )
        lines.append("")

    for surface in matrix["surfaces"]:
        lines.append(f"[{surface['status'].upper()}] {surface['label']}")
        if surface["status"] == "error":
            lines.append(f"  {surface['error_type']}: {surface['error']}")
            continue
        lines.append(f"  Missing expectations: {surface['missing_count']}")
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
            "headed validation slice can target the largest real drift first."
        )
    )
    parser.add_argument(
        "--repo-root",
        help="Lightpanda repo root to inspect. Defaults to the current directory.",
    )
    parser.add_argument(
        "--surface",
        action="append",
        default=[],
        help=(
            "Limit the audit matrix to one or more surface names such as "
            "branch-inventory or windows-full-use-route."
        ),
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print structured JSON instead of text.",
    )
    args = parser.parse_args(argv)

    selected_names = normalize_selected_surface_names(args.surface)
    available_names = {spec["name"] for spec in load_audit_specs()}
    if selected_names and not selected_names.issubset(available_names):
        matrix = build_invalid_surface_selection_matrix(
            args.repo_root,
            selected_names,
            available_names,
        )
    else:
        try:
            repo_root = resolve_repo_root(args.repo_root)
            matrix = build_attached_pages_audit_matrix(
                repo_root,
                selected_names=selected_names,
            )
        except FileNotFoundError as exc:
            matrix = build_repo_root_error_matrix(
                args.repo_root,
                str(exc),
                selected_names=selected_names,
            )

    if args.json:
        print(json.dumps(matrix, indent=2))
    else:
        print(render_text_report(matrix), end="")

    if matrix.get("error_type") == "invalid_surface_selection":
        return 2
    return 0 if not matrix.get("error_type") and not matrix.get("failing_surface_count") else 1
