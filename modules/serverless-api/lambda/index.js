'use strict';

exports.handler = async (event) => {
  const headers = event.headers || {};
  const accept = headers.accept || headers.Accept || '';
  const path = event.rawPath || '/';
  const method =
    (event.requestContext && event.requestContext.http && event.requestContext.http.method) ||
    'GET';
  const time = new Date().toISOString();
  const reqId = (event.requestContext && event.requestContext.requestId) || 'n/a';
  const ua = headers['user-agent'] || headers['User-Agent'] || 'unknown';

  const wantsJson =
    accept.includes('application/json') ||
    path.endsWith('.json') ||
    path.startsWith('/api/');
  const wantsHtml = accept.includes('text/html');

  if (wantsJson || (!wantsHtml && accept !== '')) {
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-store',
      },
      body: JSON.stringify({
        message: 'Hello from Lambda!',
        path,
        method,
        time,
        requestId: reqId,
        userAgent: ua,
      }),
    };
  }

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
    },
    body: renderPage({ path, method, time, reqId, ua }),
  };
};

function esc(s) {
  return String(s).replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c])
  );
}

function renderPage({ path, method, time, reqId, ua }) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Hangar API — Live</title>
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Ctext y='.9em' font-size='90'%3E%E2%9A%A1%3C/text%3E%3C/svg%3E" />
<style>
  *,*::before,*::after { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
    color: #e7ecf4;
    background: #07111c;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 32px 16px;
    overflow-x: hidden;
  }
  body::before {
    content: "";
    position: fixed; inset: 0;
    background:
      radial-gradient(60% 50% at 80% 10%, rgba(45,212,191,.30), transparent 60%),
      radial-gradient(50% 40% at 10% 80%, rgba(56,189,248,.22), transparent 60%),
      radial-gradient(40% 40% at 50% 50%, rgba(132,204,22,.12), transparent 60%);
    z-index: -1;
    animation: drift 20s ease-in-out infinite alternate;
  }
  @keyframes drift {
    from { transform: translate3d(0,0,0); }
    to   { transform: translate3d(30px, -20px, 0); }
  }
  main { width: 100%; max-width: 920px; }
  .card {
    background: rgba(15, 23, 35, 0.6);
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 20px;
    padding: 40px 36px;
    backdrop-filter: blur(14px);
    -webkit-backdrop-filter: blur(14px);
    box-shadow: 0 30px 80px rgba(0,0,0,0.45);
  }
  .badge {
    display: inline-flex; align-items: center; gap: 8px;
    background: rgba(45, 212, 191, 0.12);
    border: 1px solid rgba(45, 212, 191, 0.4);
    color: #5eead4;
    padding: 6px 12px;
    border-radius: 999px;
    font-size: 13px; font-weight: 500;
  }
  .badge::before {
    content: ""; width: 8px; height: 8px; border-radius: 50%;
    background: #2dd4bf; box-shadow: 0 0 10px #2dd4bf;
    animation: pulse 1.6s ease-in-out infinite;
  }
  @keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: 0.4; } }
  h1 {
    font-size: clamp(30px, 5vw, 44px);
    margin: 18px 0 8px;
    letter-spacing: -0.02em;
    background: linear-gradient(135deg, #fff 0%, #5eead4 100%);
    -webkit-background-clip: text; background-clip: text; color: transparent;
  }
  p.lede {
    font-size: 16px; line-height: 1.6; color: #b5bdcc;
    margin: 0 0 24px; max-width: 62ch;
  }
  p.lede code, .inline {
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    background: rgba(255,255,255,0.06);
    padding: 1px 6px; border-radius: 4px; font-size: 14px;
  }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 12px; margin: 18px 0 24px;
  }
  .stat {
    background: rgba(255,255,255,0.03);
    border: 1px solid rgba(255,255,255,0.06);
    border-radius: 12px; padding: 12px 14px;
  }
  .stat .label {
    font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em;
    color: #7c869b; margin-bottom: 4px;
  }
  .stat .value {
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size: 13px; color: #e7ecf4; word-break: break-word;
  }
  .method-GET { color: #5eead4; }
  .method-POST { color: #fbbf24; }
  .method-PUT, .method-PATCH { color: #c084fc; }
  .method-DELETE { color: #f87171; }
  .arch {
    background: rgba(0,0,0,0.4);
    border: 1px solid rgba(255,255,255,0.06);
    border-radius: 12px; padding: 16px;
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size: 13px; line-height: 1.55; color: #b8c1d2;
    white-space: pre; overflow-x: auto; margin: 6px 0 24px;
  }
  .arch .ok { color: #5eead4; }
  .arch .lbl { color: #7dd3fc; }
  h2 {
    font-size: 14px; text-transform: uppercase; letter-spacing: 0.1em;
    color: #94a3b8; margin: 28px 0 12px;
  }
  .row { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
  button, a.btn {
    display: inline-flex; align-items: center; gap: 8px;
    padding: 9px 14px; border-radius: 9px;
    border: 1px solid rgba(255,255,255,0.12);
    background: rgba(255,255,255,0.04);
    color: #e7ecf4; text-decoration: none; cursor: pointer;
    font-size: 13px; font-family: inherit;
    transition: transform .12s ease, background .12s ease, border-color .12s ease;
  }
  button:hover, a.btn:hover {
    background: rgba(255,255,255,0.08);
    border-color: rgba(255,255,255,0.22);
    transform: translateY(-1px);
  }
  button.primary {
    background: rgba(45, 212, 191, 0.15);
    border-color: rgba(45, 212, 191, 0.4);
    color: #5eead4;
  }
  button.primary:hover { background: rgba(45, 212, 191, 0.22); }
  pre.json {
    background: rgba(0,0,0,0.45);
    border: 1px solid rgba(255,255,255,0.07);
    border-radius: 10px; padding: 16px;
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size: 13px; line-height: 1.55; color: #c4d2e3;
    overflow-x: auto; margin: 0; min-height: 60px;
    white-space: pre-wrap; word-break: break-word;
  }
  pre.json .key { color: #7dd3fc; }
  pre.json .str { color: #5eead4; }
  pre.json .num { color: #fbbf24; }
  footer {
    margin-top: 18px; color: #7c869b;
    font-size: 12px; text-align: center;
  }
  footer code {
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace; color: #b5bdcc;
  }
</style>
</head>
<body>
<main>
  <div class="card">
    <span class="badge">Live on API Gateway + Lambda</span>
    <h1>Your serverless API is up.</h1>
    <p class="lede">
      This page was rendered <strong>by the Lambda function itself</strong>. The same endpoint also returns JSON
      when you set <code>Accept: application/json</code> or hit a <code>/api/*</code> path. The Lambda runs only when
      a request arrives, then scales back to zero — you pay per invocation.
    </p>

    <div class="grid">
      <div class="stat">
        <div class="label">Request path</div>
        <div class="value"><span class="inline">${esc(path)}</span></div>
      </div>
      <div class="stat">
        <div class="label">Method</div>
        <div class="value method-${esc(method)}">${esc(method)}</div>
      </div>
      <div class="stat">
        <div class="label">Lambda time (UTC)</div>
        <div class="value">${esc(time)}</div>
      </div>
      <div class="stat">
        <div class="label">Request ID</div>
        <div class="value">${esc(reqId)}</div>
      </div>
    </div>

    <div class="arch"><span class="lbl">browser</span>
   │  HTTPS
   ▼
<span class="lbl">API Gateway</span>  <span class="ok">✓ HTTP API</span>  <span class="ok">✓ \$default</span>
   │  AWS_PROXY (payload v2)
   ▼
<span class="lbl">Lambda</span>       <span class="ok">✓ Node 20.x</span>  <span class="ok">✓ basic exec role</span>
   │
   ▼
<span class="lbl">CloudWatch Logs</span>  /aws/lambda/...</div>

    <h2>Try the JSON API</h2>
    <p class="lede" style="margin-bottom:12px">
      Same Lambda, same URL — but we ask for JSON via the <code>Accept</code> header.
      Click a button to fire a <code>fetch()</code> from your browser.
    </p>
    <div class="row" style="margin-bottom:12px">
      <button class="primary" data-method="GET" data-path="/">GET /</button>
      <button data-method="GET" data-path="/api/users/42">GET /api/users/42</button>
      <button data-method="POST" data-path="/api/echo">POST /api/echo</button>
      <button data-method="DELETE" data-path="/api/widgets/9">DELETE /api/widgets/9</button>
    </div>
    <pre class="json" id="out">// Click a button above to fire a request.</pre>
  </div>

  <footer>
    Provisioned by Terraform · <code>terraform destroy</code> when done · request id <code>${esc(reqId)}</code>
  </footer>
</main>

<script>
  function syntaxHighlight(json) {
    json = json
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    return json.replace(
      /("(\\\\u[a-fA-F0-9]{4}|\\\\[^u]|[^\\\\"])*"(\\s*:)?|\\b(true|false|null)\\b|-?\\d+(?:\\.\\d*)?(?:[eE][+\\-]?\\d+)?)/g,
      (m) => {
        let cls = 'num';
        if (/^"/.test(m)) cls = /:$/.test(m) ? 'key' : 'str';
        else if (/true|false|null/.test(m)) cls = 'num';
        return '<span class="' + cls + '">' + m + '</span>';
      }
    );
  }

  const out = document.getElementById('out');
  document.querySelectorAll('button[data-method]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const method = btn.dataset.method;
      const url = btn.dataset.path;
      out.textContent = 'Loading ' + method + ' ' + url + ' ...';
      const t0 = performance.now();
      try {
        const opts = {
          method,
          headers: { 'Accept': 'application/json' },
        };
        if (method !== 'GET' && method !== 'DELETE') {
          opts.headers['Content-Type'] = 'application/json';
          opts.body = JSON.stringify({ hello: 'lambda', sentAt: new Date().toISOString() });
        }
        const r = await fetch(url, opts);
        const ms = Math.round(performance.now() - t0);
        const text = await r.text();
        let pretty = text;
        try { pretty = JSON.stringify(JSON.parse(text), null, 2); } catch (e) {}
        out.innerHTML =
          '<span class="key">' + method + ' ' + url + '</span>  ' +
          '<span class="num">' + r.status + '</span>  ' +
          '<span class="str">' + ms + 'ms</span>\\n\\n' +
          syntaxHighlight(pretty);
      } catch (err) {
        out.textContent = 'Error: ' + err.message;
      }
    });
  });
</script>
</body>
</html>`;
}
