#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ $# -gt 0 ]]; then
    REPO_ROOT="$1"
fi

if [[ ! -d "${REPO_ROOT}" ]]; then
    echo "Repository root does not exist: ${REPO_ROOT}" >&2
    exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required" >&2
    exit 2
fi

python3 - "${REPO_ROOT}" <<'PY'
import pathlib
import re
import sys

repo_root = pathlib.Path(sys.argv[1])

helpers = [
    ("src/browser/Session.zig", "googleWaitTraceEnabled"),
    ("src/lightpanda.zig", "googleRenderTraceEnabled"),
    ("src/display/win32_backend.zig", "googleInputTraceEnabled"),
    ("src/browser/Page.zig", "googlePresentationTraceEnabled"),
]

coverage_groups = [
    ("google homepage traces", ["google-home-", "google.com"]),
    ("fixture: google_home_title_probe", ["google_home_title_probe.html"]),
    ("fixture: body_onload_keyboard_input", ["body_onload_keyboard_input.html"]),
    ("fixture: mouse_down_focus_input", ["mouse_down_focus_input.html"]),
    (
        "attached page: google safety centre",
        [
            "control your online safety and privacy",
            "control%20your%20online%20safety%20and%20privacy",
            "google safety centre",
            "google%20safety%20centre",
        ],
    ),
    (
        "attached page: anthropic",
        [
            "anthropic",
            "job application for anthropic.html",
            "job%20application%20for%20anthropic.html",
            "job%20application%20for",
        ],
    ),
    (
        "attached page: department of war",
        [
            "department of war",
            "u.s. department of war",
            "u.s.%20department%20of%20war",
            "presidential unsealing and reporting system for uap encounters",
            "presidential%20unsealing%20and%20reporting%20system%20for%20uap%20encounters",
        ],
    ),
]


def extract_function_body(text: str, func_name: str) -> str:
    pattern = re.compile(rf"fn\s+{re.escape(func_name)}\s*\([^)]*\)\s*bool\s*\{{", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        raise ValueError(f"Could not find function {func_name}")
    index = match.end()
    depth = 1
    while index < len(text):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[match.start():index + 1]
        index += 1
    raise ValueError(f"Could not find end of function {func_name}")


print(f"Inspecting attached trace gate alignment under {repo_root}")

all_ok = True
for relative_path, func_name in helpers:
    full_path = repo_root / relative_path
    if not full_path.is_file():
        print(f"\n[FAIL] {relative_path} :: missing file")
        all_ok = False
        continue

    text = full_path.read_text(encoding="utf-8", errors="replace")
    try:
        body = extract_function_body(text, func_name).lower()
    except ValueError as exc:
        print(f"\n[FAIL] {relative_path} :: {exc}")
        all_ok = False
        continue

    missing = []
    for label, alternatives in coverage_groups:
        if not any(option.lower() in body for option in alternatives):
            missing.append(label)

    if missing:
        all_ok = False
        print(f"\n[FAIL] {relative_path} :: {func_name}")
        for label in missing:
            print(f"  - missing {label}")
    else:
        print(f"\n[PASS] {relative_path} :: {func_name}")
        print("  - all attached-page and local-fixture coverage groups found")

if all_ok:
    print("\nAll headed trace gates cover the attached compatibility pages and local fixtures.")
    sys.exit(0)

print("\nTrace gate drift remains. Widen the failing helpers before trusting attached-page headed trace coverage.")
sys.exit(1)
PY
