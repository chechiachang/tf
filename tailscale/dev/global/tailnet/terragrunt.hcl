terraform {
  source = "${get_repo_root()}/tailscale/modules/tailnet"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  policy    = file("${get_terragrunt_dir()}/policy.hujson")
  magic_dns = true
  # Node IDs, not Tailscale IPs; preserve each device's existing tags.
  device_tags = {}
}
