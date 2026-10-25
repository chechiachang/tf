terraform {
  source = "${get_repo_root()}/oracle/modules/instance"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}

dependency "network" {
  config_path = "../../network"

  mock_outputs = {
    compartment_ocid  = "ocid1.compartment.oc1..validation"
    subnet_ocids      = { instance = "ocid1.subnet.oc1..validation" }
    instance_nsg_ocid = "ocid1.networksecuritygroup.oc1..validation"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

inputs = {
  shape                       = "VM.Standard.E2.1.Micro"
  instance_count              = 2
  instance_display_name       = "free-amd"
  boot_volume_size_in_gbs     = 50
  auth                        = include.root.locals.auth
  region                      = include.region.locals.region
  profile                     = include.root.locals.profile
  tenancy_ocid                = include.root.locals.tenancy_ocid
  compartment_ocid            = dependency.network.outputs.compartment_ocid
  subnet_ocid                 = dependency.network.outputs.subnet_ocids.instance
  network_security_group_ocid = dependency.network.outputs.instance_nsg_ocid
  ssh_public_key              = file("${get_env("HOME")}/.ssh/id_rsa.pub")
  user_data                   = filebase64("${get_terragrunt_dir()}/cloud-init.yaml")
}
