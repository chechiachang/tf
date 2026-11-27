#!/bin/sh
# Run as agent after installing the Rex package and enabling lingering.
set -eu
[ "$(id -u)" != 0 ] || { echo "Run as agent, not root." >&2; exit 1; }
name=${1:-rex-arm1}
mode=${2:-ssh}
case "$name" in
  ''|*[!a-z0-9-]*|-*|*-) echo "Use a lowercase Tailscale hostname." >&2; exit 2 ;;
esac
case "$mode" in
  ssh) flags= ;;
  tailscale) flags=" --tailscale --tailscale-hostname $name" ;;
  *) echo "Usage: configure-rex [hostname] [ssh|tailscale]" >&2; exit 2 ;;
esac
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
umask 077
dropin="$HOME/.config/systemd/user/rex.service.d"
config=$(mktemp)
trap 'rm -f "$config"' EXIT HUP INT TERM
cat > "$config" <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/rex server run --log-format text$flags
EOF
if systemctl --user is-active --quiet rex.service && ! cmp -s "$config" "$dropin/tailscale.conf"; then
  echo "Rex is running. Review sessions, then stop rex.socket and rex.service before reconfiguring." >&2
  exit 1
fi
mkdir -p "$dropin"
install -m 0600 "$config" "$dropin/tailscale.conf"
rex server install
systemctl --user daemon-reload
systemctl --user enable --now rex.service
rex server status
