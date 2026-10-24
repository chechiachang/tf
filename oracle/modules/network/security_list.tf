moved {
  from = module.vcn.oci_core_default_security_list.lockdown[0]
  to   = oci_core_default_security_list.private_access
}

resource "oci_core_default_security_list" "private_access" {
  manage_default_resource_id = module.vcn.default_security_list_id
  display_name               = "private-bastion-egress"

  egress_security_rules {
    description      = "Allow the Bastion private endpoint to reach private SSH targets."
    destination      = var.subnets[var.bastion_target_subnet_key].cidr_block
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = false

    tcp_options {
      min = 22
      max = 22
    }
  }
}
