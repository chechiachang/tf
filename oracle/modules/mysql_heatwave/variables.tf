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
