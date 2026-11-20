terraform {
  source = "${get_repo_root()}/oracle/modules/mysql_vault"
}
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}
dependency "network" {
  config_path = "../../network"
  mock_outputs = {
    compartment_ocid = "ocid1.compartment.oc1..validation"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}
inputs = {
  auth           = include.root.locals.auth
  profile        = include.root.locals.profile
  region         = "ap-osaka-1"
  compartment_id = dependency.network.outputs.compartment_ocid
}
