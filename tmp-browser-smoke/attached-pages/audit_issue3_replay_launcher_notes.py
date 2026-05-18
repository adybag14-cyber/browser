import argparse
import json
from pathlib import Path

import attached_pages_launcher_reference_audit as launcher_audit


DEFAULT_REPLAY_NOTE_PATHS = (
    "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
    "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
    "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md",
)


def resolve_repo_root(repo_root: str | None = None) -> Path:
    if repo_root:
        resolved = Path(repo_root).expanduser().resolve()
    else:
        resolved = Path(__file__).resolve().parents[2]
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def issue3_replay_note_paths(repo_root: Path) -> list[Path]:
    return [repo_root / relative_path for relative_path in DEFAULT_REPLAY_NOTE_PATHS]


def build_issue3_replay_audit(repo_root: Path) -> dict[str, object]:
    selected_files = issue3_replay_note_paths(repo_root)
    audit = launcher_audit.build_reference_audit(selected_files=selected_files)
    audit["profile"] = "issue3-replay-launcher-notes"
    audit["selected_note_paths"] = list(DEFAULT_REPLAY_NOTE_PATHS)
    return audit


def render_issue3_replay_text_report(audit: dict[str, object]) -> str:
    header = [
        "Issue #3 Replay Launcher Note Audit",
        "",
        "Selected notes:",
    ]
    header.extend(f"- {path}" for path in audit["selected_note_paths"])
    header.extend(["", launcher_audit.render_text_report(audit).rstrip()])
    return "\n".join(header).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit the issue #3 replay-note family for raw attached-pages launcher drift."
    )
    parser.add_argument("--repo-root", help="Browser repo root. Defaults to the current helper's checkout.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of a text report.")
    parser.add_argument(
        "--allow-raw-launcher",
        action="store_true",
        help="Return success even when raw Python launcher references remain.",
    )
    parser.add_argument(
        "--require-wrapper-sidecar",
        action="store_true",
        help="Return failure unless at least one wrapper-backed sidecar audit reference is present.",
    )
    parser.add_argument(
        "--require-google-wrapper-sidecar",
        action="store_true",
        help="Return failure unless at least one Google-style wrapper-backed sidecar audit reference is present.",
    )
    args = parser.parse_args()

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_issue3_replay_audit(repo_root)
    failure_reasons = launcher_audit.collect_failure_reasons(
        audit,
        allow_raw_launcher=args.allow_raw_launcher,
        require_wrapper_sidecar=args.require_wrapper_sidecar,
        require_google_wrapper_sidecar=args.require_google_wrapper_sidecar,
    )

    if args.json:
        payload = dict(audit)
        payload["failure_reasons"] = failure_reasons
        print(json.dumps(payload, indent=2))
    else:
        print(render_issue3_replay_text_report(audit), end="")
        for reason in failure_reasons:
            print(f"FAIL: {reason}")

    return 1 if failure_reasons else 0


if __name__ == "__main__":
    raise SystemExit(main())
