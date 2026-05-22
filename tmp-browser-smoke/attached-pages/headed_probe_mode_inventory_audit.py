from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path


LAUNCH_BLOCK_RE = re.compile(
    r"Start-Process[\s\S]{0,500}?-ArgumentList(?P<args>[\s\S]{0,600}?)(?:-WorkingDirectory|-PassThru|-RedirectStandardOutput|-RedirectStandardError|\n\s*\n|$)",
    re.IGNORECASE,
)
EXPLICIT_HEADED_RE = re.compile(
    r"(--browser_mode[\s\",']+headed|--headed)",
    re.IGNORECASE,
)
BROWSE_RE = re.compile(r"['\"]browse['\"]", re.IGNORECASE)


@dataclass
class MissingLaunch:
    relative_path: str
    snippet: str


def resolve_repo_root(start: Path) -> Path:
    cursor = start.resolve()
    for candidate in (cursor, *cursor.parents):
        if (candidate / "build.zig").exists():
            return candidate
    raise FileNotFoundError(f"Could not resolve repo root from {start}")


def iter_probe_scripts(repo_root: Path) -> list[Path]:
    smoke_root = repo_root / "tmp-browser-smoke"
    return sorted(path for path in smoke_root.rglob("*.ps1") if path.is_file())


def extract_browser_launch_blocks(text: str) -> list[str]:
    blocks: list[str] = []
    for match in LAUNCH_BLOCK_RE.finditer(text):
        snippet = match.group(0)
        if BROWSE_RE.search(snippet):
            blocks.append(snippet)
    return blocks


def audit_probe_launches(repo_root: Path) -> dict[str, object]:
    scripts = iter_probe_scripts(repo_root)
    missing: list[MissingLaunch] = []
    launch_count = 0

    for script in scripts:
        text = script.read_text(encoding="utf-8", errors="ignore")
        for block in extract_browser_launch_blocks(text):
            launch_count += 1
            if EXPLICIT_HEADED_RE.search(block):
                continue
            missing.append(
                MissingLaunch(
                    relative_path=script.relative_to(repo_root).as_posix(),
                    snippet=" ".join(block.split()),
                )
            )

    return {
        "repo_root": str(repo_root),
        "scanned_script_count": len(scripts),
        "browser_launch_count": launch_count,
        "missing_explicit_headed": [asdict(item) for item in missing],
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit tmp-browser-smoke PowerShell browse launches for explicit headed mode."
    )
    parser.add_argument(
        "repo_root",
        nargs="?",
        default=Path(__file__).resolve().parents[2],
        type=Path,
        help="Path to the browser repository root.",
    )
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    result = audit_probe_launches(repo_root)
    print(json.dumps(result, indent=2))
    return 1 if result["missing_explicit_headed"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
