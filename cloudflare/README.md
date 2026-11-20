# Cloudflare

[Free serverless](dev/global/free/serverless/README.md): Worker compute, D1 SQL, and KV storage, with public endpoints disabled. [Free-service limits](free.csv).

State: existing OCI `chechia-terraform-state`, profile `tf`; keys `cloudflare/<stack>/terraform.tfstate`. No R2 state credentials.

From repo root:

```sh
make -C oracle auth
unset CLOUDFLARE_API_TOKEN CLOUDFLARE_API_KEY CLOUDFLARE_EMAIL
npx wrangler login
export CLOUDFLARE_API_TOKEN="$(npx wrangler auth token --json | jq -er '.token')"
cd cloudflare/dev/global/abot/share
terragrunt hcl fmt
terragrunt run -- init
terragrunt run -- validate
terragrunt run -- plan
terragrunt run -- apply
```

Review before apply. Refresh OAuth by unsetting and exporting the token again. Existing state: back up and use `init -migrate-state`, not `-reconfigure`. Never commit credentials or state.

CI: dispatch `Cloudflare Terragrunt` on `main`; apply requires `APPLY` and configured `cloudflare-production` environment approvals. Set environment variables `OCI_TENANCY_OCID`, `OCI_SESSION_FINGERPRINT` and secrets `OCI_SESSION_PRIVATE_KEY`, `OCI_SESSION_TOKEN`, `CLOUDFLARE_API_TOKEN`. Supply a fresh OCI session token and its matching PEM private key/fingerprint before dispatch; the workflow cannot refresh the session. Plan artifacts contain state data; restrict access.

## Remote agent

Wrangler 4.165.0 supports device login: approve the displayed URL/code on your phone; no callback tunnel or session upload. A separate Cloudflare token bootstrap is not needed for these stacks.

```sh
unset CLOUDFLARE_API_TOKEN CLOUDFLARE_API_KEY CLOUDFLARE_EMAIL
npx wrangler@4.165.0 login --device
export CLOUDFLARE_API_TOKEN="$(npx wrangler@4.165.0 auth token --json | jq -er '.token')"
export OCI_TF_AUTH=InstancePrincipal # on the configured A1 VM after IAM bootstrap
cd cloudflare/dev/global/abot/share
terragrunt hcl fmt
terragrunt run -- init -input=false
terragrunt run -- validate
terragrunt run -- plan -input=false -lock=false
```

Disable shell tracing before handling credentials. Wrangler stores OAuth credentials locally, outside Terraform state; do not print or commit them. Re-export after refresh. Default OAuth scopes are broader than a custom minimal token; they are user/account-authorized, not stack-scoped.

The OCI planning identities (API-key fallback and exact-VM Instance Principal) grant read access to the exact state keys for `abot/share` and `free/serverless`, not bootstrap state. Apply the reviewed OCI identity-policy update with an authorized administrator before retrying plans. These identities cannot write state or locks: use `-lock=false` for plans only; applies require separate state-write/lock credentials and review. Existing `make -C oracle auth` remains supported.
