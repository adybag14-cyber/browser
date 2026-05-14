# Local HTML Compatibility Probe

This probe runs the Windows headed browser against one or more local HTML files
served over `http://127.0.0.1`.

Use it for saved compatibility targets that are too large or too specific to
live inside the repository, including the attached HTML pages used for headed
mode validation.

## Usage

Run every `.html` or `.htm` file under a directory:

```powershell
pwsh -File .\tmp-browser-smoke\local-html-compat\chrome-local-html-compat-probe.ps1 `
  -ContentRoot C:\path\to\saved-pages
```

Run only selected pages relative to that root:

```powershell
pwsh -File .\tmp-browser-smoke\local-html-compat\chrome-local-html-compat-probe.ps1 `
  -ContentRoot C:\path\to\saved-pages `
  -Pages @(
    "Control your online safety and privacy - Google Safety Centre.html",
    "Job Application for Research Manager, Interpretability at Anthropic.html"
  )
```

You can also set `LIGHTPANDA_COMPAT_HTML_ROOT` instead of passing
`-ContentRoot`.

## What It Produces

- Starts a localhost file server for the provided HTML directory
- Opens each page in a fresh headed `browse` session
- Saves one screenshot plus browser stdout/stderr logs per page under
  `tmp-browser-smoke\local-html-compat\artifacts`
- Prints a JSON summary with the served URL, final window title, artifact paths,
  and any per-page failure

## Current Success Signal

The probe currently treats a page as passing when headed mode:

- launches a real window
- produces a non-empty screenshot
- avoids page-specific startup errors during the capture pass

That makes it a good first compatibility sweep for complex saved pages before
adding page-specific interaction expectations.
