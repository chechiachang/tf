#!/bin/bash
set -euo pipefail

if [[ $(id -un) != agent ]]; then
  echo 'Run as agent on A1.' >&2
  exit 1
fi
if (( $# != 0 && $# != 2 )); then
  echo 'Usage: configure-herdr-workers [worker1-host worker2-host]' >&2
  exit 2
fi
worker1_host=${1:-pi-worker1}
worker2_host=${2:-pi-worker2}
for host in "$worker1_host" "$worker2_host"; do
  if [[ ! $host =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]]; then
    echo 'Use a MagicDNS name or Tailscale IPv4 address.' >&2
    exit 2
  fi
done
if [[ $worker1_host == "$worker2_host" ]]; then
  echo 'Workers must have different hosts.' >&2
  exit 2
fi

umask 077
export PATH="$HOME/.local/bin:$PATH"
herdr machine --help >/dev/null
herdr-core --version
install -d -m 0700 "$HOME/.ssh"
# Trust only worker host keys advertised by the authenticated tailnet.
tailscale status --json | python3 -c '
import json,sys
peers = json.load(sys.stdin).get("Peer", {}).values()
for host in sys.argv[1:]:
    for peer in peers:
        dns = peer.get("DNSName", "").rstrip(".")
        names = [dns, dns + ".", dns.split(".")[0]] + peer.get("TailscaleIPs", [])
        if host in names:
            keys = peer.get("sshHostKeys") or []
            if not keys:
                sys.exit("Enable Tailscale SSH on worker: " + host)
            for key in keys:
                if "\n" in key or "\r" in key:
                    sys.exit("Invalid advertised SSH host key")
                print(host + " " + key.strip())
            break
    else:
        sys.exit("Worker not found in tailnet: " + host)
' "$worker1_host" "$worker2_host" > "$HOME/.ssh/herdr-workers.known_hosts"
cat > "$HOME/.ssh/herdr-workers.conf" <<EOF
Host herdr-worker1
  HostName $worker1_host
Host herdr-worker2
  HostName $worker2_host
Host herdr-worker1 herdr-worker2
  User agent
  ForwardAgent no
  StrictHostKeyChecking yes
  UserKnownHostsFile ~/.ssh/herdr-workers.known_hosts
  ServerAliveInterval 30
  ServerAliveCountMax 3
Host *
EOF
include='Include ~/.ssh/herdr-workers.conf'
if ! grep -qxF "$include" "$HOME/.ssh/config" 2>/dev/null; then
  config=$(mktemp "$HOME/.ssh/config.XXXXXX")
  trap 'rm -f "$config"' EXIT
  printf '%s\n' "$include" > "$config"
  if [[ -f $HOME/.ssh/config ]]; then
    cat "$HOME/.ssh/config" >> "$config"
  fi
  mv "$config" "$HOME/.ssh/config"
fi

# Read official registries; do not reuse unrelated machine profiles.
machine_names() {
  python3 -c '
import json,sys
kind = sys.argv[1]
data = json.load(sys.stdin)
rows = data if kind == "herdr" else data["machines"]
key = "label" if kind == "herdr" else "name"
for row in rows:
    name = row[key]
    if name in ("worker1", "worker2"):
        if row["target"] != "herdr-" + name or (row.get("session") or "default") != "default" or not row.get("enabled", True):
            sys.exit("Conflicting or disabled profile: " + name + "; inspect the machine registry first.")
    print(name)
' "$1"
}
herdr_names=$(herdr machine list --json | machine_names herdr)
core_names=$(herdr-core machine ls --json | machine_names core)
for index in 1 2; do
  name=worker$index
  target=herdr-worker$index
  ssh -o BatchMode=yes -o ConnectTimeout=15 "$target" 'set -e; export PATH="$HOME/.local/bin:$PATH"; herdr machine --help >/dev/null; herdr --version; herdr-core --version'
  if ! grep -qxF "$name" <<< "$herdr_names"; then
    herdr machine add "$target" --label "$name" --remote-session default
  fi
  if ! grep -qxF "$name" <<< "$core_names"; then
    herdr-core machine add "$target" --name "$name"
  fi
done
herdr machine status
herdr-core machine ls
