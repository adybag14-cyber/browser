#!/usr/bin/env python3
"""Launch the attached-pages server against the saved exported HTML fixtures."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path


HTML_EXTENSIONS = {".html", ".htm"}


def find_default_source_dir() -> Path | None:
    candidates: list[Path] = []
    env_dir = os.environ.get("LIGHTPANDA_ATTACHED_PAGES_DIR")
    if env_dir:
        candidates.append(Path(env_dir))

    here = Path(__file__).resolve()
    candidates.extend(
        [
            Path.cwd() / "agent_files",
            here.parents[3] / "agent_files",
            here.parents[2] / "agent_files",
        ]
    )

    for candidate in candidates:
        if candidate.is_dir() and any(path.suffix.lower() in HTML_EXTENSIONS for path in candidate.iterdir()):
            return candidate
    return None


def discover_html_inputs(source_dir: Path) -> list[Path]:
    return sorted(
        path.resolve()
        for path in source_dir.iterdir()
        if path.is_file() and path.suffix.lower() in HTML_EXTENSIONS
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, default=None)
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8235)
    parser.add_argument("--staging-root", type=Path, default=None)
    parser.add_argument("--print-inputs", action="store_true")
    parser.add_argument("--print-manifest", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source_dir = args.source_dir or find_default_source_dir()
    if source_dir is None:
        print(
            "No attached pages directory found. Pass --source-dir or set LIGHTPANDA_ATTACHED_PAGES_DIR.",
            file=sys.stderr,
        )
        return 2

    selected_files = discover_html_inputs(source_dir)
    if not selected_files:
        print(f"No HTML exports found in {source_dir}", file=sys.stderr)
        return 2

    if args.print_inputs:
        for path in selected_files:
            print(path)
        return 0

    import attached_pages_server as server_module

    if args.print_manifest:
        manifest = server_module.build_manifest(selected_files=selected_files)
        print(json.dumps(manifest, indent=2))
        return 0

    server, manifest = server_module.create_server(
        selected_files=selected_files,
        bind=args.bind,
        port=args.port,
        staging_root=args.staging_root,
    )
    host, port = server.server_address
    print(f"Serving {len(manifest)} saved attached pages from {source_dir} at http://{host}:{port}/")
    for entry in manifest:
        print(f"{entry['route']} -> {entry['file']}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        return 0
    finally:
        server.server_close()


if __name__ == "__main__":
    raise SystemExit(main())
