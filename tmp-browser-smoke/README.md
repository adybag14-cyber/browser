# Headed Probe Suites

This directory is the headed Windows validation matrix for the fork.

Use it as the first stop when a change needs a bounded localhost or browser-page
probe before broader manual browsing.

## Command-Line Helper

Use `scripts/windows/show_headed_validation_suites.ps1` when you want the probe
map in a quick table or when you need the default suite set for a specific
change area.

Examples:

- `.\\scripts\\windows\\show_headed_validation_suites.ps1`
- `.\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName layout-smoke`
- `.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea input`
- `.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input -Json`
- `.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea manual-html`
- `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1`
- `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1`

## Core Rule

- Pick the suite that matches the subsystem you changed.
- Run the narrowest probe that proves the fix.
- Re-run the closest cross-cutting gate when the change touches shared input,
  rendering, navigation, persistence, or downloads.
- Keep real-site checks as a follow-up, not the only proof.

## Suite Map

### Shell and browser pages

- `tabs/`: tab strip, tab lifecycle, session restore, reopen, startup shell
- `browser-pages/`: `browser://start`, `browser://tabs`, history, bookmarks,
  downloads, settings, and browser-page actions
- `settings/`: settings page interactions and persistence-adjacent shell checks
- `popup/`: popup policy, new-window routing, opener behavior
- `wrapped-link/`: visible-link hit testing and wrapped inline navigation
- `stop-loading/`: stop, recovery, and committed-page restore behavior
- `bookmarks/`: bookmark toggles, delete flows, keyboard paths, persistence

### Rendering and layout

- `layout-smoke/`: general display-list layout, screenshots, clipping, and
  visual regression pages
- `inline-flow/`: wrapped inline layout plus mixed controls, links, focus, and
  submit behavior
- `flow-layout/`: shared block and image flow behavior
- `rendered-link-dom/`: rendered link boxes, hit targets, and DOM-visible link
  behavior
- `font-render/`: font loading, fallback, text metrics, and button/text layout
- `font-smoke/`: authenticated and anonymous font request policy
- `image-smoke/`: runtime image, script, and module fetch behavior on the
  shared browser request path
- `stylesheet-smoke/`: stylesheet loading, import handling, and CSS policy
- `zoom/`: headed zoom behavior against shared layout and text paths

### Input, forms, editing, and Google-style follow-up

- `form-controls/`: label activation, focus, basic typing, immediate
  Enter-submit, deferred pending-submit behavior, reduced Google-home submit,
  and the stricter localhost keypress-before-submit gate through the shared
  runner
- `google-investigation-next/`: reduced Google-style localhost probes for focus
  churn, delayed readiness, correction, and Enter-submit ordering
- `google-recommended`: the current one-command localhost-first issue #3 runner
  that folds in the title pass, reduced homepage pass, submit-timing check,
  shared Enter-order wrapper, and watcher before saved-page or live-site
  follow-up
- `google-title`: bounded reduced-homepage title, focus, typing, and
  Enter-submit ordering on the real headed surface before the broader
  `google-home/`, `google-submit-timing`, or wrapper-first passes
- `google-quick`: fast title-plus-watch first pass on the real headed surface
  before the reduced homepage, submit-timing, shared Enter-order, or wrapper
  passes
- `google-home/`: reduced homepage watcher and bounded Enter-submit pass on the
  real headed surface after the localhost Google-style probes are green
- `google-submit-timing`: bounded Google-shaped keydown, keypress, and submit
  ordering on the real headed surface before broader shared gates or a manual
  Google pass
- `google-shared-enter-order`: shared label-click baseline plus shared submit
  gates, reduced Google-home form coverage, inline-flow submit coverage, and
  the stricter localhost keypress-before-submit wrapper through one runner
  entrypoint
- `find/`: find-in-page surface behavior

### Downloads and attachments

- `file-upload/`: chooser flows, replacement, cancel, multipart submit, and
  target-page upload behavior
- `downloads/`: normal download create/delete shell behavior
- `attachment-downloads/`: attachment navigation and download promotion flows

### Storage and session state

- `cookie-persistence/`: clear, cross-tab, and restart cookie behavior
- `localstorage-persistence/`: localStorage same-tab, cross-tab, storage-event,
  and restart behavior
- `indexeddb-persistence/`: IndexedDB clear, cursor, index, transaction, and
  restart behavior
- `sessionstorage-scope/`: same-tab, cross-tab, and restart sessionStorage
  scoping

### Runtime networking and fetch behavior

- `fetch-abort/`: abort propagation on in-flight requests
- `fetch-credentials/`: credentialed fetch policy
- `websocket-smoke/`: websocket connection, protocol, and close behavior

### Graphics and canvas

- `canvas-smoke/`: canvas 2D, drawImage, text metrics, and early WebGL probes
- `multi-image/`: multiple image placement and shared image-surface checks

### Packaging and release-oriented probes

- `bare-metal-release/`: packaged-image and bare-metal release probes

### Manual saved-page follow-up

- `manual-user/`: manual headed validation helpers for saved or attached
  localhost HTML pages after the matching bounded suite is green
