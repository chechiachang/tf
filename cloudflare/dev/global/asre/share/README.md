# abot direct R2 upload

This stack provisions only a private R2 bucket and object lifecycle rule. There is no Worker, workers.dev hostname, public bucket domain, or public read access. abot uploads objects using the bucket's S3-compatible API and returns time-limited presigned GET URLs. Anyone who obtains a URL can read that object until the signature expires (or the object is deleted); treat URLs as bearer credentials.

The default bucket is `tf-asre-share`, located in APAC. Objects expire after one day. Set abot's presigned GET expiry below this retention and below the S3 signature's maximum accepted lifetime. Lifecycle deletion is asynchronous, so it is a retention bound, not a precise deletion deadline.

## Credentials and configuration

Terraform uses the Cloudflare provider's `CLOUDFLARE_API_TOKEN` environment variable and `account_id` input. It does not define, accept, or output S3 credentials. Create an R2 S3 API token separately in Cloudflare for abot and inject its access key ID and secret access key only through abot's protected runtime environment/secret manager. Never place either credential in Terraform variables, outputs, repository files, plans, CI logs, or Terraform state. Rotate/revoke the token independently of this Terraform stack.

Grant the abot token only **Object Read & Write** (needed for PutObject and GetObject signing) on this single bucket, `tf-asre-share`; do not grant bucket administration, list access, access to other buckets, Cloudflare account permissions, or delete permission. Presigned GET uses the same object-scoped signing credentials and consumers do not receive the credentials. Confirm the token supports the S3 operations required by the deployed abot SDK; do not broaden permissions unless a specific failed API operation is understood and reviewed. Keep Cloudflare API token permissions separate and limited to what the Terraform provider needs to manage this bucket and lifecycle configuration.

## Terragrunt

From this directory:

```sh
terragrunt run -- fmt -recursive
terragrunt run -- init
terragrunt run -- validate
terragrunt run -- plan
```

Do not apply without reviewing the plan and securing Terraform state. Outputs disclose only the bucket name, location, and retention period. Provider API tokens are supplied out-of-band through the provider environment; no access keys are stored in Terraform state.
