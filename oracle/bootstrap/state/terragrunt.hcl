terraform {
  source = "${get_repo_root()}/oracle/modules/terraform_state_bucket"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = {
  auth         = include.root.locals.auth
  profile      = include.root.locals.profile
  region       = "ap-osaka-1"
  tenancy_ocid = include.root.locals.tenancy_ocid
  namespace    = include.root.locals.objectstorage_namespace
  bucket_name  = include.root.locals.terraform_state_bucket
}
