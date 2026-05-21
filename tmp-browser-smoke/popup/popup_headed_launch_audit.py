import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed"',
        "purpose": "Popup anchor probe keeps headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/popup/chrome-popup-background-timer-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed"',
        "purpose": "Popup background-timer probe keeps headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/popup/chrome-popup-form-enter-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed"',
        "purpose": "Popup form-enter probe keeps headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/popup/chrome-popup-form-post-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed"',
        "purpose": "Popup form-post probe keeps headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/popup/chrome-popup-form-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed"',
        "purpose": "Popup form probe keeps headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/popup/chrome-popup-named-anchor-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed"',
        "purpose": "Popup named-anchor probe keeps headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/popup/chrome-popup-script-blank-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed"',
        "purpose": "Popup script-blank probe keeps headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/popup/chrome-popup-script-named-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed"',
        "purpose": "Popup script-named probe keeps headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/popup/chrome-popup-script-policy-block-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed"',
        "purpose": "Popup script-policy-block probe keeps headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/popup/chrome-popup-script-policy-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed"',
        "purpose": "Popup script-policy probe keeps headed mode explicit in its browse launch.",
    },
    {
        "path": "tmp-browser-smoke/popup/chrome-query-load-probe.ps1",
        "snippet": '@("browse","--browser_mode","headed"',
        "purpose": "Popup query-load probe keeps headed mode explicit in its browse launch.",
    },
)


def build_missing_summary(results: list[dict[str, object]]) -> list[dict[str, object]]:
    summary = []
    for result in results:
        if result["exists"]:
            continue
        summary.append(
            {
                "path": result["path"],
                "purpose": result["purpose"],
                "snippet": result["snippet"],
            }
        )
    return summary


def audit_repo_root(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    for expectation in EXPECTATIONS:
        target = repo_root / expectation["path"]
        exists = target.is_file() and expectation["snippet"] in target.read_text(
            encoding="utf-8", errors="ignore"
        )
        results.append(
            {
                "path": expectation["path"],
                "purpose": expectation["purpose"],
                "snippet": expectation["snippet"],
                "exists": exists,
            }
        )
    missing = build_missing_summary(results)
    return {
        "profile": "popup-headed-launches",
        "repo_root": str(repo_root),
        "checked_count": len(results),
        "missing_count": len(missing),
        "missing": missing,
        "results": results,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit popup localhost probes for explicit headed browse launches."
    )
    parser.add_argument("--repo-root", default=".", help="Repository root to inspect.")
    parser.add_argument("--json", action="store_true", help="Print JSON instead of text.")
    args = parser.parse_args(argv)

    audit = audit_repo_root(Path(args.repo_root).resolve())
    if args.json:
        print(json.dumps(audit, indent=2))
    elif audit["missing_count"]:
        for item in audit["missing"]:
            print(f"FAIL {item['path']}: {item['purpose']}")
    else:
        print("Popup probe headed-launch surface is intact.")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())