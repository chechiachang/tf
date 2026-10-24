variable "auth" {
  description = "OCI provider authentication method."
  type        = string
}

variable "region" {
  description = "OCI region for the network."
  type        = string
}

variable "profile" {
  description = "OCI CLI profile for SecurityToken authentication."
  type        = string
}

variable "tenancy_ocid" {
  description = "Tenancy that owns the compartment."
  type        = string
}

variable "compartment_name" {
  description = "Name of the compartment to create."
  type        = string
}

variable "compartment_description" {
  description = "Description of the compartment to create."
  type        = string
}

variable "vcn_name" {
  description = "Name of the VCN to create."
  type        = string
}

variable "vcn_cidr" {
  description = "IPv4 CIDR for the VCN."
  type        = string
}

variable "subnets" {
  description = "Subnets to create in the VCN, keyed by logical name."
  type = map(object({
    name       = string
    cidr_block = string
    type       = string
  }))
}

variable "bastion_target_subnet_key" {
  description = "Logical subnet key containing the private SSH target."
  type        = string
}

variable "bastion_client_cidr" {
  description = "Operator public IPv4 CIDR allowed to create Bastion sessions; use a single /32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.bastion_client_cidr)) && endswith(var.bastion_client_cidr, "/32")
    error_message = "Set bastion_client_cidr to the operator's public IPv4 address with a /32 mask."
  }
}
