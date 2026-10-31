output "bucket_name" {
  value = cloudflare_r2_bucket.this.name
}

output "bucket_location" {
  value = cloudflare_r2_bucket.this.location
}

output "object_retention_days" {
  value = var.object_retention_days
}
