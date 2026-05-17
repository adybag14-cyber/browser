import argparse
import html
import json
import mimetypes
import os
import re
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit


def slugify(name: str) -> str:
    lowered = name.lower()
    normalized = re.sub(r"[^a-z0-9]+", "-", lowered).strip("-")
    return normalized or "page"


def shorten_slug(name: str, *, max_words: int = 5, max_chars: int = 36) -> str:
    slug = slugify(name)
    if slug == "page":
        return slug

    parts = [part for part in slug.split("-") if part]
    chosen: list[str] = []
    current_len = 0
    for part in parts:
        if len(chosen) >= max_words:
            break
        projected = current_len + len(part) + (1 if chosen else 0)
        if projected > max_chars:
            break
        chosen.append(part)
        current_len = projected

    if chosen:
        return "-".join(chosen)
    return slug[:max_chars].strip("-") or "page"


def extract_title(path: Path) -> str:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return path.name
    match = re.search(r"<title[^>]*>(.*?)</title>", text, re.IGNORECASE | re.DOTALL)
    if not match:
        return path.name
    title = re.sub(r"\s+", " ", match.group(1)).strip()
    return title or path.name


def choose_slug_route(rel_path: str, title: str, *, used_slug_routes: set[str]) -> str:
    path = Path(rel_path)
    title_slug = shorten_slug(title if title else path.stem)
    stem_slug = shorten_slug(path.stem)
    parent_slug = shorten_slug(path.parent.as_posix()) if path.parent.as_posix() != "." else ""

    candidates = [title_slug]
    if stem_slug != title_slug:
        candidates.append(f"{title_slug}-{stem_slug}")
    if parent_slug:
        candidates.append(f"{title_slug}-{parent_slug}")
        if stem_slug != title_slug:
            candidates.append(f"{title_slug}-{parent_slug}-{stem_slug}")

    for candidate in candidates:
        route = f"/named/{candidate}"
        if route not in used_slug_routes:
            used_slug_routes.add(route)
            return route

    suffix = 2
    while True:
        route = f"/named/{title_slug}-{suffix}"
        if route not in used_slug_routes:
            used_slug_routes.add(route)
            return route
        suffix += 1


def normalize_bundle_root(root: Path) -> tuple[Path, list[Path]]:
    resolved_root = Path(root).expanduser().resolve()
    if resolved_root.is_dir():
        html_files = sorted(path for path in resolved_root.rglob("*.html") if path.is_file())
        return resolved_root, html_files

    if resolved_root.is_file() and resolved_root.suffix.lower() == ".html":
        return resolved_root.parent, [resolved_root]

    raise FileNotFoundError(f"bundle root does not exist: {resolved_root}")


def normalize_selected_html_files(selected_files: list[Path]) -> tuple[Path, list[Path]]:
    if not selected_files:
        raise ValueError("selected HTML file list must not be empty")

    resolved_files: list[Path] = []
    for candidate in selected_files:
        resolved = Path(candidate).expanduser().resolve()
        if not resolved.is_file():
            raise FileNotFoundError(f"selected HTML file does not exist: {resolved}")
        if resolved.suffix.lower() != ".html":
            raise ValueError(f"selected file is not an .html export: {resolved}")
        resolved_files.append(resolved)

    common_root = Path(os.path.commonpath([str(path.parent) for path in resolved_files]))
    return common_root, sorted(resolved_files)


def resolve_bundle_inputs(root: Path | None = None, selected_files: list[Path] | None = None) -> tuple[Path, list[Path]]:
    if selected_files:
        return normalize_selected_html_files(selected_files)
    if root is None:
        raise ValueError("either a bundle root or selected HTML files are required")
    return normalize_bundle_root(root)


