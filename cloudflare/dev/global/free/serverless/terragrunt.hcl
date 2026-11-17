terraform {
  source = "${get_repo_root()}/cloudflare/modules/serverless"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  name = "tf-free-serverless"
}
