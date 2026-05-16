param(
    [string]$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path,
    [string]$BrowserExe = "",
    [string]$Query = "brass otter lantern",
    [string]$IpResolve = "ipv4",
    [int]$TimeoutSeconds = 60,
    [int]$Port = 9233,
    [string]$StartUrl = "",
    [switch]$DirectSearch,
    [switch]$BasicSearchMode,
    [switch]$DisablePageScripts,
    [switch]$AcceptConsent,
    [switch]$NoSeedGoogleConsent,
    [switch]$KeepPreviousArtifacts
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$repoRootFull = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')

function Assert-InRepo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $full = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $rootWithSep = $repoRootFull + [System.IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($rootWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to touch path outside repo: $full"
    }
}

function Get-RealNodePath {
    $cmd = Get-Command node -ErrorAction Stop
    if ($cmd.Source -like "*\AppData\Roaming\npm\*") {
        $nodeExe = "C:\Program Files\nodejs\node.exe"
        if (Test-Path -LiteralPath $nodeExe) {
            return $nodeExe
        }
        throw "node resolves to an npm shim and C:\Program Files\nodejs\node.exe was not found"
    }
    return $cmd.Source
}

if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}
$BrowserExe = (Resolve-Path -LiteralPath $BrowserExe).Path
$nodeExe = Get-RealNodePath

$smokeRoot = Join-Path $RepoRoot "tmp-browser-smoke\google-zig017"
Assert-InRepo -Path $smokeRoot
if ((Test-Path -LiteralPath $smokeRoot) -and -not $KeepPreviousArtifacts) {
    Remove-Item -LiteralPath $smokeRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $smokeRoot | Out-Null

. (Join-Path $RepoRoot "tmp-browser-smoke\tabs\TabProbeCommon.ps1")

Add-Type -AssemblyName System.Drawing
if (-not ("GoogleSmokeCaptureUser32" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class GoogleSmokeCaptureUser32 {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}
"@
}

function Save-WindowCapture {
    param(
        [Parameter(Mandatory = $true)]
        [IntPtr]$Hwnd,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $rect = New-Object GoogleSmokeCaptureUser32+RECT
    if (-not [GoogleSmokeCaptureUser32]::GetWindowRect($Hwnd, [ref]$rect)) {
        throw "GetWindowRect failed"
    }

    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    if ($width -le 0 -or $height -le 0) {
        throw "invalid window capture bounds"
    }

    $bitmap = [System.Drawing.Bitmap]::new($width, $height)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
        } finally {
            $graphics.Dispose()
        }
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $bitmap.Dispose()
    }
}

function Wait-CdpVersion {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [Parameter(Mandatory = $true)]
        [int]$TimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            return Invoke-RestMethod -Uri ("http://127.0.0.1:{0}/json/version" -f $Port) -TimeoutSec 2
        } catch {
            Start-Sleep -Milliseconds 250
        }
    }
    throw "CDP /json/version endpoint did not become ready on port $Port"
}

$profileDir = Join-Path $smokeRoot "profile-google-search"
$finalScreenshotPath = Join-Path $smokeRoot "google-search-final.png"
$stdoutPath = Join-Path $smokeRoot "google-search.stdout.txt"
$stderrPath = Join-Path $smokeRoot "google-search.stderr.txt"
$driverStdoutPath = Join-Path $smokeRoot "google-cdp-driver.stdout.txt"
$driverStderrPath = Join-Path $smokeRoot "google-cdp-driver.stderr.txt"
$driverResultPath = Join-Path $smokeRoot "google-cdp-result.json"
$driverScriptPath = Join-Path $smokeRoot "google-cdp-driver.js"
$driverReleasePath = Join-Path $smokeRoot "google-cdp-driver.release"

$previousTelemetry = $env:LIGHTPANDA_DISABLE_TELEMETRY
$env:LIGHTPANDA_DISABLE_TELEMETRY = "true"
$previousIpResolve = $env:LIGHTPANDA_IP_RESOLVE
if ($IpResolve) {
    $env:LIGHTPANDA_IP_RESOLVE = $IpResolve
}
$previousDisablePageJs = $env:LIGHTPANDA_DISABLE_PAGE_JS
if ($DisablePageScripts) {
    $env:LIGHTPANDA_DISABLE_PAGE_JS = "true"
} else {
    Remove-Item Env:LIGHTPANDA_DISABLE_PAGE_JS -ErrorAction SilentlyContinue
}

