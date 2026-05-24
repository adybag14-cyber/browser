#!/usr/bin/env python3

"""Report whether a GitHub issue is still practical for progress comments.

This helper is intentionally small and offline-friendly. It accepts issue
metadata exported from a GitHub API or connector response, detects the nested
`{"issue": {...}}` shape used by the Hermes connector, and flags threads that
are closed or have reached the known GitHub 2500-comment discussion cap.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import unittest


DEFAULT_COMMENT_CAP = 2500


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a GitHub issue still looks usable for progress "
            "comments, or whether a run should fall back to Memory updates."
        )
    )
    parser.add_argument(
        "--issue-json",
        default=None,
        help="Path to a JSON file containing issue metadata. Reads stdin when omitted.",
    )
    parser.add_argument(
        "--comment-cap",
        type=int,
        default=DEFAULT_COMMENT_CAP,
        help=f"Comment-count threshold that disables tracker comments (default: {DEFAULT_COMMENT_CAP}).",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit.",
    )
    return parser


def load_payload(issue_json: str | None) -> object:
    if issue_json:
        return json.loads(Path(issue_json).read_text(encoding="utf-8"))
    return json.load(sys.stdin)


def unwrap_issue(payload: object) -> dict[str, object]:
    if not isinstance(payload, dict):
        raise ValueError("issue payload must be a JSON object")
    issue = payload.get("issue")
    if isinstance(issue, dict):
        return issue
    return payload


def _coerce_int(value: object) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, str) and value.strip():
        try:
            return int(value.strip())
        except ValueError:
            return None
    return None


def assess_issue_state(issue: dict[str, object], *, comment_cap: int) -> dict[str, object]:
    issue_number = _coerce_int(issue.get("issue_number"))
    comments = _coerce_int(issue.get("comments"))
    state = str(issue.get("state") or "unknown")
    title = str(issue.get("title") or issue.get("display_title") or "unknown issue")
    url = str(issue.get("url") or issue.get("display_url") or "")

    reasons: list[str] = []
    if state.lower() != "open":
        reasons.append(f"issue state is {state}")
    if comments is None:
        reasons.append("comment count is unavailable")
    elif comments >= comment_cap:
        reasons.append(f"comment count {comments} reached the {comment_cap}-comment cap")

    commenting_available = not reasons
    status = "ready" if commenting_available else "fallback-to-memory"
    next_step = (
        "Issue comments still look available for progress updates."
        if commenting_available
        else "Skip required issue comments for this run and record progress in Memory instead."
    )
    return {
        "issue_number": issue_number,
        "title": title,
        "state": state,
        "comments": comments,
        "comment_cap": comment_cap,
        "commenting_available": commenting_available,
        "status": status,
        "reasons": reasons,
        "next_step": next_step,
        "url": url,
    }


def emit_text(result: dict[str, object]) -> None:
    status_label = "PASS" if result["commenting_available"] else "WARN"
    number = result["issue_number"] if result["issue_number"] is not None else "unknown"
    print(f"Issue #{number}: [{status_label}] {result['title']}")
    print(f"  state: {result['state']}")
    print(f"  comments: {result['comments'] if result['comments'] is not None else 'unknown'}")
    print(f"  status: {result['status']}")
    if result["url"]:
        print(f"  url: {result['url']}")
    if result["reasons"]:
        print("  reasons:")
        for reason in result["reasons"]:
            print(f"    - {reason}")
    print(f"  next: {result['next_step']}")


class IssueTrackerStateTests(unittest.TestCase):
    def test_nested_connector_payload_with_comment_cap_falls_back(self) -> None:
        payload = {
            "issue": {
                "issue_number": 3,
                "title": "Headed Windows tracker",
                "state": "open",
                "comments": 2500,
                "url": "https://example.invalid/issues/3",
            }
        }
        result = assess_issue_state(unwrap_issue(payload), comment_cap=2500)
        self.assertFalse(result["commenting_available"])
        self.assertEqual(result["status"], "fallback-to-memory")
        self.assertIn("2500-comment cap", result["reasons"][0])

    def test_open_issue_below_cap_stays_ready(self) -> None:
        payload = {"issue_number": "2", "title": "Master tracker", "state": "open", "comments": "42"}
        result = assess_issue_state(unwrap_issue(payload), comment_cap=2500)
        self.assertTrue(result["commenting_available"])
        self.assertEqual(result["status"], "ready")
        self.assertEqual(result["issue_number"], 2)
        self.assertEqual(result["comments"], 42)

    def test_closed_issue_falls_back_even_without_comment_cap(self) -> None:
        payload = {"issue_number": 9, "title": "Done", "state": "closed", "comments": 10}
        result = assess_issue_state(unwrap_issue(payload), comment_cap=2500)
        self.assertFalse(result["commenting_available"])
        self.assertIn("issue state is closed", result["reasons"])

    def test_invalid_payload_shape_raises(self) -> None:
        with self.assertRaises(ValueError):
            unwrap_issue(["not", "an", "object"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(IssueTrackerStateTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    payload = load_payload(args.issue_json)
    result = assess_issue_state(unwrap_issue(payload), comment_cap=args.comment_cap)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["commenting_available"] else 1


if __name__ == "__main__":
    sys.exit(main())
