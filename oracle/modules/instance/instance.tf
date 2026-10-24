module "free_arm_instance" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "2.4.1"

  compartment_ocid            = var.compartment_ocid
  ad_number                   = 1
  instance_count              = 1
  instance_display_name       = "free-arm"
  instance_state              = "RUNNING"
  shape                       = "VM.Standard.A1.Flex"
  instance_flex_ocpus         = 2
  instance_flex_memory_in_gbs = 12
  source_ocid                 = data.oci_core_images.oracle_linux_arm.images[0].id
  subnet_ocids                = [var.subnet_ocid]
  primary_vnic_nsg_ids        = [var.network_security_group_ocid]
  ssh_public_keys             = var.ssh_public_key

  public_ip                 = "NONE"
  assign_public_ip          = false
  boot_volume_size_in_gbs   = 150
  boot_volume_backup_policy = "disabled"
  preserve_boot_volume      = false

  cloud_agent_plugins = {
    autonomous_linux        = "DISABLED"
    bastion                 = "DISABLED"
    block_volume_mgmt       = "DISABLED"
    custom_logs             = "DISABLED"
    java_management_service = "DISABLED"
    management              = "DISABLED"
    monitoring              = "DISABLED"
    osms                    = "DISABLED"
    run_command             = "DISABLED"
    vulnerability_scanning  = "DISABLED"
  }
}
