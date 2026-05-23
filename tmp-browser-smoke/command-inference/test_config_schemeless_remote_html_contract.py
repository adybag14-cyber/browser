import importlib.util
import os
import pathlib
import tempfile
import unittest


CHECKER_RELATIVE_PATH = pathlib.Path(
    "tmp-browser-smoke/command-inference/check_config_schemeless_remote_html_contract.py"
)
CONFIG_RELATIVE_PATH = pathlib.Path("src/Config.zig")


FIXTURE_HELPER = """\
import re

UNSAFE_MARKERS = (
    'std.ascii.eqlIgnoreCase(candidate[candidate.len - 6 ..], ".xhtml")',
    'std.ascii.eqlIgnoreCase(candidate[candidate.len - 5 ..], ".html")',
    'std.ascii.eqlIgnoreCase(candidate[candidate.len - 4 ..], ".htm")',
)

SAFETY_MARKERS = (
    "authority",
    "loopback",
    "localhost",
    ".localhost",
    "127.",
    "0.0.0.0",
    "[::1]",
    "[0:0:0:0:0:0:0:1]",
    "remote",
)

def extract_function(source: str, name: str) -> str:
    match = re.search(rf"fn {re.escape(name)}\\([^)]*\\) [^{{]*\\{{", source)
    if not match:
        raise ValueError(f"missing function: {name}")
    start = match.start()
    brace_index = source.find("{", match.end() - 1)
    depth = 0
    for index in range(brace_index, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[start:index + 1]
    raise ValueError(f"unterminated function: {name}")

def detect_blanket_html_browse(function_text: str) -> bool:
    if "trimLocalBrowseTarget(token)" not in function_text:
        return False
    if not all(marker in function_text for marker in UNSAFE_MARKERS):
        return False
    return not any(marker in function_text for marker in SAFETY_MARKERS)

def evaluate_contract(source: str):
    infer_local = extract_function(source, "inferLocalBrowseTarget")
    if "file://" not in infer_local:
        return False, "inferLocalBrowseTarget no longer recognizes explicit file:// targets"
    if 'std.mem.indexOf(u8, token, "://") != null' not in infer_local:
        return False, "inferLocalBrowseTarget no longer short-circuits fully qualified URLs before local HTML inference"
    if detect_blanket_html_browse(infer_local):
        return False, (
            "inferLocalBrowseTarget still blanket-matches scheme-less .html/.htm/.xhtml "
            "targets without a loopback-or-authority check"
        )
    return True, "contract looks guarded against scheme-less remote HTML auto-browse"
"""


FIXTURE_CONFIG = """\
fn trimLocalBrowseTarget(token: []const u8) []const u8 {
    return token;
}

fn hasLocalBrowseHtmlSuffix(candidate: []const u8) bool {
    return (candidate.len >= 6 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 6 ..], ".xhtml")) or
        (candidate.len >= 5 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 5 ..], ".html")) or
        (candidate.len >= 4 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 4 ..], ".htm"));
}

fn inferLocalBrowseImplicitAuthority(token: []const u8) ?[]const u8 {
    const authority_end = std.mem.indexOfAny(u8, token, "/\\") orelse return null;
    if (authority_end == 0) {
        return null;
    }
    return token[0..authority_end];
}

fn inferLocalBrowseAuthorityIsLoopback(authority: []const u8) bool {
    if (std.ascii.eqlIgnoreCase(authority, "localhost")) return true;
    if (std.ascii.endsWithIgnoreCase(authority, ".localhost")) return true;
    if (std.ascii.startsWithIgnoreCase(authority, "127.")) return true;
    if (std.mem.eql(u8, authority, "0.0.0.0")) return true;
    if (std.ascii.eqlIgnoreCase(authority, "[::1]")) return true;
    if (std.ascii.eqlIgnoreCase(authority, "[0:0:0:0:0:0:0:1]")) return true;
    return false;
}

fn inferLocalBrowseTargetAuthorityLooksRemote(authority: []const u8) bool {
    return std.mem.indexOfScalar(u8, authority, '.') != null and !inferLocalBrowseAuthorityIsLoopback(authority);
}

fn inferLocalBrowseTarget(token: []const u8) bool {
    if (std.ascii.startsWithIgnoreCase(token, "file://")) {
        return true;
    }
    if (std.mem.indexOf(u8, token, "://") != null) {
        return false;
    }
    const candidate = trimLocalBrowseTarget(token);
    if (!hasLocalBrowseHtmlSuffix(candidate)) {
        return false;
    }
    if (inferLocalBrowseImplicitAuthority(candidate)) |authority| {
        if (inferLocalBrowseTargetAuthorityLooksRemote(authority)) {
            return false;
        }
    }
    return true;
}

test "infer mode keeps fetch for scheme-less remote html target without browse hint" {}
test "infer mode keeps fetch for scheme-less remote xhtml target without browse hint" {}
test "infer mode keeps browse for scheme-less loopback html target" {}
test "infer mode keeps browse for scheme-less ipv4 loopback html target" {}
"""


