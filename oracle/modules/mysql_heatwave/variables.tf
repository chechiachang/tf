variable "auth" {
  description = "OCI provider authentication method."
  type        = string
}

variable "region" {
  description = "OCI region for the database."
  type        = string
}

variable "profile" {
  description = "OCI CLI profile for SecurityToken authentication."
  type        = string
}

variable "compartment_id" {
  description = "Compartment that owns the MySQL DB system."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the standalone DB system."
  type        = string
}

variable "subnet_id" {
  description = "Private subnet for the MySQL DB system."
  type        = string
}

variable "network_security_group_id" {
  description = "Network security group allowing MySQL only from the application instance group."
  type        = string
}

variable "bootstrap_db_system_ocid" {
  description = "Existing DB created by bootstrap-mysql.sh; password never enters Terraform."
  type        = string
  validation {
    condition     = can(regex("^ocid1[.]mysqldbsystem[.]", var.bootstrap_db_system_ocid))
    error_message = "Run bootstrap-mysql.sh and set OCI_MYSQL_DB_SYSTEM_OCID before planning."
  }
}
