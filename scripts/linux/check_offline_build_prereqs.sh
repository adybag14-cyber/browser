#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF2'
Usage:
  scripts/linux/check_offline_build_prereqs.sh \
    [--browser-root /path/to/browser-repo] \
    [--zig-binary /path/to/zig] \
    [--cargo-binary /path/to/cargo] \
    [--rustc-binary /path/to/rustc] \
    [--prebuilt-v8-path /path/to/libc_v8_*.a] \
    [--allow-zig-mismatch]

This helper confirms that an offline Linux browser checkout is ready for a real
build attempt before `zig build` runs. It checks the active Zig version against
`build.zig.zon`, verifies the restored sibling dependency layout, confirms the
Rust/Cargo toolchain still required by `build.zig`'s html5ever step, accepts
the current offline manifest backup names, and prints the suggested validation
command. Use `--zig-binary`, `--cargo-binary`, `--rustc-binary`, `ZIG=...`,
`CARGO=...`, or `RUSTC=...` when compatible toolchains are installed outside
PATH. When the configured Zig binary is missing or version-mismatched, the
helper also scans nearby workspace roots for an exact-match Zig and prints
rerun hints for the discovered candidate paths. Use `--allow-zig-mismatch`
during active Zig port work when you want layout validation without treating a
known toolchain-version mismatch as a hard preflight failure.
EOF2
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BROWSER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_MEMORY_BROWSER_ROOT="/workspace/memory/repo_archives/browser"
DEFAULT_MEMORY_DEPENDENCIES_ROOT="${DEFAULT_MEMORY_BROWSER_ROOT}/dependencies"
DEFAULT_AGENT_FILES_ROOT="/workspace/agent_files"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
ZIG_BINARY="${ZIG:-}"
CARGO_BINARY="${CARGO:-}"
RUSTC_BINARY="${RUSTC:-}"
PREBUILT_V8_PATH=""
ALLOW_ZIG_MISMATCH=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser-root)
            BROWSER_ROOT="$2"
            shift 2
            ;;
        --zig-binary)
            ZIG_BINARY="$2"
            shift 2
            ;;
        --cargo-binary)
            CARGO_BINARY="$2"
            shift 2
            ;;
        --rustc-binary)
            RUSTC_BINARY="$2"
            shift 2
            ;;
        --prebuilt-v8-path)
            PREBUILT_V8_PATH="$2"
            shift 2
            ;;
        --allow-zig-mismatch)
            ALLOW_ZIG_MISMATCH=1
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

all_ok=true
zig_candidate_details=()
zig_candidate_paths=()
saved_zig_archive_details=()
saved_zig_archive_paths=()
matching_zig_archive_details=()
matching_zig_archive_paths=()
saved_rust_archive_details=()
saved_rust_archive_paths=()
cargo_candidate_details=()
cargo_candidate_paths=()
rustc_candidate_details=()
rustc_candidate_paths=()

format_status_line() {
    local name="$1"
    local ok="$2"
    local details="$3"
    local mark="FAIL"
    if [[ "${ok}" == "true" ]]; then
        mark="PASS"
    fi
    printf '[%s] %s - %s\n' "${mark}" "${name}" "${details}"
}

write_status() {
    local name="$1"
    local ok="$2"
    local details="$3"
    if [[ "${ok}" != "true" ]]; then
        all_ok=false
    fi
    format_status_line "${name}" "${ok}" "${details}"
}

write_status_stderr() {
    local name="$1"
    local ok="$2"
    local details="$3"
    if [[ "${ok}" != "true" ]]; then
        all_ok=false
    fi
    format_status_line "${name}" "${ok}" "${details}" >&2
}

write_info() {
    local name="$1"
    local details="$2"
    printf '[INFO] %s - %s\n' "${name}" "${details}"
}

