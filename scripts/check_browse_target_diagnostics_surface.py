#!/usr/bin/env python3
"""Check and preview the browse-target startup diagnostics surface.

This helper keeps the headed startup classification breadcrumbs easy to audit
from a checkout without rebuilding the browser. It verifies that the current
`src/main.zig` browse logs still emit the target classification fields and can
also mirror the same URL classification for sample targets.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from dataclasses import asdict, dataclass


REQUIRED_FIELD_COUNTS = {
    ".target_scheme = browse_target.scheme,": 5,
    ".target_scope = browse_target.scope,": 5,
    ".target_host = browse_target.host,": 5,
    ".target_port = browse_target.port,": 5,
}

REQUIRED_HELPERS = (
    "fn browseTargetInfo(url: []const u8) BrowseTargetInfo",
    "fn browseTargetInternal(url: []const u8, scheme: []const u8) ?BrowseTargetInfo",
    "fn browseTargetImplicitLoopback(url: []const u8) ?BrowseTargetInfo",
    "fn browseTargetImplicitRemote(url: []const u8) ?BrowseTargetInfo",
    "fn looksLikeBareLocalHtmlPath(url: []const u8) bool",
)


@dataclass(frozen=True)
class BrowseTargetInfo:
    scheme: str
    scope: str
    host: str
    port: str


def browse_target_scheme(url: str) -> str:
    scheme_end = url.find("://")
    if scheme_end <= 0:
        return "unknown"
    return url[:scheme_end]


def browse_target_authority(url: str) -> str | None:
    scheme_end = url.find("://")
    if scheme_end < 0:
        return None
    authority_start = scheme_end + 3
    if authority_start >= len(url):
        return None
    tail = url[authority_start:]
    match = re.search(r"[/?#]", tail)
    authority = tail[: match.start()] if match else tail
    return authority or None


def browse_target_implicit_authority(url: str) -> str | None:
    if "://" in url:
        return None
    match = re.search(r"[/\\?#]", url)
    authority = url[: match.start()] if match else url
    return authority or None


def browse_target_local_path_candidate(url: str) -> str:
    match = re.search(r"[?#]", url)
    return url[: match.start()] if match else url


def looks_like_bare_local_html_path(url: str) -> bool:
    if "://" in url:
        return False
    candidate = browse_target_local_path_candidate(url)
    if not candidate or "/" in candidate or "\\" in candidate:
        return False
    lowered = candidate.lower()
    return lowered.endswith(".html") or lowered.endswith(".htm") or lowered.endswith(".xhtml")


def browse_target_about(url: str) -> BrowseTargetInfo | None:
    prefix = "about:"
    if not url.lower().startswith(prefix):
        return None
    route = url[len(prefix) :]
    match = re.search(r"[?#]", route)
    page = route[: match.start()] if match else route
    return BrowseTargetInfo("about", "internal", page or "(none)", "(none)")


def browse_target_host_port_authority(authority: str) -> str:
    at_index = authority.rfind("@")
    if at_index < 0 or at_index + 1 >= len(authority):
        return authority
    return authority[at_index + 1 :]


def browse_target_host(authority: str) -> str:
    host_port_authority = browse_target_host_port_authority(authority)
    if not host_port_authority:
        return host_port_authority
    if host_port_authority.startswith("["):
        closing = host_port_authority.find("]")
        return host_port_authority if closing < 0 else host_port_authority[: closing + 1]
    port_separator = host_port_authority.rfind(":")
    return host_port_authority if port_separator < 0 else host_port_authority[:port_separator]


def browse_target_port(authority: str) -> str:
    host_port_authority = browse_target_host_port_authority(authority)
    if not host_port_authority:
        return "(none)"
    if host_port_authority.startswith("["):
        closing = host_port_authority.find("]")
        if closing < 0:
            return "(default)"
        if closing + 1 >= len(host_port_authority) or host_port_authority[closing + 1] != ":":
            return "(default)"
        port = host_port_authority[closing + 2 :]
        return port or "(default)"
    port_separator = host_port_authority.rfind(":")
    if port_separator < 0:
        return "(default)"
    port = host_port_authority[port_separator + 1 :]
    return port or "(default)"


def is_loopback_ipv4_host(host: str) -> bool:
    parts = host.split(".")
    if len(parts) != 4:
        return False
    try:
        octets = [int(part, 10) for part in parts]
    except ValueError:
        return False
    if any(octet < 0 or octet > 255 for octet in octets):
        return False
    return octets[0] == 127


def normalize_browse_host_for_classification(host: str) -> str:
    if len(host) <= 1 or not host.endswith(".") or host.startswith("["):
        return host
    return host[:-1]


def is_loopback_browse_host(host: str) -> bool:
    if not host:
        return False
    normalized = normalize_browse_host_for_classification(host)
    lowered = normalized.lower()
    return (
        lowered == "localhost"
        or lowered.endswith(".localhost")
        or is_loopback_ipv4_host(normalized)
        or normalized == "0.0.0.0"
        or lowered == "[::1]"
        or lowered == "[0:0:0:0:0:0:0:1]"
    )


def looks_like_implicit_remote_host(host: str) -> bool:
    if not host:
        return False
    if host.startswith("["):
        return True
    labels = host.split(".")
    if len(labels) < 2:
        return False
    for label in labels:
        if not label or any(not (ch.isalnum() or ch == "-") for ch in label):
            return False
    suffix = labels[-1]
    return len(suffix) >= 2 and suffix.isalpha()


def browse_target_internal(url: str, scheme: str) -> BrowseTargetInfo | None:
    if scheme.lower() != "browser":
        return None
    authority = browse_target_authority(url)
    if authority is None:
        return BrowseTargetInfo("browser", "internal", "(none)", "(none)")
    host = browse_target_host(authority)
    return BrowseTargetInfo("browser", "internal", host or "(none)", "(none)")


def browse_target_implicit_loopback(url: str) -> BrowseTargetInfo | None:
    authority = browse_target_implicit_authority(url)
    if authority is None:
        return None
    host = browse_target_host(authority)
    if not is_loopback_browse_host(host):
        return None
    return BrowseTargetInfo("implicit_http", "loopback", host, browse_target_port(authority))


def browse_target_implicit_remote(url: str) -> BrowseTargetInfo | None:
    authority = browse_target_implicit_authority(url)
    if authority is None:
        return None
    host = browse_target_host(authority)
    if is_loopback_browse_host(host) or not looks_like_implicit_remote_host(host):
        return None
    return BrowseTargetInfo("implicit_http", "remote", host, browse_target_port(authority))


def browse_target_info(url: str) -> BrowseTargetInfo:
    scheme = browse_target_scheme(url)
    if scheme.lower() == "file":
        return BrowseTargetInfo("file", "file", "(none)", "(none)")

    internal = browse_target_internal(url, scheme)
    if internal is not None:
        return internal

    about = browse_target_about(url)
    if about is not None:
        return about

    authority = browse_target_authority(url)
    if authority is None:
        implicit_loopback = browse_target_implicit_loopback(url)
        if implicit_loopback is not None:
            return implicit_loopback
        if looks_like_bare_local_html_path(url):
            return BrowseTargetInfo("path", "local_path", "(none)", "(none)")
        implicit_remote = browse_target_implicit_remote(url)
        if implicit_remote is not None:
            return implicit_remote
        local_path_candidate = browse_target_local_path_candidate(url)
        lowered = local_path_candidate.lower()
        if "://" not in local_path_candidate and (
            "/" in local_path_candidate
            or "\\" in local_path_candidate
            or lowered.endswith(".html")
            or lowered.endswith(".htm")
            or lowered.endswith(".xhtml")
        ):
            return BrowseTargetInfo("path", "local_path", "(none)", "(none)")
        return BrowseTargetInfo(scheme, "unknown", "(none)", "(none)")

    host = browse_target_host(authority)
    port = browse_target_port(authority)
    if is_loopback_browse_host(host):
        return BrowseTargetInfo(scheme, "loopback", host, port)
    return BrowseTargetInfo(scheme, "remote", host or "(none)", port)


def check_source_contract(repo_root: pathlib.Path) -> list[str]:
    source_path = repo_root / "src" / "main.zig"
    if not source_path.is_file():
        return [f"missing source file: {source_path}"]
    text = source_path.read_text(encoding="utf-8")
    failures: list[str] = []
    for snippet in REQUIRED_HELPERS:
        if snippet not in text:
            failures.append(f"missing helper signature: {snippet}")
    for snippet, minimum in REQUIRED_FIELD_COUNTS.items():
        count = text.count(snippet)
        if count < minimum:
            failures.append(f"expected at least {minimum} occurrences of {snippet!r}, found {count}")
    return failures


def run_self_test() -> list[str]:
    cases = (
        ("browser://settings/homepage", BrowseTargetInfo("browser", "internal", "settings", "(none)")),
        ("about:blank#popup-probe", BrowseTargetInfo("about", "internal", "blank", "(none)")),
        ("attached-page.html?case=1", BrowseTargetInfo("path", "local_path", "(none)", "(none)")),
        ("localhost:8123/attached-page.html", BrowseTargetInfo("implicit_http", "loopback", "localhost", "8123")),
        ("https://preview.localhost.:9443/index.html", BrowseTargetInfo("https", "loopback", "preview.localhost.", "9443")),
        ("example.com/attached-page.html", BrowseTargetInfo("implicit_http", "remote", "example.com", "(default)")),
        ("file:///tmp/attached-page.html", BrowseTargetInfo("file", "file", "(none)", "(none)")),
    )
    failures: list[str] = []
    for url, expected in cases:
        actual = browse_target_info(url)
        if actual != expected:
            failures.append(f"{url!r}: expected {expected}, found {actual}")
    return failures


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("targets", nargs="*", help="sample browse targets to classify")
    parser.add_argument("--repo-root", default=".", help="repository root containing src/main.zig")
    parser.add_argument("--json", action="store_true", dest="json_output", help="emit classifications as JSON")
    parser.add_argument("--skip-source-check", action="store_true", help="skip the src/main.zig diagnostics-surface check")
    parser.add_argument("--self-test", action="store_true", help="run embedded classifier tests")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    failures: list[str] = []

    if args.self_test:
        failures.extend(run_self_test())

    if not args.skip_source_check:
        failures.extend(check_source_contract(pathlib.Path(args.repo_root).resolve()))

    if args.targets:
        rows = [{"target": target, **asdict(browse_target_info(target))} for target in args.targets]
        if args.json_output:
            print(json.dumps(rows, indent=2, sort_keys=True))
        else:
            for row in rows:
                print(
                    "target={target} scheme={scheme} scope={scope} host={host} port={port}".format(
                        **row
                    )
                )

    if failures:
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        return 1

    if args.self_test:
        print("BROWSE_TARGET_DIAGNOSTICS_SELF_TEST=pass")
    if not args.targets:
        print("BROWSE_TARGET_DIAGNOSTICS_SURFACE=pass")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
