#!/usr/bin/env python3
"""Audit the Google home title probe trace surface used for headed issue #3.

This checker keeps a compact branch-side contract around the lightweight trace
instrumentation in ``src/browser/tests/page/google_home_title_probe.html``.
The goal is to preserve the high-signal diagnostics surface while the direct
runtime fix in large existing files remains publication-sensitive.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


REQUIRED_MARKERS = (
    "window.__lpEarlyEvents=[];",
    "window.__lpPostMessages=[];",
    "window.__lpMessageEvents=[];",
    "window.__lpListenerAdds=[];",
    "window.__lpAcCalls=[];",
    "Object.defineProperty(window,'google'",
    "Object.defineProperty(value,'ac'",
    "window.__lpAcCalls.push('c:'",
    "window.__lpListenerAdds.push(type+'@'+target);",
    "type==='keydown'||type==='keypress'||type==='keyup'||type==='focus'||type==='blur'||type==='input'||type==='beforeinput'||type==='submit'||type==='message'",
    "window.__lpPostMessages.push(String(message));",
    "window.addEventListener('message',function(e){try{window.__lpMessageEvents.push(String((e&&e.data)||''));}catch(_e){}},true);",
    "document.addEventListener('keydown',function(e){window.__lpEarlyEvents.push('KD:'",
    "document.addEventListener('keypress',function(e){window.__lpEarlyEvents.push('KP:'",
    "document.addEventListener('beforeinput',function(e){window.__lpEarlyEvents.push('BI:'",
    "document.addEventListener('input',function(e){var t=e.target;window.__lpEarlyEvents.push('IN:'",
)


def find_missing_markers(source: str) -> list[str]:
    return [marker for marker in REQUIRED_MARKERS if marker not in source]


def evaluate_source(source: str) -> dict[str, object]:
    missing = find_missing_markers(source)
    ok = not missing
    detail = (
        "google_home_title_probe.html retains the early-event, listener, and message trace surface"
        if ok
        else "google_home_title_probe.html missing markers: " + " | ".join(missing[:3])
    )
    return {
        "ok": ok,
        "detail": detail,
        "missing_markers": missing,
        "required_marker_count": len(REQUIRED_MARKERS),
        "matched_marker_count": len(REQUIRED_MARKERS) - len(missing),
    }


def evaluate_path(path: Path) -> dict[str, object]:
    return evaluate_source(path.read_text(encoding="utf-8"))


def emit_text_result(result: dict[str, object]) -> None:
    print(f"GOOGLE_HOME_TITLE_PROBE_TRACE_SURFACE={'pass' if result['ok'] else 'fail'}")
    print(f"DETAIL={result['detail']}")
    print(f"MISSING_MARKER_COUNT={len(result['missing_markers'])}")
    for marker in result["missing_markers"]:
        print(f"MISSING_MARKER={marker}")


VULNERABLE_SOURCE = """
<script>
window.__lpEarlyEvents=[];
document.addEventListener('keydown',function(e){window.__lpEarlyEvents.push('KD:'+e.key);},true);
</script>
"""


GUARDED_SOURCE = """
<script>
window.__lpEarlyEvents=[];window.__lpPostMessages=[];window.__lpMessageEvents=[];window.__lpListenerAdds=[];window.__lpAcCalls=[];
(function(){var __lpGoogleValue;Object.defineProperty(window,'google',{configurable:true,enumerable:true,get:function(){return __lpGoogleValue;},set:function(value){__lpGoogleValue=value;try{var __lpAcValue;Object.defineProperty(value,'ac',{configurable:true,enumerable:true,get:function(){return __lpAcValue;},set:function(ac){if(ac&&typeof ac.c==='function'&&!ac.__lpWrapped){var __lpOrigC=ac.c;ac.c=function(){try{window.__lpAcCalls.push('c:'+(arguments[0]&&arguments[0].client||'none'));}catch(_e){}return __lpOrigC.apply(this,arguments);};ac.__lpWrapped=true;}__lpAcValue=ac;}});}catch(_e){}}});})();
(function(){var __lpAddEventListener=EventTarget.prototype.addEventListener;EventTarget.prototype.addEventListener=function(type,listener,options){try{var target=this===window?'WINDOW':this===document?'DOCUMENT':[((this&&this.tagName)||''),((this&&this.name)||''),((this&&this.id)||'')].join(':');if(type==='keydown'||type==='keypress'||type==='keyup'||type==='focus'||type==='blur'||type==='input'||type==='beforeinput'||type==='submit'||type==='message'){window.__lpListenerAdds.push(type+'@'+target);}}catch(_e){}return __lpAddEventListener.apply(this,arguments);};})();
(function(){var __lpPostMessage=window.postMessage;window.postMessage=function(message,targetOrigin){try{window.__lpPostMessages.push(String(message));}catch(_e){}return __lpPostMessage.apply(this,arguments);};window.addEventListener('message',function(e){try{window.__lpMessageEvents.push(String((e&&e.data)||''));}catch(_e){}},true);})();
document.addEventListener('keydown',function(e){window.__lpEarlyEvents.push('KD:'+[(e.key||''),(e.code||''),e.keyCode,e.which,e.defaultPrevented?1:0].join('|'));},true);
document.addEventListener('keypress',function(e){window.__lpEarlyEvents.push('KP:'+[(e.key||''),(e.code||''),e.keyCode,e.which,e.charCode,e.defaultPrevented?1:0].join('|'));},true);
document.addEventListener('beforeinput',function(e){window.__lpEarlyEvents.push('BI:'+[(e.data||''),e.defaultPrevented?1:0].join('|'));},true);
document.addEventListener('input',function(e){var t=e.target;window.__lpEarlyEvents.push('IN:'+[(t&&t.value)||'',e.defaultPrevented?1:0].join('|'));},true);
</script>
"""


def run_self_test(json_output: bool) -> int:
    vulnerable = evaluate_source(VULNERABLE_SOURCE)
    guarded = evaluate_source(GUARDED_SOURCE)
    ok = (not vulnerable["ok"]) and bool(guarded["ok"])

    if json_output:
        print(
            json.dumps(
                {
                    "profile": "google-home-title-probe-trace-surface-self-test",
                    "self_test": "pass" if ok else "fail",
                    "vulnerable_sample": vulnerable,
                    "guarded_sample": guarded,
                },
                indent=2,
            )
        )
        return 0 if ok else 1

    print(f"SELF_TEST={'pass' if ok else 'fail'}")
    print(f"VULNERABLE_OK={'pass' if vulnerable['ok'] else 'fail'}")
    print(f"GUARDED_OK={'pass' if guarded['ok'] else 'fail'}")
    if not ok:
        print(f"VULNERABLE_DETAIL={vulnerable['detail']}")
        print(f"GUARDED_DETAIL={guarded['detail']}")
        return 1
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check that the Google home title probe keeps its trace surface"
    )
    parser.add_argument(
        "--html-path",
        type=Path,
        help="Path to src/browser/tests/page/google_home_title_probe.html",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run built-in vulnerable/guarded sample checks",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.self_test:
        return run_self_test(json_output=args.json)
    if args.html_path is None:
        raise SystemExit("--html-path is required unless --self-test is used")

    result = evaluate_path(args.html_path)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text_result(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