resolve_command() {
    local provided_path="$1"
    local status_name="$2"
    local binary_name="$3"

    if [[ -n "${provided_path}" ]]; then
        if [[ -x "${provided_path}" ]]; then
            printf '%s\n' "${provided_path}"
            return 0
        fi
        write_status_stderr "${status_name}" false "configured ${binary_name} binary is not executable: ${provided_path}"
        return 1
    fi

    if command -v "${binary_name}" >/dev/null 2>&1; then
        command -v "${binary_name}"
        return 0
    fi

    write_status_stderr "${status_name}" false "${binary_name} not found in PATH"
    return 1
}

SEARCH_ROOTS=()

append_unique_search_root() {
    local candidate="$1"
    [[ -n "${candidate}" ]] || return 0
    [[ -d "${candidate}" ]] || return 0

    local resolved
    resolved="$(cd "${candidate}" && pwd)"
    for existing in "${SEARCH_ROOTS[@]:-}"; do
        if [[ "${existing}" == "${resolved}" ]]; then
            return 0
        fi
    done
    SEARCH_ROOTS+=("${resolved}")
}

discover_matching_zig_candidates() {
    local expected_version="$1"
    shift

    local root
    local candidate
    local candidate_version
    local -A seen=()
    zig_candidate_details=()
    zig_candidate_paths=()

    for root in "$@"; do
        [[ -d "${root}" ]] || continue
        while IFS= read -r candidate; do
            [[ -n "${candidate}" ]] || continue
            if [[ -n "${seen["${candidate}"]:-}" ]]; then
                continue
            fi
            seen["${candidate}"]=1

            candidate_version="$("${candidate}" version 2>/dev/null | tr -d '\r' || true)"
            if [[ "${candidate_version}" == "${expected_version}" ]]; then
                zig_candidate_details+=("${candidate} (${candidate_version})")
                zig_candidate_paths+=("${candidate}")
            fi
        done < <(find "${root}" -maxdepth 5 -type f -name zig -perm -u+x 2>/dev/null)
    done
}

discover_command_candidates() {
    local binary_name="$1"
    shift

    local root
    local candidate
    local candidate_version
    local details=()
    local paths=()
    local -A seen=()

    for root in "$@"; do
        [[ -d "${root}" ]] || continue
        while IFS= read -r candidate; do
            [[ -n "${candidate}" ]] || continue
            if [[ -n "${seen["${candidate}"]:-}" ]]; then
                continue
            fi
            seen["${candidate}"]=1

            candidate_version="$("${candidate}" --version 2>/dev/null | head -n 1 | tr -d '\r' || true)"
            if [[ -n "${candidate_version}" ]]; then
                details+=("${candidate} (${candidate_version})")
            else
                details+=("${candidate}")
            fi
            paths+=("${candidate}")
        done < <(find "${root}" -maxdepth 6 -type f -name "${binary_name}" -perm -u+x 2>/dev/null)
    done

    case "${binary_name}" in
        cargo)
            cargo_candidate_details=("${details[@]}")
            cargo_candidate_paths=("${paths[@]}")
            ;;
        rustc)
            rustc_candidate_details=("${details[@]}")
            rustc_candidate_paths=("${paths[@]}")
            ;;
    esac
}

discover_saved_rust_archives() {
    local root
    local candidate
    local -A seen=()
    saved_rust_archive_details=()
    saved_rust_archive_paths=()

    for root in "$@"; do
        [[ -d "${root}" ]] || continue
        while IFS= read -r candidate; do
            [[ -n "${candidate}" ]] || continue
            if [[ -n "${seen["${candidate}"]:-}" ]]; then
                continue
            fi
            seen["${candidate}"]=1

            saved_rust_archive_paths+=("${candidate}")
            saved_rust_archive_details+=("${candidate} ($(basename "${candidate}"))")
        done < <(find "${root}" -maxdepth 6 -type f \( -name 'rust-*.tar.*' -o -name '01-rust-*.tar.*' \) 2>/dev/null)
    done
}

