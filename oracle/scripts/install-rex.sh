#!/bin/sh
# Install Rex preview; leave service activation to the operator.
set -eu
[ "$(id -u)" = 0 ] || { echo "Run with sudo." >&2; exit 1; }
installer=$(mktemp)
trap 'rm -f "$installer"' EXIT HUP INT TERM
curl --proto '=https' --tlsv1.2 -fsSL https://pkgs.superlogical.com/rex/install.sh -o "$installer"
# Reviewed 2026-11-27; re-review before updating this checksum.
printf '%s  %s\n' dce78e569ff30fe81ac53ac23960cc94620fd8c51515349c43989977fa06f3db "$installer" | sha256sum -c -
sh "$installer" --channel preview
