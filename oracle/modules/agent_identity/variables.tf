variable "auth" {
  type = string
}

variable "profile" {
  type = string
}

variable "region" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "compartment_ocid" {
  description = "Existing dev compartment; this identity cannot create compartments."
  type        = string
}

variable "bucket_name" {
  type = string
}

variable "public_key" {
  description = "RSA public key PEM generated outside Terraform. Never supply a private key."
  type        = string
  validation {
    condition     = startswith(trimspace(var.public_key), "-----BEGIN PUBLIC KEY-----") && endswith(trimspace(var.public_key), "-----END PUBLIC KEY-----") && !strcontains(var.public_key, "PRIVATE KEY")
    error_message = "Supply only an RSA public key PEM, not a private key."
  }
}