$process = $null
$driverProcess = $null
try {
    $arguments = @(
        "serve",
        "--host",
        "127.0.0.1",
        "--port",
        "$Port",
        "--timeout",
        ([Math]::Max($TimeoutSeconds * 2, 120)).ToString(),
        "--headed",
        "--window_width",
        "1280",
        "--window_height",
        "720",
        "--http_timeout",
        "20000",
        "--log_level",
        "debug",
        "--profile_dir",
        $profileDir
    )

    Write-Host ("Launching headed CDP Google smoke on port {0}" -f $Port)
    $process = Start-Process -FilePath $BrowserExe -ArgumentList $arguments -WorkingDirectory $RepoRoot -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru

    $version = Wait-CdpVersion -Port $Port -TimeoutSeconds 15
    if (-not $version.webSocketDebuggerUrl) {
        throw "CDP version endpoint did not return webSocketDebuggerUrl"
    }

    $env:LP_GOOGLE_SMOKE_WS = $version.webSocketDebuggerUrl
    $env:LP_GOOGLE_SMOKE_QUERY = $Query
    $env:LP_GOOGLE_SMOKE_TIMEOUT_MS = ([Math]::Max($TimeoutSeconds * 1000, 30000)).ToString()
    $env:LP_GOOGLE_SMOKE_RESULT = $driverResultPath
    $env:LP_GOOGLE_SMOKE_RELEASE = $driverReleasePath
    $env:LP_GOOGLE_SMOKE_DIRECT = if ($DirectSearch) { "true" } else { "false" }
    $env:LP_GOOGLE_SMOKE_BASIC = if ($BasicSearchMode) { "true" } else { "false" }
    $env:LP_GOOGLE_SMOKE_ACCEPT_CONSENT = if ($AcceptConsent) { "true" } else { "false" }
    $env:LP_GOOGLE_SMOKE_SEED_CONSENT = if ($NoSeedGoogleConsent) { "false" } else { "true" }
    $env:LP_GOOGLE_SMOKE_START_URL = $StartUrl

    $driverScript = @'
const fs = require("fs");
const WebSocket = require("ws");

const wsUrl = process.env.LP_GOOGLE_SMOKE_WS;
const query = process.env.LP_GOOGLE_SMOKE_QUERY || "brass otter lantern";
const timeoutMs = Number(process.env.LP_GOOGLE_SMOKE_TIMEOUT_MS || "60000");
const resultPath = process.env.LP_GOOGLE_SMOKE_RESULT;
  const releasePath = process.env.LP_GOOGLE_SMOKE_RELEASE;
  const directSearch = /^true$/i.test(process.env.LP_GOOGLE_SMOKE_DIRECT || "");
  const basicSearchMode = /^true$/i.test(process.env.LP_GOOGLE_SMOKE_BASIC || "");
  const acceptConsent = /^true$/i.test(process.env.LP_GOOGLE_SMOKE_ACCEPT_CONSENT || "");
  const seedConsent = !/^false$/i.test(process.env.LP_GOOGLE_SMOKE_SEED_CONSENT || "");
  const startUrl = process.env.LP_GOOGLE_SMOKE_START_URL || "";

let nextId = 1;
let sid = null;
const pending = new Map();
const events = [];
const navigations = [];
const networkRequests = [];
const networkResponses = [];
const networkFailures = [];
const runtimeExceptions = [];
const logEntries = [];

function pushLimited(list, value, limit = 80) {
  list.push(value);
  if (list.length > limit) {
    list.splice(0, list.length - limit);
  }
}

function diagnosticsSnapshot() {
  return {
    eventCount: events.length,
    networkRequests,
    networkResponses,
    networkFailures,
    runtimeExceptions,
    logEntries,
  };
}

function finish(result) {
  if (!result.diagnostics) {
    result.diagnostics = diagnosticsSnapshot();
  }
  if (resultPath) {
    fs.writeFileSync(resultPath, JSON.stringify(result, null, 2));
  }
  console.log(JSON.stringify(result, null, 2));
  process.exitCode = result.ok ? 0 : 20;
  waitForReleaseSync();
}

function trace(label, value = null) {
  const payload = { time: new Date().toISOString(), label };
  if (value !== null) payload.value = value;
  console.error(JSON.stringify(payload));
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function waitForReleaseSync() {
  if (!releasePath) return;
  const buffer = new SharedArrayBuffer(4);
  const state = new Int32Array(buffer);
  const deadline = Date.now() + 15000;
  while (Date.now() < deadline) {
    if (fs.existsSync(releasePath)) {
      return;
    }
    Atomics.wait(state, 0, 0, 100);
  }
}

function send(ws, method, params = {}, sessionId = sid, timeout = timeoutMs) {
  const id = nextId++;
  const message = { id, method, params };
  if (sessionId) message.sessionId = sessionId;
  ws.send(JSON.stringify(message));
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`timeout ${method}`));
    }, timeout);
    pending.set(id, {
      method,
      resolve: (value) => {
        clearTimeout(timer);
        resolve(value);
      },
      reject: (error) => {
        clearTimeout(timer);
        reject(error);
      },
    });
  });
}

function waitFor(predicate, label, timeout = timeoutMs) {
  const existing = events.find(predicate);
  if (existing) return Promise.resolve(existing);
  return new Promise((resolve, reject) => {
    const deadline = Date.now() + timeout;
    const timer = setInterval(() => {
      const found = events.find(predicate);
      if (found) {
        clearInterval(timer);
        resolve(found);
        return;
      }
      if (Date.now() > deadline) {
        clearInterval(timer);
        reject(new Error(`timeout waiting for ${label}`));
      }
    }, 50);
  });
}

function evaluate(ws, expression, timeout = timeoutMs) {
  return send(ws, "Runtime.evaluate", {
    expression,
    returnByValue: true,
    awaitPromise: false,
  }, sid, timeout);
}

async function inputCommand(ws, method, params) {
  try {
    await send(ws, method, params, sid, 5000);
    return { ok: true };
  } catch (error) {
    return { ok: false, error: String(error) };
  }
}

function valueOf(evaluateResponse) {
  return evaluateResponse?.result?.result?.value;
}

function keyCodeForChar(ch) {
  if (ch >= "a" && ch <= "z") return `Key${ch.toUpperCase()}`;
  if (ch >= "A" && ch <= "Z") return `Key${ch}`;
  if (ch >= "0" && ch <= "9") return `Digit${ch}`;
  if (ch === " ") return "Space";
  return "";
}

