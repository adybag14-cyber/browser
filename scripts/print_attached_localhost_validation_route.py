#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import shlex
from pathlib import Path
from urllib.parse import quote


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Print a localhost validation route for attached HTML pages, including "
            "URL-encoded browse targets for headed-mode runs."
        )
    )
    parser.add_argument(
        "--attached-root",
        default=None,
        help=(
            "Directory containing attached HTML pages. Defaults to ../agent_files "
            "beside the repo root when present, otherwise ./agent_files."
        ),
    )
    parser.add_argument(
        "--host",
        default="127.0.0.1",
        help="Host name to use for the local HTTP server and generated URLs.",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8123,
        help="Port to use for the local HTTP server and generated URLs.",
    )
    parser.add_argument(
        "--browser-bash",
        default="./zig-out/bin/lightpanda browse --browser_mode headed",
        help="Bash browser command prefix used in the printed example commands.",
    )
    parser.add_argument(
        "--browser-powershell",
        default=".\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed",
        help="PowerShell browser command prefix used in the printed example commands.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print the route as JSON instead of the human-readable summary.",
    )
    return parser.parse_args()


def default_attached_root(repo_root: Path) -> Path:
    sibling = repo_root.parent / "agent_files"
    if sibling.is_dir():
        return sibling
    return repo_root / "agent_files"


def encode_relative_path(relative_path: Path) -> str:
    return "/".join(quote(part) for part in relative_path.parts)


def discover_pages(attached_root: Path) -> list[dict[str, str]]:
    pages: list[dict[str, str]] = []
    for page in sorted(attached_root.rglob("*.html")):
        relative_path = page.relative_to(attached_root)
        pages.append(
            {
                "label": page.stem,
                "relative_path": relative_path.as_posix(),
                "encoded_path": encode_relative_path(relative_path),
            }
        )
    return pages


def build_route(args: argparse.Namespace, repo_root: Path) -> dict[str, object]:
    attached_root = Path(args.attached_root) if args.attached_root else default_attached_root(repo_root)
    attached_root = attached_root.resolve()
    if not attached_root.is_dir():
        raise SystemExit(f"Attached root does not exist: {attached_root}")

    pages = discover_pages(attached_root)
    if not pages:
        raise SystemExit(f"No HTML pages were found under: {attached_root}")

    server_command = [
        "python",
        "-m",
        "http.server",
        str(args.port),
        "--bind",
        args.host,
        "--directory",
        str(attached_root),
    ]

    page_routes: list[dict[str, str]] = []
    for page in pages:
        url = f"http://{args.host}:{args.port}/{page['encoded_path']}"
        page_routes.append(
            {
                "label": page["label"],
                "relative_path": page["relative_path"],
                "url": url,
                "bash_command": f"{args.browser_bash} {shlex.quote(url)}",
                "powershell_command": f'{args.browser_powershell} "{url}"',
            }
        )

    return {
        "repo_root": str(repo_root),
        "attached_root": str(attached_root),
        "host": args.host,
        "port": args.port,
        "server_command": " ".join(shlex.quote(part) for part in server_command),
        "pages": page_routes,
    }


def print_human(route: dict[str, object]) -> None:
    print("Attached localhost validation route")
    print(f"Repo root:      {route['repo_root']}")
    print(f"Attached root:  {route['attached_root']}")
    print(f"Server address: http://{route['host']}:{route['port']}/")
    print()
    print("Start the local HTTP server:")
    print(f"  {route['server_command']}")
    print()
    print("Headed browse targets:")
    for index, page in enumerate(route["pages"], start=1):
        print(f"  {index}. {page['relative_path']}")
        print(f"     URL:        {page['url']}")
        print(f"     Bash:       {page['bash_command']}")
        print(f"     PowerShell: {page['powershell_command']}")
    print()
    print(
        "The generated URLs are already percent-encoded, so filenames with spaces "
        "or Unicode punctuation can be opened without manual rewriting."
    )


def main() -> None:
    args = parse_args()
    repo_root = Path(__file__).resolve().parent.parent
    route = build_route(args, repo_root)
    if args.json:
        print(json.dumps(route, indent=2))
        return
    print_human(route)


if __name__ == "__main__":
    main()
