# Issue #3 Replay Discovery Handoff

Use this note when issue `#3` needs the fastest read-first bridge from the
top-level headed validation catalog into the current attached localhost replay
helpers on `fork/headed-mode-foundation`.

Keep this note beside:
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_HANDOFF.md`
- `docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Read-first baseline

Start from the shared issue `#3` router when you need the broader Google
validation lane reprinted first:

```powershell
.\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1
```

If the next replay is already obviously attached-page-first, reprint the
attached localhost branch directly from the top-level suite router first:

```powershell
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

Use `attached-html` when the generic three-page compatibility route should stay
visible. Use `google-attached-html` when the Google-shaped attached-page helper
should stay visible. Use `attached-html-target-bundle` when the current saved
or attached inputs are already the pinned three-page compatibility bundle.

## Attached localhost re-entry

If you are reopening the route from `docs/WINDOWS_FULL_USE.md`, keep the
broader Windows-first branch visible long enough to rerun its fail-fast route
checker, reopen the newer validation-router and catalog-side bridge, keep the
broader attached-page flow helper, the broader Google-shaped attached-page
surface checker, the deeper Google-style asset audit, the issue-specific Google
attached-page checker, and the dedicated Google attached-page flow guide
visible, rerun the suite-router next-step checker, surface the executable
next-step matrix, rerun the shortcut-first checker, reopen the shorter
shortcut-first bridge, rerun the compact suite-router handoff checker, surface
the compact suite-router handoff that remains available beside that shorter
bridge, and keep the replay-side attached-page ladder aligned before the
narrower top-level attached-page helpers take over:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_next_steps_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_handoff_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Use that route when the broader Windows runbook already made attached localhost
follow-up obvious and you want the route-level surface checker, the
validation-router attached-html bridge, the Windows-first catalog quickstart,
the replay-side attached-page surface checker, the replay-side attached-page
quickstart, the narrower validation-router and top-level attached-page helpers,
the broader attached-page flow helper, the broader Google-shaped attached-page
surface checker, the deeper Google-style asset audit, the issue-specific Google
attached-page checker, the dedicated Google attached-page flow guide, the
issue-specific Google attached-page entrypoint, the suite-router next-step
checker, the executable next-step matrix, the shortcut-first checker, the
shortcut-first bridge, the compact suite-router handoff checker, the compact
suite-router handoff, and the suite-catalog-side bridge all describing the
same re-entry order.

When the top-level suite router already made attached localhost follow-up
obvious, prefer this compact chain:

```powershell
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_next_steps_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_handoff_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1
```

Use the same helper order after `-ChangeArea google-attached-html` when the
broader Google-shaped attached-page checker, the deeper Google-style asset
audit, the shortcut-first checker, and the issue-specific bridge all need to
stay visible first. Use the same helper order after `-ChangeArea
attached-html-target-bundle` when the route should stay pinned to the known
three-page bundle before widening back into the broader safe-route chain.

If the replay already carries a non-default checkout, a saved summary, or
explicit bundle inputs, preserve that same context on the helper that you open
next by passing `-RepoRoot`, `-SummaryPath`, and `-InputPath` directly to the
chosen helper.

## Choose The Next Helper Quickly

- `show_google_issue3_windows_full_use_attached_html_route.ps1`: use this when
  the replay is reopening directly from `docs/WINDOWS_FULL_USE.md` and the
  broader Windows-side attached-page route should stay visible first.
- `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`:
  use this before narrowing back into the attached-page helper chain when the
  Windows-first route was the last broader branch and you want missing helpers
  or renamed notes to fail fast.
- `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`:
  use this when the Windows-first route should keep the validation-router
  handoff visible before the narrower top-level attached-page helpers take over.
- `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`:
  use this when the Windows full-use branch should keep the catalog-side
  attached-page quickstart visible beside the narrower top-level chain.
- `check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1`:
  use this when the replay-side attached-page ladder needs a fail-fast check
  before the narrower top-level notes and replay-route helper take over.
- `show_google_issue3_windows_replay_attached_html_quickstart.ps1`: use this
  when the replay-side attached-page ladder should stay visible before the
  top-level notes and replay-route helper take over.
- `show_google_issue3_validation_router_attached_html_quickstart.ps1`: use this
  when the broader validation-router attached-page bridge should stay visible
  before the replay collapses into the shorter top-level and replay-route
  helpers.
- `check_google_attached_html_validation_surface.ps1`: use this when the replay
  already looks Google-shaped and you want the broader attached-page surface to
  fail fast before the deeper asset audit or the narrower issue-specific
  checker take over.
- `check_attached_html_local_asset_closure.ps1 -GoogleStyle`: use this when
  missing sidecars or other saved local asset drift might explain the current
  Google-shaped attached-page failure and you want the deeper asset audit
  reprinted before the narrower issue-specific checker or bridge takes over.
- `check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1`:
  use this when the replay already looks Google-shaped and you want the
  narrower issue-specific attached-page lane to fail fast before the dedicated
  Google flow helper or the shorter issue-specific entrypoint takes over.
- `show_google_attached_html_validation_flow.ps1`: use this when the replay
  still needs the dedicated Google-shaped attached-page flow guide reprinted
  after the broader checker, the deeper asset audit, and before the route
  narrows into the shorter top-level notes.
- `show_google_issue3_google_attached_html_entrypoint.ps1`: use this when the
  issue-specific Google-shaped attached-page route should stay visible before
  the suite-router next-step checker, the executable next-step matrix, the
  shortcut-first checker, the shortcut-first bridge, the compact suite-router
  handoff checker, the compact suite-router handoff, replay-route shortcut
  bridge, replay shortcuts, or the later safe-route map.
- `check_google_issue3_suite_router_next_steps_validation_surface.ps1`: use
  this immediately before `show_google_issue3_suite_router_next_steps.ps1`
  when you want the executable branch matrix to fail fast on missing notes,
  renamed helpers, or drifted Google attached-page follow-up before the replay
  narrows further.
- `show_google_issue3_suite_router_next_steps.ps1`: use this when you want the
  executable branch matrix surfaced after the issue-specific Google attached-page
  entrypoint and before the shortcut-first checker, the shortcut-first bridge,
  the compact suite-router handoff, replay-route helper, replay shortcuts, or
  the safe-route map.
- `check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1`:
  use this immediately before `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`
  when you want the shorter suite-router shortcut bridge to fail fast on
  missing notes, drifted attached-page companion helpers, or renamed replay
  follow-up commands before the replay narrows further.
- `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`: use this
  when the executable next-step matrix has already confirmed the shorter issue
  `#3` bridge and you want replay shortcuts, the replay-route shortcut,
  attached-page follow-up, or bundle-aware next steps reprinted before the
  broader handoff helper or safe-route map takes over.
