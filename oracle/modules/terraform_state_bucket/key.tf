data "oci_objectstorage_namespace_metadata" "namespace" {
  namespace = var.namespace
}

resource "oci_kms_key" "terraform_state" {
  compartment_id    = var.tenancy_ocid
  display_name      = "${var.bucket_name}-key"
  management_endpoint = data.oci_objectstorage_namespace_metadata.namespace.kms_key_id

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}
