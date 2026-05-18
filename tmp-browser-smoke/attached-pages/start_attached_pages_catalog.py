import argparse
import importlib.util
import json
import os
import re
import sys
from pathlib import Path
from types import ModuleType


HTML_EXPORT_EXTENSIONS = {".html", ".htm"}


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


def dedupe_paths(paths: list[Path]) -> list[Path]:
    unique: list[Path] = []
    seen: set[Path] = set()
    for path in paths:
        resolved = path.expanduser().resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        unique.append(resolved)
    return unique


def get_attached_html_search_roots(repo_root: Path, *, cwd: Path | None = None) -> list[Path]:
    roots = [
        repo_root / "user_files",
        repo_root / "agent_files",
    ]

    repo_parent = repo_root.parent
    if repo_parent != repo_root:
        roots.extend(
            [
                repo_parent / "user_files",
                repo_parent / "agent_files",
            ]
        )

    current_root = (cwd or Path.cwd()).expanduser().resolve()
    roots.extend(
        [
            current_root / "user_files",
            current_root / "agent_files",
        ]
    )

    unique_roots = dedupe_paths(roots)
    return [path for path in unique_roots if path.is_dir()]


def collect_html_files_from_root(root: Path) -> list[Path]:
    return sorted(
        path for path in root.rglob("*") if path.is_file() and path.suffix.lower() in HTML_EXPORT_EXTENSIONS
    )


def normalize_explicit_input_paths(input_paths: list[str]) -> list[Path]:
    selected: list[Path] = []
    for raw_path in input_paths:
        path = Path(raw_path).expanduser().resolve()
        if path.is_dir():
            selected.extend(collect_html_files_from_root(path))
            continue
        if not path.is_file():
            raise FileNotFoundError(f"attached HTML input path not found: {path}")
        if path.suffix.lower() not in HTML_EXPORT_EXTENSIONS:
            raise ValueError(f"attached HTML input is not an .html or .htm file: {path}")
        selected.append(path)
    return dedupe_paths(selected)


def discover_attached_html_candidates(repo_root: Path, *, cwd: Path | None = None) -> list[Path]:
    candidates: list[Path] = []
    for root in get_attached_html_search_roots(repo_root, cwd=cwd):
        candidates.extend(collect_html_files_from_root(root))
    return dedupe_paths(candidates)


def google_style_fixture_summary(path: Path) -> dict[str, object]:
    score = 0
    reasons: list[str] = []
    lowered_path = str(path).lower()

    has_query_input = False
    has_search_form = False
    has_google_search_title = False

    if re.search(r"google[-_ ]?(home|search|input|query|submit|probe)", lowered_path):
        score += 6
        reasons.append("google-search path")
    elif re.search(r"search[-_ ]?(home|input|query|submit|probe|results)", lowered_path):
        score += 4
        reasons.append("search path")
    elif re.search(r"\bgoogle\b", lowered_path):
        score += 2
        reasons.append("google path")

    if re.search(r"(safety|privacy|policy|account|support)", lowered_path):
        score -= 4
        reasons.append("marketing path penalty")

    try:
        raw_text = path.read_text(encoding="utf-8", errors="ignore").lower()
    except OSError:
        return {
            "score": score,
            "reasons": reasons,
            "has_query_input": has_query_input,
            "has_search_form": has_search_form,
            "has_google_search_title": has_google_search_title,
        }

    if re.search(r"<title[^>]*>[^<]*google[^<]*(search|home)", raw_text):
        has_google_search_title = True
        score += 6
        reasons.append("google search/home title")
    elif re.search(r"<title[^>]*>[^<]*google[^<]*</title>", raw_text):
        score += 2
        reasons.append("google title")

    if re.search(r"name\s*=\s*['\"]q['\"]", raw_text):
        has_query_input = True
        score += 8
        reasons.append("query input")
    if re.search(r"aria-label\s*=\s*['\"][^'\"]*search[^'\"]*['\"]", raw_text):
        score += 2
        reasons.append("search aria")
    if re.search(r"<form[^>]+action\s*=\s*['\"][^'\"]*/search", raw_text) or re.search(
        r"\b(btnk|apjfqb|glfyf|gsfi)\b", raw_text
    ):
        has_search_form = True
        score += 6
        reasons.append("search form markers")

    if re.search(r"(google safety|safety centre|privacy policy|cookie policy)", raw_text):
        score -= 6
        reasons.append("marketing content penalty")

    return {
        "score": score,
        "reasons": reasons,
        "has_query_input": has_query_input,
        "has_search_form": has_search_form,
        "has_google_search_title": has_google_search_title,
    }


