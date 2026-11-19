# Oracle Cloud

Ubuntu 24.04: one ARM instance (100 GB disk) and two AMD micros (50 GB each); private networking, NAT/HTTPS egress, Docker, Tailscale, Node.js 22, Pi 1.5.2, Herdr, and herdr-core (`hc`) installed by cloud-init.

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

### Headless API-key planning

`bootstrap/agent` creates a dedicated, console-disabled user for read-only VM/MySQL plans in the existing dev compartment. A small custom IAM module keeps the permissions explicit. It cannot apply, manage IAM/network bootstrap, read bootstrap state, or write state. State contains sensitive data: access is limited to `dev/*` objects in the existing bucket; bucket object names and tenancy image metadata are inspectable.

Generate the RSA key on the agent host, outside Terraform and Git (do not overwrite an existing key):

```sh
umask 077
mkdir -p ~/.oci
test ! -e ~/.oci/tf-agent.pem && test ! -e ~/.oci/tf-agent-public.pem &&
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out ~/.oci/tf-agent.pem &&
  openssl pkey -in ~/.oci/tf-agent.pem -pubout -out ~/.oci/tf-agent-public.pem
```

Only the public PEM goes to the administrator; never transfer the private key or a session archive. The dev compartment OCID and agent's primary email are configured in `root.hcl`. With existing administrator authentication and the public PEM available on the administrator host:

```sh
export OCI_TF_PROFILE=tf-admin OCI_TF_AUTH=SecurityToken
export OCI_AGENT_PUBLIC_KEY_FILE=<path-to-public-pem>
cd bootstrap/agent
terragrunt hcl fmt
terragrunt run -- validate
terragrunt run -- plan
# Administrator reviews and applies separately, then obtains:
terragrunt output -raw user_ocid
terragrunt output -raw fingerprint
```

On the agent host, add a `[tf-agent]` profile to `~/.oci/config` using those outputs:

```ini
[tf-agent]
user=<user-ocid>
fingerprint=<fingerprint>
tenancy=<tenancy-ocid-from-root.hcl>
region=ap-osaka-1
key_file=/absolute/path/to/.oci/tf-agent.pem
```

```sh
chmod 600 ~/.oci/config ~/.oci/tf-agent.pem
export OCI_TF_AUTH=APIKey OCI_TF_PROFILE=tf-agent
cd dev/ap-osaka-1/asre/instance # or asre/amd or asre/mysql, from oracle/
terragrunt hcl fmt
terragrunt run -- init -reconfigure -input=false
terragrunt run -- validate
terragrunt run -- plan -lock=false
```

Read-only credentials cannot create backend locks; do not run these unlocked plans during an apply. Do not save plan files in Git. Provider and backend both use the selected profile; Makefile OCI commands use it too. This identity cannot create Bastion sessions (`make ssh`) or update its allowlist. Do not run `make auth` for an API-key profile. Defaults remain `SecurityToken`/`tf`. Test effective permissions after administrator bootstrap; grants inherited from other policies must also be reviewed. Revoke the registered public key if the host is compromised.

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

The AMD micros get a persistent 2 GB `/swapfile`, `vm.swappiness=20`, and earlyoom. Verify with `swapon --show` and `sysctl vm.swappiness`; configure existing hosts manually, without replacing them.

## 6. Phone access and Pi

On each VM, connect through Bastion and enroll interactively:

```sh
sudo tailscale up --ssh --hostname pi-hub # A1; use pi-worker1 / pi-worker2 on AMDs
tailscale status
```

Approve the login URL in your browser. Tag the ARM VM `tag:pi-hub` and the micros `tag:pi-worker`. No enrollment keys belong in cloud-init or Terraform state.

The [Tailscale stack](../tailscale/README.md) enables private MagicDNS. Keep DNS acceptance enabled (default); the three unique names resolve only inside the tailnet. For already enrolled VMs, use `sudo tailscale set --hostname <name> --accept-dns=true`. Use the actual names from `tailscale status` if a duplicate gets a suffix.

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
      "users": ["agent", "ubuntu"]
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
pi
```

Use Pi's `/login` to authenticate. Pi runs in the foreground; SSH disconnects can stop it. Pi has no native phone GUI or configured multi-agent orchestrator.

### Herdr and worker agents

As `agent`, save OpenAI credentials in `/home/agent/.pi/agent/auth.json`, mode `0600`; never in the repo. Each VM needs its own credentials:

```json
{"openai":{"type":"api_key","key":"<api-key>"}}
```

On A1 as `agent`, register both workers over MagicDNS, then open the persistent dashboard:

```sh
configure-herdr-workers # defaults: pi-worker1 and pi-worker2
# Or: configure-herdr-workers <worker1-magicdns-name-or-ip> <worker2-magicdns-name-or-ip>
herdr --session a1
```

Select each machine in the sidebar, enter its project directory, and run `pi --provider openai`. Detach with Ctrl+B, then Q. In an A1 shell pane, use `herdr --machine worker1 agent list`, then `herdr --machine worker1 agent prompt <target> '<task>' --wait`. Herdr does not automatically distribute tasks or copy projects or credentials.

`configure-herdr-workers` saves private SSH aliases and registers `worker1` / `worker2` in both Herdr TUI and herdr-core (separate runtimes). It can be rerun with the same hosts. `agent` lingering keeps terminals alive after logout, not reboot. To run and inspect a core-managed worker terminal from A1:

```sh
hc run --bg --on worker1 --cwd /home/agent --name pi pi --provider openai
hc ls
hc read worker1/pi --lines 100
hc send worker1/pi '<task>'
hc attach worker1/pi # Ctrl+\ detaches
```

Enroll all three VMs in the same tailnet. From the hub as `agent`, connect to either micro using its Tailscale IP (or MagicDNS name):

```sh
tailscale status
ssh agent@<micro-tailscale-ip>
# Run a worker command without opening a shell:
ssh agent@<micro-tailscale-ip> 'hostname'
```

Tailscale SSH uses tailnet identity; no shared SSH keys are needed. The policy above allows hub → micros, not micros → hub. For reverse access, add a grant from `tag:pi-worker` to `tag:pi-hub` for `tcp:22` and an SSH `accept` rule with the same source/destination and `users: ["agent"]`, then run `ssh agent@<hub-tailscale-ip>` from a micro. This provides SSH access, not automatic worker registration or job scheduling.

The `agent` account has no sudo or Docker-group access. Keep provider credentials in this account's private home, never the repository; grant only necessary OCI permissions and review plans before applying. Pi can execute shell commands as this account without an approval boundary.

The instance NSG allows outbound UDP 3478/41641 and HTTPS 443 for Tailscale DERP fallback. No public ingress is added; direct connections are not guaranteed. Keep OCI Bastion for recovery.

Existing VMs do not rerun cloud-init when metadata changes. Copy `scripts/setup-agents.sh` to each VM through Bastion and run `sudo bash setup-agents.sh hub` on ARM or `sudo bash setup-agents.sh worker` on each micro, then enroll. Copy `scripts/configure-herdr-workers.sh` to A1, install it with `sudo install -m 0755 configure-herdr-workers.sh /usr/local/bin/configure-herdr-workers`, and run `configure-herdr-workers` as `agent`. Do not replace VMs just to install these tools.

State is in the private, versioned `chechia-terraform-state` bucket; never delete it or commit state, credentials, or private keys. Replacing an instance deletes its boot disk; shrinking a disk requires replacement. Review instance plans carefully when changing cloud-init.