async function clickSearchBox(ws) {
  const targetResponse = await evaluate(ws, `(() => {
    const q = document.querySelector('textarea[name=q],input[name=q]');
    if (!q) return { ok: false, reason: 'no q' };
    q.scrollIntoView({ block: 'center', inline: 'center' });
    const r = q.getBoundingClientRect();
    return {
      ok: true,
      x: r.left + r.width / 2,
      y: r.top + r.height / 2,
      width: r.width,
      height: r.height,
      tag: q.tagName,
      type: q.type || '',
    };
  })()`);
  const target = valueOf(targetResponse);
  if (!target?.ok || !Number.isFinite(target.x) || !Number.isFinite(target.y)) {
    return { ok: false, reason: target?.reason || "invalid rect", target };
  }
  const events = [];
  events.push(await inputCommand(ws, "Input.dispatchMouseEvent", {
    type: "mouseMoved",
    x: target.x,
    y: target.y,
    button: "none",
    buttons: 0,
  }));
  events.push(await inputCommand(ws, "Input.dispatchMouseEvent", {
    type: "mousePressed",
    x: target.x,
    y: target.y,
    button: "left",
    buttons: 1,
  }));
  events.push(await inputCommand(ws, "Input.dispatchMouseEvent", {
    type: "mouseReleased",
    x: target.x,
    y: target.y,
    button: "left",
    buttons: 0,
  }));
  await sleep(300);
  if (events.every((event) => event.ok)) {
    return { ok: true, target, events };
  }
  const fallback = await focusSearchBox(ws).catch((error) => ({ ok: false, error: String(error) }));
  return { ok: !!fallback?.ok, target, events, fallback };
}

async function typeSearchQuery(ws, text) {
  const inserted = await inputCommand(ws, "Input.insertText", { text });
  if (inserted.ok) return inserted;
  const fallback = await evaluate(ws, `(() => {
    const q = document.querySelector('textarea[name=q],input[name=q]');
    if (!q) return { ok: false, reason: 'no q' };
    q.value = ${JSON.stringify(text)};
    q.dispatchEvent(new InputEvent('beforeinput', { bubbles: true, data: ${JSON.stringify(text)}, inputType: 'insertText' }));
    q.dispatchEvent(new InputEvent('input', { bubbles: true, data: ${JSON.stringify(text)}, inputType: 'insertText' }));
    q.dispatchEvent(new Event('change', { bubbles: true }));
    return { ok: true, value: q.value };
  })()`);
  return { ok: !!valueOf(fallback)?.ok, inserted, fallback: valueOf(fallback) };
}

async function prepareGoogleFormForSubmit(ws) {
  const response = await evaluate(ws, `(() => {
    const form = document.querySelector('textarea[name=q],input[name=q]')?.closest('form')
      || document.querySelector('form[action*="/search"]');
    if (!form) return { ok: false, reason: 'no form' };
    const width = String(window.innerWidth || document.documentElement.clientWidth || 1280);
    const height = String(window.innerHeight || document.documentElement.clientHeight || 720);
    const fields = [['biw', width], ['bih', height]];
    if (basicSearchMode) {
      fields.push(['gbv', '1'], ['ucbcb', '1']);
    }
    for (const [name, value] of fields) {
      let field = form.querySelector('input[name="' + name + '"]');
      if (!field) {
        field = document.createElement('input');
        field.type = 'hidden';
        field.name = name;
        form.appendChild(field);
      }
      field.value = value;
    }
    return {
      ok: true,
      biw: form.querySelector('input[name="biw"]')?.value || '',
      bih: form.querySelector('input[name="bih"]')?.value || '',
      gbv: form.querySelector('input[name="gbv"]')?.value || '',
      ucbcb: form.querySelector('input[name="ucbcb"]')?.value || '',
    };
  })()`);
  return valueOf(response);
}

async function focusSearchBox(ws) {
  const focusedResponse = await evaluate(ws, `(() => {
    const candidates = Array.from(document.querySelectorAll('textarea[name=q],input[name=q]'));
    const attempts = [];
    if (!candidates.length) return { ok: false, reason: 'no q', attempts };
    const ranked = candidates
      .map((q, index) => {
        const r = q.getBoundingClientRect();
        return {
          q,
          index,
          visible: r.width > 0 && r.height > 0,
          area: Math.max(0, r.width) * Math.max(0, r.height),
          id: q.id || '',
          tag: q.tagName,
          type: q.type || '',
        };
      })
      .sort((a, b) => {
        if (a.id === 'APjFqb' && b.id !== 'APjFqb') return -1;
        if (b.id === 'APjFqb' && a.id !== 'APjFqb') return 1;
        if (a.visible !== b.visible) return a.visible ? -1 : 1;
        return b.area - a.area;
      });
    for (const candidate of ranked) {
      const q = candidate.q;
      const focusLog = [];
      const recordFocus = (event) => {
        const target = event.target;
        focusLog.push([
          event.type,
          target && target.tagName || '',
          target && (target.getAttribute('name') || '') || '',
          target && (target.id || '') || '',
        ].join(':'));
      };
      document.addEventListener('focus', recordFocus, true);
      document.addEventListener('focusin', recordFocus, true);
      document.addEventListener('blur', recordFocus, true);
      document.addEventListener('focusout', recordFocus, true);
      q.focus();
      document.removeEventListener('focus', recordFocus, true);
      document.removeEventListener('focusin', recordFocus, true);
      document.removeEventListener('blur', recordFocus, true);
      document.removeEventListener('focusout', recordFocus, true);
      if (typeof q.setSelectionRange === 'function') {
        q.setSelectionRange(0, q.value.length);
      }
      attempts.push({
        index: candidate.index,
        id: candidate.id,
        tag: candidate.tag,
        type: candidate.type,
        visible: candidate.visible,
        area: candidate.area,
        connected: q.isConnected,
        disabled: !!q.disabled,
        readOnly: !!q.readOnly,
        tabIndex: q.tabIndex,
        active: document.activeElement === q,
        activeTag: document.activeElement ? document.activeElement.tagName : '',
        activeName: document.activeElement ? (document.activeElement.getAttribute('name') || '') : '',
        activeId: document.activeElement ? (document.activeElement.id || '') : '',
        focusLog,
        value: q.value,
      });
      if (document.activeElement === q) {
        return { ok: true, attempts, chosen: attempts[attempts.length - 1] };
      }
    }
    return {
      ok: false,
      attempts,
      activeTag: document.activeElement ? document.activeElement.tagName : '',
      activeName: document.activeElement ? (document.activeElement.getAttribute('name') || '') : '',
      activeId: document.activeElement ? (document.activeElement.id || '') : '',
      value: ranked[0]?.q?.value || '',
    };
  })()`);
  return valueOf(focusedResponse);
}

