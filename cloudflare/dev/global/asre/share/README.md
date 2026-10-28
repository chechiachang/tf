# abot direct R2 upload

This stack provisions only a private R2 bucket and object lifecycle rule. There is no Worker, workers.dev hostname, public bucket domain, or public read access. abot uploads objects using the bucket's S3-compatible API and returns time-limited presigned GET URLs. Anyone who obtains a URL can read that object until the signature expires (or the object is deleted); treat URLs as bearer credentials.

The default bucket is `tf-asre-share`, located in APAC. Objects expire after one day. Set abot's presigned GET expiry below this retention and below the S3 signature's maximum accepted lifetime. Lifecycle deletion is asynchronous, so it is a retention bound, not a precise deletion deadline.

## Credentials and configuration

Terraform uses the Cloudflare provider's `CLOUDFLARE_API_TOKEN` environment variable and `account_id` input. It does not define, accept, or output S3 credentials. Create an R2 S3 API token separately in Cloudflare for abot and inject its access key ID and secret access key only through abot's protected runtime environment/secret manager. Never place either credential in Terraform variables, outputs, repository files, plans, CI logs, or Terraform state. Rotate/revoke the token independently of this Terraform stack.

For abot, create an R2 API token with the **Object Read & Write** preset scoped to the single bucket `tf-asre-share` (or the exact configured bucket name). This is the least-privilege preset Cloudflare provides for the required object uploads and downloads: Cloudflare's preset also includes object listing (`ListBucket`), so it is not accurate to claim that listing is denied. The preset does not grant bucket administration, access to other buckets, or Cloudflare account permissions. Cloudflare does not offer a narrower preset that permits PutObject/GetObject while excluding ListBucket; accept that included permission rather than granting broader bucket/account access. Presigned GET uses the same token credentials to sign requests, and consumers do not receive those credentials. Keep the Cloudflare API token used by Terraform separate and limited to what the provider needs to manage this bucket and lifecycle configuration.

## Terragrunt

From this directory:

```sh
terragrunt run -- fmt -recursive
terragrunt run -- init
terragrunt run -- validate
terragrunt run -- plan
```

Do not apply without reviewing the plan and securing Terraform state. Outputs disclose only the bucket name, location, and retention period. Provider API tokens are supplied out-of-band through the provider environment; no access keys are stored in Terraform state.
