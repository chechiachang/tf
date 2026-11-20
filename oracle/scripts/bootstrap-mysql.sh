#!/usr/bin/env bash
set +x
set -euo pipefail
umask 077
ulimit -c 0
unset TF_LOG TF_LOG_PATH OCI_CLI_DEBUG
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec python3 "$script_dir/bootstrap-mysql.py" "$@"
