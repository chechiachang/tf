variable "compartment_id" {
  description = "Compartment containing the network security group."
  type        = string
}

variable "vcn_id" {
  description = "VCN to associate with the network security group."
  type        = string
}

variable "bastion_private_endpoint_ip" {
  description = "Bastion private endpoint allowed to connect to instances over SSH."
  type        = string
}
