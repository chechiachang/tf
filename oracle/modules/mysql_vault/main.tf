resource "oci_kms_vault" "mysql" {
  compartment_id = var.compartment_id
  display_name   = "asre-mysql"
  vault_type     = "DEFAULT"
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_kms_key" "mysql" {
  compartment_id      = var.compartment_id
  display_name        = "asre-mysql-secret"
  management_endpoint = oci_kms_vault.mysql.management_endpoint
  protection_mode     = "SOFTWARE"
  key_shape {
    algorithm = "AES"
    length    = 32
  }
  lifecycle {
    prevent_destroy = true
  }
}

output "vault_id" {
  value = oci_kms_vault.mysql.id
}

output "key_id" {
  value = oci_kms_key.mysql.id
}

output "compartment_id" {
  value = var.compartment_id
}
