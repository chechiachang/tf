# MySQL without password-bearing Terraform state

For a new database only. Terraform manages a DEFAULT Vault, software AES key, and the imported MySQL/HeatWave configuration. Secret creation/content and password-bearing DB creation stay outside Terraform. This uses free-tier resource types, subject to tenancy quotas; review current pricing and plans.

1. With administrator OCI/backend credentials, initialize, validate, review and apply `../mysql-vault` using Terragrunt. Obtain its `vault_id`, `key_id`, and `compartment_id` outputs.
2. In the OCI console create a secret named `asre-mysql-admin` in that Vault/compartment, encrypted by that key. Enter a new MySQL-compatible password manually and keep its version CURRENT. Do not add secret content to Terraform or chat.
3. From repo root, explicitly authorize creation:

   ```sh
   export OCI_TF_AUTH=SecurityToken OCI_TF_PROFILE=tf-admin
   oracle/scripts/bootstrap-mysql.sh --secret-id <secret-ocid> --create
   ```

   Alternatively use administrator APIKey credentials. The script does not grant A1 bootstrap/secret privileges. Bootstrap needs secret metadata and CURRENT bundle reads, MySQL creation/read privileges, network output reads, Vault output reads, and MySQL backend state/lock writes. A separate delegated identity should restrict bundle reads to `target.secret.id = '<secret-ocid>'` and MySQL actions to the dev compartment; never grant these to the planning identity by default.
4. Keep the emitted DB OCID. If interrupted after creation, inspect the DB and resume with `--secret-id <secret-ocid> --db-system-id <db-ocid>`; the script refuses duplicate named databases. It never deletes a failed DB automatically.
5. After successful import/state-password check:

   ```sh
   export OCI_MYSQL_DB_SYSTEM_OCID=<db-ocid>
   cd oracle/dev/ap-osaka-1/asre/mysql
   terragrunt hcl fmt
   terragrunt run -- validate
   terragrunt run -- plan -input=false
   # Review before applying non-secret settings and the HeatWave cluster.
   ```

The script reads credentials into memory, passes OCI create JSON through stdin, captures CLI diagnostics, and prints identifiers only. No shell tracing, debug logs, core dumps, or external command-recording tools while handling secrets. The secret must match the configured Vault/key/compartment. A 30-minute readiness timeout leaves the DB available for a later resume.

Terraform never reads the secret. Import should not contain `admin_password`; the script verifies current state and stops if one appears. `prevent_destroy` blocks database replacement/deletion and `ignore_changes` leaves password rotation outside Terraform. Rotation must update MySQL and Vault together using a separate reviewed workflow; changing Vault alone does not change the database password.

No legacy-state migration is performed. Previously generated passwords may remain in old state versions/backups until deliberately handled and rotated. A1 remains denied access to MySQL/Vault state and secret bundles. Preserve administrator access until bootstrap and state inspection complete.
