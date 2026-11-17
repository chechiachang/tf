locals {
  oracle = read_terragrunt_config("${get_repo_root()}/oracle/root.hcl")
}

remote_state {
  backend = "oci"
  config = merge(local.oracle.remote_state.config, {
    key = "tailscale/${path_relative_to_include()}/terraform.tfstate"
  })
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
