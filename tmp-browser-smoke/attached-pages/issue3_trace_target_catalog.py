from __future__ import annotations

from pathlib import Path
from typing import Iterable


GOOGLE_TRACE_HINTS: tuple[str, ...] = (
    "google-home-",
    "google.com",
)

ATTACHED_FIXTURE_TRACE_HINTS: tuple[str, ...] = (
    "google_home_title_probe.html",
    "body_onload_keyboard_input.html",
    "mouse_down_focus_input.html",
)

SAVED_ATTACHMENT_TRACE_HINTS: tuple[str, ...] = (
    "control your online safety and privacy",
    "control%20your%20online%20safety%20and%20privacy",
    "google safety centre",
    "google%20safety%20centre",
    "anthropic",
    "job application for",
    "presidential unsealing and reporting system for uap encounters",
    "presidential%20unsealing%20and%20reporting%20system%20for%20uap%20encounters",
    "department of war",
    "department%20of%20war",
)

ISSUE3_TRACE_HINTS: tuple[str, ...] = (
    *GOOGLE_TRACE_HINTS,
    *ATTACHED_FIXTURE_TRACE_HINTS,
    *SAVED_ATTACHMENT_TRACE_HINTS,
)

REPRESENTATIVE_TRACE_URLS: dict[str, str] = {
    "google-home": "https://www.google.com/",
    "fixture-title-probe": "http://127.0.0.1:8000/google_home_title_probe.html",
    "fixture-onload-input": "http://127.0.0.1:8000/body_onload_keyboard_input.html",
    "fixture-mousedown-input": "http://127.0.0.1:8000/mouse_down_focus_input.html",
    "saved-google-safety": "file:///tmp/Control%20your%20online%20safety%20and%20privacy%20%E2%80%93%20Google%20Safety%20Centre.html",
    "saved-anthropic-job": "file:///tmp/Job%20Application%20for%20Research%20Manager%20at%20Anthropic.html",
    "saved-department-of-war": "file:///tmp/Presidential%20Unsealing%20and%20Reporting%20System%20for%20UAP%20Encounters%20_%20U.S.%20Department%20of%20War.html",
}


def normalize_trace_text(text: str) -> str:
    return text.casefold()


def is_issue3_trace_target(text: str) -> bool:
    normalized = normalize_trace_text(text)
    return any(hint in normalized for hint in ISSUE3_TRACE_HINTS)


def matching_trace_hints(lines: Iterable[str]) -> dict[str, bool]:
    normalized_lines = [normalize_trace_text(line) for line in lines]
    return {
        hint: any(normalize_trace_text(hint) in line for line in normalized_lines)
        for hint in ISSUE3_TRACE_HINTS
    }


def missing_trace_hints(lines: Iterable[str]) -> list[str]:
    return [hint for hint, present in matching_trace_hints(lines).items() if not present]


def matching_trace_urls(lines: Iterable[str]) -> dict[str, bool]:
    remaining = dict.fromkeys(REPRESENTATIVE_TRACE_URLS, False)
    for line in lines:
        for name, url in REPRESENTATIVE_TRACE_URLS.items():
            if not remaining[name] and normalize_trace_text(url) in normalize_trace_text(line):
                remaining[name] = True
    return remaining


def missing_trace_urls(lines: Iterable[str]) -> list[str]:
    return [name for name, present in matching_trace_urls(lines).items() if not present]


def audit_trace_source(path: str | Path) -> list[str]:
    source_path = Path(path)
    lines = source_path.read_text(encoding="utf-8").splitlines()
    return missing_trace_hints(lines)


def audit_trace_log(path: str | Path) -> list[str]:
    trace_path = Path(path)
    lines = trace_path.read_text(encoding="utf-8").splitlines()
    return missing_trace_urls(lines)
