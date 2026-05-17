#!/usr/bin/env python3
"""Stage attached HTML pages into a clean localhost-friendly smoke bundle.

This helper copies saved HTML pages plus any adjacent ``*_files`` asset folders
into a target directory with stable ASCII-safe names. It also generates a small
catalog page so headed-mode validation can launch the staged bundle from a
single localhost root.
"""

from __future__ import annotations

import argparse
import html
import json
import re
import shutil
import unicodedata
from pathlib import Path


TITLE_RE = re.compile(r"<title[^>]*>(.*?)</title>", re.IGNORECASE | re.DOTALL)
WHITESPACE_RE = re.compile(r"\s+")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Copy attached HTML pages into a clean bundle with predictable names "
            "for localhost headed-mode validation."
        )
    )
    parser.add_argument(
        "--source-dir",
        type=Path,
        required=True,
        help="Directory containing saved HTML files and optional *_files folders.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        required=True,
        help="Directory to populate with rewritten pages and the generated catalog.",
    )
    return parser.parse_args()


def slugify(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    ascii_only = normalized.encode("ascii", "ignore").decode("ascii")
    cleaned = re.sub(r"[^a-zA-Z0-9]+", "-", ascii_only).strip("-").lower()
    return cleaned or "page"


def extract_title(contents: str, fallback: str) -> str:
    match = TITLE_RE.search(contents)
    if not match:
        return fallback
    title = WHITESPACE_RE.sub(" ", match.group(1)).strip()
    return title or fallback


def find_asset_dir(html_path: Path) -> Path | None:
    candidates = [
        html_path.with_name(f"{html_path.stem}_files"),
        html_path.with_name(f"{html_path.name}_files"),
    ]
    for candidate in candidates:
        if candidate.is_dir():
            return candidate
    return None


def rewrite_asset_references(contents: str, original_asset_dir: str, staged_asset_dir: str) -> str:
    escaped_original = re.escape(original_asset_dir)
    patterns = [
        (rf"(\./){escaped_original}/", rf"\1{staged_asset_dir}/"),
        (rf"(\.\./){escaped_original}/", rf"\1{staged_asset_dir}/"),
        (rf"([\"'(=]){escaped_original}/", rf"\1{staged_asset_dir}/"),
    ]
    rewritten = contents
    for pattern, replacement in patterns:
        rewritten = re.sub(pattern, replacement, rewritten)
    return rewritten


def build_index(records: list[dict[str, object]]) -> str:
    items: list[str] = []
    for record in records:
        staged_name = html.escape(str(record["staged_html_name"]))
        title = html.escape(str(record["title"]))
        source_name = html.escape(str(record["source_name"]))
        asset_note = ""
        if record["staged_asset_dir"]:
            asset_dir = html.escape(str(record["staged_asset_dir"]))
            asset_note = f"<div class='meta'>Assets: <code>{asset_dir}</code></div>"
        items.append(
            "      <li>"
            f"<a href=\"{staged_name}\">{title}</a>"
            f"<div class='meta'>Source: <code>{source_name}</code></div>"
            f"{asset_note}"
            "</li>"
        )
    item_markup = "\n".join(items)
    return f"""<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\">
  <title>Attached HTML Validation Bundle</title>
  <style>
    :root {{
      color-scheme: light;
      font-family: system-ui, sans-serif;
    }}
    body {{
      margin: 2rem;
      line-height: 1.5;
    }}
    h1 {{
      margin-bottom: 0.5rem;
    }}
    ul {{
      padding-left: 1.25rem;
    }}
    li {{
      margin-bottom: 1rem;
    }}
    .meta {{
      color: #555;
      font-size: 0.95rem;
    }}
    code {{
      font-family: ui-monospace, monospace;
    }}
  </style>
</head>
<body>
  <h1>Attached HTML Validation Bundle</h1>
  <p>Use this catalog as the localhost entrypoint when manually validating headed mode against staged saved pages.</p>
  <ul>
{item_markup}
  </ul>
</body>
</html>
"""


def stage_pages(source_dir: Path, output_dir: Path) -> list[dict[str, object]]:
    html_files = sorted(source_dir.glob("*.html"))
    if not html_files:
        raise SystemExit(f"No .html files found in {source_dir}")

    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    records: list[dict[str, object]] = []
    for index, html_path in enumerate(html_files, start=1):
        original_contents = html_path.read_text(encoding="utf-8", errors="replace")
        title = extract_title(original_contents, html_path.stem)
        slug = slugify(f"{index:02d}-{html_path.stem}")
        staged_html_name = f"{slug}.html"
        staged_asset_dir_name: str | None = None

        asset_dir = find_asset_dir(html_path)
        staged_contents = original_contents
        if asset_dir is not None:
            staged_asset_dir_name = f"{slug}_files"
            shutil.copytree(asset_dir, output_dir / staged_asset_dir_name)
            staged_contents = rewrite_asset_references(
                staged_contents,
                asset_dir.name,
                staged_asset_dir_name,
            )

        (output_dir / staged_html_name).write_text(
            staged_contents,
            encoding="utf-8",
        )

        records.append(
            {
                "title": title,
                "source_name": html_path.name,
                "staged_html_name": staged_html_name,
                "staged_asset_dir": staged_asset_dir_name,
            }
        )

    (output_dir / "index.html").write_text(build_index(records), encoding="utf-8")
    (output_dir / "manifest.json").write_text(
        json.dumps({"pages": records}, indent=2),
        encoding="utf-8",
    )
    return records


def main() -> None:
    args = parse_args()
    records = stage_pages(args.source_dir.resolve(), args.output_dir.resolve())
    print(json.dumps({"pages": records}, indent=2))


if __name__ == "__main__":
    main()
