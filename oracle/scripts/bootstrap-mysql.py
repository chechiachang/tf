#!/usr/bin/env python3
"""Secret-bearing OCI creation outside Terraform; never print CLI diagnostics."""
import argparse
import base64
from contextlib import contextmanager
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
REGION = "ap-osaka-1"
STACK = ROOT / "dev" / REGION / "asre/mysql"
ADDRESS = "oci_mysql_mysql_db_system.this"


def run(args, stage, cwd=None, payload=None):
    result = subprocess.run(args, input=payload, capture_output=True, text=True, cwd=cwd)
    if result.returncode:
        raise RuntimeError(f"{stage} failed; diagnostics withheld to protect credentials.")
    return result.stdout


def tg(stack, *args):
    return run(["terragrunt", "run", "--", *args], "Terragrunt " + args[0], stack)


def clean_state(state):
    for resource in state.get("resources", []):
        if resource.get("type") == "random_password":
            raise RuntimeError("Legacy password state detected; use a separate migration.")
        for instance in resource.get("instances", []):
            if instance.get("attributes", {}).get("admin_password"):
                raise RuntimeError("Password found in state; stop and rotate/migrate with an administrator.")
    if state.get("outputs", {}).get("admin_password", {}).get("value"):
        raise RuntimeError("Legacy password output detected; use a separate migration.")


@contextmanager
def remote_lock(oci):
    """Atomic conditional OCI object write; body contains a non-secret owner token."""
    uri = ("https://objectstorage.ap-osaka-1.oraclecloud.com/n/axyygu1yi2iu/"
           "b/chechia-terraform-state/o/dev%2Fap-osaka-1%2Fasre%2Fmysql%2Fbootstrap.lock")
    result = oci("raw-request", "--target-uri", uri, "--http-method", "PUT",
                 "--request-headers", json.dumps({"If-None-Match": "*"}),
                 "--request-body", json.dumps({"owner": str(uuid.uuid4())}))
    if not result.get("status", "").startswith("2"):
        raise RuntimeError("Bootstrap lock unavailable; another bootstrap may be running.")
    etag = next((value for key, value in result.get("headers", {}).items() if key.lower() == "etag"), None)
    if not etag:
        raise RuntimeError("Lock created but ETag missing; inspect the bootstrap lock before retrying.")
    try:
        yield
    finally:
        result = oci("raw-request", "--target-uri", uri, "--http-method", "DELETE",
                     "--request-headers", json.dumps({"If-Match": etag}))
        if not result.get("status", "").startswith("2"):
            raise RuntimeError("Conditional bootstrap lock release failed; inspect its owner before retrying.")