- `check_google_issue3_suite_router_handoff_validation_surface.ps1`: use this
  immediately before `show_google_issue3_suite_router_handoff.ps1` when you
  want the compact suite-router handoff to fail fast on missing bridge notes,
  attached-page helpers, replay-route companions, or bundle-aware follow-up
  before the smaller helper ladder takes over.
- `show_google_issue3_suite_router_handoff.ps1`: use this when the
  issue-specific Google-shaped attached-page bridge is already visible, the
  shortcut-first bridge has already been refreshed, and you want the compact
  suite-router handoff to reprint the narrower checker directly while keeping
  replay shortcuts, the next-step matrix, replay route, the replay-route
  shortcut, and bundle-aware follow-up aligned on one smaller surface before
  the route widens again.
- `show_google_issue3_top_level_attached_html_quickstart.ps1`: use this first
  when the top-level suite router already narrowed replay to attached localhost
  follow-up and you want the shortest top-level attached-page bridge before the
  broader attached-page notes reopen.
- `show_google_issue3_top_level_attached_html_entrypoint.ps1`: use this when
  you want the broader top-level attached-page bridge reprinted before the
  route narrows into the newer suite-router or suite-catalog attached-page
  helpers.
- `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`: use this
  when the compact top-level attached-page route and the suite-catalog-side
  bridge should stay visible together before the replay narrows again.
- `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`: use this when
  the top-level shortcut-first bridge should stay visible before the narrower
  attached-page shortcut, replay-route, or replay-shortcuts surfaces take over.
- `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1`:
  use this when the replay-side attached-page ladder, the top-level catalog
  quickstart, and the suite-catalog-side bridge should stay visible on the same
  compact surface before the route narrows again.
