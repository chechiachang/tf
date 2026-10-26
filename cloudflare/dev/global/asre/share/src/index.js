const MAX_BYTES = 65536;
const MAX_TTL = 7 * 24 * 60 * 60;
const MIN_TTL = 60;
const TOKEN_RE = /^[A-Za-z0-9_-]{43}$/;

function response(body, status, contentType = "text/plain; charset=utf-8") {
  return new Response(body, {
    status,
    headers: {
      "Content-Type": contentType,
      "Cache-Control": "no-store, private",
      "X-Content-Type-Options": "nosniff",
      "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
      "Referrer-Policy": "no-referrer",
      "X-Frame-Options": "DENY",
      "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
    },
  });
}

function htmlEscape(value) {
  return value.replace(/[&<>"']/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[character]);
}

function boundedInteger(value, fallback, min, max) {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed >= min && parsed <= max ? parsed : fallback;
}

async function createToken() {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function handle(request, env) {
  const url = new URL(request.url);
  const maxBytes = boundedInteger(env.MAX_UPLOAD_BYTES, MAX_BYTES, 1, MAX_BYTES);
  const ttl = boundedInteger(env.TTL_SECONDS, 86400, MIN_TTL, MAX_TTL);

  if (url.pathname === "/api/share" && request.method === "POST") {
    if (!env.UPLOAD_TOKEN || request.headers.get("Authorization") !== `Bearer ${env.UPLOAD_TOKEN}`) {
      return response("Unauthorized", 401);
    }
    const declared = Number(request.headers.get("Content-Length"));
    if (!Number.isSafeInteger(declared) || declared < 0 || declared > maxBytes) return response("Payload too large", 413);
    const type = (request.headers.get("Content-Type") || "").split(";", 1)[0].trim().toLowerCase();
    if (type !== "text/plain" && type !== "text/markdown") return response("Use text/plain or text/markdown", 415);

    const text = await request.text();
    const bytes = new TextEncoder().encode(text);
    if (bytes.byteLength > maxBytes) return response("Payload too large", 413);
    if (bytes.byteLength === 0) return response("Empty content", 400);

    const token = await createToken();
    const expiresAt = Date.now() + ttl * 1000;
    await env.SHARES.put(token, text, {
      expiration: Math.floor(expiresAt / 1000),
      httpMetadata: { contentType: "text/plain; charset=utf-8" },
      customMetadata: { expiresAt: String(expiresAt) },
    });
    return response(JSON.stringify({ url: `${url.origin}/s/${token}`, expires_at: new Date(expiresAt).toISOString() }), 201, "application/json; charset=utf-8");
  }

  const match = url.pathname.match(/^\/s\/([^/]+)$/);
  if (match && request.method === "GET") {
    if (!TOKEN_RE.test(match[1])) return response("Not found", 404);
    const object = await env.SHARES.get(match[1]);
    if (!object || Number(object.customMetadata?.expiresAt || 0) <= Date.now()) return response("Not found or expired", 404);
    const text = await object.text();
    const title = htmlEscape("Shared text");
    const body = `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>${title}</title><style>body{font:16px/1.5 system-ui,sans-serif;max-width:72rem;margin:2rem auto;padding:0 1rem}pre{white-space:pre-wrap;overflow-wrap:anywhere}</style><h1>${title}</h1><pre>${htmlEscape(text)}</pre></html>`;
    return response(body, 200, "text/html; charset=utf-8");
  }
  if (url.pathname === "/health" && request.method === "GET") return response("ok", 200);
  return response("Not found", 404);
}

export default {
  async fetch(request, env) {
    try {
      return await handle(request, env);
    } catch {
      return response("Internal server error", 500);
    }
  },
  async scheduled(_event, env, ctx) {
    ctx.waitUntil(cleanup(env));
  },
};

async function cleanup(env) {
  const now = Date.now();
  let cursor;
  do {
    const page = await env.SHARES.list({ cursor, limit: 1000 });
    for (const key of page.objects) {
      if (Number(key.customMetadata?.expiresAt || 0) <= now) await env.SHARES.delete(key.key);
    }
    cursor = page.truncated ? page.cursor : undefined;
  } while (cursor);
}
