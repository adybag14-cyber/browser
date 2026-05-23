#!/usr/bin/env python3
"""Suggest headed validation suites for a changed area or file path."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True)
class Route:
    key: str
    title: str
    summary: str
    suites: tuple[str, ...]
    notes: tuple[str, ...] = ()


ROUTES: tuple[Route, ...] = (
    Route(
        key="shell-navigation",
        title="Shell and navigation",
        summary="Tab, address bar, browser pages, navigation chrome, stop/reload, and popup routing.",
        suites=(
            "tmp-browser-smoke/tabs",
            "tmp-browser-smoke/browser-pages",
            "tmp-browser-smoke/settings",
            "tmp-browser-smoke/wrapped-link",
            "tmp-browser-smoke/popup",
            "tmp-browser-smoke/stop-loading",
        ),
        notes=(
            "Run this route after browser shell, session wiring, popup policy, or navigation state changes.",
        ),
    ),
    Route(
        key="rendering-layout",
        title="Rendering and layout",
        summary="Shared surface, layout, hit-testing, images, and visual fidelity on the headed path.",
        suites=(
            "tmp-browser-smoke/layout-smoke",
            "tmp-browser-smoke/inline-flow",
            "tmp-browser-smoke/flow-layout",
            "tmp-browser-smoke/rendered-link-dom",
            "tmp-browser-smoke/image-smoke",
            "tmp-browser-smoke/font-render",
        ),
        notes=(
            "Use when the shared display list, document painter, hit-testing, or image layout changes.",
        ),
    ),
    Route(
        key="text-input-ime",
        title="Text input, focus, and IME",
        summary="Caret movement, focus delivery, selection, text commit, submit, and zoom-sensitive editing behavior.",
        suites=(
            "tmp-browser-smoke/form-controls",
            "tmp-browser-smoke/find",
            "tmp-browser-smoke/zoom",
            "tmp-browser-smoke/inline-flow",
            "tmp-browser-smoke/popup",
        ),
        notes=(
            "Use when Win32 input dispatch, Input/TextArea/Label behavior, or Google-style typed-input paths change.",
        ),
    ),
    Route(
        key="graphics",
        title="Canvas and graphics",
        summary="Canvas 2D, WebGL, image draw paths, and graphics-facing text/image behavior.",
        suites=(
            "tmp-browser-smoke/canvas-smoke",
            "tmp-browser-smoke/image-smoke",
            "tmp-browser-smoke/font-render",
        ),
    ),
    Route(
        key="network-runtime",
        title="Network and runtime",
        summary="Fetch, websocket, stylesheet, script, auth, redirect, and runtime-loaded resource behavior.",
        suites=(
            "tmp-browser-smoke/fetch-abort",
            "tmp-browser-smoke/fetch-credentials",
            "tmp-browser-smoke/websocket-smoke",
            "tmp-browser-smoke/stylesheet-smoke",
            "tmp-browser-smoke/image-smoke",
        ),
    ),
    Route(
        key="storage-session",
        title="Storage and session",
        summary="Cookie, storage, restart, cross-tab, and session restore behavior.",
        suites=(
            "tmp-browser-smoke/cookie-persistence",
            "tmp-browser-smoke/localstorage-persistence",
            "tmp-browser-smoke/indexeddb-persistence",
            "tmp-browser-smoke/sessionstorage-scope",
            "tmp-browser-smoke/tabs",
            "tmp-browser-smoke/browser-pages",
        ),
    ),
    Route(
        key="file-handling",
        title="Downloads and uploads",
        summary="File picker, upload, attachment promotion, downloads UI, and file routing behavior.",
        suites=(
            "tmp-browser-smoke/file-upload",
            "tmp-browser-smoke/downloads",
            "tmp-browser-smoke/attachment-downloads",
            "tmp-browser-smoke/browser-pages",
        ),
    ),
    Route(
        key="release-build",
        title="Build and release discipline",
        summary="Build-cache recovery, packaged binary smoke, and release-candidate proof points.",
        suites=("tmp-browser-smoke/bare-metal-release",),
        notes=(
            "Pair this with the Windows build recovery flow in docs/WINDOWS_FULL_USE.md and scripts/windows/manage_build_artifacts.ps1.",
        ),
    ),
)

ROUTES_BY_KEY = {route.key: route for route in ROUTES}

PREFIX_MAP: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("src/display/win32_backend.zig", ("text-input-ime", "shell-navigation", "rendering-layout")),
    ("src/display/", ("shell-navigation", "rendering-layout")),
    ("src/render/", ("rendering-layout", "graphics")),
    ("src/browser/webapi/canvas/", ("graphics",)),
    ("src/browser/webapi/element/html/Input.zig", ("text-input-ime",)),
    ("src/browser/webapi/element/html/TextArea.zig", ("text-input-ime",)),
    ("src/browser/webapi/element/html/Label.zig", ("text-input-ime",)),
    ("src/browser/Page.zig", ("text-input-ime", "shell-navigation")),
    ("src/browser/Browser.zig", ("shell-navigation", "storage-session")),
    ("src/browser/Session.zig", ("shell-navigation", "storage-session")),
    ("src/browser/EventManager.zig", ("shell-navigation", "text-input-ime")),
    ("src/browser/webapi/net/", ("network-runtime",)),
    ("src/http/", ("network-runtime",)),
    ("src/Net.zig", ("network-runtime",)),
    ("src/HostPaths.zig", ("storage-session", "file-handling")),
    ("src/Config.zig", ("shell-navigation", "network-runtime", "release-build")),
    ("src/App.zig", ("shell-navigation", "release-build")),
    ("src/main.zig", ("shell-navigation", "release-build")),
    ("scripts/windows/manage_build_artifacts.ps1", ("release-build",)),
    ("scripts/windows/package_bare_metal_image.ps1", ("release-build",)),
    ("docs/WINDOWS_FULL_USE.md", ("release-build",)),
    ("tmp-browser-smoke/form-controls/", ("text-input-ime",)),
    ("tmp-browser-smoke/layout-smoke/", ("rendering-layout",)),
    ("tmp-browser-smoke/inline-flow/", ("rendering-layout", "text-input-ime")),
    ("tmp-browser-smoke/canvas-smoke/", ("graphics",)),
    ("tmp-browser-smoke/fetch-", ("network-runtime",)),
    ("tmp-browser-smoke/websocket-smoke/", ("network-runtime",)),
    ("tmp-browser-smoke/cookie-persistence/", ("storage-session",)),
    ("tmp-browser-smoke/localstorage-persistence/", ("storage-session",)),
    ("tmp-browser-smoke/indexeddb-persistence/", ("storage-session",)),
    ("tmp-browser-smoke/sessionstorage-scope/", ("storage-session",)),
    ("tmp-browser-smoke/file-upload/", ("file-handling",)),
    ("tmp-browser-smoke/downloads/", ("file-handling",)),
    ("tmp-browser-smoke/attachment-downloads/", ("file-handling",)),
    ("tmp-browser-smoke/bare-metal-release/", ("release-build",)),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Show headed validation suites for a subsystem or changed file path."
    )
    parser.add_argument(
        "--area",
        action="append",
        default=[],
        help="Route key to show directly. Repeatable. Use --list-areas to see choices.",
    )
    parser.add_argument(
        "--path",
        action="append",
        default=[],
        help="Changed file path to classify. Repeatable.",
    )
    parser.add_argument(
        "--list-areas",
        action="store_true",
        help="List known route keys and exit.",
    )
    return parser


def normalize_path(raw: str) -> str:
    return raw.replace("\\", "/").lstrip("./")


def route_keys_for_path(path: str) -> list[str]:
    normalized = normalize_path(path)

    if normalized.startswith("tmp-browser-smoke/"):
        parts = normalized.split("/")
        if len(parts) >= 2:
            suite = "/".join(parts[:2]) + "/"
            for prefix, keys in PREFIX_MAP:
                if prefix == suite:
                    return list(keys)

    keys: list[str] = []
    for prefix, route_keys in PREFIX_MAP:
        if normalized.startswith(prefix):
            for key in route_keys:
                if key not in keys:
                    keys.append(key)
    return keys


def ordered_unique(values: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for value in values:
        if value not in seen:
            seen.add(value)
            ordered.append(value)
    return ordered


def print_route(route: Route) -> None:
    print(f"[{route.key}] {route.title}")
    print(f"  {route.summary}")
    print("  Suites:")
    for suite in route.suites:
        print(f"    - {suite}")
    if route.notes:
        print("  Notes:")
        for note in route.notes:
            print(f"    - {note}")
    print()


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.list_areas:
        for route in ROUTES:
            print(f"{route.key}: {route.title}")
        return 0

    selected_keys: list[str] = []
    unknown_areas: list[str] = []

    for area in args.area:
        if area in ROUTES_BY_KEY:
            selected_keys.append(area)
        else:
            unknown_areas.append(area)

    path_matches: list[tuple[str, list[str]]] = []
    for raw_path in args.path:
        keys = route_keys_for_path(raw_path)
        path_matches.append((normalize_path(raw_path), keys))
        selected_keys.extend(keys)

    if unknown_areas:
        parser.error("unknown area(s): " + ", ".join(sorted(unknown_areas)))

    selected_keys = ordered_unique(selected_keys)

    if not selected_keys:
        print("No area or path was provided, so showing the full headed validation matrix.\n")
        for route in ROUTES:
            print_route(route)
        return 0

    if path_matches:
        print("Matched paths:")
        for path, keys in path_matches:
            if keys:
                print(f"  - {path}: {', '.join(keys)}")
            else:
                print(f"  - {path}: no direct route match, use the nearest subsystem route manually")
        print()

    for key in selected_keys:
        print_route(ROUTES_BY_KEY[key])

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
