# Oracle Cloud

Ubuntu 24.04: one ARM instance (100 GB disk) and two AMD micros (50 GB each); private networking, NAT/HTTPS egress, and Docker installed by cloud-init.

## 1. Authenticate

Run from `oracle/`; configure `root.hcl` and use `~/.ssh/id_rsa.pub` for instance SSH.

```sh
make auth
```

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

## 6. Agents over Tailscale

Cloud-init installs Tailscale, tmux and Herdr on all hosts, OpenCode on the ARM hub, and earlyoom/2 GB swap on the micros. Herdr v0.9.5 and OpenCode v1.19.5 binaries are pinned and SHA-256 checked; update versions and hashes together. No auth key is stored.

The shared instance NSG allows outbound UDP 3478/41641; HTTPS 443 provides DERP fallback. No inbound rules are added; direct connections are not guaranteed with restricted UDP.

```sh
sudo tailscale up --ssh --hostname=hub # use worker-1/worker-2 on the micros; open the login URL
```

On the hub, as `ubuntu`, verify SSH and save both workers:

```sh
ssh ubuntu@worker-1 # verify host key; repeat for worker-2
herdr machine add ubuntu@worker-1 --label worker-1
herdr machine add ubuntu@worker-2 --label worker-2
herdr
```

Run `opencode` inside the hub's Herdr pane; use `/connect` to configure a provider interactively. Cloud-init installs Herdr's bundled skill and OpenCode state-reporting integration for `ubuntu`. Keep provider credentials on the hub, out of Terraform and git.

Phone (Termius/Blink, with Tailscale app): `ssh ubuntu@hub`, then `herdr` to reattach. `Ctrl+B Q` detaches without stopping pane processes. A reboot does not preserve running processes.

OpenCode's built-in subagents run on the hub, not automatically on workers. Ask the coordinator to load the `herdr` skill and delegate bounded shell/build/test jobs through the remote CLI:

```sh
herdr --machine worker-1 pane list
herdr --machine worker-1 pane split --no-focus # use the returned pane ID below
herdr --machine worker-1 pane run <pane-id> 'hostname; free -h'
herdr --machine worker-1 pane read <pane-id> --lines 100
```

Provision each worker's checkout/dependencies separately and limit it to one memory-heavy job at a time. Worker shell panes are not independent LLM agents; Herdr does not provide autonomous task routing by itself. No coordinator plugin is installed.

Restrict tailnet network and SSH policies to your mobile identity accessing the hub and the hub accessing workers as `ubuntu`; automated worker SSH must not require interactive approval. Do not expose Herdr sockets or OpenCode HTTP services to the network.

Cloud-init changes apply on first boot, not to existing hosts. Install/configure existing hosts manually; do not replace them without reviewing the plan and backing up their boot disks.
