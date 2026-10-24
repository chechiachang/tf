module "instance_security_group" {
  source = "./security_group"

  compartment_id              = oci_identity_compartment.this.id
  vcn_id                      = module.vcn.vcn_id
  bastion_private_endpoint_ip = oci_bastion_bastion.remote_access.private_endpoint_ip_address
}
