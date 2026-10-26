# Telegram long-response share worker

Text-only `POST /api/share` returns an unguessable public capability URL at `GET /s/<43-char-random-token>`. Uploads require bearer authentication, allow `text/plain`/`text/markdown`, and are limited to 64 KiB. Content expires after 24 hours (configurable up to 7 days). Possession of the URL grants access; it is not user authentication. Never upload credentials or content requiring access control.

## Deploy

Requires Node/npm and Wrangler. From this directory:

```sh
npm install
npx wrangler r2 bucket create tf-asre-share
npx wrangler secret put UPLOAD_TOKEN
npm test
npx wrangler deploy
```

Set a long random `UPLOAD_TOKEN`; keep it only in protected caller configuration. `MAX_UPLOAD_BYTES` and `TTL_SECONDS` in `wrangler.toml` may be lowered/adjusted within enforced limits. Object expiration is set at write time; a scheduled Worker also deletes expired entries hourly. Monitor usage and configure billing alerts. Cloudflare pricing, limits and free allowances change; check [`cloudflare/free.csv`](../../../free.csv) and the linked official documentation before relying on any figure.

`dev/global/asre` is the repository's organizational path, not a Cloudflare location. Workers run on Cloudflare's global edge network; conventional region selection/pinning is not available. R2 placement follows Cloudflare's storage model rather than OCI-style region selection.

## Telegram caller protocol

After normalizing the final Telegram response to UTF-8 text, the Telegram caller (e.g. Sumire) decides when it exceeds its own message limit. Send the entire text as raw UTF-8 `text/plain` with `Authorization: Bearer <UPLOAD_TOKEN>` to `POST https://<worker-host>/api/share`. On `201`, read JSON `{ "url": "...", "expires_at": "..." }` and send `url` as the Telegram reply instead of the oversized response. On errors, follow the caller's existing split/truncate fallback. Never log or expose the upload token. This service requires no Sumire changes; no SDK/protocol beyond the HTTP contract is assumed.
