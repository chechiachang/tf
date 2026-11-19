output "worker_name" {
  value = cloudflare_workers_script.this.script_name
}

output "database_id" {
  value = cloudflare_d1_database.this.id
}

output "namespace_id" {
  value = cloudflare_workers_kv_namespace.this.id
}
