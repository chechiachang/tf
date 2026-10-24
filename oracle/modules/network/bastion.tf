resource "oci_bastion_bastion" "remote_access" {
  bastion_type                 = "STANDARD"
  compartment_id               = oci_identity_compartment.this.id
  target_subnet_id             = module.vcn.subnet_id[var.subnets[var.bastion_target_subnet_key].name]
  client_cidr_block_allow_list = [var.bastion_client_cidr]
  max_session_ttl_in_seconds   = 3600
  name                         = "private-instance-ssh"
}
