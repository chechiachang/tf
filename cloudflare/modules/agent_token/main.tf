locals {
  permission_names = toset([
    "Workers R2 Storage Read",
    "Workers Scripts Read",
    "Workers KV Storage Read",
    "D1 Read",
  ])
}

data "cloudflare_api_token_permission_groups_list" "read" {
  for_each = local.permission_names
  name     = urlencode(each.key)
  scope    = urlencode("com.cloudflare.api.account")
}

resource "cloudflare_api_token" "plan" {
  name       = "tf-agent-plan"
  expires_on = var.expires_on

  policies = [{
    effect = "allow"
    permission_groups = [for name in sort(tolist(local.permission_names)) : {
      id = one(data.cloudflare_api_token_permission_groups_list.read[name].result).id
    }]
    resources = jsonencode({
      "com.cloudflare.api.account.${var.account_id}" = "*"
    })
  }]
}
