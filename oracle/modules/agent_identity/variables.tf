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

variable "instance_ocid" {
  description = "Exact A1 agent VM; null leaves Instance Principal disabled."
  type        = string
  default     = null

  validation {
    condition     = var.instance_ocid == null ? true : can(regex("^ocid1[.]instance[.]", var.instance_ocid))
    error_message = "Supply an OCI instance OCID."
  }
}
