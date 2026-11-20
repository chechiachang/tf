variable "account_id" {
  type = string
}

variable "expires_on" {
  description = "Required token expiry in RFC3339 UTC format."
  type        = string

  validation {
    condition     = can(timecmp(var.expires_on, "2020-01-01T00:00:00Z"))
    error_message = "expires_on must be an RFC3339 timestamp."
  }
}