def load_checker_module(repo_root: pathlib.Path):
    checker_path = repo_root / CHECKER_RELATIVE_PATH
    spec = importlib.util.spec_from_file_location(
        "check_config_schemeless_remote_html_contract", checker_path
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-config-contract-"))
    helper_path = root / CHECKER_RELATIVE_PATH
    helper_path.parent.mkdir(parents=True, exist_ok=True)
    helper_path.write_text(FIXTURE_HELPER, encoding="utf-8")
    config_path = root / CONFIG_RELATIVE_PATH
    config_path.parent.mkdir(parents=True, exist_ok=True)
    config_path.write_text(FIXTURE_CONFIG, encoding="utf-8")
    return root


VULNERABLE_CONFIG = """\
fn trimLocalBrowseTarget(token: []const u8) []const u8 {
    return token;
}

fn inferLocalBrowseTarget(token: []const u8) bool {
    if (std.ascii.startsWithIgnoreCase(token, "file://")) {
        return true;
    }
    if (std.mem.indexOf(u8, token, "://") != null) {
        return false;
    }
    const candidate = trimLocalBrowseTarget(token);
    if (candidate.len >= 6 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 6 ..], ".xhtml")) {
        return true;
    }
    if (candidate.len >= 5 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 5 ..], ".html")) {
        return true;
    }
    if (candidate.len >= 4 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 4 ..], ".htm")) {
        return true;
    }
    return false;
}
"""


class ConfigSchemelessRemoteHtmlContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.checker = load_checker_module(cls.repo_root)
        cls.config_source = (cls.repo_root / CONFIG_RELATIVE_PATH).read_text(encoding="utf-8")

    def test_vulnerable_sample_fails_contract(self) -> None:
        ok, reason = self.checker.evaluate_contract(VULNERABLE_CONFIG)
        self.assertFalse(ok)
        self.assertIn("blanket-matches scheme-less .html/.htm/.xhtml", reason)

    def test_live_config_passes_contract(self) -> None:
        ok, reason = self.checker.evaluate_contract(self.config_source)
        self.assertTrue(ok, reason)
        self.assertIn("guarded against scheme-less remote HTML auto-browse", reason)

    def test_live_config_keeps_authority_and_loopback_helpers(self) -> None:
        for marker in (
            "fn hasLocalBrowseHtmlSuffix(candidate: []const u8) bool {",
            "fn inferLocalBrowseImplicitAuthority(token: []const u8) ?[]const u8 {",
            "fn inferLocalBrowseTargetAuthorityLooksRemote(authority: []const u8) bool {",
            "localhost",
            ".localhost",
            "127.",
            "0.0.0.0",
            "[::1]",
            "[0:0:0:0:0:0:0:1]",
        ):
            self.assertIn(marker, self.config_source)

    def test_live_config_keeps_scheme_less_remote_and_loopback_regressions(self) -> None:
        for marker in (
            'test "infer mode keeps fetch for scheme-less remote html target without browse hint" {',
            'test "infer mode keeps fetch for scheme-less remote xhtml target without browse hint" {',
            'test "infer mode keeps browse for scheme-less loopback html target" {',
            'test "infer mode keeps browse for scheme-less ipv4 loopback html target" {',
        ):
            self.assertIn(marker, self.config_source)


if __name__ == "__main__":
    unittest.main()
