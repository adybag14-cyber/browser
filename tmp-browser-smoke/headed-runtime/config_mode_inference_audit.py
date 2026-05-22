import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "src/Config.zig",
        "snippet": "fn looksLikeImplicitRemoteHost(host: []const u8) bool {",
        "purpose": "The mode inference keeps the helper that recognizes scheme-less remote hosts before treating HTML targets as local browse inputs.",
    },
    {
        "path": "src/Config.zig",
        "snippet": "return !looksLikeImplicitRemoteHost(host);",
        "purpose": "The local browse inference still rejects scheme-less remote HTML targets while keeping genuine local and loopback targets on browse.",
    },
    {
        "path": "src/Config.zig",
        "snippet": 'test "infer mode keeps fetch for scheme-less remote html target without browse hint" {',
        "purpose": "The branch keeps a regression test for scheme-less remote HTML targets staying on fetch by default.",
    },
    {
        "path": "src/Config.zig",
        "snippet": 'test "infer mode keeps fetch for scheme-less remote xhtml target without browse hint" {',
        "purpose": "The branch keeps a regression test for scheme-less remote XHTML targets staying on fetch by default.",
    },
    {
        "path": "src/Config.zig",
        "snippet": 'test "infer mode keeps browse for scheme-less loopback html target" {',
        "purpose": "The branch keeps a regression test for localhost HTML targets staying on browse.",
    },
    {
        "path": "src/Config.zig",
        "snippet": 'test "infer mode keeps browse for scheme-less ipv4 loopback html target" {',
        "purpose": "The branch keeps a regression test for 127.0.0.1 HTML targets staying on browse.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_repo_root_error_audit(root: str | None, message: str) -> dict[str, object]:
    repo_root = str(Path.cwd()) if root is None else str(Path(root).expanduser())
    return {
        "repo_root": repo_root,
        "expectation_count": len(EXPECTATIONS),
        "missing_count": None,
        "results": [],
        "error_type": "repo_root_not_found",
        "error": message,
    }


def build_mode_inference_audit(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    missing_count = 0

    for expectation in EXPECTATIONS:
        full_path = repo_root / expectation["path"]
        if not full_path.is_file():
            exists = False
        else:
            exists = expectation["snippet"] in full_path.read_text(encoding="utf-8", errors="ignore")

        if not exists:
            missing_count += 1

        results.append(
            {
                "path": expectation["path"],
                "purpose": expectation["purpose"],
                "exists": exists,
                "snippet": expectation["snippet"],
            }
        )

    return {
        "repo_root": str(repo_root),
        "expectation_count": len(results),
        "missing_count": missing_count,
        "results": results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Config Mode Inference Audit",
        "",
        f"Repo root: {audit['repo_root']}",
    ]

    if audit.get("error_type"):
        lines.extend(
            [
                f"Error: {audit['error']}",
                "",
            ]
        )
        return "\n".join(lines).rstrip() + "\n"

    lines.extend(
        [
            f"Expectations checked: {audit['expectation_count']}",
            f"Missing expectations: {audit['missing_count']}",
            "",
        ]
    )

    for result in audit["results"]:
        status = "PASS" if result["exists"] else "FAIL"
        lines.append(f"[{status}] {result['path']}")
        lines.append(f"  {result['purpose']}")
        if not result["exists"]:
            lines.append(f"  Missing snippet: {result['snippet']}")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit Config.zig mode inference coverage for local and scheme-less remote HTML targets."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    try:
        repo_root = resolve_repo_root(args.repo_root)
        audit = build_mode_inference_audit(repo_root)
    except FileNotFoundError as exc:
        audit = build_repo_root_error_audit(args.repo_root, str(exc))

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    if audit.get("error_type"):
        return 1
    return 0 if not audit.get("missing_count") else 1


if __name__ == "__main__":
    raise SystemExit(main())