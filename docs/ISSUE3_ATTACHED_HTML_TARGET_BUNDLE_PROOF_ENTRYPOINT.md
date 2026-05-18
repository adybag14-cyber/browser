# Issue #3 Attached HTML Target-Bundle Proof Entrypoint

Use this note when the issue `#3` replay is already pinned to the known three-page compatibility bundle and you want the shortest written route for collecting the fixed-list screenshot-and-title proof before the helper chain widens back into the broader attached-page routes.

This note matches `show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1`.

Before trusting this proof-only bridge after helper or note updates, rerun its dedicated surface checker:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
```

Keep these companion notes nearby:
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`

## Goal

Start from the pinned three-page compatibility bundle, rerun the bundle surface checks when branch state or attached inputs may have changed, keep the delegated bundle replay visible until the same three pages are green, then use the fixed-list local HTML fixture proof on those same inputs before widening back into the broader attached-page or Google-shaped follow-up routes.

## Bundle replay before proof

Use this route when the delegated replay still needs to run or when you want one last fail-fast confirmation that the current inputs still match the known three-page bundle:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when:
- the current replay should stay pinned to the saved three-page compatibility set
- you want the fail-fast surface check and bundle check rerun before collecting proof
- the headed localhost replay still needs to run on the same bundle inputs before the narrower proof pass

## Fixed-list proof

Use this route immediately after the bundle replay when you want the fixed screenshot-and-title proof attached to the same three pages:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1 -FixturePaths 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' 'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html' 'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'
```

Use that route when:
- the delegated bundle replay already turned green and you want tighter proof for the same pinned inputs
- the next follow-up depends on keeping the exact three attached pages visible instead of widening back into a looser attached-page route immediately
- you want the proof pass to stay tied to the known fixed filename set without re-deriving placeholder names from the bundle reference note

## Widen back out when needed

If the proof pass makes it clear that the next replay should reopen a broader attached-page route, keep these nearby:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use the broader attached-page flow when the proof pass says the route should widen back into generic localhost compatibility replay.
Use the Google-shaped attached-page flow when the current bundle still needs the narrower Google-first route kept visible beside the broader fallback.
Use the bundle suite surface and bundle-first entrypoint when the replay should stay pinned to the same three-page compatibility set before reopening the rest of issue `#3`.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or explicit input paths, keep that same context attached to the proof entrypoint helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:
- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned and the proof pass should stay on those exact inputs

## Practical rule

1. Rerun the proof-entrypoint surface checker when the helper chain or note set has changed.
2. Reconfirm the current inputs still match the known three-page bundle.
3. Keep the delegated bundle replay visible until the same inputs are ready for proof.
4. Run the local HTML fixture surface check and the fixed-list screenshot-and-title proof on those same pages.
5. Widen back into the broader attached-page or Google-shaped helper routes only after the proof pass is in hand.

When explicit `InputPath` values are already pinned, preserve those same paths across the bundle checks, the delegated bundle replay, and the proof helper so the evidence stays attached to the exact same three local pages.