def build_manifest(root: Path | None = None, *, selected_files: list[Path] | None = None) -> list[dict[str, str]]:
    bundle_root, html_files = resolve_bundle_inputs(root, selected_files)
    entries: list[dict[str, str]] = []
    used_alias_routes: set[str] = set()
    used_slug_routes: set[str] = set()
    for index, path in enumerate(html_files, start=1):
        rel_path = path.relative_to(bundle_root).as_posix()
        title = extract_title(path)
        short_slug = shorten_slug(title if title else path.stem)
        route = f"/pages/{index}"
        alias_route = f"/pages/{index}-{short_slug}"
        slug_route = choose_slug_route(rel_path, title, used_slug_routes=used_slug_routes)
        suffix = 2
        while alias_route in used_alias_routes:
            alias_route = f"/pages/{index}-{short_slug}-{suffix}"
            suffix += 1
        used_alias_routes.add(alias_route)
        entries.append(
            {
                "index": str(index),
                "route": route,
                "alias_route": alias_route,
                "slug_route": slug_route,
                "raw_path": f"/raw/{quote(rel_path)}",
                "file": rel_path,
                "title": title,
            }
        )
    return entries


def render_index(manifest: list[dict[str, str]]) -> bytes:
    rows = []
    for entry in manifest:
        rows.append(
            "<li>"
            f"<a href=\"{html.escape(entry['route'])}/\">{html.escape(entry['title'])}</a>"
            f"<div>short route: <code>{html.escape(entry['route'])}</code></div>"
            f"<div>alias route: <code>{html.escape(entry['alias_route'])}</code></div>"
            f"<div>named route: <code>{html.escape(entry['slug_route'])}</code></div>"
            f"<div><code>{html.escape(entry['file'])}</code></div>"
            f"<div><a href=\"{html.escape(entry['raw_path'])}\">raw file</a></div>"
            "</li>"
        )
    body = "\n".join(rows) if rows else "<li>No HTML files were found in the selected bundle.</li>"
    page = f"""<!doctype html>
<html lang=\"en\">
  <head>
    <meta charset=\"utf-8\">
    <title>Attached Pages Catalog</title>
    <style>
      body {{
        font-family: sans-serif;
        margin: 2rem auto;
        max-width: 56rem;
        line-height: 1.5;
        color: #202124;
      }}
      h1 {{
        margin-bottom: 0.5rem;
      }}
      p {{
        margin-top: 0;
      }}
      ul {{
        padding-left: 1.25rem;
      }}
      li {{
        margin: 0 0 1rem;
      }}
      code {{
        background: #f1f3f4;
        padding: 0.1rem 0.3rem;
      }}
    </style>
  </head>
  <body>
    <h1>Attached Pages Catalog</h1>
    <p>
      This server exposes stable short routes for a directory of saved HTML pages so
      headed-mode validation can target them without depending on long exported filenames.
    </p>
    <p>
      Each entry includes a short route, a readable alias route, a named route, and raw-file
      access. The short and named routes redirect into an asset-safe directory form so relative
      CSS, images, and scripts keep working for exported bundles.
    </p>
    <ul>
      {body}
    </ul>
  </body>
</html>
"""
    return page.encode("utf-8")


