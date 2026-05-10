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
  Enter-submit, and deferred pending-submit behavior
- `google-investigation-next/`: reduced Google-style localhost probes for focus
  churn, delayed readiness, correction, and Enter-submit ordering
- `google-home/`: reduced homepage watcher and bounded Enter-submit pass on the
  real headed surface after the localhost Google-style probes are green
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

### Shared helpers

- `common/`: shared Windows input helpers used by multiple suites

## Recommended Validation Order

Use this order unless a narrower issue demands something more specific first.

1. Build or reuse a fresh headed Windows binary.
2. Run one narrow suite for the subsystem you changed.
3. Run one nearby shared-behavior suite if the change touched input, rendering,
   navigation, storage, or downloads.
4. For Google search-box or other real-page typing issues, start with
   `google-investigation-next/`, then `google-home/`, then the nearest shared
   `form-controls/` or `inline-flow/` submit probe before the live-site pass.
5. For saved or attached localhost HTML pages, start with the matching bounded
   suite first and only then move into `manual-user/` for the real page
   follow-up.
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
  ordering: run `google-investigation-next/`, then `google-home/`, then one
  nearby shared input gate such as `form-controls/` or `inline-flow/`.
- Saved or attached localhost HTML compatibility passes: run the matching
  bounded suite first, then use `manual-user/` and the localhost helper scripts
  for the real follow-up on the saved pages.
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
`tmp-browser-smoke/google-investigation-next/`, then
`tmp-browser-smoke/google-home/`, then the closest shared submit gates such as
`tmp-browser-smoke/form-controls/enter-submit-probe.ps1` and
`tmp-browser-smoke/inline-flow/chrome-inline-break-input-enter-submit-probe.ps1`.
Use `src/browser/tests/page/google_home_title_probe.html` when the change
specifically touches load or readiness ordering, and only then move on to the
full `https://www.google.com/` pass. These probes are narrowing and regression
helpers, not replacements for the core `form-controls/` and `inline-flow/`
gates.

For attached or saved HTML page follow-up, use
`tmp-browser-smoke/manual-user/README.md`,
`start_localhost_html_validation.ps1`,
`start_staged_localhost_html_validation.ps1`, and
`summarize_localhost_html_pages.ps1` after the matching bounded suite is green.
