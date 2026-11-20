import base64
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("bootstrap", Path(__file__).with_name("bootstrap-mysql.py"))
b = importlib.util.module_from_spec(spec)
spec.loader.exec_module(b)


class BootstrapTests(unittest.TestCase):
    def test_rejects_legacy_state(self):
        for state in [{"resources": [{"type": "random_password"}]},
                      {"resources": [{"instances": [{"attributes": {"admin_password": "secret"}}]}]},
                      {"outputs": {"admin_password": {"value": "secret"}}}]:
            with self.assertRaises(RuntimeError):
                b.clean_state(state)

    def test_create_password_only_in_stdin_and_import_without_secret(self):
        password = "Synthetic-password-123!"
        calls = []
        db = {"id": "db", "compartment-id": "comp", "subnet-id": "sub",
              "shape-name": "MySQL.Free", "display-name": "asre-mysql", "nsg-ids": ["nsg"],
              "lifecycle-state": "ACTIVE"}

        def fake_run(args, stage, cwd=None, payload=None):
            calls.append((args, payload))
            if args[0] == "terragrunt":
                if "output" in args:
                    values = ({"vault_id": "vault", "key_id": "key"} if "mysql-vault" in str(cwd)
                              else {"compartment_ocid": "comp", "subnet_ocids": {"database": "sub"},
                                    "database_nsg_ocid": "nsg"})
                    return json.dumps({k: {"value": v} for k, v in values.items()})
                if "pull" in args:
                    return json.dumps({"resources": [{"instances": [{"attributes": {"admin_password": None}}]}]})
                return ""
            if "secret-bundle" in args:
                data = {"secret-bundle-content": {"content": base64.b64encode(password.encode()).decode()}}
            elif "secret" in args:
                data = {"vault-id": "vault", "key-id": "key", "compartment-id": "comp"}
            elif "list" in args:
                data = []
            elif "create" in args:
                self.assertEqual(json.loads(payload)["adminPassword"], password)
                self.assertIn("file:///dev/stdin", args)
                data = db
            else:
                data = db
            return json.dumps({"data": data})

        out = io.StringIO()
        with patch.object(b, "run", side_effect=fake_run), \
             patch.object(b.subprocess, "run", return_value=subprocess.CompletedProcess([], 1, "", "No state file was found")), \
             patch.dict(os.environ, {"OCI_TF_AUTH": "APIKey"}, clear=True), \
             patch("sys.argv", ["bootstrap", "--secret-id", "secret", "--create"]), contextlib.redirect_stdout(out):
            b.main()
        self.assertNotIn(password, out.getvalue())
        self.assertTrue(any("import" in args for args, _ in calls))
        for args, payload in calls:
            self.assertNotIn(password, " ".join(args))
            if args[0] == "terragrunt":
                self.assertIsNone(payload)

    def test_cli_error_does_not_expose_payload(self):
        result = subprocess.CompletedProcess([], 1, "secret response", "secret diagnostics")
        with patch.object(b.subprocess, "run", return_value=result):
            with self.assertRaisesRegex(RuntimeError, "diagnostics withheld") as error:
                b.run(["oci"], "Create", payload="secret payload")
        self.assertNotIn("secret", str(error.exception))


if __name__ == "__main__":
    unittest.main()
