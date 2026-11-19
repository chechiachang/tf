terraform {
  source = "${get_repo_root()}/oracle/modules/agent_identity"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = {
  auth             = include.root.locals.auth
  profile          = include.root.locals.profile
  region           = "ap-osaka-1"
  tenancy_ocid     = include.root.locals.tenancy_ocid
  compartment_ocid = include.root.locals.compartment_ocid
  bucket_name      = include.root.locals.terraform_state_bucket
  email            = include.root.locals.agent_email
  public_key       = file(get_env("OCI_AGENT_PUBLIC_KEY_FILE"))
}