discover_saved_zig_archives() {
    local expected_version="$1"
    shift

    local root
    local candidate
    local archive_name
    local archive_version
    local detail
    local -A seen=()
    saved_zig_archive_details=()
    saved_zig_archive_paths=()
    matching_zig_archive_details=()
    matching_zig_archive_paths=()

    for root in "$@"; do
        [[ -d "${root}" ]] || continue
        while IFS= read -r candidate; do
            [[ -n "${candidate}" ]] || continue
            if [[ -n "${seen["${candidate}"]:-}" ]]; then
                continue
            fi
            seen["${candidate}"]=1

            archive_name="$(basename "${candidate}")"
            archive_version="$(printf '%s\n' "${archive_name}" | sed -E 's/^zig-[^-]+-[^-]+-(.+)\.tar\.[^.]+$/\1/')"
            if [[ "${archive_version}" == "${archive_name}" ]]; then
                archive_version="unknown"
            fi

            if [[ "${archive_version}" == "${expected_version}" ]]; then
                detail="${candidate} (version ${archive_version}, matches build.zig.zon)"
                matching_zig_archive_details+=("${detail}")
                matching_zig_archive_paths+=("${candidate}")
            else
                detail="${candidate} (version ${archive_version}, expected ${expected_version})"
                saved_zig_archive_details+=("${detail}")
                saved_zig_archive_paths+=("${candidate}")
            fi
        done < <(find "${root}" -maxdepth 6 -type f \( -name 'zig-*.tar.xz' -o -name 'zig-*.tar.gz' -o -name 'zig-*.zip' \) 2>/dev/null)
    done
}

if [[ ! -f "${BROWSER_ROOT}/build.zig.zon" ]]; then
    write_status "BrowserRoot" false "build.zig.zon not found under ${BROWSER_ROOT}"
    echo
    echo "Offline build prerequisites are not ready yet."
    exit 1
fi
write_status "BrowserRoot" true "${BROWSER_ROOT}"

BUILD_ZON_PATH="${BROWSER_ROOT}/build.zig.zon"
WORKSPACE_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)"
OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
BUILD_ZON_BACKUP=""

append_unique_search_root "${BROWSER_ROOT}"
append_unique_search_root "${WORKSPACE_ROOT}"
append_unique_search_root "$(cd "${WORKSPACE_ROOT}/.." && pwd 2>/dev/null || true)"
append_unique_search_root "${DEFAULT_MEMORY_BROWSER_ROOT}"
append_unique_search_root "${DEFAULT_MEMORY_DEPENDENCIES_ROOT}"
append_unique_search_root "${DEFAULT_AGENT_FILES_ROOT}"
if [[ -n "${ZIG_BINARY}" ]]; then
    append_unique_search_root "$(dirname "${ZIG_BINARY}")"
    append_unique_search_root "$(cd "$(dirname "${ZIG_BINARY}")/.." && pwd 2>/dev/null || true)"
fi
if [[ -n "${CARGO_BINARY}" ]]; then
    append_unique_search_root "$(dirname "${CARGO_BINARY}")"
    append_unique_search_root "$(cd "$(dirname "${CARGO_BINARY}")/.." && pwd 2>/dev/null || true)"
fi
if [[ -n "${RUSTC_BINARY}" ]]; then
    append_unique_search_root "$(dirname "${RUSTC_BINARY}")"
    append_unique_search_root "$(cd "$(dirname "${RUSTC_BINARY}")/.." && pwd 2>/dev/null || true)"
fi

for candidate in \
    "${BROWSER_ROOT}/build.zig.zon.remote-sources.bak" \
    "${BROWSER_ROOT}/build.zig.zon.before-offline"
do
    if [[ -f "${candidate}" ]]; then
        BUILD_ZON_BACKUP="${candidate}"
        break
    fi
done

MINIMUM_ZIG_VERSION="$(python3 - "${BUILD_ZON_PATH}" <<'PY'
import pathlib
import re
import sys
text = pathlib.Path(sys.argv[1]).read_text()
match = re.search(r'\.minimum_zig_version\s*=\s*"([^"]+)"', text)
if not match:
    raise SystemExit('missing minimum_zig_version')
