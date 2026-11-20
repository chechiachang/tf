locals {
  permission_names = toset([
    "Workers R2 Storage Write",
    "Workers Scripts Write",
    "Workers KV Storage Write",
    "D1 Write",
  ])
}

data "cloudflare_api_token_permission_groups_list" "permissions" {
  for_each = local.permission_names
  name     = urlencode(each.key)
  scope    = urlencode("com.cloudflare.api.account")
}

resource "cloudflare_api_token" "plan" {
  name       = "tf-agent"
  expires_on = var.expires_on

  policies = [{
    effect = "allow"
    permission_groups = [for name in sort(tolist(local.permission_names)) : {
      id = one(data.cloudflare_api_token_permission_groups_list.permissions[name].result).id
    }]
    resources = jsonencode({
      "com.cloudflare.api.account.${var.account_id}" = "*"
    })
  }]
}