- `show_google_issue3_suite_router_attached_html_quickstart.ps1`: use this when
  the route is already inside attached-page follow-up and you want the
  suite-router-side attached-page bridge kept visible before choosing between
  the catalog bridge, the attached-page shortcut, replay route, replay
  shortcuts, or the safe-route map.
- `show_google_issue3_suite_catalog_entrypoints.ps1`: use this when the broader
  suite-catalog companion surface should stay visible beside the narrower
  attached-page chain before you widen back into replay-route, replay-shortcuts,
  or safe-route helpers.
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`: use this
  when the suite-catalog-side attached-page bridge should stay visible before
  the route narrows again.
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`: use this when the
  attached-page compatibility branch itself should stay visible before widening
  into replay route, replay shortcuts, the next-step matrix, or the safe-route
  map.
- `show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1`:
  use this when the replay is already narrowing back into replay shortcuts and
  you want the shortest bridge into the replay-side attached-page ladder before
  the broader replay-route or safe-route helpers take over again.
- `show_google_issue3_replay_route.ps1`: use this when the attached-page helper
  chain is already established and you want the current replay-route surface
  printed before you drop into the narrower replay-route shortcut helper.
- `check_google_issue3_replay_route_shortcut_validation_surface.ps1`: use this
  immediately before `show_google_issue3_replay_route_shortcut_entrypoint.ps1`
  when you want the compact replay-route bridge to fail fast on missing replay
  notes, attached-page helpers, replay-side bridges, or bundle-aware follow-up
  before the narrower shortcut helper takes over.
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1`: use this when
  `show_google_issue3_replay_route.ps1` is already open, the dedicated
  replay-route shortcut checker is green, and you want the smaller replay-route
  companion surface before widening into replay shortcuts, the next-step
  matrix, the bundle-first branch, or the safe-route map.
- `show_google_issue3_replay_shortcuts.ps1`: use this when the route is already
  clear and you want the narrowest stable helper surface. Keep
  `docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md` nearby when the replay is
  about to collapse into that shorter replay-helper family from the broader
  replay discovery map.
- `show_google_issue3_contextual_flow.ps1`: use this when you still need
  `RepoRoot`, `SummaryPath`, or the pinned bundle context preserved before
  narrowing further.
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`: use this when
  `InputPath` is already pinned to the known three-page compatibility set.
- `show_google_issue3_safe_route_entrypoints.ps1`: use this only after the
  route has narrowed enough that the wrapper-heavy issue `#3` command surface is
  the next useful layer.

## Practical Rule

From the top-level suite router, prefer
`show_google_issue3_validation_router_attached_html_quickstart.ps1` first
whenever attached localhost follow-up is already the next obvious branch. If
you are arriving from `docs/WINDOWS_FULL_USE.md`, rerun
`check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`,
reopen
`show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`,
keep `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`,
`check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1`,
and `show_google_issue3_windows_replay_attached_html_quickstart.ps1` nearby,
reopen `show_attached_html_validation_flow.ps1`, then
`check_google_attached_html_validation_surface.ps1`, then
`check_attached_html_local_asset_closure.ps1 -GoogleStyle`, then
`check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1`,
then `show_google_attached_html_validation_flow.ps1`, then
`show_google_issue3_google_attached_html_entrypoint.ps1`, then
`check_google_issue3_suite_router_next_steps_validation_surface.ps1`, then
`show_google_issue3_suite_router_next_steps.ps1`, then
`check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1`,
then `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`, then
`check_google_issue3_suite_router_handoff_validation_surface.ps1`, then
`show_google_issue3_suite_router_handoff.ps1` once the attached-page branch is
back in view so the shorter bridge and the wider compact handoff both stay
aligned, and then follow the same narrower attached-page helper chain. Once the
route is clearly inside the narrower attached-page helpers, prefer
`show_google_issue3_replay_route.ps1`, then
`check_google_issue3_replay_route_shortcut_validation_surface.ps1`, then
`show_google_issue3_replay_route_shortcut_entrypoint.ps1`, then
`show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1`,
before widening back into `show_google_issue3_replay_shortcuts.ps1`, the
longer validation-chain notes, or the wrapper-heavy safe-route work.

- broader suite-catalog surface still matters beside the narrower attached-page
  chain: reopen `show_google_issue3_suite_catalog_entrypoints.ps1` before
  falling back to the suite-catalog attached-page bridge, replay-route helper,
  replay shortcuts, or the safe-route map.