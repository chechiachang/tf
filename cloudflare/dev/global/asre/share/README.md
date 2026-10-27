# Telegram message share service

Terraform contains the Worker and R2 configuration, but `enable_share_infrastructure` defaults to `false`; a normal plan provisions nothing. The source is retained, but the public Workers.dev API, scheduled cleanup Worker, and backing bucket will not be created unless provisioning is deliberately opted into. Serverless Workers have no VM scaling setting to disable. Any existing deployment is not automatically removed by this default; inspect state and explicitly destroy existing resources if required.

## Manual Terragrunt workflow

`.github/workflows/cloudflare-terragrunt.yml` runs only through `workflow_dispatch` on `feat/cloudflare-share-terraform-ci`. Select `plan` to create a short-lived plan artifact. Apply requires selecting `apply`, typing `APPLY`, and approval in the GitHub `cloudflare-production` environment. Configure that environment with required reviewers and prevent self-review. The job applies from configuration, not the plan artifact; review a fresh plan before approving apply. The default infrastructure flag remains false, so apply does not provision the Worker unless the config is deliberately changed and reviewed.

Configure these repository/environment settings:

- Secret `CLOUDFLARE_API_TOKEN`: scoped to only the target Cloudflare account. Cloudflare resource docs specify **Workers Scripts: Read and Write** for the script, workers.dev subdomain, and cron trigger; **Workers R2 Storage: Write** for the bucket. Do not grant account-wide admin or DNS permissions. A plan-only token needs Workers Scripts and R2 read permissions, but the workflow uses one environment-protected token for both.
- Secret `CLOUDFLARE_UPLOAD_TOKEN`: high-entropy future caller bearer token, only required if the Worker is deliberately enabled. Do not reuse it as the API token.
- Variable `CLOUDFLARE_ACCOUNT_ID`: target Cloudflare account ID.
- Create the GitHub environment named `cloudflare-production`, add required reviewers, and disable administrator/self-review bypass where available. No separate GitHub write permission is granted to jobs.

Cloudflare Workers deployment uses account-scoped Workers Scripts permissions. The script uses a Workers.dev subdomain and cron trigger; confirm account-level Workers Scripts edit covers those operations for your account. No zone/DNS permissions are needed. Protect Terraform state and any backend credentials if a remote backend is configured.

For local authorized provisioning only, set `enable_share_infrastructure = true` deliberately. The Terraform `upload_token` variable is sensitive, but Terraform state may contain the binding and must be protected.

The share API accepts raw UTF-8 text via `POST /api/share`, `Content-Type: text/plain`, and `Authorization: Bearer <UPLOAD_TOKEN>`. It returns an unguessable, expiring `/s/<token>` capability URL that can be read by anyone possessing it. Do not upload secrets, credentials, personal data, or other sensitive content. Uploads are bounded to 64 KiB by default and expire after 24 hours, with hourly cleanup as a backstop.

Run the Worker unit tests with `npm install && npm test`.
