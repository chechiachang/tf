resource "cloudflare_d1_database" "this" {
  account_id            = var.account_id
  name                  = "${var.name}-db"
  primary_location_hint = "apac"

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_workers_kv_namespace" "this" {
  account_id = var.account_id
  title      = "${var.name}-kv"

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_workers_script" "this" {
  account_id         = var.account_id
  script_name        = var.name
  main_module        = "worker.js"
  content            = file("${path.module}/worker.js")
  compatibility_date = "2026-01-01"
  logpush            = false

  bindings = [
    {
      name = "DB"
      type = "d1"
      id   = cloudflare_d1_database.this.id
    },
    {
      name         = "KV"
      type         = "kv_namespace"
      namespace_id = cloudflare_workers_kv_namespace.this.id
    }
  ]
}

resource "cloudflare_workers_script_subdomain" "this" {
  account_id       = var.account_id
  script_name      = cloudflare_workers_script.this.script_name
  enabled          = false
  previews_enabled = false
}
