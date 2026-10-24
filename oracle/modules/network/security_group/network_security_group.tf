resource "oci_core_network_security_group" "instance" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "instance-private"
}

resource "oci_core_network_security_group" "database" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "database-private"
}
