variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "bucket_name" {
  description = "Private R2 bucket name."
  type        = string
}

variable "location" {
  type    = string
  default = "apac"
}

variable "jurisdiction" {
  type    = string
  default = null
}

variable "storage_class" {
  type    = string
  default = "Standard"
}

variable "object_retention_days" {
  description = "Object expiry in days; null omits lifecycle management."
  type        = number
  default     = null
  validation {
    condition     = var.object_retention_days == null ? true : var.object_retention_days >= 1 && var.object_retention_days <= 365 && floor(var.object_retention_days) == var.object_retention_days
    error_message = "object_retention_days must be a whole number between 1 and 365."
  }
}
