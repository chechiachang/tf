#!/bin/bash
set -euo pipefail

if [[ "$EUID" != 0 ]]; then
  echo 'Run as root.' >&2
  exit 1
fi
case "${1:-}" in
  hub|worker) role="$1" ;;
  *) echo 'Usage: setup-agents.sh hub|worker' >&2; exit 2 ;;
esac

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg -o /etc/apt/keyrings/tailscale.gpg
chmod a+r /etc/apt/keyrings/tailscale.gpg
echo 'deb [signed-by=/etc/apt/keyrings/tailscale.gpg] https://pkgs.tailscale.com/stable/ubuntu noble main' > /etc/apt/sources.list.d/tailscale.list
apt-get update
apt-get install -y tailscale
systemctl enable --now tailscaled.service

if ! id agent >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash agent
fi
chmod 0700 /home/agent

if [[ "$role" == hub ]]; then
  apt-get install -y gnupg git tmux
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key -o /etc/apt/keyrings/nodesource.asc
  gpg --batch --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg /etc/apt/keyrings/nodesource.asc
  chmod a+r /etc/apt/keyrings/nodesource.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main' > /etc/apt/sources.list.d/nodesource.list
  apt-get update
  apt-get install -y nodejs
  node -e 'const [major, minor] = process.versions.node.split(".").map(Number); if (major < 22 || (major === 22 && minor < 19)) { throw new Error("Pi requires Node.js >=22.19"); }'
  npm install --global --prefix /usr/local --ignore-scripts @earendil-works/pi-coding-agent@1.5.2
  pi --version
fi

echo 'Installed. Enroll interactively with sudo tailscale up --ssh and configure tailnet access policies.'
