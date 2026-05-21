from __future__ import annotations

from pathlib import Path
from typing import Iterable


IMAGE_SMOKE_PROBES: tuple[str, ...] = (
    "chrome-http-runtime-image-accept-probe.ps1",
    "chrome-http-runtime-image-auth-anonymous-probe.ps1",
    "chrome-http-runtime-image-auth-inherit-probe.ps1",
    "chrome-http-runtime-image-auth-probe.ps1",
    "chrome-http-runtime-image-policy-probe.ps1",
    "chrome-http-runtime-image-probe.ps1",
    "chrome-http-runtime-image-redirect-probe.ps1",
    "chrome-http-runtime-module-auth-anonymous-probe.ps1",
    "chrome-http-runtime-module-auth-probe.ps1",
    "chrome-http-runtime-script-auth-anonymous-probe.ps1",
    "chrome-http-runtime-script-auth-probe.ps1",
)

HEADED_LAUNCH_TOKENS: tuple[str, ...] = (
    '"browse"',
    '"--browser_mode"',
    '"headed"',
)


def normalize_launch_text(text: str) -> str:
    return text.casefold()


def explicit_headed_launch_present(text: str) -> bool:
    normalized = normalize_launch_text(text)
    position = 0
    for token in HEADED_LAUNCH_TOKENS:
        next_position = normalized.find(normalize_launch_text(token), position)
        if next_position < 0:
            return False
        position = next_position + len(token)
    return True


def missing_headed_launch_files(probe_sources: dict[str, str]) -> list[str]:
    return [
        name
        for name, source in probe_sources.items()
        if not explicit_headed_launch_present(source)
    ]


def load_probe_sources(root: str | Path) -> dict[str, str]:
    root_path = Path(root)
    return {
        name: (root_path / name).read_text(encoding="utf-8")
        for name in IMAGE_SMOKE_PROBES
    }


def audit_image_smoke_root(root: str | Path) -> list[str]:
    return missing_headed_launch_files(load_probe_sources(root))


def audit_image_smoke_lines(lines: Iterable[str]) -> bool:
    return explicit_headed_launch_present("\n".join(lines))