# Issue #3 Attached HTML Target Bundle Markers

Use this companion note with `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md` when the replay is already pinned to the current three-page compatibility bundle and you need concrete on-page anchors from the saved files themselves.

This note is intentionally narrower than the broader checklist. It does not replace the existing route helpers, suite surfaces, or proof entrypoints. It gives the next run a faster way to answer a simpler question: did headed mode render the right saved page, or did it only open some partial shell?

## Exact bundle order

Keep the current issue `#3` bundle in this exact order:

1. `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
2. `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
3. `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

If a helper surfaces a different order or a different filename set, stop and treat that as bundle selection drift before you interpret any headed result.

## Bundle-wide marker rules

Use these markers as observable anchors, not as hard parser assertions:

- titles should match or clearly contain the page names below
- the saved Google page should look media-heavy and link-heavy, not sparse
- the Anthropic page should look like a long working application form, not a short marketing page
- the Department of War page should look asset-heavy and portal-like, not like a plain unstyled document

Approximate tag counts from the saved bundle can help triage whether the wrong file or a badly degraded render loaded:

- Google Safety Centre snapshot: about 75 links, 90 images, 11 scripts, no `<form>` element
- Anthropic application snapshot: about 1 form, 55 input-like controls, 33 links, 10 scripts
- Department of War snapshot: about 1 form, 76 input-like controls, 203 links, 23 images, 37 scripts

Treat those counts as orientation only. The manual pass still depends on visible headed behavior.

## Page 1: Google Safety Centre

Saved file:
- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`

Expected title anchor:
- `Control your online safety and privacy – Google Safety Centre`

Useful visible markers from the saved file:
- a Google Safety Centre privacy and safety surface
- a `Recent news` section
- cards such as `5 helpful tools from Google to keep your accounts safe`
- a media-heavy page with many images and deeper stacked content blocks

What usually counts as a believable green pass:
- the first viewport is clearly branded as Google Safety Centre rather than a blank or fallback surface
- scrolling reaches deeper card sections without the page collapsing to empty paint
- pointer interaction still works on obvious top-level controls or links after the first scroll

What usually points to the wrong subsystem:
- blank cards or collapsed media regions suggest rendering or asset-loading drift
- correct paint but dead clicks suggest input delivery or hit-target drift

## Page 2: Anthropic application

Saved file:
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`

Expected title anchor:
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic`

Useful visible markers from the saved file:
- an H1 for `[Expression of Interest] Research Manager, Interpretability`
- an `Apply for this job` section
- longer follow-up sections such as voluntary self-identification prompts
- a dense form body with many input controls

What usually counts as a believable green pass:
- the first focused input keeps typed text visible after click-to-focus
- tabbing or clicking deeper into the form does not break later fields
- form controls still look alive after scrolling beyond the top section

What usually points to the wrong subsystem:
- disappearing typed text or dropped focus suggests input or focus delivery drift
- lower sections failing only after scroll suggests lifecycle, layout, or focus restoration drift

## Page 3: Department of War UAP page

Saved file:
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

Expected title anchor:
- `Presidential Unsealing and Reporting System for UAP Encounters | U.S. Department of War`

Useful visible markers from the saved file:
- a portal-style Department of War shell rather than plain text
- PURSUE naming in metadata and page context
- a search-oriented surface near the header area
- a heavier page with many linked assets, scripts, and navigation targets
- modal or detail language such as `Record detail`

What usually counts as a believable green pass:
- the top shell looks styled instead of raw or missing most assets
- the search affordance can be focused or expanded without losing text visibility
- large menu or navigation hit targets stay aligned with what is painted

What usually points to the wrong subsystem:
- an unstyled or partially styled shell suggests sidecar or asset completeness drift first
- visible controls with broken activation suggest input routing or hit-target drift second

## Fast triage use

Use this note when you need to answer one of these before reopening deeper debugging:

- did the route open the intended saved page at all
- is this failure page-specific or shared across the bundle
- does the break look more like rendering, assets, focus, or pointer delivery

If the page title and visible markers already miss badly, route back to bundle selection, sidecar completeness, or asset completeness before you blame deeper headed runtime behavior.
