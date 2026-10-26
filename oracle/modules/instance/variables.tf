variable "user_data" {
  description = "Base64-encoded cloud-init configuration for first boot."
  type        = string
  default     = null
}

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

variable "shape" {
  description = "Always Free compute shape."
  type        = string
  default     = "VM.Standard.A1.Flex"

  validation {
    condition     = contains(["VM.Standard.A1.Flex", "VM.Standard.E2.1.Micro"], var.shape)
    error_message = "Use an Always Free A1 or E2 micro shape."
  }
}

variable "instance_count" {
  description = "Number of instances."
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2], var.instance_count)
    error_message = "Create one or two instances."
  }
}

variable "instance_display_name" {
  description = "Instance name prefix."
  type        = string
  default     = "free-arm"
}

variable "boot_volume_size_in_gbs" {
  description = "Boot disk size; Ubuntu requires at least 50 GB."
  type        = number
  default     = 150

  validation {
    condition     = var.boot_volume_size_in_gbs >= 50
    error_message = "Ubuntu boot disks must be at least 50 GB."
  }
}
