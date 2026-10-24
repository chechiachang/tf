resource "oci_identity_policy" "mysql_network_access" {
  compartment_id = var.tenancy_ocid
  name           = "${var.compartment_name}-mysql-network-access"
  description    = "Allow MySQL DB systems in ${var.compartment_name} to attach VNICs to private database subnets and NSGs."

  statements = [
    "Allow any-user to {NETWORK_SECURITY_GROUP_UPDATE_MEMBERS} in compartment ${var.compartment_name} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${oci_identity_compartment.this.id}'}",
    "Allow any-user to {VNIC_CREATE, VNIC_UPDATE, VNIC_ASSOCIATE_NETWORK_SECURITY_GROUP, VNIC_DISASSOCIATE_NETWORK_SECURITY_GROUP} in compartment ${var.compartment_name} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${oci_identity_compartment.this.id}'}",
  ]
}
