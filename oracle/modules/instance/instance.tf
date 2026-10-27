module "free_arm_instance" {
  source = "github.com/oracle-terraform-modules/terraform-oci-compute-instance?ref=b19dbe063ab82529c9ef71c92d1472fba2d30595"

  compartment_ocid            = var.compartment_ocid
  ad_number                   = 1
  instance_count              = var.instance_count
  instance_display_name       = var.instance_display_name
  instance_state              = "RUNNING"
  shape                       = var.shape
  instance_flex_ocpus         = var.shape == "VM.Standard.A1.Flex" ? 2 : null
  instance_flex_memory_in_gbs = var.shape == "VM.Standard.A1.Flex" ? 12 : null
  source_ocid                 = data.oci_core_images.ubuntu.images[0].id
  subnet_ocids                = [var.subnet_ocid]
  primary_vnic_nsg_ids        = [var.network_security_group_ocid]
  ssh_public_keys             = var.ssh_public_key
  user_data                   = var.user_data

  public_ip                 = "NONE"
  assign_public_ip          = false
  boot_volume_size_in_gbs   = var.boot_volume_size_in_gbs
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
