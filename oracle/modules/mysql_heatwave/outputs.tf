output "private_ip" {
  description = "Private IP address of the MySQL DB system."
  value       = oci_mysql_mysql_db_system.this.ip_address
}

output "port" {
  description = "MySQL client port."
  value       = oci_mysql_mysql_db_system.this.port
}

output "admin_username" {
  description = "Generated MySQL administrator username."
  value       = oci_mysql_mysql_db_system.this.admin_username
}

output "admin_password" {
  description = "Generated MySQL administrator password; retrieve with Terragrunt output when needed."
  value       = random_password.admin.result
  sensitive   = true
}
