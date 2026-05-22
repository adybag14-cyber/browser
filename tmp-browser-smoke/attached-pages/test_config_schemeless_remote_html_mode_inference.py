import argparse
import json
import re
import unittest


RUN_BROWSE = "browse"
RUN_FETCH = "fetch"
RUN_SERVE = "serve"


def trim_local_browse_target(token: str) -> str:
    query_index = token.find("?")
    fragment_index = token.find("#")
    end = len(token)
    if query_index != -1:
        end = min(end, query_index)
    if fragment_index != -1:
        end = min(end, fragment_index)
    return token[:end]


def has_html_suffix(token: str) -> bool:
    lower = token.lower()
    return lower.endswith(".xhtml") or lower.endswith(".html") or lower.endswith(".htm")


def strip_userinfo(authority: str) -> str:
    if "@" not in authority:
        return authority
    return authority.rsplit("@", 1)[1]


def split_host_port(authority: str) -> tuple[str, str | None]:
    bare = strip_userinfo(authority)
    if bare.startswith("["):
        end = bare.find("]")
        if end == -1:
            return bare, None
        host = bare[: end + 1]
        if end + 1 < len(bare) and bare[end + 1] == ":":
            return host, bare[end + 2 :]
        return host, None
    if bare.count(":") == 1:
        host, port = bare.split(":", 1)
        return host, port or None
    return bare, None


def is_loopback_host(host: str) -> bool:
    lowered = host.lower()
    if lowered == "localhost" or lowered.endswith(".localhost"):
        return True
    if lowered == "0.0.0.0":
        return True
    if lowered == "[::1]" or lowered == "[0:0:0:0:0:0:0:1]":
        return True
    if re.fullmatch(r"127(?:\.\d{1,3}){3}", lowered):
        return True
    return False


def is_windows_drive_path(candidate: str) -> bool:
    return len(candidate) >= 3 and candidate[1] == ":" and candidate[2] in ("\\", "/") and candidate[0].isalpha()


def extract_implicit_authority(candidate: str) -> str | None:
    if "/" not in candidate and "\\" not in candidate:
        return None
    parts = re.split(r"[\\/]", candidate, maxsplit=1)
    authority = parts[0]
    if not authority:
        return None
    return authority


def is_implicit_remote_html_target(candidate: str) -> bool:
    if not has_html_suffix(candidate):
        return False
    if is_windows_drive_path(candidate):
        return False
    authority = extract_implicit_authority(candidate)
    if authority is None:
        return False
    host, _port = split_host_port(authority)
    if not host:
        return False
    if is_loopback_host(host):
        return False
    if "." in host and not host.startswith(".") and not host.endswith("."):
        return True
    return False


def infer_local_browse_target(token: str) -> bool:
    if token.lower().startswith("file://"):
        return True
    if "://" in token:
        return False
    candidate = trim_local_browse_target(token)
    if not has_html_suffix(candidate):
        return False
    if is_implicit_remote_html_target(candidate):
        return False
    return True


def infer_mode(tokens: list[str]) -> str:
    browse_hint = False
    browser_mode = "headless"
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if token in {"--screenshot_bmp", "--screenshot_png"}:
            return RUN_BROWSE

        if token == "--browser_mode":
            browse_hint = True
            if index + 1 < len(tokens):
                browser_mode = tokens[index + 1]
                index += 2
            else:
                index += 1
            continue

        if token == "--headed":
            browse_hint = True
            browser_mode = "headed"
            index += 1
            continue

        if token == "--headless":
            browse_hint = True
            browser_mode = "headless"
            index += 1
            continue

        if token in {
            "--window_width",
            "--window_height",
            "--http_proxy",
            "--proxy_bearer_token",
            "--http_max_concurrent",
            "--http_max_host_open",
            "--http_timeout",
            "--http_connect_timeout",
            "--http_max_response_size",
            "--log_level",
            "--log_format",
            "--log_filter_scopes",
            "--user_agent_suffix",
            "--profile_dir",
        }:
            if token in {"--window_width", "--window_height"}:
                browse_hint = True
            index += 2 if index + 1 < len(tokens) else 1
            continue

        if token == "--obey_robots":
            index += 1
            continue

        if token in {"browse", "fetch", "serve", "mcp", "help", "--help", "-h", "--version"}:
            mapping = {
                "browse": RUN_BROWSE,
                "fetch": RUN_FETCH,
                "serve": RUN_SERVE,
                "mcp": "mcp",
                "help": "help",
                "--help": "help",
                "-h": "help",
                "--version": "version",
            }
            return mapping[token]

        if infer_local_browse_target(token):
            return RUN_BROWSE

        if ":" not in token and "/" not in token:
            return RUN_SERVE
        if browse_hint or browser_mode == "headed":
            return RUN_BROWSE
        return RUN_FETCH

    return "help"


