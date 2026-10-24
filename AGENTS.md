# Repository Guidelines

This is a Terraform live-infrastructure repository. Keep changes small and follow the existing stack and module layout.

## Less is better

Extremely compact and simple style description is preferred.

## Infrastructure Changes

- Use Terragrunt for every stack command; run `terragrunt hcl fmt` and validate from the stack directory.
- Prefer maintained community OCI modules. Add custom modules under `oracle/modules/` only when needed.
- Never commit credentials, state files, or other secrets.

## Security Review

Before committing, review changes and plans for least-privilege IAM, public exposure, network access, secret handling, and destructive changes. Resolve findings first.

## Documentation

Keep READMEs and comments simple and compact. Document only what is needed to operate or safely change the infrastructure.
