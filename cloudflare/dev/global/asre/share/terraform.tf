terraform {
  required_version = ">= 1.9.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "cloudflare" {
  # CLOUDFLARE_API_TOKEN is read from the environment by the provider.
}

variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "worker_name" {
  description = "Worker name, also used as the R2 bucket name."
  type        = string
  default     = "tf-asre-share"
}

variable "ttl_seconds" {
  description = "Message lifetime in seconds (60 seconds to 7 days)."
  type        = number
  default     = 86400
  validation {
    condition     = var.ttl_seconds >= 60 && var.ttl_seconds <= 604800 && floor(var.ttl_seconds) == var.ttl_seconds
    error_message = "ttl_seconds must be a whole number between 60 and 604800."
  }
}

variable "max_upload_bytes" {
  description = "Maximum text upload size in bytes (1 through 65536)."
  type        = number
  default     = 65536
  validation {
    condition     = var.max_upload_bytes >= 1 && var.max_upload_bytes <= 65536 && floor(var.max_upload_bytes) == var.max_upload_bytes
    error_message = "max_upload_bytes must be a whole number between 1 and 65536."
  }
}

variable "upload_token" {
  description = "Caller bearer token. Inject via TF_VAR_upload_token; never commit it."
  type        = string
  sensitive   = true
}

# Source is retained for possible future use, but infrastructure is intentionally
# disabled by default. Setting this true explicitly opts in to provisioning it.
variable "enable_share_infrastructure" {
  description = "Opt in to provisioning the share R2 bucket and public Worker. Disabled by default."
  type        = bool
  default     = false
}

resource "cloudflare_r2_bucket" "shares" {
  count      = var.enable_share_infrastructure ? 1 : 0
  account_id = var.account_id
  name       = var.worker_name
  location   = "APAC"
}

resource "cloudflare_workers_script" "share" {
  count              = var.enable_share_infrastructure ? 1 : 0
  account_id         = var.account_id
  script_name        = var.worker_name
  content            = file("${path.module}/src/index.js")
  compatibility_date = "2026-10-26"
  main_module        = "index.js"
  bindings = [
    {
      name        = "SHARES"
      type        = "r2_bucket"
      bucket_name = cloudflare_r2_bucket.shares[0].name
    },
    {
      name = "MAX_UPLOAD_BYTES"
      type = "plain_text"
      text = tostring(var.max_upload_bytes)
    },
    {
      name = "TTL_SECONDS"
      type = "plain_text"
      text = tostring(var.ttl_seconds)
    },
    {
      name = "UPLOAD_TOKEN"
      type = "secret_text"
      text = var.upload_token
    }
  ]
}

resource "cloudflare_workers_script_subdomain" "share" {
  count       = var.enable_share_infrastructure ? 1 : 0
  account_id  = var.account_id
  script_name = cloudflare_workers_script.share[0].script_name
  enabled     = true
}

resource "cloudflare_workers_cron_trigger" "cleanup" {
  count       = var.enable_share_infrastructure ? 1 : 0
  account_id  = var.account_id
  script_name = cloudflare_workers_script.share[0].script_name
  schedules   = [{ cron = "17 * * * *" }]
}

output "worker_url" {
  description = "Public upload API and unguessable, expiring capability URLs."
  value       = var.enable_share_infrastructure ? "https://${cloudflare_workers_script.share[0].script_name}.${var.account_id}.workers.dev" : null
}

output "bucket_name" {
  description = "Private R2 bucket used by the Worker (not directly publicly accessible)."
  value       = var.enable_share_infrastructure ? cloudflare_r2_bucket.shares[0].name : null
}
