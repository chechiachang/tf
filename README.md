# Terraform Live

Cloud stacks live in `<cloud>/<environment>/<region>/`. OCI is in `oracle/`; the Azure repository is a submodule at `azure/`.

## OCI stack

```sh
cd oracle/dev/us-ashburn-1
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
```

Use an OCI CLI profile configured locally. Configure protected remote state before applying infrastructure. Review the plan and complete a security review before committing changes.

Initialize the Azure submodule after cloning:

```sh
git submodule update --init --recursive
```
