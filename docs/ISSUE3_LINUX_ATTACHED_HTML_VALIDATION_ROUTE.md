# Issue #3 Linux Attached HTML Validation Route

Use this note when issue `#3` replay should stay on the saved attached-page
bundle, but the current run is on Linux or WSL and should not depend on the
Windows PowerShell wrapper.

Companion helper:

- `scripts/linux/start_attached_pages_catalog.sh`
- `tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`

## When To Use It

Use this route when any of these are true:

- the next headed replay is running from Linux or WSL
- the saved HTML bundle needs sidecar or asset audits before localhost replay
- the replay should keep the current three-page compatibility bundle pinned
  without reopening the broader Windows-first helper chain

## Quick Route

From the browser repo root:

```bash
bash ./scripts/linux/start_attached_pages_catalog.sh --input-path ./agent_files --audit-sidecars
bash ./scripts/linux/start_attached_pages_catalog.sh --input-path ./agent_files --audit-assets
bash ./scripts/linux/start_attached_pages_catalog.sh --input-path ./agent_files --print-manifest
bash ./scripts/linux/start_attached_pages_catalog.sh --input-path ./agent_files --require-complete-sidecars --require-complete-assets --print-manifest
bash ./scripts/linux/start_attached_pages_catalog.sh --input-path ./agent_files --require-complete-sidecars --require-complete-assets
```

Run the sidecar audit first so missing sibling `_files` directories fail before
the browser is blamed. Run the asset audit second so broader local export drift
stays visible. Use the manifest step when the pinned routes should be printed
without starting the server. Use the strict manifest or strict launch forms when
the bundle should fail fast on either sidecar or asset drift. Use the final
strict launch form when the localhost catalog itself should only open after the
bundle is already proven complete.

## Google-First Bundle Route

When the replay should keep the Google Safety Centre page first while staying on
the current compatibility bundle, pass the preferred page explicitly:

```bash
bash ./scripts/linux/start_attached_pages_catalog.sh \
  --input-path ./agent_files \
  --preferred-initial-page "Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html" \
  --print-manifest
```

The same preferred-first route also works with `--audit-sidecars`,
`--audit-assets`, or the final localhost launch command.

Keep this exact file set together from the start when the replay is already on
the known compatibility bundle:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

## Working Rules

- Use this Linux route before widening back out to live Google when the saved
  bundle can still narrow the failure faster.
- Keep the sidecar and asset audits ahead of localhost replay so bundle drift is
  ruled out before runtime blame.
- Reuse `--preferred-initial-page` when the replay should keep the
  Google-shaped page first across audit, manifest, and localhost launch steps.
- Read `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` when the replay
  should widen back into the broader Google-like attached-page ladder after this
  Linux-first preflight passes.
