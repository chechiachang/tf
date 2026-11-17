# Free serverless

One Worker with D1 (`DB`) and KV (`KV`) bindings. No routes, workers.dev endpoint, or preview URLs. D1/KV deletion and replacement are blocked. State uses the existing private OCI backend.

Use an account on **Workers Free**; Terraform does not enforce the subscription. Account-wide limits: 100,000 Worker requests/day, 10 ms CPU/request; D1 5 million rows read/day, 100,000 written/day, 5 GB total (500 MB/database); KV 100,000 reads/day, 1,000 writes/day, 1 GB total. Free-plan operations fail at limits; Paid accounts can incur charges. [Sources](../../../../free.csv).

Follow [Cloudflare authentication](../../../../README.md). For a scoped API token, grant only account Workers Scripts Write, D1 Write, and Workers KV Storage Write. Do not put tokens in HCL or bindings.

From this directory:

```sh
terragrunt hcl fmt
terragrunt run -- init
terragrunt run -- validate
terragrunt run -- plan
# After reviewing the plan:
terragrunt run -- apply
```

Invoke `GET /health` through another Worker's service binding or the dashboard test tool; it checks D1 and KV without writing. Add authentication before introducing public routes. Revert Worker code and apply to roll back; export D1/KV data before intentionally removing destruction protection.
