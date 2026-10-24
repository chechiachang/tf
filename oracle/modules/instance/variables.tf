variable "region" {
  description = "OCI region for this stack."
  type        = string
}

variable "profile" {
  description = "Profile in the local OCI CLI configuration."
  type        = string
  default     = "DEFAULT"
}

variable "auth" {
  description = "OCI provider authentication method."
  type        = string
  default     = "SecurityToken"
}

variable "tenancy_ocid" {
  description = "Tenancy OCID used to look up the platform image."
  type        = string

  validation {
    condition     = length(trimspace(var.tenancy_ocid)) > 0
    error_message = "Set tenancy_ocid in oracle/root.hcl from the [tf] tenancy value in ~/.oci/config."
  }
}

variable "compartment_ocid" {
  description = "Compartment created by the network stack."
  type        = string
}

variable "subnet_ocid" {
  description = "Private subnet created by the network stack."
  type        = string
}

variable "network_security_group_ocid" {
  description = "Network security group attached to the instance primary VNIC."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key installed on the instance."
  type        = string

  validation {
    condition     = length(trimspace(var.ssh_public_key)) > 0
    error_message = "The SSH public key file configured in the instance stack must exist; never use a private key."
  }
}