- `scripts/windows/run_saved_page_localhost_validation.ps1`: one-command saved
  page summary plus direct-or-staged localhost launch helper
- `scripts/windows/run_attached_html_localhost_validation.ps1`: one-command
  attached HTML discovery, summary, and localhost launch helper for the current
  workspace snapshots
- `scripts/windows/show_saved_page_google_validation_flow.ps1`: saved-page
  issue #3 flow map that keeps the localhost Google phases ahead of the manual
  headed pass

### Shared helpers

- `common/`: shared Windows input helpers used by multiple suites

## Recommended Validation Order

Use this order unless a narrower issue demands something more specific first.

1. Build or reuse a fresh headed Windows binary.
2. Run one narrow suite for the subsystem you changed.
3. Run one nearby shared-behavior suite if the change touched input, rendering,
   navigation, storage, or downloads.
4. For Google search-box or other real-page typing issues, start with
   `google-investigation-next/`, then use `google-title` for the narrow
   real-surface title/focus gate or `google-quick` for the fast title-plus-watch
   first pass, then use `google-recommended` for the one-command bounded pass
   when you want the shared watcher flow bundled in, then `google-home/`, then
   `google-submit-timing`, then `google-shared-enter-order`, and only then move
   on to the saved-page or live-site follow-up.
5. For saved or attached localhost HTML pages, start with the matching bounded
   suite first and only then move into `manual-user/`,
   `run_saved_page_localhost_validation.ps1`, or
   `run_attached_html_localhost_validation.ps1` for the real page follow-up.
6. Finish with the smallest real headed manual pass that exercises the same
   user flow.

## Fast Mapping By Change Type

- Browser shell, tabs, address bar, start/history/bookmarks/downloads/settings,
  or stop/recovery behavior: run `tabs/`, `browser-pages/`, `bookmarks/`, and
  the closest `settings/`, `popup/`, or `stop-loading/` probe.
- Shared input, focus, caret, or form submit behavior: run `form-controls/`,
  the closest `inline-flow/` probe, and only then move on to the live-site pass
  when the issue is Google search-box related.
- Google-style focus churn, delayed readiness, correction, or Enter-submit
  ordering: run `google-investigation-next/`, then `google-title` for the
  narrow real-surface title/focus gate, then `google-quick` for the fast
  title-plus-watch first pass, then `google-recommended` for the current
  one-command bounded pass, or drop into the stepwise `home`, `submit-timing`,
  and `shared-enter-order` phases when you need to narrow the first failing
  gate before the saved-page or live-site follow-up.
- Saved or attached localhost HTML compatibility passes: run the matching
  bounded suite first, then use `manual-user/`,
  `run_saved_page_localhost_validation.ps1`,
  `run_attached_html_localhost_validation.ps1`, and
  `show_saved_page_google_validation_flow.ps1` when the saved-page follow-up is
  part of the Google-style headed typing investigation.
- Layout, painter, screenshots, clipping, or hit testing: run `layout-smoke/`,
  `flow-layout/`, `rendered-link-dom/`, and the nearest `inline-flow/` case.
- Font, text metrics, or zoom behavior: run `font-render/`, `font-smoke/`, and
  `zoom/`.
- Network policy or protected subresource loading: run `image-smoke/`,
  `stylesheet-smoke/`, `fetch-credentials/`, `fetch-abort/`, and
  `websocket-smoke/` as needed.
- Persistence or restart behavior: run the matching storage suite plus
  `tabs/` or `browser-pages/` when shell state also changed.
- File chooser or download manager changes: run `file-upload/`, `downloads/`,
  and `attachment-downloads/`.
- Multi-image placement or shared image-surface regressions: run `multi-image/`
  plus the closest `image-smoke/`, `flow-layout/`, or `layout-smoke/` check.

## Issue-Specific Note

For live-site Google search-box work, start with
`tmp-browser-smoke/google-investigation-next/`, then use
`powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_home_title_probe.ps1`
or `show_headed_validation_suites.ps1 -SuiteName google-title` when the next
question is whether the reduced headed surface is reaching the expected title,
focus, typing, and Enter-submit markers. Then use
`powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase quick`
for the fast title-plus-watch first pass, then
`powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1`
for the current one-command bounded pass, or move through
`-Phase home`, `-Phase submit-timing`, and `-Phase shared-enter-order` when you
want to isolate the first failing gate before the saved-page or live-site
follow-up.

Use `src/browser/tests/page/google_home_title_probe.html` when the change
specifically touches load or readiness ordering, and use
`powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1`
when you want the current issue #3 validation order printed as reusable
commands. These probes are narrowing and regression helpers, not replacements
for the core `form-controls/` and `inline-flow/` gates.

For attached or saved HTML page follow-up, use
`tmp-browser-smoke/manual-user/README.md`,
`run_saved_page_localhost_validation.ps1`,
`run_attached_html_localhost_validation.ps1`,
`show_saved_page_google_validation_flow.ps1`,
`start_localhost_html_validation.ps1`,
`start_staged_localhost_html_validation.ps1`, and
`summarize_localhost_html_pages.ps1` after the matching bounded suite is green.
