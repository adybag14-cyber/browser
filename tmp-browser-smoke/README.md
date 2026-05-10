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

### Input, forms, and editing

- `form-controls/`: label activation and Enter-submit basics
- `google-investigation-next/`: reduced Google-style localhost probes for focus
  churn, delayed readiness, correction, and Enter-submit ordering
- `find/`: find-in-page surface behavior
- `file-upload/`: chooser flows, replacement, cancel, multipart submit, and
  target-page upload behavior
- `downloads/`: normal download create/delete shell behavior
- `attachment-downloads/`: attachment navigation and download promotion flows

### Storage and session state

- `cookie-persistence/`: clear, cross-tab, and restart cookie behavior
- `localstorage-persistence/`: localStorage same-tab, cross-tab, and restart
  behavior
- `indexeddb-persistence/`: IndexedDB clear, cursor, index, transaction, and
  restart behavior
- `sessionstorage-scope/`: same-tab vs new-tab sessionStorage scoping

### Runtime networking and fetch behavior

- `fetch-abort/`: abort propagation on in-flight requests
- `fetch-credentials/`: credentialed fetch policy
- `websocket-smoke/`: websocket connection, protocol, and close behavior

### Graphics and canvas

- `canvas-smoke/`: canvas 2D, drawImage, text metrics, and early WebGL probes
- `multi-image/`: multiple image placement checks

### Packaging and release-oriented probes

- `bare-metal-release/`: packaged-image and bare-metal release probes

### Manual real-page follow-up

- `manual-user/`: manual headed validation helpers for saved or attached
  localhost HTML pages after the bounded suite for the changed subsystem is
  green

### Shared helpers

- `common/`: shared Windows input helpers used by multiple suites

## Recommended Validation Order

Use this order unless a narrower issue demands something more specific first.

1. Build or reuse a fresh headed Windows binary.
2. Run one narrow suite for the subsystem you changed.
3. Run one nearby shared-behavior suite if the change touched input, rendering,
   navigation, storage, or downloads.
4. Re-run `google-investigation-next/` or another issue-specific reduced probe
   only after the bounded localhost suite is green.
5. Finish with the smallest real headed manual pass that exercises the same
   user flow.

## Fast Mapping By Change Type

- Browser shell, tabs, address bar, start/history/bookmarks/downloads/settings:
  run `tabs/`, `browser-pages/`, and the closest `settings/` or `popup/` probe.
- Shared input, focus, caret, or form submit behavior: run `form-controls/`,
  the closest `inline-flow/` probe, and `google-investigation-next/` when the
  issue is Google search-box related.
- Layout, painter, screenshots, clipping, or hit testing: run `layout-smoke/`,
  `flow-layout/`, `rendered-link-dom/`, and the nearest `inline-flow/` case.
- Font, text metrics, or zoom behavior: run `font-render/`, `font-smoke/`, and
  `zoom/`.
- Network policy or protected subresource loading: run `image-smoke/`,
  `stylesheet-smoke/`, `fetch-credentials/`, and `fetch-abort/` as needed.
- Persistence or restart behavior: run the matching storage suite plus
  `tabs/` or `browser-pages/` when shell state also changed.
- File chooser or download manager changes: run `file-upload/`, `downloads/`,
  and `attachment-downloads/`.
- Saved or attached HTML compatibility passes: run the matching bounded suite
  first, then use `manual-user/` with
  `scripts/windows/start_localhost_html_validation.ps1` for the real-page
  localhost follow-up.

## Issue-Specific Note

For live-site Google search-box work, start with the reduced probes under
`google-investigation-next/`, then use `scripts/windows/watch_headed_probe.ps1`
against `src/browser/tests/page/google_home_title_probe.html`, and only then
move on to the full `https://www.google.com/` pass. These probes are narrowing
and regression tools, not replacements for the core `form-controls/` and
`inline-flow/` gates.