async function dismissConsent(ws) {
  const response = await evaluate(ws, `(() => {
    const controls = Array.from(document.querySelectorAll('button,[role="button"],input[type="button"],input[type="submit"],a[href]'));
    const candidates = controls.map((control, index) => ({
      index,
      id: control.id || '',
      tag: control.tagName || '',
      role: control.getAttribute('role') || '',
      href: control.href || '',
      text: (control.innerText || control.textContent || control.value || '').replace(/\\s+/g, ' ').trim(),
      aria: control.getAttribute('aria-label') || '',
    }));
    const label = (control) => (control.text + ' ' + control.aria).trim();
    const isAccept = (control) => /Accept all|I agree|Agree/i.test(label(control));
    const isReject = (control) => /Reject all/i.test(label(control));
    const match = candidates.find(isAccept) || candidates.find(isReject);
    if (!match) {
      return { clicked: false, candidates: candidates.slice(0, 8) };
    }
    const control = controls[match.index];
    control.scrollIntoView({ block: 'center', inline: 'center' });
    control.click();
    return { clicked: true, chosen: match, candidates: candidates.slice(0, 8) };
  })()`);
  return valueOf(response);
}

async function pressEnter(ws) {
  await send(ws, "Input.dispatchKeyEvent", {
    type: "keyDown",
    key: "Enter",
    code: "Enter",
  });
  await send(ws, "Input.dispatchKeyEvent", {
    type: "keyUp",
    key: "Enter",
    code: "Enter",
  });
}

async function submitSearchForm(ws, overrideValue = null) {
  const overrideLiteral = overrideValue === null ? "null" : JSON.stringify(String(overrideValue));
  const response = await evaluate(ws, `(() => {
    const q = document.querySelector('textarea[name=q],input[name=q]');
    if (!q) return { ok: false, reason: 'no q' };
    const overrideValue = ${overrideLiteral};
    if (overrideValue !== null) {
      q.value = overrideValue;
    } else if (typeof q.value === 'string' && /\\s$/.test(q.value)) {
      q.value = q.value.replace(/\\s+$/g, '');
      q.dispatchEvent(new Event('input', { bubbles: true }));
      q.dispatchEvent(new Event('change', { bubbles: true }));
    }
    const form = q.closest('form') || document.querySelector('form[action*="/search"]');
    if (!form) return { ok: false, reason: 'no form', value: q.value };
    if (overrideValue !== null) {
      if (typeof HTMLFormElement !== 'undefined' && HTMLFormElement.prototype.submit) {
        HTMLFormElement.prototype.submit.call(form);
        return { ok: true, method: 'native_form_submit_override', value: q.value, action: form.action };
      }
      form.submit();
      return { ok: true, method: 'form.submit_override', value: q.value, action: form.action };
    }
    const submitter = form.querySelector('input[type=submit][name=btnK],button[type=submit],input[type=submit]');
    if (submitter && typeof submitter.click === 'function') {
      submitter.click();
      return { ok: true, method: 'submitter.click', value: q.value, action: form.action };
    }
    if (typeof form.requestSubmit === 'function') {
      form.requestSubmit();
      return { ok: true, method: 'form.requestSubmit', value: q.value, action: form.action };
    }
    form.submit();
    return { ok: true, method: 'form.submit', value: q.value, action: form.action };
  })()`, overrideValue === null ? timeoutMs : 5000);
  return valueOf(response);
}

async function navigateSearchFromForm(ws, searchValue) {
  const queryLiteral = JSON.stringify(String(searchValue));
  let built = null;
  try {
    const response = await evaluate(ws, `(() => {
      const q = document.querySelector('textarea[name=q],input[name=q]');
      const form = q ? (q.closest('form') || document.querySelector('form[action*="/search"]')) : document.querySelector('form[action*="/search"]');
      const action = form ? (form.getAttribute('action') || form.action || '/search') : '/search';
      const url = new URL(action, location.href);
      url.search = '';
      let copied = 0;
      if (form && form.elements) {
        for (const element of Array.from(form.elements)) {
          const name = element && element.name;
          if (!name) continue;
          const type = (element.type || '').toLowerCase();
          if (['button', 'submit', 'reset', 'file', 'image'].includes(type)) continue;
          if ((type === 'checkbox' || type === 'radio') && !element.checked) continue;
          const value = name === 'q' ? ${queryLiteral} : (element.value || '');
          if (value === '') continue;
          url.searchParams.append(name, value);
          copied += 1;
        }
      }
      if (!url.searchParams.has('q')) url.searchParams.set('q', ${queryLiteral});
      url.searchParams.set('igu', '1');
      url.searchParams.set('pws', '0');
      return { ok: true, url: url.href, copied, action: form ? form.action : '', referrer: location.href };
    })()`, 5000);
    built = valueOf(response);
  } catch (error) {
    const params = new URLSearchParams({ q: String(searchValue), source: "hp", igu: "1", pws: "0" });
    built = {
      ok: true,
      url: `https://www.google.com/search?${params.toString()}`,
      copied: 0,
      action: "https://www.google.com/search",
      referrer: "https://www.google.com/webhp",
      fallback: "static_search_url_after_form_extract_timeout",
      error: String(error),
    };
  }
  if (!built?.ok || !built.url) return built || { ok: false, reason: "missing search url" };
  const navigate = await send(ws, "Page.navigate", {
    url: built.url,
    referrer: built.referrer || "https://www.google.com/webhp",
    transitionType: "form_submit",
  }, sid, 10000).catch((error) => ({ warning: String(error) }));
  return { ok: true, method: "cdp_page_navigate_from_form", url: built.url, built, navigate };
}

