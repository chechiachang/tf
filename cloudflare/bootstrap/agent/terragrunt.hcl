terraform {
  source = "${get_repo_root()}/cloudflare/modules/agent_token"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  expires_on = get_env("CLOUDFLARE_PLAN_TOKEN_EXPIRES_ON")
}