CASES = (
    {
        "name": "scheme_less_remote_html_keeps_fetch",
        "tokens": ["example.com/attached-page.html"],
        "expected_mode": RUN_FETCH,
        "reason": "Implicit remote HTML targets should keep the fetch fallback when there is no browse hint.",
    },
    {
        "name": "scheme_less_remote_xhtml_keeps_fetch",
        "tokens": ["example.com/attached-page.xhtml#focus-probe"],
        "expected_mode": RUN_FETCH,
        "reason": "Implicit remote XHTML targets should keep the fetch fallback when there is no browse hint.",
    },
    {
        "name": "loopback_html_keeps_browse",
        "tokens": ["localhost:8123/attached-page.html"],
        "expected_mode": RUN_BROWSE,
        "reason": "Loopback attached pages should still infer browse for local headed validation.",
    },
    {
        "name": "loopback_ipv4_html_keeps_browse",
        "tokens": ["127.0.0.1:8123/attached-page.html?case=1"],
        "expected_mode": RUN_BROWSE,
        "reason": "IPv4 loopback attached pages should still infer browse for local headed validation.",
    },
    {
        "name": "bare_local_html_keeps_browse",
        "tokens": ["attached-page.html"],
        "expected_mode": RUN_BROWSE,
        "reason": "Bare local attached pages should stay on browse.",
    },
    {
        "name": "windows_local_html_keeps_browse",
        "tokens": ["user_files\\attached-page.html"],
        "expected_mode": RUN_BROWSE,
        "reason": "Windows local attached pages should stay on browse.",
    },
    {
        "name": "explicit_remote_html_url_keeps_fetch",
        "tokens": ["https://example.com/attached-page.html"],
        "expected_mode": RUN_FETCH,
        "reason": "Explicit remote URLs should keep fetch without a browse hint.",
    },
    {
        "name": "headed_hint_overrides_remote_html_to_browse",
        "tokens": ["--headed", "example.com/attached-page.html"],
        "expected_mode": RUN_BROWSE,
        "reason": "An explicit headed hint should still force browse for remote HTML targets.",
    },
)


def build_audit() -> dict:
    results = []
    for case in CASES:
        actual = infer_mode(list(case["tokens"]))
        results.append(
            {
                "name": case["name"],
                "tokens": case["tokens"],
                "expected_mode": case["expected_mode"],
                "actual_mode": actual,
                "matches": actual == case["expected_mode"],
                "reason": case["reason"],
            }
        )
    return {
        "case_count": len(results),
        "mismatch_count": sum(0 if entry["matches"] else 1 for entry in results),
        "results": results,
    }


class ConfigSchemelessRemoteHtmlModeInferenceTests(unittest.TestCase):
    def test_trim_local_browse_target(self) -> None:
        self.assertEqual("attached-page.html", trim_local_browse_target("attached-page.html?case=1#focus"))

    def test_scheme_less_remote_html_keeps_fetch(self) -> None:
        self.assertEqual(RUN_FETCH, infer_mode(["example.com/attached-page.html"]))

    def test_scheme_less_remote_xhtml_keeps_fetch(self) -> None:
        self.assertEqual(RUN_FETCH, infer_mode(["example.com/attached-page.xhtml#focus-probe"]))

    def test_loopback_html_keeps_browse(self) -> None:
        self.assertEqual(RUN_BROWSE, infer_mode(["localhost:8123/attached-page.html"]))

    def test_loopback_ipv4_html_keeps_browse(self) -> None:
        self.assertEqual(RUN_BROWSE, infer_mode(["127.0.0.1:8123/attached-page.html"]))

    def test_bare_local_html_keeps_browse(self) -> None:
        self.assertEqual(RUN_BROWSE, infer_mode(["attached-page.html"]))

    def test_windows_drive_path_keeps_browse(self) -> None:
        self.assertEqual(RUN_BROWSE, infer_mode([r"C:\fixtures\attached-page.html"]))

    def test_explicit_remote_html_url_keeps_fetch(self) -> None:
        self.assertEqual(RUN_FETCH, infer_mode(["https://example.com/attached-page.html"]))

    def test_headed_hint_overrides_remote_html_to_browse(self) -> None:
        self.assertEqual(RUN_BROWSE, infer_mode(["--headed", "example.com/attached-page.html"]))

    def test_audit_has_no_mismatches(self) -> None:
        self.assertEqual(0, build_audit()["mismatch_count"])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="print the audit as JSON")
    parser.add_argument("--self-test", action="store_true", help="run the embedded unittest suite")
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            ConfigSchemelessRemoteHtmlModeInferenceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    audit = build_audit()
    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(f"CONFIG_SCHEMELESS_REMOTE_HTML_MODE_CASES={audit['case_count']}")
        print(f"CONFIG_SCHEMELESS_REMOTE_HTML_MODE_MISMATCHES={audit['mismatch_count']}")
        for entry in audit["results"]:
            print(
                "CONFIG_SCHEMELESS_REMOTE_HTML_MODE_CASE="
                + json.dumps(
                    {
                        "name": entry["name"],
                        "expected_mode": entry["expected_mode"],
                        "actual_mode": entry["actual_mode"],
                        "matches": entry["matches"],
                    },
                    sort_keys=True,
                )
            )
    return 0 if audit["mismatch_count"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
