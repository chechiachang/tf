# Tailscale

Manage tailnet policy, MagicDNS, and optional device tags. State uses `oracle/root.hcl`'s OCI bucket and auth, at `tailscale/dev/global/tailnet/terraform.tfstate`.

## Configure

Create a scoped OAuth client with policy-file and DNS read/write permissions; add device-core read/write permissions when managing device tags. Supply credentials through environment variables, never files in the repo:

```sh
export TAILSCALE_OAUTH_CLIENT_ID=...
export TAILSCALE_OAUTH_CLIENT_SECRET=...
export TAILSCALE_TAILNET=-
oci session authenticate --region ap-osaka-1 --profile-name tf
```

In `dev/global/tailnet/policy.hujson`, replace `<your-tailnet-login>` and merge your existing **complete** policy. This resource replaces the entire policy; import does not merge it. Review existing broad grants/ACLs that bypass the intended restrictions.

Enroll VMs with `sudo tailscale up --ssh --hostname <name>`: `pi-hub` on ARM, `pi-worker1` / `pi-worker2` on AMDs. MagicDNS resolves these private names within the tailnet; leave DNS acceptance enabled. Rename existing nodes with `sudo tailscale set --hostname <name> --accept-dns=true`. Set ARM to `tag:pi-hub` and AMDs to `tag:pi-worker` in the console, or populate `device_tags` in `terragrunt.hcl` with node IDs and complete tag sets:

```hcl
device_tags = {
  "<arm-node-id>" = ["tag:pi-hub"]
  "<amd-node-id>" = ["tag:pi-worker"]
}
```

## Import and apply

Operators can SSH as `agent` or `ubuntu` on tagged hubs/workers, with Tailscale's interactive identity check: `ssh ubuntu@pi-hub` (or `pi-worker1` / `pi-worker2`). Hub-to-worker automation remains `agent` only; root login is not granted.

Run from `tailscale/dev/global/tailnet/`:

```sh
terragrunt hcl fmt
terragrunt run -- init
terragrunt run -- validate
terragrunt run -- import tailscale_acl.policy acl
terragrunt run -- import tailscale_dns_preferences.tailnet dns_preferences
# For each configured device with existing tags:
terragrunt run -- import 'tailscale_device_tags.device["<node-id>"]' '<node-id>'
terragrunt run -- plan
terragrunt run -- apply
```

Policy deletion is guarded; destroy does not reset it to Tailscale's default. No auth keys are generated, and no VMs need recreation. Keep OCI Bastion for recovery.
