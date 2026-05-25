#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the issue #3 Linux or WSL Zig toolchain recovery route for the blocked
Enter-submit runtime lane.
EOF
}

normalize_saved_archives_root() {
    local raw_root="$1"
    if [[ -d "${raw_root}/dependencies" ]]; then
        raw_root="${raw_root}/dependencies"
    fi
    if [[ -d "${raw_root}" ]]; then
        (
            cd "${raw_root}"
            pwd
        )
        return 0
    fi
    printf '%s\n' "${raw_root}"
}

resolve_first_existing_path() {
    local start="$1"
    local relative_path="$2"
    local current="$start"
    while true; do
        if [[ -e "${current}/${relative_path}" ]]; then
            printf '%s\n' "${current}/${relative_path}"
            return 0
        fi
        if [[ "${current}" == "/" ]]; then
            return 1
        fi
        current="$(dirname "${current}")"
    done
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
TOOLCHAINS_ROOT=""
SAVED_ARCHIVES_ROOT=""
OFFLINE_DEPS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
            shift 2
            ;;
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
            shift 2
            ;;
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --json)
            JSON=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "toolchains" || true)"
    if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
        TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
    fi
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "memory/repo_archives/browser" || true)"
    if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
        SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
    fi
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "offline-deps" || true)"
    if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
        OFFLINE_DEPS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/offline-deps"
    fi
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(resolve_first_existing_path "${REPO_ROOT}" "agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz" || true)"
    if [[ -z "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    fi
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

python3 - "${REPO_ROOT}" "${TOOLCHAINS_ROOT}" "${SAVED_ARCHIVES_ROOT}" "${OFFLINE_DEPS_ROOT}" "${FALLBACK_ZIG_ARCHIVE}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import re
import shlex
import subprocess
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
toolchains_root = pathlib.Path(sys.argv[2]).resolve()
saved_archives_root = pathlib.Path(sys.argv[3]).resolve()
offline_deps_root = pathlib.Path(sys.argv[4]).resolve()
fallback_zig_archive = sys.argv[5]
emit_json = sys.argv[6] == "1"

build_zon = repo_root / "build.zig.zon"
if not build_zon.is_file():
    raise SystemExit(f"build.zig.zon not found under {repo_root}")

match = re.search(
    r'\.minimum_zig_version\s*=\s*"([^"]+)"',
    build_zon.read_text(encoding="utf-8"),
)
if match is None:
    raise SystemExit("Could not find minimum_zig_version in build.zig.zon")
minimum_zig = match.group(1)

semver_re = re.compile(r"(\d+)\.(\d+)\.(\d+)")


def parse_semver(text: str) -> tuple[int, int, int]:
    match = semver_re.search(text)
    if match is None:
        raise ValueError(text)
    return tuple(int(part) for part in match.groups())


def classify(actual: str) -> str:
    minimum_parts = parse_semver(minimum_zig)
    actual_parts = parse_semver(actual)
    if actual_parts < minimum_parts:
        return "older-than-minimum"
    if actual_parts[:2] == minimum_parts[:2]:
        return "matches-expected-line"
    return "mismatched-line"


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_recovery_route_surface.sh"
matching_line_gate_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh"
saved_archive_candidates_script = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"
readiness_script = repo_root / "scripts" / "check_linux_build_readiness.py"
fallback_restore_script = repo_root / "scripts" / "linux" / "restore_issue3_fallback_zig_toolchain.sh"


def load_saved_archive_report() -> tuple[
    list[dict[str, str]],
    dict[str, str] | None,
    str | None,
    str | None,
    str | None,
]:
    if not saved_archive_candidates_script.is_file():
        return [], None, None, None, f"saved archive candidate helper is missing: {saved_archive_candidates_script}"

    command = [
        sys.executable,
        str(saved_archive_candidates_script),
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
        "--json",
    ]
    if fallback_zig_archive:
        command.extend(("--fallback-zig-archive", fallback_zig_archive))

    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        return [], None, None, None, f"saved archive candidate helper could not run: {exc}"

    helper_stdout = completed.stdout.strip()
    if not helper_stdout:
        detail = completed.stderr.strip()
        if detail:
            detail = f"; stderr: {detail}"
        return [], None, None, None, f"saved archive candidate helper produced no JSON output{detail}"

    try:
        helper_report = json.loads(helper_stdout)
    except json.JSONDecodeError as exc:
        return [], None, None, None, f"saved archive candidate helper returned invalid JSON: {exc}"

    commands = helper_report.get("commands") or {}
    return (
        helper_report.get("zig_archives") or [],
        helper_report.get("preferred_archive"),
        commands.get("restore_check"),
        commands.get("restore"),
        None,
    )

patterns = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")
candidates: list[dict[str, str]] = []
seen: set[pathlib.Path] = set()

if toolchains_root.is_dir():
    for pattern in patterns:
        for path in sorted(toolchains_root.glob(pattern)):
            resolved = path.resolve()
            if resolved in seen or not resolved.is_file():
                continue
            seen.add(resolved)
            try:
                completed = subprocess.run(
                    [str(resolved), "version"],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                version = completed.stdout.strip() or completed.stderr.strip()
                status = classify(version)
            except Exception:
                version = "unusable"
                status = "version-probe-failed"
            candidates.append(
                {
                    "path": str(resolved),
                    "version": version,
                    "status": status,
                }
            )

matching_candidate = next(
    (candidate for candidate in candidates if candidate["status"] == "matches-expected-line"),
    None,
)
(
    saved_archives,
    preferred_saved_archive,
    matching_archive_restore_check_command,
    matching_archive_restore_command,
    saved_archive_helper_warning,
) = load_saved_archive_report()

surface_check_command = format_command(
    [
        "bash",
        str(route_surface_script),
        "--repo-root",
        str(repo_root),
    ]
)
matching_line_gate_parts = [
    "bash",
    str(matching_line_gate_script),
    "--repo-root",
    str(repo_root),
    "--toolchains-root",
    str(toolchains_root),
]
if fallback_zig_archive:
    matching_line_gate_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
matching_line_gate_command = format_command(matching_line_gate_parts)
saved_archive_candidate_discovery_command = format_command(
    [
        "python",
        str(saved_archive_candidates_script),
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
    ]
    + (
        ["--fallback-zig-archive", fallback_zig_archive]
        if fallback_zig_archive
        else []
    )
)
archive_restore_surface_check_command = format_command(
    [
        "bash",
        str(archive_restore_surface_script),
        "--repo-root",
        str(repo_root),
    ]
)
discovery_parts = [
    "python",
    str(readiness_script),
    "--repo-root",
    str(repo_root),
    "--skip-zig-check",
    "--skip-rust-check",
    "--expect-saved-archives",
    "--saved-archives-root",
    str(saved_archives_root),
    "--toolchains-root",
    str(toolchains_root),
]
if fallback_zig_archive:
    discovery_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
discovery_command = format_command(discovery_parts)
matching_readiness_command = None
if matching_candidate is not None:
    matching_parts = [
        "python",
        str(readiness_script),
        "--repo-root",
        str(repo_root),
        "--zig",
        matching_candidate["path"],
        "--expect-saved-archives",
        "--saved-archives-root",
        str(saved_archives_root),
        "--expect-offline-deps",
        "--offline-deps-root",
        str(offline_deps_root),
        "--require-prebuilt-v8",
        "--toolchains-root",
        str(toolchains_root),
    ]
    if fallback_zig_archive:
        matching_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
    matching_readiness_command = format_command(matching_parts)

fallback_restore_check_command = None
fallback_restore_command = None
if fallback_zig_archive:
    fallback_restore_check_command = format_command(
        [
            "bash",
            str(fallback_restore_script),
            "--browser-root",
            str(repo_root),
            "--toolchains-root",
            str(toolchains_root),
            "--archive",
            fallback_zig_archive,
            "--check-only",
        ]
    )
    fallback_restore_command = format_command(
        [
            "bash",
            str(fallback_restore_script),
            "--browser-root",
            str(repo_root),
            "--toolchains-root",
            str(toolchains_root),
            "--archive",
            fallback_zig_archive,
        ]
    )

result = {
    "issue": "Google issue #3 Zig toolchain recovery route",
    "repo_root": str(repo_root),
    "toolchains_root": str(toolchains_root),
    "saved_archives_root": str(saved_archives_root),
    "offline_deps_root": str(offline_deps_root),
    "minimum_zig": minimum_zig,
    "fallback_zig_archive": fallback_zig_archive,
    "matching_candidate": matching_candidate["path"] if matching_candidate else "",
    "matching_candidate_version": matching_candidate["version"] if matching_candidate else "",
    "preferred_saved_archive": preferred_saved_archive["path"] if preferred_saved_archive else "",
    "preferred_saved_archive_version": preferred_saved_archive["version"] if preferred_saved_archive else "",
    "commands": {
        "surface_check": surface_check_command,
        "matching_line_gate": matching_line_gate_command,
        "saved_archive_candidate_discovery": saved_archive_candidate_discovery_command,
        "archive_restore_surface_check": archive_restore_surface_check_command,
        "discovery": discovery_command,
    },
    "candidates": candidates,
    "saved_archives": saved_archives,
    "saved_archive_helper_warning": saved_archive_helper_warning or "",
}
if matching_readiness_command is not None:
    result["commands"]["matching_readiness"] = matching_readiness_command
if matching_archive_restore_check_command is not None:
    result["commands"]["matching_archive_restore_check"] = matching_archive_restore_check_command
if matching_archive_restore_command is not None:
    result["commands"]["matching_archive_restore"] = matching_archive_restore_command
if fallback_restore_check_command is not None:
    result["commands"]["fallback_restore_check"] = fallback_restore_check_command
if fallback_restore_command is not None:
    result["commands"]["fallback_restore"] = fallback_restore_command

if emit_json:
    print(json.dumps(result, indent=2))
    raise SystemExit(0)

print("Google issue #3 Zig toolchain recovery route")
print()
print(f"Repo root:            {repo_root}")
print(f"Toolchains root:      {toolchains_root}")
print(f"Saved archives root:  {saved_archives_root}")
print(f"Offline deps root:    {offline_deps_root}")
print(f"Minimum Zig line:     {minimum_zig}")
print(
    "Fallback Zig archive: "
    f"{fallback_zig_archive or 'not found beside the repo workspace'}"
)
print()
print("Read first")
print("==========")
print("  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md")
print("  docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md")
print("  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")
print("  docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
print()
print("Surface check")
print("=============")
print(f"  {surface_check_command}")
print()
print("Matching-line gate")
print("==================")
print(f"  {matching_line_gate_command}")
print()
print("Saved archive candidate discovery")
print("================================")
print(f"  {saved_archive_candidate_discovery_command}")
print()
print("Archive restore surface check")
print("=============================")
print(f"  {archive_restore_surface_check_command}")
print()
print("Candidate discovery")
print("===================")
print(f"  {discovery_command}")

if saved_archives:
    print()
    print("Saved Zig archives")
    print("==================")
    for archive in saved_archives:
        version = archive["version"] or "unknown-version"
        print(
            f"  - {archive['path']} "
            f"[top-level={archive['top_level']}; {version}; {archive['status']}]"
        )
    if matching_archive_restore_check_command is not None and matching_archive_restore_command is not None:
        print()
        print("Preferred archive restore")
        print("=========================")
        print(f"  {matching_archive_restore_check_command}")
        print(f"  {matching_archive_restore_command}")
elif saved_archive_helper_warning is not None:
    print()
    print("Saved archive helper warning")
    print("===========================")
    print(f"  {saved_archive_helper_warning}")

if fallback_restore_check_command is not None and fallback_restore_command is not None:
    print()
    print("Fallback archive staging")
    print("========================")
    print(f"  {fallback_restore_check_command}")
    print(f"  {fallback_restore_command}")

if not candidates:
    print()
    print("Discovered Zig candidates: none")
    print()
    print("Working rules")
    print("=============")
    print(
        "  - Run the surface check first so missing docs or helper drift fails "
        "before the route blames the fallback Zig bundle."
    )
    print(
        "  - Run the matching-line gate right after the surface check so the "
        "shared toolchains directory has to prove a real 0.15.x candidate exists "
        "before broader readiness is trusted again."
    )
    print(
        "  - Run the saved archive candidate discovery command before choosing "
        "a restore target so the preferred 0.15.x archive stays visible on a "
        "branch-local helper surface."
    )
    print(
        "  - Run the archive restore surface check before restoring any saved or "
        "manual Zig archive so route drift fails fast before toolchain staging starts."
    )
    if saved_archive_helper_warning is not None:
        print(
            "  - Re-run the saved archive candidate helper once its warning is resolved "
            "so the preferred 0.15.x restore path is visible on the route again."
        )
    print(
        "  - The saved-archives-root override accepts either repo_archives/browser "
        "or repo_archives/browser/dependencies and is normalized before discovery runs."
    )
    if preferred_saved_archive is not None:
        print(
            "  - Use the preferred archive restore commands above before falling "
            "back to the attached Zig 0.17 bundle."
        )
    print(
        f"  - Stage a Zig {minimum_zig.rsplit('.', 1)[0]}.x toolchain under "
        f"{toolchains_root} before reopening focused Linux or WSL validation."
    )
    if fallback_restore_command is not None:
        print(
            "  - If the only available archive is the attached Zig 0.17 fallback, "
            "use the fallback restore helper above so later reruns can probe it "
            "consistently from the shared toolchains area."
        )
    print(
        "  - Treat the attached Zig 0.17 dev bundle as a surfaced fallback "
        "only; it is not branch-compatible validation evidence for this checkout."
    )
    print(
        "  - After staging a matching Zig line, rerun the discovery command, "
        "then rerun the matching-line gate before the full readiness helper."
    )
    raise SystemExit(0)

print()
print("Discovered Zig candidates")
print("=========================")
for candidate in candidates:
    print(
        f"  - {candidate['path']} "
        f"[{candidate['version']}; {candidate['status']}]"
    )

print()
if matching_readiness_command is not None:
    print("Suggested matching readiness command")
    print("====================================")
    print(f"  {matching_readiness_command}")
    print()
    print("Working rules")
    print("=============")
    print(
        "  - Run the surface check first so missing docs or helper drift fails "
        "before the route blames the fallback Zig bundle."
    )
    print(
        "  - Run the matching-line gate right after the surface check so the "
        "shared toolchains directory proves the staged candidate before broader "
        "readiness is trusted again."
    )
    print(
        "  - Run the saved archive candidate discovery command before choosing "
        "a restore target so the preferred 0.15.x archive stays visible on a "
        "branch-local helper surface."
    )
    print(
        "  - Run the archive restore surface check before restaging a saved Zig "
        "archive so route drift fails fast before toolchain staging starts."
    )
    if saved_archive_helper_warning is not None:
        print(
            "  - Re-run the saved archive candidate helper once its warning is resolved "
            "so the preferred 0.15.x restore path is visible on the route again."
        )
    print(
        "  - The saved-archives-root override accepts either repo_archives/browser "
        "or repo_archives/browser/dependencies and is normalized before discovery runs."
    )
    if preferred_saved_archive is not None:
        print(
            "  - Keep the preferred saved-archive restore commands above as the "
            "shortest way to restage a matching Zig line if toolchains/ gets reset."
        )
    print(
        f"  - Prefer {matching_candidate['path']} because it matches the branch's "
        f"{minimum_zig.rsplit('.', 1)[0]}.x Zig line."
    )
    if fallback_restore_command is not None:
        print(
            "  - Keep the fallback restore helper above as the branch-local way "
            "to restage the attached Zig archive when toolchains/ is empty on a "
            "future rerun."
        )
    print(
        "  - Keep the saved-archive, offline-dependency, and fallback-Zig path "
        "surfaces aligned with the current workspace when rerunning readiness."
    )
    print(
        "  - Only reopen the direct Page.zig plus win32_backend.zig runtime "
        "patch after this matching-line readiness pass stops reporting the "
        "environment as the blocker."
    )
else:
    print("No branch-compatible Zig candidate is staged yet.")
    print()
    print("Working rules")
    print("=============")
    print(
        "  - Run the surface check first so missing docs or helper drift fails "
        "before the route blames the fallback Zig bundle."
    )
    print(
        "  - Run the matching-line gate right after the surface check so the "
        "shared toolchains directory has to prove a real 0.15.x candidate exists "
        "before broader readiness is trusted again."
    )
    print(
        "  - Run the saved archive candidate discovery command before choosing "
        "a restore target so the preferred 0.15.x archive stays visible on a "
        "branch-local helper surface."
    )
    print(
        "  - Run the archive restore surface check before restoring a saved or "
        "manual Zig archive so route drift fails fast before toolchain staging starts."
    )
    if saved_archive_helper_warning is not None:
        print(
            "  - Re-run the saved archive candidate helper once its warning is resolved "
            "so the preferred 0.15.x restore path is visible on the route again."
        )
    print(
        "  - The saved-archives-root override accepts either repo_archives/browser "
        "or repo_archives/browser/dependencies and is normalized before discovery runs."
    )
    if preferred_saved_archive is not None:
        print(
            "  - Restore the preferred saved Zig archive above before relying on "
            "the fallback archive staging route."
        )
    print(
        f"  - Ignore candidates above that are older than {minimum_zig} or that "
        "live on a different major/minor Zig line."
    )
    print(
        f"  - Stage a Zig {minimum_zig.rsplit('.', 1)[0]}.x toolchain under "
        f"{toolchains_root}, then rerun the discovery command."
    )
    if fallback_restore_command is not None:
        print(
            "  - If the only available archive is the attached Zig 0.17 fallback, "
            "use the fallback restore helper above to keep that staging step on a "
            "branch-local route instead of rebuilding the extraction command by hand."
        )
    print(
        "  - Treat the attached Zig 0.17 dev bundle as a surfaced fallback "
        "only; it is not honest issue #3 validation evidence for this branch."
    )
PY
