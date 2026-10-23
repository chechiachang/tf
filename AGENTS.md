# Repository Guidelines

This is a Terraform live-infrastructure repository. Keep changes small and follow the existing stack and module layout.

## Terraform Changes

- Run `terraform fmt` on changed files and validate from the relevant stack directory.
- Review the Terraform plan before proposing infrastructure changes.
- Never commit credentials, state files, or other secrets.

## Security Review

Security first: review every change and plan for least-privilege IAM, public exposure, network access, secret handling, and unintended destructive changes **before committing**. Resolve findings before commit.

## Documentation

Keep READMEs and comments simple and compact. Document only what is needed to operate or safely change the infrastructure.
