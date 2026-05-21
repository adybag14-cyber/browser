from __future__ import annotations

from pathlib import Path
from typing import Iterable


HELPER_MARKERS: tuple[str, ...] = (
    "fn browseTargetInternal(",
    "fn browseTargetImplicitLoopback(",
    'scope = "internal"',
    'scope = "loopback"',
    'scope = "local_path"',
)

BROWSER_INTERNAL_CASE_MARKERS: tuple[str, ...] = (
    "browser://downloads",
    "browser://settings/homepage",
)

LOCAL_PATH_CASE_MARKERS: tuple[str, ...] = (
    "attached-page.html?case=1",
    "attached-page.xhtml#focus-probe",
    "user_files\\attached-page.xhtml",
)

LOOPBACK_CASE_MARKERS: tuple[str, ...] = (
    "localhost:8123/attached-page.html",
    "0.0.0.0:8123/attached-page.html#focus-probe",
    "[::1]:8123/replay.xhtml?case=1",
    "127.0.0.1/replay.xhtml#focus-probe",
)

STARTUP_DIAGNOSTIC_MARKERS: tuple[str, ...] = (
    *HELPER_MARKERS,
    *BROWSER_INTERNAL_CASE_MARKERS,
    *LOCAL_PATH_CASE_MARKERS,
    *LOOPBACK_CASE_MARKERS,
)


def normalize_marker(text: str) -> str:
    return text.casefold()


def matching_startup_markers(lines: Iterable[str]) -> dict[str, bool]:
    normalized_lines = [normalize_marker(line) for line in lines]
    return {
        marker: any(normalize_marker(marker) in line for line in normalized_lines)
        for marker in STARTUP_DIAGNOSTIC_MARKERS
    }


def missing_startup_markers(lines: Iterable[str]) -> list[str]:
    return [
        marker
        for marker, present in matching_startup_markers(lines).items()
        if not present
    ]


def audit_main_source(path: str | Path) -> list[str]:
    source_path = Path(path)
    lines = source_path.read_text(encoding="utf-8").splitlines()
    return missing_startup_markers(lines)
