output "compartment_ocid" {
  description = "OCID of the created compartment."
  value       = oci_identity_compartment.this.id
}

output "subnet_ocids" {
  description = "Subnet OCIDs keyed by the logical subnet keys from var.subnets."
  value = {
    for key, subnet in var.subnets : key => module.vcn.subnet_id[subnet.name]
  }
}

output "instance_nsg_ocid" {
  description = "OCID of the private instance network security group."
  value       = module.instance_security_group.id
}

output "database_nsg_ocid" {
  description = "OCID of the private MySQL database network security group."
  value       = module.instance_security_group.database_id
}

output "bastion_ocid" {
  description = "OCID of the OCI Bastion used for short-lived SSH sessions."
  value       = oci_bastion_bastion.remote_access.id
}

output "bastion_private_endpoint_ip" {
  description = "Private endpoint IP allowed by the instance NSG for SSH."
  value       = oci_bastion_bastion.remote_access.private_endpoint_ip_address
}