def is_google_style_fixture(path: Path) -> bool:
    summary = google_style_fixture_summary(path)
    return bool(
        summary["score"] > 5
        and (
            summary["has_query_input"]
            or summary["has_search_form"]
            or summary["has_google_search_title"]
        )
    )


def select_attached_html_inputs(
    repo_root: Path,
    *,
    explicit_inputs: list[str] | None = None,
    google_style: bool = False,
    cwd: Path | None = None,
) -> list[Path]:
    if explicit_inputs:
        selected = normalize_explicit_input_paths(explicit_inputs)
    else:
        selected = discover_attached_html_candidates(repo_root, cwd=cwd)

    if not selected:
        raise FileNotFoundError("no attached HTML files were found for the catalog helper")

    if google_style:
        google_candidates = [path for path in selected if is_google_style_fixture(path)]
        if google_candidates:
            selected = google_candidates
        selected = sorted(
            selected,
            key=lambda path: (-int(google_style_fixture_summary(path)["score"]), str(path)),
        )

    return selected


def convert_to_display_path(path: Path, repo_root: Path) -> str:
    resolved_path = path.expanduser().resolve()
    try:
        return resolved_path.relative_to(repo_root).as_posix()
    except ValueError:
        return str(resolved_path)


def describe_fixture_selection(
    fixture_paths: list[Path], *, repo_root: Path, google_style: bool = False
) -> list[str]:
    lines = ["Selected fixtures:"]
    for path in fixture_paths:
        display_path = convert_to_display_path(path, repo_root)
        if google_style:
            summary = google_style_fixture_summary(path)
            reasons = ", ".join(summary["reasons"]) if summary["reasons"] else "no matched hints"
            lines.append(f"- {display_path} (score {summary['score']}: {reasons})")
        else:
            lines.append(f"- {display_path}")
    return lines


