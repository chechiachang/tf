locals {
  auth                    = "SecurityToken"
  profile                 = "tf"
  objectstorage_namespace = "axyygu1yi2iu"
  terraform_state_bucket  = "chechia-terraform-state"
  # From [tf] tenancy in ~/.oci/config.
  tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaaxe5s4joljofgqupzjpjy6rue2q7agaj4qx2y3jcfs3qm6m5e7nwq"
}

remote_state {
  backend = "oci"
  config = {
    bucket              = local.terraform_state_bucket
    namespace           = local.objectstorage_namespace
    key                 = "${path_relative_to_include()}/terraform.tfstate"
    region              = "ap-osaka-1"
    auth                = local.auth
    config_file_profile = local.profile
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
