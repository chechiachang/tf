# Cloudflare

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
