resource "cloudflare_r2_bucket" "this" {
  account_id    = var.account_id
  name          = var.bucket_name
  location      = var.location
  jurisdiction  = var.jurisdiction
  storage_class = var.storage_class

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_r2_bucket_lifecycle" "this" {
  count = var.object_retention_days == null ? 0 : 1

  account_id   = var.account_id
  bucket_name  = cloudflare_r2_bucket.this.name
  jurisdiction = var.jurisdiction

  rules = [{
    id      = "expire-objects"
    enabled = true
    conditions = {
      prefix = ""
    }
    delete_objects_transition = {
      condition = {
        type    = "Age"
        max_age = var.object_retention_days * 86400
      }
    }
  }]
}
