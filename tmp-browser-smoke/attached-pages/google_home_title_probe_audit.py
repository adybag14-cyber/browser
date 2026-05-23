#!/usr/bin/env python3
"""Audit the Google home title probe diagnostics surface used for headed issue #3."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "early_event_arrays",
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": (
            "<script>window.__lpEarlyEvents=[];window.__lpPostMessages=[];"
            "window.__lpMessageEvents=[];window.__lpListenerAdds=[];"
            "window.__lpAcCalls=[];"
        ),
        "why": "The probe should keep the early event capture arrays available before Google scripts run.",
    },
    {
        "label": "fixed_probe_badge",
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": (
            "badge.id = 'lp-probe-status';\n"
            "  badge.style.position = 'fixed';\n"
            "  badge.style.top = '8px';\n"
            "  badge.style.right = '8px';"
        ),
        "why": "The headed probe needs a visible status badge during manual localhost and Google validation.",
    },
    {
        "label": "title_summary_fields",
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": (
            "var summary = lastMark + '|A=' + describeElement(document.activeElement) + "
            "'|Q=' + describeElement(currentQ) + '|V=' + value + '|S=' + selection + '|E=' + early;\n"
            "    document.title = summary;\n"
            "    badge.textContent = summary;"
        ),
        "why": "The document title should keep the active element, query node, value, selection, and last event summary together.",
    },
    {
        "label": "query_input_focus_and_submit_markers",
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": (
            "q.addEventListener('focus', function(){ mark('FOCUSED'); });\n"
            "    q.addEventListener('input', function(){ mark('TYPED:' + q.value); });\n"
            "    q.addEventListener('beforeinput', function(e){\n"
            "      mark('BEFOREINPUT:' + (e.data || '') + ':' + q.value);\n"
            "    });\n"
            "    q.addEventListener('keypress', function(e){\n"
            "      mark('KEYPRESS:' + (e.key || '') + ':' + q.value);\n"
            "    });"
        ),
        "why": "The query input should keep explicit focus, beforeinput, keypress, and typed-value markers.",
    },
    {
        "label": "query_input_keydown_and_submit",
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": (
            "if (e.key === 'Enter' || e.keyCode === 13 || e.which === 13) {\n"
            "        mark('KEYDOWN:' + q.value + ':' + e.keyCode + ':' + e.which);\n"
            "      } else if ((e.key || '').length === 1) {\n"
            "        mark('KEYDOWN:' + e.key + ':' + q.value);\n"
            "      }\n"
            "    });\n"
            "    if (q.form && !q.form.__lpProbeBound) {\n"
            "      q.form.__lpProbeBound = true;\n"
            "      q.form.addEventListener('submit', function(e){\n"
            "        e.preventDefault();\n"
            "        mark('SUBMIT:' + q.value);\n"
            "      });"
        ),
        "why": "The probe should keep explicit Enter handling plus a visible submit marker for issue #3.",
    },
    {
        "label": "document_capture_diagnostics",
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": (
            "document.addEventListener('keydown', function(e){\n"
            "    if (e.target === currentQ && (e.key || '').length === 1) {\n"
            "      return;\n"
            "    }\n"
            "    if (e.key === 'Enter' || e.keyCode === 13 || e.which === 13) {\n"
            "      mark('DOC-KD:' + describeElement(e.target) + ':' + (e.key || '') + ':' + e.keyCode + ':' + e.which);\n"
            "    } else if ((e.key || '').length === 1) {\n"
            "      mark('DOC-KD:' + describeElement(e.target) + ':' + e.key);\n"
            "    }\n"
            "  }, true);\n"
            "\n"
            "  document.addEventListener('keypress', function(e){"
        ),
        "why": "Document-level capture listeners should stay in place so headed traces show where events land when the query field stops committing.",
    },
    {
        "label": "focus_selection_and_rebind_loop",
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": (
            "document.addEventListener('selectionchange', function(){\n"
            "    mark('SEL:' + describeElement(document.activeElement));\n"
            "  }, true);\n"
            "\n"
            "  document.addEventListener('focusin', function(e){\n"
            "    mark('FOCUSIN:' + describeElement(e.target));\n"
            "  }, true);\n"
            "\n"
            "  document.addEventListener('focusout', function(e){\n"
            "    mark('FOCUSOUT:' + describeElement(e.target));\n"
            "  }, true);\n"
            "\n"
            "  function syncQueryInput() {\n"
            "    var next = (document.forms.f && document.forms.f.q) || document.querySelector('[name=\"q\"]');"
        ),
        "why": "Selection, focus transitions, and query rebinding are part of the live issue #3 probe surface.",
    },
    {
        "label": "steady_sync_interval",
        "path": "src/browser/tests/page/google_home_title_probe.html",
        "snippet": (
            "  syncQueryInput();\n"
            "  if (!currentQ) {\n"
            "    return;\n"
            "  }\n"
            "  window.setInterval(syncQueryInput, 250);"
        ),
        "why": "The probe should continue resynchronizing against Google's late query field rewrites.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether the Google home title probe still exposes the key "
            "diagnostics surface used to narrow headed issue #3."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=default_repo_root,
        help="Repository root to inspect. Defaults to the current script's repo.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the full audit summary as JSON.",
    )
    return parser.parse_args()


def audit(repo_root: Path) -> dict[str, object]:
    checks: list[dict[str, object]] = []
    missing = 0

    for expectation in EXPECTATIONS:
        target = repo_root / expectation["path"]
        exists = target.is_file()
        if exists:
            text = target.read_text(encoding="utf-8")
            present = expectation["snippet"] in text
        else:
            present = False
        if not present:
            missing += 1
        checks.append({**expectation, "exists": exists, "present": present})

    return {
        "repo_root": str(repo_root),
        "expectation_count": len(EXPECTATIONS),
        "missing_count": missing,
        "ok": missing == 0,
        "checks": checks,
    }


def main() -> int:
    args = parse_args()
    result = audit(args.repo_root.resolve())

    if args.json:
        json.dump(result, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        status = "PASS" if result["ok"] else "FAIL"
        print(f"[{status}] google home title probe audit")
        print(f"Repo root: {result['repo_root']}")
        print(
            f"Matched {result['expectation_count'] - result['missing_count']} of "
            f"{result['expectation_count']} expectations."
        )
        for check in result["checks"]:
            marker = "ok" if check["present"] else "missing"
            print(f"- {marker}: {check['label']} ({check['path']})")
            if not check["present"]:
                print(f"  Why: {check['why']}")

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())