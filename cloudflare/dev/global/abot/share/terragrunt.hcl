terraform {
  source = "${get_repo_root()}/cloudflare/modules/r2_bucket"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  bucket_name           = "abot-share"
  object_retention_days = 90
}