def main():
    parser = argparse.ArgumentParser(description="Create/import MySQL from a manually populated Vault secret.")
    parser.add_argument("--secret-id", required=True)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--create", action="store_true", help="Explicitly authorize creation of one MySQL.Free DB.")
    action.add_argument("--db-system-id", help="Resume using an existing bootstrap-created DB; never create another.")
    args = parser.parse_args()
    if any(os.environ.get(k) for k in ("TF_LOG", "TF_LOG_PATH", "OCI_CLI_DEBUG")):
        raise RuntimeError("Disable credential-bearing debug logging first.")
    auth = os.environ.get("OCI_TF_AUTH", "SecurityToken")
    auth = {"APIKey": "api_key", "SecurityToken": "security_token", "InstancePrincipal": "instance_principal"}[auth]
    cli = ["oci", "--auth", auth, "--region", REGION]
    if auth != "instance_principal":
        cli += ["--profile", os.environ.get("OCI_TF_PROFILE", "tf")]

    def oci(*parts, payload=None):
        return json.loads(run(cli + list(parts), "OCI " + " ".join(parts[:3]), payload=payload))

    with remote_lock(oci):
        # These outputs contain identifiers only, not secret contents.
        network = json.loads(tg(ROOT / "dev" / REGION / "network", "output", "-json"))
        vault = json.loads(tg(ROOT / "dev" / REGION / "asre/mysql-vault", "output", "-json"))
        compartment = network["compartment_ocid"]["value"]
        subnet = network["subnet_ocids"]["value"]["database"]
        nsg = network["database_nsg_ocid"]["value"]
        secret = oci("vault", "secret", "get", "--secret-id", args.secret_id)["data"]
        if (secret["vault-id"] != vault["vault_id"]["value"] or
                secret["key-id"] != vault["key_id"]["value"] or
                secret["compartment-id"] != compartment):
            raise RuntimeError("Secret does not belong to the configured MySQL vault/key/compartment.")
        os.environ["OCI_MYSQL_DB_SYSTEM_OCID"] = args.db_system_id or "ocid1.mysqldbsystem.oc1..bootstrap"
        tg(STACK, "init", "-input=false")
        snapshot = subprocess.run(["terragrunt", "run", "--", "state", "pull"],
                                  capture_output=True, text=True, cwd=STACK)
        if snapshot.returncode:
            if "No state file was found" not in snapshot.stderr:
                raise RuntimeError("Cannot inspect MySQL state; stop before creation.")
        else:
            state = json.loads(snapshot.stdout) if snapshot.stdout.strip() else {}
            clean_state(state)  # Includes outputs-only state, before any DB creation.
            if any(r.get("type") == "oci_mysql_mysql_db_system" and r.get("name") == "this"
                   for r in state.get("resources", [])):
                raise RuntimeError("DB already managed: use a reviewed Terragrunt plan, not bootstrap.")
        if args.create:
            matches = oci("mysql", "db-system", "list", "--compartment-id", compartment,
                          "--display-name", "asre-mysql", "--all")["data"]
            if any(db.get("lifecycle-state") != "DELETED" for db in matches):
                raise RuntimeError("Existing asre-mysql found; resume with --db-system-id after checking its identity.")
            bundle = oci("secrets", "secret-bundle", "get", "--secret-id", args.secret_id, "--stage", "CURRENT")["data"]
            password = base64.b64decode(bundle["secret-bundle-content"]["content"], validate=True).decode()
            if not password:
                raise RuntimeError("Vault password is empty.")
            payload = json.dumps({"compartmentId": compartment, "availabilityDomain": "gynr:AP-OSAKA-1-AD-1",
                                  "subnetId": subnet, "nsgIds": [nsg], "shapeName": "MySQL.Free",
                                  "displayName": "asre-mysql", "adminUsername": "asreadmin",
                                  "adminPassword": password, "dataStorageSizeInGbs": 50,
                                  "isHighlyAvailable": False})
            # JSON travels through a pipe, not argv or a plaintext file. OCI output is captured.
            created = oci("mysql", "db-system", "create", "--from-json", "file:///dev/stdin", payload=payload)
            db_id = created["data"]["id"]
            del password, payload, bundle, created
            print("Created DB:", db_id, flush=True)
            print("If interrupted, resume with --db-system-id", db_id, flush=True)
        else:
            db_id = args.db_system_id
        deadline = time.monotonic() + 1800
        while True:
            db = oci("mysql", "db-system", "get", "--db-system-id", db_id)["data"]
            if (db["compartment-id"] != compartment or db["subnet-id"] != subnet or
                    db["shape-name"] != "MySQL.Free" or db["display-name"] != "asre-mysql" or
                    nsg not in db.get("nsg-ids", [])):
                raise RuntimeError("DB does not match the configured bootstrap target.")
            if db["lifecycle-state"] == "ACTIVE":
                break
            if db["lifecycle-state"] in ("FAILED", "DELETING", "DELETED") or time.monotonic() >= deadline:
                raise RuntimeError("DB not active; inspect it in OCI and resume later. No automatic deletion.")
            time.sleep(15)
        os.environ["OCI_MYSQL_DB_SYSTEM_OCID"] = db_id
        tg(STACK, "import", "-input=false", ADDRESS, db_id)
        clean_state(json.loads(tg(STACK, "state", "pull")))
        print("Imported; verified no MySQL admin password in current state.")
        print("Export OCI_MYSQL_DB_SYSTEM_OCID=" + db_id + " before subsequent Terragrunt commands.")
        print("Review a plan next; HeatWave creation/configuration is not applied by this script.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, KeyError, ValueError, OSError) as error:
        # Even decode/API errors must not leak secret-bearing payloads or responses.
        if isinstance(error, RuntimeError):
            print(str(error), file=sys.stderr)
        else:
            print("Bootstrap stopped: invalid configuration or API response; details withheld.", file=sys.stderr)
        sys.exit(1)
