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

resource "oci_identity_user" "agent" {
  compartment_id = var.tenancy_ocid
  name           = "tf-plan-agent"
  description    = "Read-only Terraform planning identity; no console password."
  email          = var.email
}

resource "oci_identity_user_capabilities_management" "agent" {
  user_id                      = oci_identity_user.agent.id
  can_use_api_keys             = true
  can_use_auth_tokens          = false
  can_use_console_password     = false
  can_use_customer_secret_keys = false
  can_use_smtp_credentials     = false
}

resource "oci_identity_group" "agent" {
  compartment_id = var.tenancy_ocid
  name           = "tf-plan-agents"
  description    = "Read-only dev infrastructure and Cloudflare state access."
}

resource "oci_identity_user_group_membership" "agent" {
  user_id  = oci_identity_user.agent.id
  group_id = oci_identity_group.agent.id
}

resource "oci_identity_api_key" "agent" {
  user_id   = oci_identity_user.agent.id
  key_value = var.public_key
}

resource "oci_identity_policy" "agent" {
  compartment_id = var.tenancy_ocid
  name           = "tf-plan-agent"
  description    = "Plan dev and Cloudflare stacks without mutation or bootstrap-state access."
  statements = [
    "Allow group id ${oci_identity_group.agent.id} to read instance-family in compartment id ${var.compartment_ocid}",
    "Allow group id ${oci_identity_group.agent.id} to read volume-family in compartment id ${var.compartment_ocid}",
    "Allow group id ${oci_identity_group.agent.id} to read virtual-network-family in compartment id ${var.compartment_ocid}",
    "Allow group id ${oci_identity_group.agent.id} to read mysql-family in compartment id ${var.compartment_ocid}",
    "Allow group id ${oci_identity_group.agent.id} to read bastion-family in compartment id ${var.compartment_ocid}",
    "Allow group id ${oci_identity_group.agent.id} to inspect compartments in tenancy where target.compartment.id = '${var.compartment_ocid}'",
    "Allow group id ${oci_identity_group.agent.id} to inspect instance-images in tenancy",
    "Allow group id ${oci_identity_group.agent.id} to read buckets in tenancy where target.bucket.name = '${var.bucket_name}'",
    "Allow group id ${oci_identity_group.agent.id} to inspect objects in tenancy where target.bucket.name = '${var.bucket_name}'",
    "Allow group id ${oci_identity_group.agent.id} to read objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = 'dev/*'}",
    "Allow group id ${oci_identity_group.agent.id} to read objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = 'cloudflare/dev/global/abot/share/terraform.tfstate'}",
    "Allow group id ${oci_identity_group.agent.id} to read objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = 'cloudflare/dev/global/free/serverless/terraform.tfstate'}",
  ]
}

output "user_ocid" {
  value = oci_identity_user.agent.id
}

output "fingerprint" {
  value = oci_identity_api_key.agent.fingerprint
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
  statements = [for statement in oci_identity_policy.agent.statements : replace(
    statement,
    "group id ${oci_identity_group.agent.id}",
    "dynamic-group id ${oci_identity_dynamic_group.a1[0].id}"
  )]
}
