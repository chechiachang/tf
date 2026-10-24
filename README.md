# Terraform Live

Use Terragrunt for all stack operations. Stacks live in `<cloud>/<environment>/<region>/`; OCI is in `oracle/`, and Azure is a submodule at `azure/`.

## OCI authentication and workflow

```sh
oci session authenticate --region ap-osaka-1 --profile-name tf
oci session validate --profile tf --auth security_token
cd oracle/dev/ap-osaka-1/network
terragrunt run -- plan
```

OCI auth settings and tenancy OCID are in `oracle/root.hcl`. Find the OCID under `[tf] tenancy` in `~/.oci/config` or in OCI Console > Tenancy Details. The instance stack reads `~/.ssh/id_rsa.pub`; change its path in `oracle/dev/ap-osaka-1/asre/instance/terragrunt.hcl` if needed. Session auth uses a browser login and short-lived token in `~/.oci/`; refresh with `oci session refresh --profile tf`.

State uses a private, versioned OCI Object Storage bucket. Apply `network` first, then plan `asre/instance` and `asre/mysql`. The A1 instance has no public IP. See [Oracle operations](oracle/README.md) for state, SSH, and firewall instructions.

Initialize the Azure submodule after cloning:

```sh
git submodule update --init --recursive
```
