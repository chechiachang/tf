variable "account_id" {
  description = "Cloudflare account on Workers Free; token supplied through CLOUDFLARE_API_TOKEN."
  type        = string
}

variable "name" {
  description = "Unique prefix for the Worker, database, and namespace."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,39}$", var.name))
    error_message = "name must be 1–40 lowercase letters, digits, or hyphens, starting with a letter."
  }
}
