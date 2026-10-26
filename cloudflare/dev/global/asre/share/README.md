# Telegram message share service

Terraform provisions a private R2 bucket and public Workers.dev endpoint. Authenticated text/Markdown uploads receive an unguessable `GET /s/<43-char-token>` URL that serves the rendered message directly. The capability URL allows anyone possessing it to read; it is public-by-link, not authentication. No public R2 endpoint, bucket listing, or browsing route exists. Do not upload secrets, credentials, personal data, or other sensitive content.

The R2 object expires after the configured TTL (default 24 hours; 60 seconds to 7 days), with an hourly cleanup Worker as backstop. Uploads are bounded to 64 KiB by default. The Worker escapes content and sends restrictive CSP, `nosniff`, and no-store headers.

## Provision

Use a Cloudflare API token with Workers Scripts edit and R2 Storage edit permissions. Supply its value, account ID, and a high-entropy bearer upload token in the environment; never commit credentials. The provider reads `CLOUDFLARE_API_TOKEN`; Terraform's secret variable is sensitive, although the state contains the secret binding and must be protected.

```sh
export CLOUDFLARE_API_TOKEN='...'
export TF_VAR_account_id='...'
export TF_VAR_upload_token="$(openssl rand -hex 32)"
terraform init
terraform plan
terraform apply
```

The `worker_url` output is the API base address. For caller integrations, POST raw UTF-8 text with `Content-Type: text/plain` and `Authorization: Bearer <UPLOAD_TOKEN>` to `/api/share`; send the returned `url` verbatim as the message. The exact link renders the content, without a download or extra navigation step.

Do not run Terraform apply except for authorized provisioning. Run unit tests with `npm install && npm test`.
