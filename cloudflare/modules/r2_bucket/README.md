# R2 bucket

Private, `prevent_destroy`. Required: `account_id`, `bucket_name`.
Defaults: `location=apac`, `jurisdiction=null`, `storage_class=Standard`, `object_retention_days=null` (or 1–365).
Null skips lifecycle management; disable existing expiry rules before removing management—the provider cannot delete them.
