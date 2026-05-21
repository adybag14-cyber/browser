from __future__ import annotations

from pathlib import Path
from typing import Iterable


REPRESENTATIVE_STARTUP_TARGETS: dict[str, dict[str, str]] = {
    "inline-data-html": {
        "url": "data:text/html,<title>Inline</title>",
        "target_scheme": "data",
        "target_scope": "inline",
        "target_host": "(none)",
        "target_port": "(none)",
    },
    "about-blank-popup": {
        "url": "about:blank#popup-probe",
        "target_scheme": "about",
        "target_scope": "internal",
        "target_host": "blank",
        "target_port": "(none)",
    },
    "browser-downloads": {
        "url": "browser://downloads",
        "target_scheme": "browser",
        "target_scope": "internal",
        "target_host": "downloads",
        "target_port": "(none)",
    },
    "implicit-localhost": {
        "url": "localhost:8123/attached-page.html",
        "target_scheme": "implicit_http",
        "target_scope": "loopback",
        "target_host": "localhost",
        "target_port": "8123",
    },
    "attached-query-path": {
        "url": "attached-page.html?case=1",
        "target_scheme": "path",
        "target_scope": "local_path",
        "target_host": "(none)",
        "target_port": "(none)",
    },
}


def normalize_startup_log_text(text: str) -> str:
    return text.casefold()


def expected_field_fragments(name: str) -> tuple[str, ...]:
    target = REPRESENTATIVE_STARTUP_TARGETS[name]
    return (
        f"url={target['url']}",
        f"target_scheme={target['target_scheme']}",
        f"target_scope={target['target_scope']}",
        f"target_host={target['target_host']}",
        f"target_port={target['target_port']}",
    )


def matching_startup_targets(lines: Iterable[str]) -> dict[str, bool]:
    normalized_lines = [normalize_startup_log_text(line) for line in lines]
    matches: dict[str, bool] = {}
    for name in REPRESENTATIVE_STARTUP_TARGETS:
        fragments = tuple(normalize_startup_log_text(part) for part in expected_field_fragments(name))
        matches[name] = any(all(fragment in line for fragment in fragments) for line in normalized_lines)
    return matches


def missing_startup_targets(lines: Iterable[str]) -> list[str]:
    return [name for name, present in matching_startup_targets(lines).items() if not present]


def audit_startup_log(path: str | Path) -> list[str]:
    log_path = Path(path)
    lines = log_path.read_text(encoding="utf-8").splitlines()
    return missing_startup_targets(lines)
