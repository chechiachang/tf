terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
}

provider "oci" {
  auth                = var.auth
  region              = var.region
  config_file_profile = var.profile
}

resource "oci_identity_dynamic_group" "a1" {
  count          = var.instance_ocid == null ? 0 : 1
  compartment_id = var.tenancy_ocid
  name           = "tf-plan-a1"
  description    = "Exact A1 agent host; no compartment-wide membership."
  matching_rule  = "ALL {instance.id = '${var.instance_ocid}', instance.compartment.id = '${var.compartment_ocid}'}"
}

resource "oci_identity_policy" "a1" {
  count          = var.instance_ocid == null ? 0 : 1
  compartment_id = var.tenancy_ocid
  name           = "tf-plan-a1"
  description    = "A1 read-only planning; no IAM administration, state writes, or bootstrap reads."
  statements = [
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read instance-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read volume-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read virtual-network-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read mysql-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read bastion-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to inspect compartments in tenancy where target.compartment.id = '${var.compartment_ocid}'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to inspect instance-images in tenancy",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read buckets in tenancy where target.bucket.name = '${var.bucket_name}'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to inspect objects in tenancy where target.bucket.name = '${var.bucket_name}'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = 'dev/ap-osaka-1/asre/instance/terraform.tfstate'}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = 'dev/ap-osaka-1/asre/amd/terraform.tfstate'}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = 'cloudflare/dev/global/abot/share/terraform.tfstate'}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = 'cloudflare/dev/global/free/serverless/terraform.tfstate'}",
  ]
}