async function followGoogleFallback(ws) {
  const response = await evaluate(ws, `(() => {
    const links = Array.from(document.querySelectorAll('a[href]'));
    const link = links.find((a) => /click here/i.test((a.innerText || a.textContent || '').trim()));
    if (!link) {
      return { ok: false, reason: 'missing fallback link', linkCount: links.length };
    }
    const href = link.href;
    link.click();
    return { ok: true, href, text: (link.innerText || link.textContent || '').trim() };
  })()`);
  return valueOf(response);
}

async function seedGoogleConsentCookies(ws) {
  if (!seedConsent) return [];
  const expires = Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 540;
  const cookies = [
    {
      name: "SOCS",
      value: "CAISNQgCEitib3FfaWRlbnRpdHlmcm9udGVuZHVpc2VydmVyXzIwMjYwNTEyLjA3X3AwGgJlbiAEGgYIgMSZ0AY",
      domain: ".google.com",
      path: "/",
      secure: true,
      sameSite: "Lax",
      expires,
    },
  ];
  const result = await send(ws, "Network.setCookies", { cookies }, sid, 5000).catch((error) => ({ warning: String(error) }));
  return cookies.map((cookie) => ({
    name: cookie.name,
    domain: cookie.domain,
    path: cookie.path,
    result,
  }));
}

async function pageState(ws) {
  for (let attempt = 0; attempt < 8; attempt += 1) {
    try {
      const response = await evaluate(ws, `({
        href: location.href,
        title: document.title,
        ready: document.readyState,
        text: document.body ? document.body.innerText.slice(0, 1200) : "",
        activeTag: document.activeElement ? document.activeElement.tagName : "",
        activeName: document.activeElement ? (document.activeElement.getAttribute("name") || "") : "",
        activeId: document.activeElement ? (document.activeElement.id || "") : "",
        hasSearchBox: !!document.querySelector('textarea[name=q],input[name=q]'),
        hasResultStats: !!document.querySelector('#result-stats'),
        resultLinkCount: document.querySelectorAll('#search a[href],#rso a[href],div.g a[href]').length,
        fallbackHref: (() => {
          const link = Array.from(document.querySelectorAll('a[href]'))
            .find((a) => /click here/i.test((a.innerText || a.textContent || '').trim()));
          return link ? link.href : "";
        })(),
        searchBoxValue: (() => {
          const q = document.querySelector('textarea[name=q],input[name=q]');
          return q ? q.value : "";
        })(),
        documentCookie: document.cookie ? document.cookie.slice(0, 300) : "",
        navigatorSnapshot: (() => {
          const uaData = navigator.userAgentData && typeof navigator.userAgentData.toJSON === "function"
            ? navigator.userAgentData.toJSON()
            : null;
          return {
            userAgent: navigator.userAgent,
            appVersion: navigator.appVersion,
            platform: navigator.platform,
            language: navigator.language,
            languages: Array.from(navigator.languages || []),
            webdriver: navigator.webdriver,
            cookieEnabled: navigator.cookieEnabled,
            hardwareConcurrency: navigator.hardwareConcurrency,
            deviceMemory: navigator.deviceMemory,
            maxTouchPoints: navigator.maxTouchPoints,
            plugins: navigator.plugins ? navigator.plugins.length : -1,
            mimeTypes: navigator.mimeTypes ? navigator.mimeTypes.length : -1,
            userAgentData: uaData,
          };
        })(),
        screenSnapshot: window.screen ? {
          width: screen.width,
          height: screen.height,
          availWidth: screen.availWidth,
          availHeight: screen.availHeight,
          colorDepth: screen.colorDepth,
          pixelDepth: screen.pixelDepth,
        } : null,
        viewport: {
          innerWidth: window.innerWidth,
          innerHeight: window.innerHeight,
          outerWidth: window.outerWidth,
          outerHeight: window.outerHeight,
          devicePixelRatio: window.devicePixelRatio,
        },
      })`);
      return valueOf(response);
    } catch (error) {
      if (!String(error.message || error).includes("Cannot find context")) {
        throw error;
      }
      await sleep(500);
    }
  }
  throw new Error("runtime context did not stabilize after navigation");
}

function classify(state) {
  const href = state?.href || "";
  const text = state?.text || "";
  const haystack = `${href}\n${state?.title || ""}\n${text}`;
  const encodedPlus = encodeURIComponent(query).replace(/%20/g, "+");
  const hasQuery = haystack.includes(query) || haystack.includes(encodedPlus);
  if (/\/sorry\/|Our systems have detected unusual traffic/i.test(haystack)) return "google_blocked";
  if (/trouble accessing Google Search/i.test(text)) return "google_fallback";
  if (/google\.com\/search/i.test(href) && hasQuery && (state?.hasResultStats || (state?.resultLinkCount || 0) > 0)) return "search_results";
  if (/consent\.google\.com|Before you continue/i.test(haystack)) return "consent";
  return "other";
}

