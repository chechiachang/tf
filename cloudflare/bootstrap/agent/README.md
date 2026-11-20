# Agent planning token

Creates a user-owned token with R2, Workers Scripts, Workers KV, and D1 Read permissions for the account in `cloudflare/root.hcl`. No writes, zone access, or token-management permissions. Permission lookup must return exactly one match per name.

The token **is stored in OCI Terraform state**. Sensitive output only hides normal display. Anyone who can read this state can retrieve the token; restrict state access and do not publish bootstrap plans or outputs.

Bootstrap requires a separate Cloudflare credential with API Tokens Read/Write, supplied privately as `CLOUDFLARE_API_TOKEN`, plus OCI backend credentials. The planning token cannot manage itself.

From this directory:

```sh
export CLOUDFLARE_PLAN_TOKEN_EXPIRES_ON=2027-02-01T00:00:00Z # choose an expiry
terragrunt hcl fmt
terragrunt run -- init -input=false
terragrunt run -- validate
terragrunt run -- plan -input=false
# After reviewing the plan:
terragrunt run -- apply
export CLOUDFLARE_API_TOKEN="$(terragrunt run -- output -raw api_token)"
```

Disable shell tracing before handling credentials. The last command captures the token without printing it; use it in the same terminal for existing Cloudflare stack plans. OCI auth is still required (`make -C oracle auth` from repo root, or existing API-key backend configuration).

Rotate by replacing the token in a reviewed bootstrap plan and delivering the new credential privately. Do not commit saved plans, state, or token values.
