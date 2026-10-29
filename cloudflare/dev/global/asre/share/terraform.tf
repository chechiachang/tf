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

variable "bucket_name" {
  description = "R2 bucket used by abot uploads."
  type        = string
  default     = "tf-asre-share"
}

variable "object_retention_days" {
  description = "Number of days to retain uploaded objects."
  type        = number
  default     = 1
  validation {
    condition     = var.object_retention_days >= 1 && var.object_retention_days <= 365 && floor(var.object_retention_days) == var.object_retention_days
    error_message = "object_retention_days must be a whole number between 1 and 365."
  }
}

resource "cloudflare_r2_bucket" "shares" {
  account_id = var.account_id
  name       = var.bucket_name
  location   = "APAC"
}

resource "cloudflare_r2_bucket_lifecycle" "shares" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.shares.name

  rules = [{
    id      = "expire-abot-uploads"
    enabled = true
    conditions = {
      prefix = ""
    }
    delete_objects_transition = {
      condition = {
        type    = "Age"
        max_age = var.object_retention_days * 86400
      }
    }
  }]
}

output "bucket_name" {
  description = "Private R2 bucket name for abot direct S3 API uploads."
  value       = cloudflare_r2_bucket.shares.name
}

output "bucket_location" {
  description = "R2 jurisdiction/location for the bucket."
  value       = cloudflare_r2_bucket.shares.location
}

output "object_retention_days" {
  description = "Configured lifecycle retention; presigned URL expiry must not exceed this."
  value       = var.object_retention_days
}
