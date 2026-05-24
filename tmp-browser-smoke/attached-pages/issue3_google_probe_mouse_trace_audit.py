#!/usr/bin/env python3
"""Audit the issue #3 Google probe mouse-trace contract."""

from __future__ import annotations

import argparse
import json
import sys
import tempfile
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "status_uses_mouse_trace_list",
        "snippet": "var mouseEvents = window.__lpMouseEvents || (window.__lpMouseEvents = []);",
        "why": "The probe should keep a stable mouse trace list even when earlier bootstrap code did not create one.",
    },
    {
        "label": "status_exposes_last_mouse_trace",
        "snippet": "var summary = lastMark + '|A=' + describeElement(document.activeElement) + '|Q=' + describeElement(currentQ) + '|V=' + value + '|S=' + selection + '|E=' + early + '|M=' + mouse;",
        "why": "The title summary should expose the newest mouse trace entry alongside the existing keyboard and value state.",
    },
    {
        "label": "query_input_tracks_mousedown",
        "snippet": "q.addEventListener('mousedown', function(e){",
        "why": "The focused query input should emit a compact mousedown marker before focus and typing decisions diverge.",
    },
    {
        "label": "query_input_tracks_mouseup",
        "snippet": "q.addEventListener('mouseup', function(e){",
        "why": "The focused query input should emit a mouseup marker so click completion timing is visible.",
    },
    {
        "label": "query_input_tracks_click",
        "snippet": "q.addEventListener('click', function(e){",
        "why": "The focused query input should emit a click marker for the final activation state.",
    },
    {
        "label": "query_input_mousedown_mark",
        "snippet": "mark('Q-MD:' + e.button + ':' + q.value);",
        "why": "The input-local mousedown marker should keep the button number and live value together.",
    },
    {
        "label": "query_input_mouseup_mark",
        "snippet": "mark('Q-MU:' + e.button + ':' + q.value);",
        "why": "The input-local mouseup marker should keep the button number and live value together.",
    },
    {
        "label": "query_input_click_mark",
        "snippet": "mark('Q-CL:' + e.button + ':' + q.value);",
        "why": "The input-local click marker should keep the button number and live value together.",
    },
    {
        "label": "document_mouse_capture_loop_present",
        "snippet": "['mousedown', 'mouseup', 'click'].forEach(function(type) {",
        "why": "The probe should capture the document-level mouse activation path for click-to-focus classification.",
    },
    {
        "label": "document_mouse_entry_records_target_and_button",
        "snippet": "var entry = code + ':' + describeElement(e.target) + ':' + e.button;",
        "why": "The document mouse trace should preserve both the target identity and the button number.",
    },
    {
        "label": "document_mouse_trace_list_is_updated",
        "snippet": "mouseEvents.push(entry);",
        "why": "The document mouse trace should keep the latest activation markers in a stable list.",
    },
    {
        "label": "document_mouse_mark_is_rendered",
        "snippet": "mark('DOC-' + entry);",
        "why": "The document mouse trace should immediately surface the newest marker in the title summary.",
    },
)


TARGET_PATH = Path("src/browser/tests/page/google_home_title_probe.html")

