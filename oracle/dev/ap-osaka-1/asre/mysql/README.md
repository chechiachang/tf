# MySQL without password-bearing Terraform state

For a new database only. Terraform manages a DEFAULT Vault, software AES key, and the imported MySQL/HeatWave configuration. Secret creation/content and password-bearing DB creation stay outside Terraform. This uses free-tier resource types, subject to tenancy quotas; review current pricing and plans.

1. After an administrator applies `oracle/bootstrap/agent`, use A1 Instance Principal credentials to initialize, validate, review and apply `../mysql-vault` using Terragrunt. Obtain its `vault_id`, `key_id`, and `compartment_id` outputs.
2. In the OCI console create a secret named `asre-mysql-admin` in that Vault/compartment, encrypted by that key. Enter a new MySQL-compatible password manually and keep its version CURRENT. Do not add secret content to Terraform or chat.
3. From repo root, explicitly authorize creation:

   ```sh
   export OCI_TF_AUTH=InstancePrincipal
   export OCI_BASTION_CLIENT_CIDR="$(curl -fsS --max-time 15 https://api.ipify.org)/32"
   oracle/scripts/bootstrap-mysql.sh --secret-id <secret-ocid> --create
   ```

   Alternatively use separately authorized administrator credentials. Permanent A1 provisioning permissions must be applied first. Bootstrap needs secret metadata and CURRENT bundle reads, MySQL creation/read privileges, network output reads, Vault output reads, and MySQL backend state/lock writes. A separate delegated identity should restrict bundle reads to `target.secret.id = '<secret-ocid>'` and MySQL actions to the dev compartment; These are separate from the read-only planning policy.
4. Keep the emitted DB OCID. If interrupted after creation, inspect the DB and resume with `--secret-id <secret-ocid> --db-system-id <db-ocid>`; the script refuses duplicate named databases and takes an atomic OCI object lock across hosts. It never deletes a failed DB automatically.
5. After successful import/state-password check:

   ```sh
   export OCI_MYSQL_DB_SYSTEM_OCID=<db-ocid>
   cd oracle/dev/ap-osaka-1/asre/mysql
   terragrunt hcl fmt
   terragrunt run -- validate
   terragrunt run -- plan -input=false
   # Review before applying non-secret settings and the HeatWave cluster.
   ```

The script reads credentials into memory, passes OCI create JSON through stdin, captures CLI diagnostics, and prints identifiers only. No shell tracing, debug logs, core dumps, or external command-recording tools while handling secrets. The secret must match the configured Vault/key/compartment. A 30-minute readiness timeout leaves the DB available for a later resume. The lock is conditionally released on normal exit. After a crash/kill, inspect `dev/ap-osaka-1/asre/mysql/bootstrap.lock` and confirm no bootstrap is running before an operator removes the stale lock; the script never steals locks.

Terraform never reads the secret. Import should not contain `admin_password`; the script verifies current state and stops if one appears. `prevent_destroy` blocks database replacement/deletion and `ignore_changes` leaves password rotation outside Terraform. Rotation must update MySQL and Vault together using a separate reviewed workflow; changing Vault alone does not change the database password.

No legacy-state migration is performed. Previously generated passwords may remain in old state versions/backups until deliberately handled and rotated. A1 now has permanent access to the named MySQL secret, MySQL/Vault state, and required state locks. IAM bootstrap state remains excluded. Preserve administrator access until bootstrap and state inspection complete.
