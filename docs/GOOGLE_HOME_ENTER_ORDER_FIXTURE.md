# Google Home Enter Order Fixture

Use `src/browser/tests/page/google_home_enter_order_probe.html` when issue `#3`
work needs a smaller Google-shaped localhost reproduction before the broader
homepage-fixture, submit-timing, or live Google passes.

## What It Covers

- named-form access through `document.forms.f` and `name="q"`
- Google-like centered search input plus sibling submit controls
- headed focus, typing, Enter keydown, Enter keypress, and form submit ordering
- title and on-page status markers that expose the latest event and the reduced
  Enter event ladder

## Expected Marker Progression

Click the search box, type `QZ`, then press `Enter`.

The title and status badge should move through markers like:

- `BOUND`
- `FOCUSED`
- `TYPED:Q`
- `TYPED:QZ`
- `KEYDOWN:QZ|13|13`
- `KEYPRESS:QZ|13|13`
- `SUBMIT:QZ|E=KP:ENTER`

The `ORD=` suffix should end as:

- `ORD=KEYDOWN>KEYPRESS>SUBMIT`

If submit lands before keypress, or if typing never reaches `TYPED:QZ`, the
fixture has already narrowed the issue before the full Google-style helpers are
needed.

## Suggested Localhost Use

Serve the page through the same local validation server used for other headed
fixtures, then open the fixture in headed mode and exercise the search box by
hand or through the current Win32 probe stack.

Use this fixture before the broader saved-homepage or live Google replay when
the current question is specifically whether the shared headed Enter path still
waits for keypress before submit on a Google-shaped form shell.