print(match.group(1))
PY
)"

zig_version=""
zig_cmd="$(resolve_command "${ZIG_BINARY}" "Zig" zig || true)"
if [[ -n "${zig_cmd}" ]]; then
    zig_version="$("${zig_cmd}" version | tr -d '\r')"
    write_status "Zig" true "${zig_cmd} (${zig_version})"
fi

if [[ -n "${zig_version}" ]]; then
    if [[ "${zig_version}" == "${MINIMUM_ZIG_VERSION}" ]]; then
        write_status "ZigVersion" true "matches build.zig.zon minimum ${MINIMUM_ZIG_VERSION}"
    else
        if [[ "${ALLOW_ZIG_MISMATCH}" -eq 1 ]]; then
            printf '[WARN] %s - expected %s, found %s; continuing because --allow-zig-mismatch was set\n' "ZigVersion" "${MINIMUM_ZIG_VERSION}" "${zig_version}"
        else
            write_status "ZigVersion" false "expected ${MINIMUM_ZIG_VERSION}, found ${zig_version}"
        fi
    fi
fi

need_zig_candidate_search=false
if [[ -z "${zig_cmd}" ]]; then
    need_zig_candidate_search=true
elif [[ "${zig_version}" != "${MINIMUM_ZIG_VERSION}" && "${ALLOW_ZIG_MISMATCH}" -ne 1 ]]; then
    need_zig_candidate_search=true
fi

