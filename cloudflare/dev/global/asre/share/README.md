# Cloudflare message share service

This module provisions a private R2 bucket and a public Workers.dev endpoint. `POST /api/share` requires `Authorization: Bearer <UPLOAD_TOKEN>`; it stores bounded UTF-8 plain text/Markdown. The response is a long capability URL (`GET /s/<43-char-random-token>`) that displays the message directly, without a download or secondary lookup. Anyone holding the URL can read it. There is no public R2 endpoint, directory listing, or browsing route; tokenized objects are only fetched through the Worker. Do not upload secrets, credentials, personal data, or any other sensitive content. This is public-by-link, not authentication or access control.

Objects expire in R2 at the configured TTL and an hourly scheduled Worker removes stale objects. The handler independently refuses expired records. Default expiry is 24 hours, configurable between 60 seconds and 7 days. Upload size defaults to 64 KiB and can only be reduced. Responses use escaped HTML, restrictive CSP, `nosniff`, and no-store headers.

## Provisioning

Terraform uses the Cloudflare provider and deploys `src/index.js` as a module Worker with an R2 binding, Workers.dev subdomain, and hourly cron trigger. Choose the API token and account ID outside the repository; the token requires account Workers Scripts edit and R2 storage edit permissions. Supply the credentials only to Terraform's environment:

```sh
export CLOUDFLARE_API_TOKEN='...'
export TF_VAR_account_id='...'
export TF_VAR_upload_token="$(openssl rand -hex 32)"
cd cloudflare/dev/global/asre/share
terraform init
terraform plan
terraform apply
```

Do not put secret values in committed tfvars, CI logs, outputs, or source control. Terraform marks secret variables sensitive, but Terraform state contains the Worker secret binding and must be stored with restricted access. `worker_url` is the public `https://<worker>.<account>.workers.dev` base; send the URL returned from the authenticated upload request as the message reply. No custom domain is necessary, keeping setup independent of a zone.

Run the Worker unit tests with `npm install && npm test` from this directory. Do not run apply except in an explicitly authorized deployment.
