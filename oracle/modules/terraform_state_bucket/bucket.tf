resource "oci_objectstorage_bucket" "terraform_state" {
  compartment_id = var.tenancy_ocid
  namespace      = var.namespace
  name                  = var.bucket_name
  access_type           = "NoPublicAccess"
  storage_tier          = "Standard"
  versioning            = "Enabled"
  kms_key_id            = oci_kms_key.terraform_state.id
  object_events_enabled = true
}