def load_server_module(repo_root: Path) -> ModuleType:
    server_path = repo_root / "tmp-browser-smoke" / "attached-pages" / "attached_pages_server.py"
    if not server_path.is_file():
        raise FileNotFoundError(f"attached pages catalog server not found: {server_path}")

    spec = importlib.util.spec_from_file_location("attached_pages_server", server_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"could not load attached pages server module from {server_path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_sidecar_module(repo_root: Path) -> ModuleType:
    sidecar_path = repo_root / "tmp-browser-smoke" / "attached-pages" / "attached_pages_sidecar_audit.py"
    if not sidecar_path.is_file():
        raise FileNotFoundError(f"attached pages sidecar audit helper not found: {sidecar_path}")

    spec = importlib.util.spec_from_file_location("attached_pages_sidecar_audit", sidecar_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"could not load attached pages sidecar audit helper from {sidecar_path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def render_strict_sidecar_failure(report: str) -> str:
    return (
        report.rstrip()
        + "\n\n"
        + "Refusing to continue because the selected attached HTML bundle is missing required sibling _files directories.\n"
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Start or inspect the attached-pages localhost catalog using auto-discovery or explicit pinned inputs."
    )
    parser.add_argument(
        "--input",
        action="append",
        dest="explicit_inputs",
        help="Explicit HTML file or directory to include. Repeat to pin the manifest to selected inputs.",
    )
    parser.add_argument("--repo-root", help="Override the Lightpanda repo root.")
    parser.add_argument("--bind", default="127.0.0.1", help="Address to bind. Defaults to 127.0.0.1.")
    parser.add_argument("--port", type=int, default=8235, help="TCP port to listen on. Defaults to 8235.")
    parser.add_argument(
        "--google-style",
        action="store_true",
        help="Prefer the strongest Google-like attached page first when auto-discovering fixtures.",
    )
    parser.add_argument(
        "--print-manifest",
        action="store_true",
        help="Print the generated manifest JSON and exit instead of starting the server.",
    )
    parser.add_argument(
        "--audit-assets",
        action="store_true",
        help="Audit local asset references for the selected bundle before starting the server.",
    )
    parser.add_argument(
        "--audit-assets-json",
        action="store_true",
        help="Print structured JSON from --audit-assets instead of the text summary.",
    )
    parser.add_argument(
        "--allow-missing-assets",
        action="store_true",
        help="Return success from --audit-assets even when the bundle has missing local assets.",
    )
    parser.add_argument(
        "--audit-sidecars",
        action="store_true",
        help="Audit sibling _files sidecar directories for the selected bundle before starting the server.",
    )
    parser.add_argument(
        "--audit-sidecars-json",
        action="store_true",
        help="Print structured JSON from --audit-sidecars instead of the text summary.",
    )
    parser.add_argument(
        "--allow-missing-sidecars",
        action="store_true",
        help="Return success from --audit-sidecars even when the bundle has missing sidecar directories.",
    )
    parser.add_argument(
        "--require-complete-sidecars",
        action="store_true",
        help="Fail before printing a manifest or starting the server when the selected bundle is missing sibling _files directories.",
    )
    args = parser.parse_args(argv)

    if args.audit_assets_json and not args.audit_assets:
        parser.error("--audit-assets-json requires --audit-assets")
    if args.allow_missing_assets and not args.audit_assets:
        parser.error("--allow-missing-assets requires --audit-assets")
    if args.audit_sidecars_json and not args.audit_sidecars:
        parser.error("--audit-sidecars-json requires --audit-sidecars")
    if args.allow_missing_sidecars and not args.audit_sidecars:
        parser.error("--allow-missing-sidecars requires --audit-sidecars")
    if args.audit_assets and args.audit_sidecars:
        parser.error("choose only one of --audit-assets or --audit-sidecars")

    repo_root = resolve_repo_root(Path(args.repo_root) if args.repo_root else Path(__file__))
    selected_files = select_attached_html_inputs(
        repo_root,
        explicit_inputs=args.explicit_inputs,
        google_style=args.google_style,
    )

    sidecar_module: ModuleType | None = None
    sidecar_audit: dict[str, object] | None = None

    def ensure_sidecar_audit() -> tuple[ModuleType, dict[str, object]]:
        nonlocal sidecar_module, sidecar_audit
        if sidecar_module is None:
            sidecar_module = load_sidecar_module(repo_root)
        if sidecar_audit is None:
            sidecar_audit = sidecar_module.build_sidecar_audit(selected_files=selected_files)
        return sidecar_module, sidecar_audit

    if args.print_manifest:
        if args.require_complete_sidecars:
            sidecar_module, sidecar_audit = ensure_sidecar_audit()
            if sidecar_audit["fixtures_with_missing_sidecars"] > 0:
                print(
                    render_strict_sidecar_failure(sidecar_module.render_text_report(sidecar_audit)),
                    end="",
                    file=sys.stderr,
                )
                return 1
        server_module = load_server_module(repo_root)
        print(json.dumps(server_module.build_manifest(selected_files=selected_files), indent=2))
        return 0

    if args.audit_assets:
        server_module = load_server_module(repo_root)
        audit = server_module.build_asset_audit(selected_files=selected_files)
        if args.audit_assets_json:
            print(json.dumps(audit, indent=2))
        else:
            print(server_module.render_asset_audit_text(audit), end="")
        if audit["fixtures_with_missing_assets"] > 0 and not args.allow_missing_assets:
            return 1
        return 0

    if args.audit_sidecars:
        sidecar_module, sidecar_audit = ensure_sidecar_audit()
        if args.audit_sidecars_json:
            print(json.dumps(sidecar_audit, indent=2))
        else:
            print(sidecar_module.render_text_report(sidecar_audit), end="")
        if sidecar_audit["fixtures_with_missing_sidecars"] > 0 and not args.allow_missing_sidecars:
            return 1
        return 0

    if args.require_complete_sidecars:
        sidecar_module, sidecar_audit = ensure_sidecar_audit()
        if sidecar_audit["fixtures_with_missing_sidecars"] > 0:
            print(
                render_strict_sidecar_failure(sidecar_module.render_text_report(sidecar_audit)),
                end="",
                file=sys.stderr,
            )
            return 1

    server_module = load_server_module(repo_root)
    _, sidecar_audit = ensure_sidecar_audit()
    audit = server_module.build_asset_audit(selected_files=selected_files)
    print("Attached pages catalog")
    print("")
    print(
        "Mode: "
        + ("explicit pinned inputs" if args.explicit_inputs else "auto-discovery")
        + (" with google-style ranking" if args.google_style else "")
    )
    print(f"Inputs pinned: {len(selected_files)}")
    print(f"Bind: http://{args.bind}:{args.port}/")
    print("Routes: /, /manifest.json, /audit.json, /audit.txt, /pages/<n>, /named/<slug>, /raw/...")
    print("")
    for line in describe_fixture_selection(
        selected_files, repo_root=repo_root, google_style=args.google_style
    ):
        print(line)
    print("")
    if sidecar_audit["fixtures_with_missing_sidecars"] > 0:
        print(
            "Warning: some attached HTML files are missing their sibling _files directories. "
            "Replay may reflect an incomplete export bundle before it reflects a browser regression."
        )
        print("")
    if audit["fixtures_with_missing_assets"] > 0:
        print(
            "Warning: some attached HTML files still have missing local sidecars. "
            "Headed localhost replay may differ until those files are restored."
        )
        print("")

    server, manifest = server_module.create_server(
        bind=args.bind,
        port=args.port,
        selected_files=selected_files,
    )
    print(f"Serving attached pages bundle with {len(manifest)} page(s)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping attached pages server.")
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())