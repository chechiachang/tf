#!/usr/bin/env python3
"""Create bucket-only R2 credentials; never print or put secrets in Terraform state."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import sys
import urllib.error
import urllib.request

ACCOUNT = "664e4225fa00f97af165b5562ae199a9"
BUCKET = "abot-share"
PERMISSION = "Workers R2 Storage Bucket Item Write"  # Includes read/list/create.


def api(path, token, body=None):
    request = urllib.request.Request(
        "https://api.cloudflare.com/client/v4/" + path,
        data=None if body is None else json.dumps(body).encode(),
        headers={"Authorization": "Bearer " + token, "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            result = json.load(response)
    except urllib.error.HTTPError as error:
        # Do not log requests, response bodies, or credential-bearing exceptions.
        raise RuntimeError(f"Cloudflare HTTP {error.code}; check bootstrap token permissions") from None
    if not result.get("success"):
        raise RuntimeError("Cloudflare API request failed")
    return result["result"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="New private env file outside the repository")
    args = parser.parse_args()
    output = args.output.expanduser().resolve()
    repository = Path(__file__).resolve().parents[2]
    if output.is_relative_to(repository):
        raise RuntimeError("Credentials must be stored outside the repository")
    token = os.environ.get("CLOUDFLARE_API_TOKEN")
    if not token:
        raise RuntimeError("Set CLOUDFLARE_API_TOKEN with API Tokens Read and Write (not Wrangler OAuth)")
    groups = api("user/tokens/permission_groups", token)
    group = next((g for g in groups if g["name"] == PERMISSION), None)
    if group is None:
        raise RuntimeError("R2 object-write permission group not found")
    # Reserve storage before issuing credentials; refuse to overwrite existing credentials.
    output.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    fd = os.open(output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    created = None
    try:
        with os.fdopen(fd, "w") as file:
            created = api("user/tokens", token, {
                "name": "a1-codex-abot-share",
                "policies": [{
                    "effect": "allow",
                    "permission_groups": [{"id": group["id"]}],
                    "resources": {f"com.cloudflare.edge.r2.bucket.{ACCOUNT}_default_{BUCKET}": "*"},
                }],
            })
            values = {
                "R2_ACCESS_KEY_ID": created["id"],
                "R2_SECRET_ACCESS_KEY": hashlib.sha256(created["value"].encode()).hexdigest(),
                "R2_ENDPOINT": f"https://{ACCOUNT}.r2.cloudflarestorage.com",
                "R2_BUCKET": BUCKET,
            }
            file.write("".join(f"export {key}={shlex.quote(value)}\n" for key, value in values.items()))
    except Exception:
        output.unlink(missing_ok=True)
        if created:
            print(f"Revoke token {created['id']}: local credential save failed", file=sys.stderr)
        raise
    print(f"Created bucket-scoped token; credentials saved to {output} (0600)")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        print(str(error) if isinstance(error, RuntimeError) else "Failed to create or save R2 credentials", file=sys.stderr)
        sys.exit(1)