if [[ "${need_zig_candidate_search}" == "true" ]]; then
    discover_matching_zig_candidates "${MINIMUM_ZIG_VERSION}" "${SEARCH_ROOTS[@]}"
    if (( ${#zig_candidate_details[@]} > 0 )); then
        for candidate_detail in "${zig_candidate_details[@]}"; do
            write_status "ZigCandidate" true "${candidate_detail}"
        done
    else
        write_status "ZigCandidate" false "no local zig binary matching ${MINIMUM_ZIG_VERSION} was discovered under ${SEARCH_ROOTS[*]}"
    fi

    discover_saved_zig_archives "${MINIMUM_ZIG_VERSION}" "${SEARCH_ROOTS[@]}"
    if (( ${#matching_zig_archive_details[@]} > 0 )); then
        for candidate_detail in "${matching_zig_archive_details[@]}"; do
            write_info "ZigArchive" "saved archive available for extraction: ${candidate_detail}"
        done
    fi
    if (( ${#saved_zig_archive_details[@]} > 0 )); then
        for candidate_detail in "${saved_zig_archive_details[@]}"; do
            write_info "ZigArchive" "${candidate_detail}"
        done
    fi
fi

cargo_cmd="$(resolve_command "${CARGO_BINARY}" "Cargo" cargo || true)"
if [[ -n "${cargo_cmd}" ]]; then
    cargo_version="$("${cargo_cmd}" --version | tr -d '\r')"
    write_status "Cargo" true "${cargo_cmd} (${cargo_version})"
else
    discover_command_candidates cargo "${SEARCH_ROOTS[@]}"
    if (( ${#cargo_candidate_details[@]} > 0 )); then
        for candidate_detail in "${cargo_candidate_details[@]}"; do
            write_status "CargoCandidate" true "${candidate_detail}"
        done
    else
        write_info "CargoCandidate" "no local cargo binary discovered under ${SEARCH_ROOTS[*]}"
    fi
fi

rustc_cmd="$(resolve_command "${RUSTC_BINARY}" "Rustc" rustc || true)"
if [[ -n "${rustc_cmd}" ]]; then
    rustc_version="$("${rustc_cmd}" --version | tr -d '\r')"
    write_status "Rustc" true "${rustc_cmd} (${rustc_version})"
else
    discover_command_candidates rustc "${SEARCH_ROOTS[@]}"
    if (( ${#rustc_candidate_details[@]} > 0 )); then
        for candidate_detail in "${rustc_candidate_details[@]}"; do
            write_status "RustcCandidate" true "${candidate_detail}"
        done
    else
        write_info "RustcCandidate" "no local rustc binary discovered under ${SEARCH_ROOTS[*]}"
    fi
fi

if [[ -z "${cargo_cmd}" || -z "${rustc_cmd}" ]]; then
    discover_saved_rust_archives "${SEARCH_ROOTS[@]}"
    if (( ${#saved_rust_archive_details[@]} > 0 )); then
        for archive_detail in "${saved_rust_archive_details[@]}"; do
            write_info "RustArchive" "saved archive available for extraction: ${archive_detail}"
        done
    fi
fi

if [[ -n "${BUILD_ZON_BACKUP}" ]]; then
    write_status "ManifestBackup" true "${BUILD_ZON_BACKUP}"
else
    write_status "ManifestBackup" false "missing build.zig.zon.remote-sources.bak or build.zig.zon.before-offline"
fi

DEP_PATH_ROWS="$(python3 - "${BUILD_ZON_PATH}" <<'PY'
import pathlib
import re
import sys
text = pathlib.Path(sys.argv[1]).read_text()
for dep in ("brotli", "zlib", "nghttp2", "curl"):
    block = re.search(rf'\.{re.escape(dep)}\s*=\s*\.\{{(.*?)\n\s*\}},', text, re.S)
    if not block:
        print(f"{dep}\t")
        continue
    path_match = re.search(r'\.path\s*=\s*"([^"]+)"', block.group(1))
    print(f"{dep}\t{path_match.group(1) if path_match else ''}")
PY
)"

manifest_paths_ok=true
while IFS=$'\t' read -r dep relpath; do
    if [[ -z "${dep}" ]]; then
        continue
    fi

    if [[ -z "${relpath}" ]]; then
        write_status "manifest:${dep}" false "missing .path entry for ${dep} in build.zig.zon"
        manifest_paths_ok=false
        continue
    fi

    if [[ "${relpath}" != ../offline-deps/* ]]; then
        write_status "manifest:${dep}" false "expected ${dep} to resolve under ../offline-deps, found ${relpath}"
        manifest_paths_ok=false
        continue
    fi

    dep_path="$(python3 - "${BROWSER_ROOT}" "${relpath}" <<'PY'
from pathlib import Path
import sys
browser_root = Path(sys.argv[1])
relpath = sys.argv[2]
print((browser_root / relpath).resolve())
PY
)"
    if [[ -d "${dep_path}" ]]; then
        write_status "offline:${dep}" true "${dep_path}"
    else
        write_status "offline:${dep}" false "missing ${dep_path}"
        manifest_paths_ok=false
    fi
done <<< "${DEP_PATH_ROWS}"

if [[ "${manifest_paths_ok}" == "true" ]]; then
    write_status "ManifestPaths" true "build.zig.zon points brotli/zlib/nghttp2/curl at local ../offline-deps paths"
else
    write_status "ManifestPaths" false "build.zig.zon and the extracted offline dependency directories are not aligned yet"
fi

for sibling in zig-v8-fork boringssl-zig; do
    sibling_path="${WORKSPACE_ROOT}/${sibling}"
    if [[ -d "${sibling_path}" ]]; then
        write_status "${sibling}" true "${sibling_path}"
    else
        write_status "${sibling}" false "missing ${sibling_path}"
    fi
done

if [[ -f "${BROWSER_ROOT}/.cargo/config.toml" ]]; then
    write_status "cargo-config" true "${BROWSER_ROOT}/.cargo/config.toml"
else
    write_status "cargo-config" false "missing ${BROWSER_ROOT}/.cargo/config.toml"
fi

if [[ -d "${BROWSER_ROOT}/vendor" ]]; then
    write_status "vendor" true "${BROWSER_ROOT}/vendor"
else
    write_status "vendor" false "missing ${BROWSER_ROOT}/vendor"
fi

if [[ -z "${PREBUILT_V8_PATH}" ]]; then
    PREBUILT_V8_PATH="$(find "${OFFLINE_DEPS_ROOT}" -maxdepth 1 -type f -name 'libc_v8_*.a' | head -n 1 || true)"
fi

if [[ -n "${PREBUILT_V8_PATH}" && -f "${PREBUILT_V8_PATH}" ]]; then
    write_status "prebuilt-v8" true "${PREBUILT_V8_PATH}"
else
    write_status "prebuilt-v8" false "missing libc_v8_*.a archive (pass --prebuilt-v8-path if stored elsewhere)"
fi

if [[ "${all_ok}" == "true" ]]; then
    echo
    echo "Offline build prerequisites look good."
    if [[ -n "${zig_cmd}" ]]; then
        printf "Suggested validation command:\n  %s build --summary all -Dprebuilt_v8_path='%s'\n" "${zig_cmd}" "${PREBUILT_V8_PATH}"
    else
        printf "Suggested validation command:\n  zig build --summary all -Dprebuilt_v8_path='%s'\n" "${PREBUILT_V8_PATH}"
    fi
    exit 0
fi

echo
echo "Offline build prerequisites are not ready yet."
if (( ${#zig_candidate_paths[@]} > 0 )); then
    echo "Compatible Zig candidate(s) were found locally. Re-run the preflight with one of these:"
    for candidate_path in "${zig_candidate_paths[@]}"; do
        printf "  --zig-binary '%s'\n" "${candidate_path}"
        printf "  ZIG='%s' scripts/linux/check_offline_build_prereqs.sh\n" "${candidate_path}"
    done
elif (( ${#matching_zig_archive_paths[@]} > 0 )); then
    echo "A saved Zig archive matching ${MINIMUM_ZIG_VERSION} was found locally. Extract it, then rerun preflight with the resulting zig binary:"
    for archive_path in "${matching_zig_archive_paths[@]}"; do
        printf "  %s\n" "${archive_path}"
    done
else
    echo "No local Zig candidate matching ${MINIMUM_ZIG_VERSION} was discovered in the nearby workspace roots."
    if (( ${#saved_zig_archive_paths[@]} > 0 )); then
        echo "Saved Zig archives were found, but they do not match the branch requirement:"
        for archive_path in "${saved_zig_archive_paths[@]}"; do
            printf "  %s\n" "${archive_path}"
        done
    fi
fi

if (( ${#cargo_candidate_paths[@]} > 0 || ${#rustc_candidate_paths[@]} > 0 )); then
    echo "Local Rust toolchain candidates were also found. Re-run with explicit paths if they are still outside PATH:"
    for candidate_path in "${cargo_candidate_paths[@]}"; do
        printf "  --cargo-binary '%s'\n" "${candidate_path}"
    done
    for candidate_path in "${rustc_candidate_paths[@]}"; do
        printf "  --rustc-binary '%s'\n" "${candidate_path}"
    done
elif (( ${#saved_rust_archive_paths[@]} > 0 )); then
    echo "Saved Rust archive(s) were found locally. Extract one, then rerun preflight with the resulting cargo and rustc binaries if needed:"
    for archive_path in "${saved_rust_archive_paths[@]}"; do
        printf "  %s\n" "${archive_path}"
    done
fi

echo "Run scripts/linux/restore_offline_build_inputs.sh (or scripts/linux/prepare_offline_build_inputs.sh for custom archive locations), switch to Zig ${MINIMUM_ZIG_VERSION}, and make sure cargo plus rustc are available before retrying zig build. Use --zig-binary /path/to/zig, --cargo-binary /path/to/cargo, --rustc-binary /path/to/rustc, or the ZIG/CARGO/RUSTC environment variables when the compatible toolchains are installed outside PATH."
if [[ "${ALLOW_ZIG_MISMATCH}" -eq 1 ]]; then
    echo "Because --allow-zig-mismatch was set, the remaining failures are layout or toolchain-path issues rather than the expected Zig version drift."
fi
exit 1