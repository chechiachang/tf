# Oracle Cloud

Ubuntu 24.04: one ARM instance (100 GB disk) and two AMD micros (50 GB each); private networking, NAT/HTTPS egress, Docker and Tailscale installed by cloud-init. The ARM hub also has Node.js 22, Pi 1.5.2 and tmux.

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

## 6. Phone access and Pi

On each VM, connect through Bastion and enroll interactively:

```sh
sudo tailscale up --ssh
tailscale status
```

Approve the login URL in your browser. Tag the ARM VM `tag:pi-hub` and the micros `tag:pi-worker`. No enrollment keys belong in cloud-init or Terraform state.

Merge these rules into your tailnet policy, replacing the login placeholder. Remove any existing broad rules that would override these restrictions.

```json
{
  "groups": {
    "group:operators": ["<your-tailnet-login>"]
  },
  "tagOwners": {
    "tag:pi-hub": ["group:operators"],
    "tag:pi-worker": ["group:operators"]
  },
  "grants": [
    {
      "src": ["group:operators"],
      "dst": ["tag:pi-hub", "tag:pi-worker"],
      "ip": ["tcp:22"]
    },
    {
      "src": ["tag:pi-hub"],
      "dst": ["tag:pi-worker"],
      "ip": ["tcp:22"]
    }
  ],
  "ssh": [
    {
      "action": "check",
      "src": ["group:operators"],
      "dst": ["tag:pi-hub", "tag:pi-worker"],
      "users": ["agent"]
    },
    {
      "action": "accept",
      "src": ["tag:pi-hub"],
      "dst": ["tag:pi-worker"],
      "users": ["agent"]
    }
  ]
}
```

Enable Tailscale on your phone, then use an SSH app to connect to the hub's Tailscale IP as `agent`. In a project directory:

```sh
tmux new-session -A -s pi
pi
```

Use Pi's `/login` to authenticate. Detach with `Ctrl-b d`; reconnect with the same tmux command. Sessions survive phone disconnects, not VM reboots. Pi has no native phone GUI or configured multi-agent orchestrator; worker access is ordinary SSH over Tailscale.

The `agent` account has no sudo or Docker-group access. Keep provider credentials in this account's private home, never the repository; grant only necessary OCI permissions and review plans before applying. Pi can execute shell commands as this account without an approval boundary.

HTTPS egress supports Tailscale DERP relays without public ingress; connections may be relayed. UDP/direct connectivity is not configured. Keep OCI Bastion for recovery.

Existing VMs do not rerun cloud-init when metadata changes. Copy `scripts/setup-agents.sh` to each VM through Bastion and run `sudo bash setup-agents.sh hub` on ARM or `sudo bash setup-agents.sh worker` on each micro, then enroll. Do not replace VMs just to install these tools.

State is in the private, versioned `chechia-terraform-state` bucket; never delete it or commit state, credentials, or private keys. Replacing an instance deletes its boot disk; shrinking a disk requires replacement. Review instance plans carefully when changing cloud-init.
