terraform {
  source = "${get_repo_root()}/oracle/modules/network"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}

inputs = {
  auth                      = include.root.locals.auth
  region                    = include.region.locals.region
  profile                   = include.root.locals.profile
  tenancy_ocid              = include.root.locals.tenancy_ocid
  compartment_name          = "dev"
  compartment_description   = "Development compartment for ASRE."
  vcn_name                  = "dev"
  vcn_cidr                  = "10.42.0.0/16"
  bastion_target_subnet_key = "instance"
  bastion_client_cidr       = get_env("OCI_BASTION_CLIENT_CIDR")
  subnets = {
    instance = {
      name       = "instance-private"
      cidr_block = "10.42.1.0/24"
      type       = "private"
    }
    database = {
      name       = "database-private"
      cidr_block = "10.42.2.0/24"
      type       = "private"
    }
  }
}
