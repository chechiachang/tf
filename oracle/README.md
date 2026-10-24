# Oracle Cloud

Use the Makefile from `oracle/` for OCI session auth:

```sh
make auth
```

Set auth, profile, and tenancy OCID in `root.hcl`; find the OCID in `[tf] tenancy` in `~/.oci/config` or OCI Console > Tenancy Details. The instance stack reads `~/.ssh/id_rsa.pub`; change that path in its `terragrunt.hcl` if needed.

Terraform state is stored in the private, versioned Osaka Object Storage bucket `chechia-terraform-state`:

- `dev/ap-osaka-1/network/terraform.tfstate`
- `dev/ap-osaka-1/asre/instance/terraform.tfstate`
- `dev/ap-osaka-1/asre/mysql/terraform.tfstate`
- `bootstrap/state/terraform.tfstate`

The OCI backend supports state locking. Its operator needs `OBJECT_INSPECT`, `OBJECT_CREATE`, `OBJECT_DELETE`, and `OBJECT_READ` on the bucket. The bucket is within the Object Storage Always Free allowance listed in `free.csv`. Do not delete it or its state objects; state includes sensitive values such as the MySQL admin password.

Set `OCI_BASTION_CLIENT_CIDR` to your current public IPv4 `/32` before running Terragrunt; do not use `0.0.0.0/0`. The operator's IAM policy should be scoped to the `dev` compartment and grant `use bastion`, `manage bastion-session`, and read access to target networking/instance resources; see the [Bastion policy reference](https://docs.oracle.com/en-us/iaas/Content/Bastion/Reference/bastionpolicyreference.htm). Apply `network` first, then `instance`; both share the regional network.

```sh
cd oracle/dev/ap-osaka-1/network
terragrunt run -- plan
```

The A1 instance has no public IP. OCI Bastion is allow-listed to that client `/32`, and the instance NSG allows TCP/22 only from the Bastion private endpoint. The subnet security list permits TCP/22 egress to the private instance subnet so that endpoint can connect. Sessions expire within one hour and `make ssh` deletes its session on exit. From `oracle/`:

```sh
make bastion-allow OCI_BASTION_CLIENT_CIDR=<your-current-public-ip>/32 # when your IP changes
make ssh # detects your public IP with curl; no apply
```

Use the public IPv4 address of the computer running `make`, not the A1's private `10.42.x.x` address. If your public IP changed, update the Bastion allow-list first. The target is Oracle Linux user `opc`; the default key is `~/.ssh/id_rsa`. Never commit credentials, private keys, or state.
