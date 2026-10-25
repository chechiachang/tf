SHELL := /bin/bash

OCI_REGION ?= ap-osaka-1
OCI_PROFILE ?= tf
OCI_AUTH ?= security_token
OCI_BASTION_CLIENT_CIDR ?=
export OCI_BASTION_CLIENT_CIDR
SSH_KEY ?= $(HOME)/.ssh/id_rsa
LOCAL_PORT ?= 2222
INSTANCE_INDEX ?= 0

NETWORK_DIR := dev/$(OCI_REGION)/network
INSTANCE_DIR ?= dev/$(OCI_REGION)/asre/instance
BASTION_HOST := host.bastion.$(OCI_REGION).oci.oraclecloud.com

OCI := oci --profile $(OCI_PROFILE) --auth $(OCI_AUTH) --region $(OCI_REGION)

.SHELLFLAGS := -eu -o pipefail -c

.PHONY: help auth bastion-allow ssh

help:
	@printf '%s\n' \
	  'make auth' \
	  'make bastion-allow OCI_BASTION_CLIENT_CIDR=<your-current-public-ip>/32' \
	  'make ssh [SSH_KEY=~/.ssh/id_rsa] [LOCAL_PORT=2222]' \
	  'make ssh INSTANCE_DIR=dev/ap-osaka-1/asre/amd INSTANCE_INDEX=0 # or 1'

auth:
	oci session authenticate --region $(OCI_REGION) --profile-name $(OCI_PROFILE)
	oci session validate --profile $(OCI_PROFILE) --auth $(OCI_AUTH)

bastion-allow:
	@test -n "$(OCI_BASTION_CLIENT_CIDR)" || { printf '%s\n' 'Set OCI_BASTION_CLIENT_CIDR to your current public IPv4 /32.' >&2; exit 2; }
	cd "$(NETWORK_DIR)" && OCI_BASTION_CLIENT_CIDR="$(OCI_BASTION_CLIENT_CIDR)" terragrunt apply

ssh:
	@set -euo pipefail; \
	  export OCI_BASTION_CLIENT_CIDR="$$(curl -fsS --max-time 10 https://api.ipify.org)/32"; \
	  oci session validate --profile $(OCI_PROFILE) --auth $(OCI_AUTH); \
	bastion=$$(cd "$(NETWORK_DIR)" && terragrunt output -raw bastion_ocid); \
	ip=$$(cd "$(INSTANCE_DIR)" && terragrunt output -json private_ips | python3 -c 'import json,sys; print(json.load(sys.stdin)[$(INSTANCE_INDEX)])'); \
	ssh-add "$(SSH_KEY)"; \
	session=$$($(OCI) bastion session create-port-forwarding --bastion-id "$$bastion" --target-private-ip "$$ip" --target-port 22 --ssh-public-key-file "$(SSH_KEY).pub" --session-ttl 3600 --query data.id --raw-output); \
	socket="/tmp/oci-bastion-$$$$.sock"; \
	trap 'ssh -S "$$socket" -O exit "$$session@$(BASTION_HOST)" >/dev/null 2>&1 || true; rm -f "$$socket"; $(OCI) bastion session delete --session-id "$$session" --force >/dev/null 2>&1 || true' EXIT; \
	echo 'Waiting for Bastion session...'; \
	for attempt in {1..60}; do \
	  state=$$($(OCI) bastion session get --session-id "$$session" --query 'data."lifecycle-state"' --raw-output); \
	  [[ "$$state" == ACTIVE ]] && break; \
	  [[ "$$state" == FAILED || "$$state" == TERMINATED ]] && exit 1; \
	  sleep 2; \
	done; \
	[[ "$$state" == ACTIVE ]]; \
	for attempt in {1..30}; do \
	  if ssh -M -S "$$socket" -fN -i "$(SSH_KEY)" -o IdentitiesOnly=yes -o ExitOnForwardFailure=yes -o ConnectTimeout=15 -L "$(LOCAL_PORT):$$ip:22" "$$session@$(BASTION_HOST)"; then break; fi; \
	  sleep 2; \
	done; \
	ssh -S "$$socket" -O check "$$session@$(BASTION_HOST)"; \
	ssh -i "$(SSH_KEY)" -o IdentitiesOnly=yes -o ConnectTimeout=15 -o HostKeyAlias="oci-$(OCI_REGION)-$$ip" -p $(LOCAL_PORT) ubuntu@127.0.0.1;
