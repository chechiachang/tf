output "private_ip" {
  description = "Private IP address of the MySQL DB system."
  value       = oci_mysql_mysql_db_system.this.ip_address
}

output "port" {
  description = "MySQL client port."
  value       = oci_mysql_mysql_db_system.this.port
}

output "admin_username" {
  description = "Administrator username set by the external bootstrap."
  value       = "asreadmin"
}