def build_route_lookup(manifest: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    route_lookup: dict[str, dict[str, str]] = {}
    for entry in manifest:
        for route in (entry["route"], entry["alias_route"], entry["slug_route"]):
            route_lookup[route] = entry
    return route_lookup


def split_page_route(request_path: str, route_lookup: dict[str, dict[str, str]]) -> tuple[dict[str, str] | None, str | None]:
    for route, entry in route_lookup.items():
        if request_path == route:
            return entry, ""
        prefix = f"{route}/"
        if request_path == prefix:
            return entry, ""
        if request_path.startswith(prefix):
            return entry, request_path[len(prefix) :]
    return None, None


def ensure_within_root(root: Path, target: Path) -> Path | None:
    resolved_root = root.resolve()
    resolved_target = target.resolve()
    try:
        resolved_target.relative_to(resolved_root)
    except ValueError:
        return None
    return resolved_target


LOCAL_REFERENCE_PATTERNS = (
    re.compile(r"\b(?:src|href|poster)\s*=\s*[\"']([^\"']+)[\"']", re.IGNORECASE),
    re.compile(r"\bsrcset\s*=\s*[\"']([^\"']+)[\"']", re.IGNORECASE),
    re.compile(r"@import\s+(?:url\()?\s*[\"']?([^\"')\s;]+)", re.IGNORECASE),
    re.compile(r"url\(\s*[\"']?([^\"')]+)[\"']?\s*\)", re.IGNORECASE),
)

MODULE_REFERENCE_PATTERNS = (
    re.compile(r"\bimport\s+(?:[^;'\"\\]*?\s+from\s+)?[\"']([^\"']+)[\"']", re.IGNORECASE),
    re.compile(r"\bexport\s+[^;'\"\\]*?\s+from\s+[\"']([^\"']+)[\"']", re.IGNORECASE),
    re.compile(r"(?<![\w$])import\s*\(\s*[\"']([^\"']+)[\"']\s*\)", re.IGNORECASE),
)


def normalize_reference_value(reference: str) -> str | None:
    stripped = reference.strip()
    if not stripped:
        return None
    if stripped.startswith(("data:", "javascript:", "mailto:", "tel:", "#")):
        return None

    parts = urlsplit(stripped)
    if parts.scheme or parts.netloc:
        return None

    normalized = parts.path.strip()
    if not normalized:
        return None
    if normalized.startswith("/"):
        normalized = normalized[1:]
    if not normalized or normalized in (".", ".."):
        return None
    return normalized


def extract_local_reference_candidates(content: str) -> list[str]:
    candidates: list[str] = []

    def add_candidate(value: str) -> None:
        normalized = normalize_reference_value(value)
        if normalized is not None and normalized not in candidates:
            candidates.append(normalized)

    for pattern in LOCAL_REFERENCE_PATTERNS:
        for match in pattern.finditer(content):
            value = match.group(1)
            if "srcset" in pattern.pattern:
                for entry in value.split(","):
                    srcset_candidate = entry.strip().split()[0] if entry.strip() else ""
                    if srcset_candidate:
                        add_candidate(srcset_candidate)
            else:
                add_candidate(value)

    for pattern in MODULE_REFERENCE_PATTERNS:
        for match in pattern.finditer(content):
            value = match.group(1).strip()
            if value.startswith(("./", "../")):
                add_candidate(value)

    return candidates


def build_asset_audit(root: Path | None = None, *, selected_files: list[Path] | None = None) -> dict[str, object]:
    bundle_root, manifest = resolve_bundle_inputs(root, selected_files)
    audit_entries: list[dict[str, object]] = []
    fixtures_with_missing_assets = 0

    for html_path in manifest:
        relative_html_path = html_path.relative_to(bundle_root).as_posix()
        pending: list[tuple[Path, str]] = [(html_path, relative_html_path)]
        visited: set[Path] = {html_path.resolve()}
        inspected_files: list[str] = []
        inspected_css_files: list[str] = []
        inspected_module_script_files: list[str] = []
        missing_assets: list[str] = []

        while pending:
            current_path, current_relative = pending.pop(0)
            inspected_files.append(current_relative)
            try:
                content = current_path.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                missing_entry = f"unreadable:{current_relative}"
                if missing_entry not in missing_assets:
                    missing_assets.append(missing_entry)
                continue

            for reference in extract_local_reference_candidates(content):
                resolved = ensure_within_root(bundle_root, current_path.parent / unquote(reference))
                display_path = Path(current_relative).parent.joinpath(unquote(reference)).as_posix()
                if resolved is None or not resolved.is_file():
                    if display_path not in missing_assets:
                        missing_assets.append(display_path)
                    continue

                extension = resolved.suffix.lower()
                resolved_relative = resolved.relative_to(bundle_root).as_posix()
                resolved_key = resolved.resolve()
                if extension == ".css":
                    if resolved_relative not in inspected_css_files:
                        inspected_css_files.append(resolved_relative)
                    if resolved_key not in visited:
                        visited.add(resolved_key)
                        pending.append((resolved, resolved_relative))
                elif extension in (".js", ".mjs"):
                    if resolved_relative not in inspected_module_script_files:
                        inspected_module_script_files.append(resolved_relative)
                    if resolved_key not in visited:
                        visited.add(resolved_key)
                        pending.append((resolved, resolved_relative))

        if missing_assets:
            fixtures_with_missing_assets += 1

        audit_entries.append(
            {
                "path": str(html_path),
                "display_path": relative_html_path,
                "missing_assets": missing_assets,
                "missing_asset_count": len(missing_assets),
                "inspected_files": inspected_files,
                "inspected_file_count": len(inspected_files),
                "inspected_css_files": inspected_css_files,
                "inspected_css_file_count": len(inspected_css_files),
                "inspected_module_script_files": inspected_module_script_files,
                "inspected_module_script_file_count": len(inspected_module_script_files),
            }
        )

    return {
        "bundle_root": str(bundle_root),
        "fixture_count": len(audit_entries),
        "fixtures_with_missing_assets": fixtures_with_missing_assets,
        "fixtures": audit_entries,
    }


def render_asset_audit_text(audit: dict[str, object]) -> str:
    lines = [
        "Attached Pages Asset Audit",
        "",
        f"Bundle root: {audit['bundle_root']}",
        f"Fixtures: {audit['fixture_count']}",
        f"Fixtures with missing assets: {audit['fixtures_with_missing_assets']}",
        "",
    ]
    for fixture in audit["fixtures"]:
        lines.append(f"Fixture: {fixture['display_path']}")
        lines.append(f"Inspected files: {fixture['inspected_file_count']}")
        lines.append(f"Inspected CSS files: {fixture['inspected_css_file_count']}")
        lines.append(f"Inspected module script files: {fixture['inspected_module_script_file_count']}")
        if fixture["missing_asset_count"] == 0:
            lines.append("Missing assets: none")
        else:
            lines.append(f"Missing assets: {fixture['missing_asset_count']}")
            for asset in fixture["missing_assets"][:10]:
                lines.append(f"- {asset}")
            remaining = fixture["missing_asset_count"] - min(10, fixture["missing_asset_count"])
            if remaining > 0:
                lines.append(f"- ... {remaining} more")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def build_bundle_state(root: Path | None = None, *, selected_files: list[Path] | None = None) -> tuple[Path, list[dict[str, str]], dict[str, dict[str, str]], bytes, bytes]:
    bundle_root, _ = resolve_bundle_inputs(root, selected_files)
    manifest = build_manifest(root, selected_files=selected_files)
    route_lookup = build_route_lookup(manifest)
    index_bytes = render_index(manifest)
    manifest_bytes = json.dumps(manifest, indent=2).encode("utf-8")
    return bundle_root, manifest, route_lookup, index_bytes, manifest_bytes


class ReuseServer(ThreadingHTTPServer):
    allow_reuse_address = True


def create_server(root: Path | None = None, *, bind: str = "127.0.0.1", port: int = 8235, selected_files: list[Path] | None = None) -> tuple[ReuseServer, list[dict[str, str]]]:
    bundle_root, manifest, route_lookup, index_bytes, manifest_bytes = build_bundle_state(root, selected_files=selected_files)

    class AttachedPagesHandler(SimpleHTTPRequestHandler):
        def __init__(self, *handler_args, **handler_kwargs):
            super().__init__(*handler_args, directory=str(bundle_root), **handler_kwargs)

        def end_headers(self):
            self.send_header("Cache-Control", "no-store")
            super().end_headers()

        def send_bytes(self, content: bytes, content_type: str, *, head_only: bool = False):
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(content)))
            self.end_headers()
            if not head_only:
                self.wfile.write(content)

        def send_redirect(self, location: str):
            self.send_response(302)
            self.send_header("Location", location)
            self.end_headers()

        def send_page_asset(self, entry: dict[str, str], asset_suffix: str, *, head_only: bool = False):
            page_file = bundle_root / entry["file"]
            if asset_suffix in ("", "index.html"):
                self.send_bytes(page_file.read_bytes(), "text/html; charset=utf-8", head_only=head_only)
                return

            asset_path = ensure_within_root(bundle_root, page_file.parent / unquote(asset_suffix))
            if asset_path is None or not asset_path.is_file():
                self.send_error(404, "File not found")
                return

            content_type, _ = mimetypes.guess_type(str(asset_path))
            self.send_bytes(asset_path.read_bytes(), content_type or "application/octet-stream", head_only=head_only)

        def handle_attached_request(self, *, head_only: bool = False):
            request_path = urlsplit(self.path).path
            if request_path == "/" or request_path == "/index.html":
                self.send_bytes(index_bytes, "text/html; charset=utf-8", head_only=head_only)
                return
            if request_path == "/manifest.json":
                self.send_bytes(manifest_bytes, "application/json; charset=utf-8", head_only=head_only)
                return

            entry, asset_suffix = split_page_route(request_path, route_lookup)
            if entry is not None:
                if request_path in (entry["route"], entry["alias_route"], entry["slug_route"]):
                    self.send_redirect(f"{request_path}/")
                    return
                self.send_page_asset(entry, asset_suffix or "", head_only=head_only)
                return

            if request_path.startswith("/raw/"):
                self.path = request_path[len("/raw") :]
            if head_only:
                return super().do_HEAD()
            return super().do_GET()

        def do_GET(self):
            return self.handle_attached_request()

        def do_HEAD(self):
            return self.handle_attached_request(head_only=True)

    server = ReuseServer((bind, port), partial(AttachedPagesHandler))
    return server, manifest


