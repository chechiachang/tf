# R2 share

Private `abot-share`, APAC, protected; 90-day expiry (asynchronous). Presigned URLs are bearer credentials; expire them within seven days (S3 signing limit).
[Login/apply](../../../../README.md). abot needs a separate R2 **Object Read & Write** token scoped to this bucket (includes listing), stored only in runtime secrets.

## A1 Codex credentials

Wrangler OAuth cannot manage API tokens. Bootstrap with a user API token with **API Tokens Read/Write** in `CLOUDFLARE_API_TOKEN` (never paste/log it):

```sh
python3 cloudflare/scripts/create-r2-share-token.py --output /home/agent/codex/.config/r2-share/credentials.env
unset CLOUDFLARE_API_TOKEN
. /home/agent/codex/.config/r2-share/credentials.env
```

Run from repo root. Creates `a1-codex-abot-share`: only **Object Read & Write** on `abot-share`, no bucket administration. Stores S3 credentials outside git/state, mode `0600`; refuses overwrite. Revoke/rotate in Cloudflare R2 → Manage API Tokens. Alternatively create this scoped token there and save the four environment variables locally. Never expose the bootstrap token to the sharing skill.

## Compact skill plan

Add `r2-share/SKILL.md` and `scripts/share.py` to the host's Codex skills directory; keep this Terraform repo responsible only for infrastructure/bootstrap.

- Invoke for responses too long for terminal, or explicit sharing requests. Keep a short summary in terminal.
- Script reads UTF-8 from stdin/file (nonempty, max 1 MiB) and the four `R2_*` variables above; uses `boto3` S3, region `auto`, path-style endpoint, bounded timeouts.
- Upload `codex/responses/<48-random-hex>.txt` as `text/plain; charset=utf-8`, `Cache-Control: no-store`; never make the bucket/object public.
- Print only a presigned GET URL, default one hour, configurable 1–604800 seconds. Agent returns summary, link, and expiry. Link expiry is not object deletion: existing lifecycle deletes objects after 90 days asynchronously.
- No automatic upload of credentials or sensitive content. On failure keep the response local and report the error without credentials/URLs in debug logs.
- Verify upload/read equality, signing expiry, rejected empty/oversized/invalid UTF-8 input, and sanitized errors; then one live upload/read/delete smoke check.

Reference: abot `internal/telegram/r2.go` (random private text objects + S3 presigning). The supplied PR #29 concerns model routing, not R2 sharing. No Worker, public domain, new bucket, or Terraform-managed credential state needed.
