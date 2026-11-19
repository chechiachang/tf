# Oracle Cloud

Ubuntu 24.04: one ARM instance (100 GB disk) and two AMD micros (50 GB each); private networking, NAT/HTTPS egress, and Docker installed by cloud-init.

## 1. Authenticate

Run from `oracle/`; configure `root.hcl` and use `~/.ssh/id_rsa.pub` for instance SSH.

All three VMs receive `ssh/termius.pub` and, when present, the operator's `~/.ssh/id_rsa.pub`. Existing VMs may require adding the Termius key to Ubuntu's `~/.ssh/authorized_keys` through existing SSH access; metadata changes alone do not guarantee guest access. Do not replace VMs just to add a key. SSH remains private through Bastion.

```sh
make auth
```

### A1 agent host prerequisites

A1 cloud-init installs OCI CLI with pipx. For an existing Ubuntu 24.04 host:

```sh
sudo apt-get update
sudo apt-get install -y pipx xdg-utils
sudo env PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install oci-cli
oci --version
```

The inspected Codex host has Terraform, Terragrunt, Python and `hc`, but lacks OCI CLI, pipx, a browser, `xdg-open`, and a graphical session. Optional browser packages:

```sh
sudo apt-get install -y snapd xvfb
sudo snap install firefox
```

Firefox needs an accessible graphical desktop; Xvfb alone does not provide remote viewing. Codex browser-control tools are supplied by the agent environment, not apt. Use a host browser you can control remotely to complete `make auth` and MFA; iPhone Safari cannot deliver a localhost callback to the host. Herdr terminal access alone is not browser access.

The stacks already use the `tf` profile with `SecurityToken`. Validate with `oci session validate --profile tf --auth security_token` before planning. Keep `~/.oci` outside the repository. Do not replace an existing A1 instance just to install these tools.

## 2. Apply networking

Allow your computer's current public IPv4 `/32`, then review and apply the network plan.

```sh
export OCI_BASTION_CLIENT_CIDR="$(curl -fsS https://api.ipify.org)/32"
cd dev/ap-osaka-1/network
terragrunt hcl fmt
terragrunt run -- validate
terragrunt run -- plan
terragrunt run -- apply
```

## 3. Apply instances

Run from each stack directory: `dev/ap-osaka-1/asre/instance` and `dev/ap-osaka-1/asre/amd`.

```sh
terragrunt hcl fmt
terragrunt run -- validate
terragrunt run -- plan
terragrunt run -- apply
```

## 4. SSH

Run from `oracle/`; Bastion uses Ubuntu user `ubuntu` and deletes the session on exit.

```sh
make bastion-allow OCI_BASTION_CLIENT_CIDR=<your-current-public-ip>/32 # when your IP changes
make ssh # ARM
make ssh INSTANCE_DIR=dev/ap-osaka-1/asre/amd INSTANCE_INDEX=0 # or 1
```

## 5. Verify

Run on the host after cloud-init finishes.

```sh
sudo cloud-init status --wait
df -h /
sudo docker run --rm hello-world
sudo docker compose version
```

The two AMD micros get a persistent 2 GB `/swapfile` and `vm.swappiness=20` at first boot. Verify with `swapon --show` and `sysctl vm.swappiness`. Existing hosts need manual configuration; do not replace them just to add swap.

State is in the private, versioned `chechia-terraform-state` bucket; never delete it or commit state, credentials, or private keys. Replacing an instance deletes its boot disk; shrinking a disk requires replacement.
