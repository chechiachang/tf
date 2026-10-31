locals {
  account_id = "664e4225fa00f97af165b5562ae199a9"
  oracle     = read_terragrunt_config("${get_repo_root()}/oracle/root.hcl")
}

remote_state {
  backend = "oci"
  config = merge(local.oracle.remote_state.config, {
    key = "cloudflare/${path_relative_to_include()}/terraform.tfstate"
  })
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  account_id = local.account_id
}