TEMPLATE = """<!doctype html>
<html>
<body>
<script>
  var currentQ = null;
  var lastMark = 'INIT';

  function describeElement(el) {
    return el ? 'EL' : 'NONE';
  }

  function renderStatus() {
    var early = window.__lpEarlyEvents && window.__lpEarlyEvents.length
      ? window.__lpEarlyEvents[window.__lpEarlyEvents.length - 1]
      : 'NONE';
    var mouseEvents = window.__lpMouseEvents || (window.__lpMouseEvents = []);
    var mouse = mouseEvents.length ? mouseEvents[mouseEvents.length - 1] : 'NONE';
    var value = currentQ ? (currentQ.value || '') : '';
    var selection = currentQ ? [currentQ.selectionStart, currentQ.selectionEnd].join(':') : 'NONE';
    var summary = lastMark + '|A=' + describeElement(document.activeElement) + '|Q=' + describeElement(currentQ) + '|V=' + value + '|S=' + selection + '|E=' + early + '|M=' + mouse;
    document.title = summary;
  }

  function mark(value) {
    lastMark = value;
    renderStatus();
  }

  function bindQueryInput(q) {
    q.addEventListener('mousedown', function(e){
      mark('Q-MD:' + e.button + ':' + q.value);
    });
    q.addEventListener('mouseup', function(e){
      mark('Q-MU:' + e.button + ':' + q.value);
    });
    q.addEventListener('click', function(e){
      mark('Q-CL:' + e.button + ':' + q.value);
    });
  }

  ['mousedown', 'mouseup', 'click'].forEach(function(type) {
    document.addEventListener(type, function(e){
      var mouseEvents = window.__lpMouseEvents || (window.__lpMouseEvents = []);
      var code = type === 'mousedown' ? 'MD' : (type === 'mouseup' ? 'MU' : 'CL');
      var entry = code + ':' + describeElement(e.target) + ':' + e.button;
      mouseEvents.push(entry);
      mark('DOC-' + entry);
    }, true);
  });
</script>
</body>
</html>
"""


def audit(repo_root: Path) -> dict[str, object]:
    source_path = repo_root / TARGET_PATH
    exists = source_path.exists()
    source = source_path.read_text(encoding="utf-8") if exists else ""
    checks = []

    for expectation in EXPECTATIONS:
        present = expectation["snippet"] in source
        checks.append(
            {
                "label": expectation["label"],
                "present": present,
                "exists": exists,
                "why": expectation["why"],
            }
        )

    missing = [check for check in checks if not check["present"]]
    return {
        "ok": not missing,
        "target": str(TARGET_PATH),
        "missing_count": len(missing),
        "checks": checks,
    }


def render_repo(repo_root: Path, *, missing_label: str | None = None) -> None:
    content = TEMPLATE
    if missing_label:
        for expectation in EXPECTATIONS:
            if expectation["label"] == missing_label:
                content = content.replace(expectation["snippet"], "")
                break
        else:
            raise ValueError(f"unknown label: {missing_label}")

    target_path = repo_root / TARGET_PATH
    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_text(content, encoding="utf-8")


def run_self_test() -> tuple[bool, list[str]]:
    failures: list[str] = []
    with tempfile.TemporaryDirectory() as tmp_dir:
        repo_root = Path(tmp_dir)
        render_repo(repo_root)
        result = audit(repo_root)
        if not result["ok"]:
            failures.append("guarded sample should pass")
        for expectation in EXPECTATIONS:
            render_repo(repo_root, missing_label=expectation["label"])
            result = audit(repo_root)
            if result["ok"]:
                failures.append(f"missing {expectation['label']} unexpectedly passed")
    return not failures, failures


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo_root", nargs="?", default=".", help="Repository root to audit")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of text")
    parser.add_argument("--self-test", action="store_true", help="Run the synthetic fixture self-test")
    args = parser.parse_args(argv)

    if args.self_test:
        ok, failures = run_self_test()
        payload = {
            "profile": "issue3-google-probe-mouse-trace-audit-self-test",
            "ok": ok,
            "failures": failures,
        }
        if args.json:
            print(json.dumps(payload, indent=2))
        else:
            print(f"SELF_TEST={'pass' if ok else 'fail'}")
            for failure in failures:
                print(f"FAILURE={failure}")
        return 0 if ok else 1

    result = audit(Path(args.repo_root))
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"ISSUE3_GOOGLE_PROBE_MOUSE_TRACE_AUDIT={'pass' if result['ok'] else 'fail'}")
        print(f"TARGET={result['target']}")
        print(f"MISSING_COUNT={result['missing_count']}")
        for check in result["checks"]:
            if not check["present"]:
                print(f"MISSING_LABEL={check['label']}")
                print(f"MISSING_WHY={check['why']}")
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
