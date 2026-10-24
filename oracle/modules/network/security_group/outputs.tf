output "id" {
  description = "OCID of the instance network security group."
  value       = oci_core_network_security_group.instance.id
}

output "database_id" {
  description = "OCID of the MySQL database network security group."
  value       = oci_core_network_security_group.database.id
}
