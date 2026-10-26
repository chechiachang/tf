resource "oci_kms_vault" "terraform_state" {
  compartment_id = var.tenancy_ocid
  display_name   = "${var.bucket_name}-vault"
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "terraform_state" {
  compartment_id      = var.tenancy_ocid
  display_name        = "${var.bucket_name}-key"
  management_endpoint = oci_kms_vault.terraform_state.management_endpoint
  protection_mode     = "SOFTWARE"

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}