async function main() {
  trace("driver_start", { wsUrl });
  const ws = new WebSocket(wsUrl);
  ws.on("message", (buffer) => {
    const message = JSON.parse(buffer.toString());
    if (message.id && pending.has(message.id)) {
      const waiter = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) {
        waiter.reject(new Error(`${waiter.method}: ${message.error.message || JSON.stringify(message.error)}`));
      } else {
        waiter.resolve(message);
      }
      return;
    }
    events.push(message);
    if (message.method === "Target.attachedToTarget") {
      sid = message.params.sessionId;
    } else if (message.method === "Page.frameNavigated") {
      const url = message.params?.frame?.url || "";
      navigations.push(url);
    } else if (message.method === "Network.requestWillBeSent") {
      pushLimited(networkRequests, {
        url: message.params?.request?.url || "",
        method: message.params?.request?.method || "",
        type: message.params?.type || "",
        hasUserGesture: message.params?.hasUserGesture,
        initiatorType: message.params?.initiator?.type || "",
        headers: message.params?.request?.headers || {},
      });
    } else if (message.method === "Network.responseReceived") {
      pushLimited(networkResponses, {
        url: message.params?.response?.url || "",
        status: message.params?.response?.status,
        statusText: message.params?.response?.statusText || "",
        mimeType: message.params?.response?.mimeType || "",
        headers: message.params?.response?.headers || {},
      });
    } else if (message.method === "Network.loadingFailed") {
      pushLimited(networkFailures, {
        requestId: message.params?.requestId || "",
        errorText: message.params?.errorText || "",
        type: message.params?.type || "",
        canceled: message.params?.canceled,
      });
    } else if (message.method === "Runtime.exceptionThrown") {
      pushLimited(runtimeExceptions, message.params || {});
    } else if (message.method === "Log.entryAdded") {
      pushLimited(logEntries, message.params?.entry || message.params || {});
    }
  });

  await new Promise((resolve, reject) => {
    ws.once("open", resolve);
    ws.once("error", reject);
  });
  trace("websocket_open");

  try {
    await send(ws, "Target.setAutoAttach", {
      autoAttach: true,
      waitForDebuggerOnStart: false,
      flatten: true,
    }, null);
    const attached = await waitFor((event) => event.method === "Target.attachedToTarget", "Target.attachedToTarget");
    sid = attached.params.sessionId;
    trace("target_attached", { sessionId: sid });

    await send(ws, "Page.enable");
    await send(ws, "Runtime.enable");
    await send(ws, "Network.enable").catch((error) => {
      pushLimited(networkFailures, { requestId: "Network.enable", errorText: String(error), type: "CDP" });
    });
    await send(ws, "Log.enable").catch((error) => {
      pushLimited(logEntries, { source: "driver", level: "warning", text: `Log.enable failed: ${String(error)}` });
    });
    const seededCookies = await seedGoogleConsentCookies(ws);
    trace("seeded_cookies", seededCookies);
    const homeUrl = startUrl || (directSearch
      ? (basicSearchMode
        ? `https://www.google.com/search?q=${encodeURIComponent(query)}&gbv=1`
        : `https://www.google.com/search?q=${encodeURIComponent(query)}`)
      : (basicSearchMode
        ? "https://www.google.com/search?gbv=1"
        : "https://www.google.com/webhp"));
    const homeNavigate = await send(
      ws,
      "Page.navigate",
      { url: homeUrl },
      sid,
      Math.min(timeoutMs, 10000),
    ).catch((error) => ({ warning: String(error) }));
    trace("home_navigate", homeNavigate);
    await waitFor((event) => event.method === "Page.loadEventFired", "Google home load").catch(() => {});
    await sleep(2500);

    const consent = acceptConsent ? await dismissConsent(ws) : { clicked: false, skipped: true };
    trace("consent_initial", consent);
    if (consent?.clicked) {
      await waitFor((event) => event.method === "Page.loadEventFired", "post-consent load", 5000).catch(() => {});
      await sleep(2000);
    }

    const before = await pageState(ws);
    trace("before_state", { href: before.href, title: before.title, status: classify(before), hasSearchBox: before.hasSearchBox, activeTag: before.activeTag, activeName: before.activeName });
    if (directSearch) {
      const directStatus = classify(before);
      if (directStatus === "search_results") {
        finish({
          ok: true,
          status: "search_results",
          mode: "direct_basic_search",
          homeNavigate,
          seededCookies,
          consent,
          final: before,
          transientSearchUrl: before.href,
          navigations,
        });
        ws.close();
        return;
      }
      if (directStatus === "google_blocked" || directStatus === "consent") {
        finish({
          ok: false,
          status: directStatus,
          mode: "direct_basic_search",
          homeNavigate,
          seededCookies,
          consent,
          final: before,
          transientSearchUrl: before.href,
          navigations,
        });
        ws.close();
        return;
      }
    }
    if (!before.hasSearchBox) {
      finish({
        ok: false,
        status: "no_search_box",
        homeNavigate,
        seededCookies,
        consent,
        before,
        navigations,
      });
      ws.close();
      return;
    }

    let focused = { ok: false, skipped: false };
    let afterInput = before;
    let submitted = null;
    let submitFallback = null;
    if (consent?.skipped) {
      focused = { ok: false, skipped: true, reason: "consent_skipped_form_navigation" };
      submitFallback = await navigateSearchFromForm(ws, query).catch((error) => ({ ok: false, error: String(error) }));
      trace("consent_skipped_form_navigation", submitFallback);
      if (submitFallback?.ok) {
        submitted = {
          ok: true,
          method: submitFallback.method,
          value: query,
          focused,
          preparedForm: null,
        };
      }
      if (!submitted) {
        finish({
          ok: false,
          status: "form_navigation_failed",
          seededCookies,
          consent,
          before,
          focused,
          submitFallback,
          navigations,
        });
        ws.close();
        return;
      }
    } else {
      focused = await clickSearchBox(ws);
      trace("focused", { ok: focused.ok, reason: focused.reason, activeTag: focused.activeTag, activeName: focused.activeName });
      if (!focused.ok) {
        submitFallback = await navigateSearchFromForm(ws, query).catch((error) => ({ ok: false, error: String(error) }));
        trace("focus_failed_form_navigation", submitFallback);
        if (submitFallback?.ok) {
          submitted = {
            ok: true,
            method: submitFallback.method,
            value: query,
            focused,
            preparedForm: null,
          };
        }
        if (!submitted) {
          finish({
            ok: false,
            status: "focus_failed",
            seededCookies,
            consent,
            before,
            focused,
            submitFallback,
            navigations,
          });
          ws.close();
          return;
        }
      }
    }

    if (focused.ok) {
      await typeSearchQuery(ws, query);
      afterInput = await pageState(ws);
      trace("after_type", { searchBoxValue: afterInput.searchBoxValue, activeName: afterInput.activeName });
      if (afterInput.searchBoxValue !== query) {
        const focusResult = await focusSearchBox(ws);
        focused.fallbackFocus = focusResult;
        if (focusResult?.ok) {
          await typeSearchQuery(ws, query);
          afterInput = await pageState(ws);
        }
      } else if (afterInput.activeName !== "q") {
        focused.fallbackFocus = await focusSearchBox(ws);
        afterInput = await pageState(ws);
      }
      if (afterInput.searchBoxValue !== query) {
        finish({
          ok: false,
          status: "input_failed",
          seededCookies,
          consent,
          before,
          focused,
          afterInput,
          navigations,
        });
        ws.close();
        return;
      }

      const preparedForm = await prepareGoogleFormForSubmit(ws).catch((error) => ({ ok: false, error: String(error) }));
      await pressEnter(ws);
      submitted = {
        ok: true,
        method: "cdp_input_enter",
        value: afterInput.searchBoxValue,
        focused,
        preparedForm,
      };
      trace("enter_submitted", submitted);
    }
    let searchNavigation = await waitFor(
      (event) => event.method === "Page.frameNavigated" && /google\.com\/search/.test(event.params?.frame?.url || ""),
      "Google search navigation",
      Math.min(timeoutMs, 12000),
    ).catch(() => null);
    trace("search_navigation_wait", { found: !!searchNavigation });
    if (!searchNavigation && !submitFallback) {
      submitFallback = await submitSearchForm(ws).catch((error) => ({ ok: false, error: String(error) }));
      trace("submit_fallback", submitFallback);
      if (submitFallback?.ok) {
        searchNavigation = await waitFor(
          (event) => event.method === "Page.frameNavigated" && /google\.com\/search/.test(event.params?.frame?.url || ""),
          "Google search navigation after submit fallback",
          Math.min(timeoutMs, 12000),
        ).catch(() => null);
      }
    }
    if (!searchNavigation && navigations.some((url) => /google\.com\/(?:search|sorry)\//.test(url) || /google\.com\/search/.test(url))) {
      searchNavigation = { synthetic: true };
    }
    if (!searchNavigation) {
      const afterEnter = await pageState(ws).catch((error) => ({ error: String(error) }));
      const afterEnterStatus = classify(afterEnter);
      const transientSearchUrl = navigations.find((url) => /google\.com\/search/.test(url)) || null;
      if (afterEnterStatus === "search_results") {
        finish({
          ok: true,
          status: "search_results",
          homeNavigate,
          seededCookies,
          consent,
          before,
          submitted,
          submitFallback,
          final: afterEnter,
          transientSearchUrl,
          navigations,
        });
        ws.close();
        return;
      }
      if (afterEnterStatus === "google_blocked" || afterEnterStatus === "consent") {
        finish({
          ok: false,
          status: afterEnterStatus,
          homeNavigate,
          seededCookies,
          consent,
          before,
          submitted,
          submitFallback,
          afterInput,
          final: afterEnter,
          transientSearchUrl,
          navigations,
        });
        ws.close();
        return;
      }
      finish({
        ok: false,
        status: "submit_failed",
        seededCookies,
        consent,
        before,
        submitted,
        submitFallback,
        afterInput,
        afterEnter,
        navigations,
      });
      ws.close();
      return;
    }

    const deadline = Date.now() + timeoutMs;
    let lastState = null;
    let lastStatus = "other";
    let transientSearchUrl = null;
    let googleFallback = null;
    let postSubmitConsent = null;
    while (Date.now() < deadline) {
      await sleep(1000);
      lastState = await pageState(ws).catch((error) => ({ error: String(error) }));
      lastStatus = classify(lastState);
      trace("poll_state", { status: lastStatus, href: lastState.href, hasResultStats: lastState.hasResultStats, resultLinkCount: lastState.resultLinkCount });
      transientSearchUrl = navigations.find((url) => /google\.com\/search/.test(url)) || transientSearchUrl;
      if (lastStatus === "search_results") {
        finish({
          ok: true,
          status: "search_results",
          homeNavigate,
          seededCookies,
          consent,
          before,
          submitted,
          final: lastState,
          googleFallback,
          postSubmitConsent,
          transientSearchUrl,
          navigations,
        });
        ws.close();
        return;
      }
      if (lastStatus === "google_fallback" && !googleFallback) {
        googleFallback = await followGoogleFallback(ws).catch((error) => ({ ok: false, error: String(error) }));
        if (googleFallback?.ok) {
          await waitFor((event) => event.method === "Page.loadEventFired", "Google fallback results load", 8000).catch(() => {});
          await sleep(2000);
          continue;
        }
      }
      if (lastStatus === "consent" && !acceptConsent) {
        break;
      }
      if (lastStatus === "consent" && !postSubmitConsent) {
        postSubmitConsent = await dismissConsent(ws).catch((error) => ({ clicked: false, error: String(error) }));
        if (postSubmitConsent?.clicked) {
          await waitFor((event) => event.method === "Page.loadEventFired", "post-search consent load", 8000).catch(() => {});
          await sleep(2000);
          continue;
        }
      }
      if (lastStatus === "google_blocked" || lastStatus === "consent") {
        break;
      }
    }

    finish({
      ok: false,
      status: lastStatus,
      homeNavigate,
      seededCookies,
      consent,
      before,
      submitted,
      final: lastState,
      googleFallback,
      postSubmitConsent,
      transientSearchUrl,
      navigations,
    });
    ws.close();
  } catch (error) {
    finish({
      ok: false,
      status: "driver_error",
      error: String(error && error.stack || error),
      navigations,
    });
    try {
      ws.close();
    } catch {}
  }
}

