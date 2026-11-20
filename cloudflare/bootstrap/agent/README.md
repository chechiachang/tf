# Agent plan/apply token

Creates a user-owned token with R2 Storage Write, Workers Scripts Write, Workers KV Storage Write, and D1 Write permissions for the account in `cloudflare/root.hcl`. These cover plan and apply for the existing R2 bucket/lifecycle and Workers/D1/KV stacks. No zone access or token-management permissions. Grants are account-wide for these services, not limited to individual Terraform resources; write grants also permit deletion outside Terraform. Permission lookup must return exactly one match per name.

The token **is stored in OCI Terraform state**. Sensitive output only hides normal display. Anyone who can read this state can retrieve the token; restrict state access and do not publish bootstrap plans or outputs.

Bootstrap requires a separate Cloudflare credential with API Tokens Read/Write, supplied privately as `CLOUDFLARE_API_TOKEN`, plus OCI backend credentials. The agent token cannot manage itself.

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

Disable shell tracing before handling credentials. The last command captures the token without printing it; use it in the same terminal for existing Cloudflare stack plans and reviewed applies. OCI credentials must also permit backend state writes for apply. OCI auth is still required (`make -C oracle auth` from repo root, or existing API-key backend configuration).

Rotate by replacing the token in a reviewed bootstrap plan and delivering the new credential privately. Do not commit saved plans, state, or token values.
