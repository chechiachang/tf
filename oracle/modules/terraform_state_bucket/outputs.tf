output "bucket_name" {
  value = oci_objectstorage_bucket.terraform_state.name
}

output "namespace" {
  value = oci_objectstorage_bucket.terraform_state.namespace
}
