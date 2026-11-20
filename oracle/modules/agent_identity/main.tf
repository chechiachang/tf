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

locals {
  provision_state_keys = [
    "dev/ap-osaka-1/asre/mysql-vault/terraform.tfstate",
    "dev/ap-osaka-1/asre/mysql/terraform.tfstate",
    "cloudflare/dev/global/abot/share/terraform.tfstate",
    "cloudflare/dev/global/free/serverless/terraform.tfstate",
  ]
}

resource "oci_identity_policy" "a1_provision" {
  count          = var.instance_ocid == null ? 0 : 1
  compartment_id = var.tenancy_ocid
  name           = "tf-provision-a1"
  description    = "Permanent MySQL/Vault provisioner; no IAM or compute administration."
  statements = concat([
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to manage mysql-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to use subnets in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to use network-security-groups in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {VAULT_INSPECT, VAULT_READ, VAULT_CREATE, VAULT_UPDATE, VAULT_CREATE_KEY} in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {KEY_INSPECT, KEY_READ, KEY_CREATE, KEY_UPDATE} in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read secrets in compartment id ${var.compartment_ocid} where target.secret.name = 'asre-mysql-admin'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read secret-bundles in compartment id ${var.compartment_ocid} where target.secret.name = 'asre-mysql-admin'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = 'dev/ap-osaka-1/network/terraform.tfstate'}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to manage objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = 'dev/ap-osaka-1/asre/mysql/bootstrap.lock'}",
    ], [for key in local.provision_state_keys :
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {OBJECT_READ, OBJECT_CREATE, OBJECT_OVERWRITE} in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = '${key}'}"
    ], [for key in local.provision_state_keys :
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to manage objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = '${key}.lock'}"
  ])
}
