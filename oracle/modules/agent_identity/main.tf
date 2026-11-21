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
    "dev/ap-osaka-1/asre/amd/terraform.tfstate",
    "dev/ap-osaka-1/asre/storage/terraform.tfstate",
    "dev/ap-osaka-1/asre/notifications/terraform.tfstate",
    "dev/ap-osaka-1/asre/mysql-vault/terraform.tfstate",
    "dev/ap-osaka-1/asre/mysql/terraform.tfstate",
    "cloudflare/dev/global/abot/share/terraform.tfstate",
    "cloudflare/dev/global/free/serverless/terraform.tfstate",
  ]
  workload_bucket_names = ["asre-artifacts", "asre-backups"]
  plan_only_state_keys = [
    "dev/ap-osaka-1/network/terraform.tfstate",
    "dev/ap-osaka-1/asre/instance/terraform.tfstate",
  ]
}

resource "oci_identity_tag_namespace" "workload" {
  compartment_id = var.compartment_ocid
  name           = "TfWorkload"
  description    = "Administrator-owned workload delegation; never tag A1 resources."
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_identity_tag" "workload_scope" {
  tag_namespace_id = oci_identity_tag_namespace.workload.id
  name             = "Scope"
  description      = "AMD resources and notification topics delegated to A1."
  validator {
    validator_type = "ENUM"
    values         = ["amd", "notifications"]
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_identity_policy" "a1_provision" {
  count          = var.instance_ocid == null ? 0 : 1
  compartment_id = var.tenancy_ocid
  name           = "tf-provision-a1"
  description    = "Workload provisioner; no IAM, shared infrastructure, or A1 mutation."
  statements = concat([
    # Metrics are read-only except the workload's custom namespace; alarms stay admin-only.
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read metrics in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to use metrics in compartment id ${var.compartment_ocid} where target.metrics.namespace = 'asre'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to inspect alarms in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to inspect ons-topics in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to inspect ons-subscriptions in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {ONS_TOPIC_CREATE} in compartment id ${var.compartment_ocid} where request.operation = 'CreateTopic'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {ONS_TOPIC_READ, ONS_TOPIC_UPDATE, ONS_TOPIC_DELETE, ONS_TOPIC_SUBSCRIBE, ONS_TOPIC_PUBLISH} in compartment id ${var.compartment_ocid} where target.resource.tag.TfWorkload.Scope = 'notifications'",
    # Launch only; existing instances/VNICs require the administrator's workload tag.
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {INSTANCE_CREATE, VNIC_CREATE, VNIC_ATTACH, VNIC_ASSOCIATE_NETWORK_SECURITY_GROUP} in compartment id ${var.compartment_ocid} where request.operation = 'LaunchInstance'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {INSTANCE_UPDATE, INSTANCE_DELETE, INSTANCE_POWER_ACTIONS} in compartment id ${var.compartment_ocid} where target.resource.tag.TfWorkload.Scope = 'amd'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {VNIC_UPDATE, VNIC_DELETE, VNIC_DETACH, VNIC_ASSOCIATE_NETWORK_SECURITY_GROUP, VNIC_DISASSOCIATE_NETWORK_SECURITY_GROUP} in compartment id ${var.compartment_ocid} where target.resource.tag.TfWorkload.Scope = 'amd'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to use tag-namespaces in compartment id ${var.compartment_ocid} where all {target.tag-namespace.id = '${oci_identity_tag_namespace.workload.id}', request.operation != 'CreateTag', request.operation != 'UpdateTag', request.operation != 'BulkEditTags'}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {VNIC_ASSOCIATE_NETWORK_SECURITY_GROUP, VNIC_DISASSOCIATE_NETWORK_SECURITY_GROUP} in compartment id ${var.compartment_ocid} where any {request.operation = 'CreateDbSystem', request.operation = 'UpdateDbSystem'}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to manage mysql-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to use subnets in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to use network-security-groups in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {VAULT_INSPECT, VAULT_READ, VAULT_CREATE, VAULT_UPDATE, VAULT_CREATE_KEY} in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {KEY_INSPECT, KEY_READ, KEY_CREATE, KEY_UPDATE} in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read secrets in compartment id ${var.compartment_ocid} where target.secret.name = 'asre-mysql-secret'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read secret-bundles in compartment id ${var.compartment_ocid} where target.secret.name = 'asre-mysql-secret'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to read objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = 'dev/ap-osaka-1/network/terraform.tfstate'}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to manage objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = 'dev/ap-osaka-1/asre/mysql/bootstrap.lock'}",
    ], flatten([for name in local.workload_bucket_names : [
      "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {BUCKET_INSPECT, BUCKET_READ, BUCKET_CREATE, BUCKET_UPDATE, BUCKET_DELETE} in compartment id ${var.compartment_ocid} where target.bucket.name = '${name}'",
      "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {OBJECT_INSPECT, OBJECT_READ, OBJECT_CREATE, OBJECT_OVERWRITE, OBJECT_DELETE} in compartment id ${var.compartment_ocid} where target.bucket.name = '${name}'",
    ]]), [for key in local.provision_state_keys :
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to {OBJECT_READ, OBJECT_CREATE, OBJECT_OVERWRITE} in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = '${key}'}"
    ], [for key in concat(local.provision_state_keys, local.plan_only_state_keys) :
    "Allow dynamic-group id ${oci_identity_dynamic_group.a1[0].id} to manage objects in tenancy where all {target.bucket.name = '${var.bucket_name}', target.object.name = '${key}.lock'}"
  ])
}