def main() -> int:
    parser = argparse.ArgumentParser(description="Serve an attached HTML bundle for headed-mode smoke validation.")
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument("--root", help="Directory or single HTML file to expose.")
    input_group.add_argument(
        "--input",
        action="append",
        dest="selected_files",
        help="Explicit HTML export to expose. Repeat to pin the manifest to a file list.",
    )
    parser.add_argument("--bind", default="127.0.0.1", help="Address to bind. Defaults to 127.0.0.1.")
    parser.add_argument("--port", type=int, default=8235, help="TCP port to listen on. Defaults to 8235.")
    parser.add_argument(
        "--print-manifest",
        action="store_true",
        help="Print the generated manifest JSON and exit instead of starting the server.",
    )
    parser.add_argument(
        "--audit-assets",
        action="store_true",
        help="Audit local CSS, image, and script references across the selected HTML bundle before starting the server.",
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
    args = parser.parse_args()

    selected_files = [Path(path) for path in args.selected_files] if args.selected_files else None
    root = Path(args.root) if args.root else None

    if args.audit_assets_json and not args.audit_assets:
        parser.error("--audit-assets-json requires --audit-assets")

    if args.print_manifest:
        print(json.dumps(build_manifest(root, selected_files=selected_files), indent=2))
        return 0

    if args.audit_assets:
        audit = build_asset_audit(root, selected_files=selected_files)
        if args.audit_assets_json:
            print(json.dumps(audit, indent=2))
        else:
            print(render_asset_audit_text(audit), end="")
        if audit["fixtures_with_missing_assets"] > 0 and not args.allow_missing_assets:
            return 1
        return 0

    server, manifest = create_server(root, bind=args.bind, port=args.port, selected_files=selected_files)
    source_description = root.expanduser().resolve() if root is not None else f"{len(selected_files or [])} selected files"
    host, port = server.server_address
    print(f"Serving {len(manifest)} attached pages from {source_description} at http://{host}:{port}/")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        return 0


if __name__ == "__main__":
    raise SystemExit(main())