main();
'@

    Set-Content -LiteralPath $driverScriptPath -Value $driverScript -Encoding UTF8
    Remove-Item -LiteralPath $driverReleasePath -Force -ErrorAction SilentlyContinue

    $driverProcess = Start-Process -FilePath $nodeExe -ArgumentList @($driverScriptPath) -WorkingDirectory $RepoRoot -RedirectStandardOutput $driverStdoutPath -RedirectStandardError $driverStderrPath -PassThru
    $driverDeadline = (Get-Date).AddSeconds([Math]::Max($TimeoutSeconds + 20, 45))
    while ((Get-Date) -lt $driverDeadline) {
        if (Test-Path -LiteralPath $driverResultPath) {
            break
        }
        if ($driverProcess.HasExited) {
            break
        }
        Start-Sleep -Milliseconds 200
    }

    $hwnd = Wait-TabWindowHandle $process.Id 80
    if ($hwnd -ne [IntPtr]::Zero) {
        Show-SmokeWindow $hwnd
        # Keep the CDP page alive while the headed presentation loop catches up
        # to the final DOM state before taking the bounded smoke artifact.
        Start-Sleep -Milliseconds 5000
        Save-WindowCapture -Hwnd $hwnd -Path $finalScreenshotPath
    }

    New-Item -ItemType File -Force -Path $driverReleasePath | Out-Null
    if (-not $driverProcess.WaitForExit(15000)) {
        $driverCmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($driverProcess.Id)").CommandLine
        if ($driverCmdLine -match "codex\.js|@openai/codex") {
            Write-Warning "Refusing to stop protected Codex process $($driverProcess.Id)"
        } else {
            Stop-Process -Id $driverProcess.Id -Force
            $driverProcess.WaitForExit()
        }
    }
    $driverExit = $driverProcess.ExitCode

    if (-not (Test-Path -LiteralPath $driverResultPath)) {
        $driverErr = if (Test-Path -LiteralPath $driverStderrPath) { Get-Content -LiteralPath $driverStderrPath -Raw } else { "" }
        throw "Google CDP smoke did not produce a result file. Driver exit: $driverExit. $driverErr"
    }

    $result = Get-Content -LiteralPath $driverResultPath -Raw | ConvertFrom-Json
    if (-not $result.ok) {
        $transientSearchUrl = if ($result.PSObject.Properties.Name -contains "transientSearchUrl") {
            $result.transientSearchUrl
        } else {
            $null
        }
        $errorText = if ($result.PSObject.Properties.Name -contains "error") {
            " error: $($result.error)"
        } else {
            ""
        }
        $details = if ($transientSearchUrl) { " transient search URL: $transientSearchUrl" } else { "" }
        throw "headed Google search smoke failed with status '$($result.status)'.$details$errorText See $driverResultPath and $finalScreenshotPath"
    }

    $finalScreenshotSize = if (Test-Path -LiteralPath $finalScreenshotPath) {
        (Get-Item -LiteralPath $finalScreenshotPath).Length
    } else {
        0
    }
    Write-Host ("Google headed search smoke passed. Final screenshot: {0} ({1} bytes)" -f $finalScreenshotPath, $finalScreenshotSize)
    Write-Host ("Final URL: {0}" -f $result.final.href)
    Write-Host ("Logs: {0}, {1}, {2}" -f $stdoutPath, $stderrPath, $driverResultPath)
} finally {
    if ($driverProcess -and -not $driverProcess.HasExited) {
        New-Item -ItemType File -Force -Path $driverReleasePath | Out-Null
        if (-not $driverProcess.WaitForExit(5000)) {
            $driverCmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($driverProcess.Id)").CommandLine
            if ($driverCmdLine -match "codex\.js|@openai/codex") {
                Write-Warning "Refusing to stop protected Codex process $($driverProcess.Id)"
            } else {
                Stop-Process -Id $driverProcess.Id -Force
                $driverProcess.WaitForExit()
            }
        }
    }
    if ($process -and -not $process.HasExited) {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($process.Id)").CommandLine
        if ($cmdLine -match "codex\.js|@openai/codex") {
            Write-Warning "Refusing to stop protected Codex process $($process.Id)"
        } else {
            Stop-Process -Id $process.Id -Force
            $process.WaitForExit()
        }
    }
    if ($null -ne $previousTelemetry) {
        $env:LIGHTPANDA_DISABLE_TELEMETRY = $previousTelemetry
    } else {
        Remove-Item Env:LIGHTPANDA_DISABLE_TELEMETRY -ErrorAction SilentlyContinue
    }
    if ($null -ne $previousIpResolve) {
        $env:LIGHTPANDA_IP_RESOLVE = $previousIpResolve
    } else {
        Remove-Item Env:LIGHTPANDA_IP_RESOLVE -ErrorAction SilentlyContinue
    }
    if ($null -ne $previousDisablePageJs) {
        $env:LIGHTPANDA_DISABLE_PAGE_JS = $previousDisablePageJs
    } else {
        Remove-Item Env:LIGHTPANDA_DISABLE_PAGE_JS -ErrorAction SilentlyContinue
    }
    Remove-Item Env:LP_GOOGLE_SMOKE_WS -ErrorAction SilentlyContinue
    Remove-Item Env:LP_GOOGLE_SMOKE_QUERY -ErrorAction SilentlyContinue
    Remove-Item Env:LP_GOOGLE_SMOKE_TIMEOUT_MS -ErrorAction SilentlyContinue
    Remove-Item Env:LP_GOOGLE_SMOKE_RESULT -ErrorAction SilentlyContinue
    Remove-Item Env:LP_GOOGLE_SMOKE_RELEASE -ErrorAction SilentlyContinue
    Remove-Item Env:LP_GOOGLE_SMOKE_DIRECT -ErrorAction SilentlyContinue
    Remove-Item Env:LP_GOOGLE_SMOKE_BASIC -ErrorAction SilentlyContinue
    Remove-Item Env:LP_GOOGLE_SMOKE_ACCEPT_CONSENT -ErrorAction SilentlyContinue
}
