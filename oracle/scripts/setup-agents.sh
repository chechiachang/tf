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

apt-get install -y gnupg git sudo openssh-client python3
loginctl enable-linger agent
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key -o /etc/apt/keyrings/nodesource.asc
gpg --batch --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg /etc/apt/keyrings/nodesource.asc
chmod a+r /etc/apt/keyrings/nodesource.gpg
echo 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main' > /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y nodejs
node -e 'const [major, minor] = process.versions.node.split(".").map(Number); if (major < 22 || (major === 22 && minor < 19)) { throw new Error("Pi requires Node.js >=22.19"); }'
npm install --global --prefix /usr/local --ignore-scripts @earendil-works/pi-coding-agent@1.5.2
pi --version

sudo -H -u agent bash -s <<'HERDR'
set -euo pipefail
umask 077
export PATH="$HOME/.local/bin:$PATH"
install -d -m 0700 "$HOME/.pi" "$HOME/.pi/agent"
if [[ ! -x "$HOME/.local/bin/herdr" ]] || ! herdr machine --help >/dev/null 2>&1; then
  installer=$(mktemp)
  trap 'rm -f "$installer"' EXIT
  curl -fsSL --retry 3 --connect-timeout 10 --max-time 60 https://herdr.dev/install.sh -o "$installer"
  sh "$installer"
fi
herdr --version
herdr integration install pi
if [[ ! -x "$HOME/.local/bin/herdr-core" ]]; then
  core_installer=$(mktemp)
  trap 'rm -f "${installer:-}" "$core_installer"' EXIT
  curl -fsSL --retry 3 --connect-timeout 10 --max-time 60 https://releases.herdr.dev/core/install.sh -o "$core_installer"
  sh "$core_installer"
fi
herdr-core --version
HERDR

echo "Installed Pi, Herdr and herdr-core for $role. Enroll with sudo tailscale up --ssh --hostname <pi-hub|pi-worker1|pi-worker2>; run herdr as agent."
