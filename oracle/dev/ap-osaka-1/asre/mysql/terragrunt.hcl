terraform {
  source = "${get_repo_root()}/oracle/modules/mysql_heatwave"
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
  config_path                            = "../../network"
  mock_outputs_merge_strategy_with_state = "deep_map_only"

  mock_outputs = {
    compartment_ocid  = "ocid1.compartment.oc1..validation"
    subnet_ocids      = { database = "ocid1.subnet.oc1..validation" }
    database_nsg_ocid = "ocid1.networksecuritygroup.oc1..validation"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

inputs = {
  auth                      = include.root.locals.auth
  region                    = include.region.locals.region
  profile                   = include.root.locals.profile
  compartment_id            = dependency.network.outputs.compartment_ocid
  availability_domain       = "gynr:AP-OSAKA-1-AD-1"
  subnet_id                 = dependency.network.outputs.subnet_ocids.database
  network_security_group_id = dependency.network.outputs.database_nsg_ocid
}
