resource "tailscale_acl" "policy" {
  acl                        = var.policy
  overwrite_existing_content = false
  reset_acl_on_destroy       = false

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = !strcontains(var.policy, "<your-tailnet-login>")
      error_message = "Replace the operator login and merge the existing tailnet policy before planning."
    }
  }
}

resource "tailscale_dns_preferences" "tailnet" {
  magic_dns = var.magic_dns
}

resource "tailscale_device_tags" "device" {
  for_each = var.device_tags

  device_id = each.key
  tags      = each.value

  depends_on = [tailscale_acl.policy]
}
