# Terraform Live

Recurring free allowances and official sources live in each provider's `free.csv`: [OCI](oracle/free.csv), [Cloudflare](cloudflare/free.csv), [GCP](gcp/free.csv), [AWS](aws/free.csv), [Azure](azure/free.csv), [GitHub](github/free.csv), [Render](render/free.csv), [Neon](neon/free.csv), [Supabase](supabase/free.csv), [MongoDB](mongodb/free.csv), [Upstash](upstash/free.csv), [Grafana](grafana/free.csv), and [Tailscale](tailscale/free.csv). Paid overages and add-ons can cost extra; trial credits are excluded.

Ready-to-plan stacks: OCI VMs, Cloudflare R2, and [Workers + D1 + KV](cloudflare/dev/global/free/serverless/README.md). Other CSV entries are catalog-only.

Use Terragrunt for all stack operations. Stacks live in `<cloud>/<environment>/<region>/`; OCI is in `oracle/`, and Azure is a submodule at `azure/`.

## OCI authentication and workflow

```sh
oci session authenticate --region ap-osaka-1 --profile-name tf
oci session validate --profile tf --auth security_token
cd oracle/dev/ap-osaka-1/network
terragrunt run -- plan
```

OCI auth settings and tenancy OCID are in `oracle/root.hcl`. Find the OCID under `[tf] tenancy` in `~/.oci/config` or in OCI Console > Tenancy Details. The instance stack reads `~/.ssh/id_rsa.pub`; change its path in `oracle/dev/ap-osaka-1/asre/instance/terragrunt.hcl` if needed. Session auth uses a browser login and short-lived token in `~/.oci/`; refresh with `oci session refresh --profile tf`.

State uses a private, versioned OCI Object Storage bucket. Apply `network` first, then plan `asre/instance` and `asre/mysql`. The A1 instance has no public IP. See [Oracle operations](oracle/README.md) for state, SSH, and firewall instructions.

Initialize the Azure submodule after cloning:

```sh
git submodule update --init --recursive
```

## Cloudflare

The `cloudflare/dev/global/abot/share` Terragrunt stack provisions the private `abot-share` R2 bucket with 90-day lifecycle expiry. See the [stack README](cloudflare/dev/global/abot/share/README.md) for S3 credential handling. The separate free serverless stack provisions a Worker, D1 database, and KV namespace without public routes.
