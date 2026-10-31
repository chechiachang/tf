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
	cd "$(NETWORK_DIR)" && terragrunt run -- init -input=false && OCI_BASTION_CLIENT_CIDR="$(OCI_BASTION_CLIENT_CIDR)" terragrunt apply

ssh:
	@set -euo pipefail; \
	  export TG_DOWNLOAD_DIR=.terragrunt-cache; \
	  export OCI_BASTION_CLIENT_CIDR="$$(curl -fsS --max-time 10 https://api.ipify.org)/32"; \
	  oci session validate --profile $(OCI_PROFILE) --auth $(OCI_AUTH); \
	(cd "$(NETWORK_DIR)" && terragrunt run -- init -input=false); \
	bastion=$$(cd "$(NETWORK_DIR)" && terragrunt output -raw bastion_ocid); \
	allowed=$$($(OCI) bastion bastion get --bastion-id "$$bastion" --query 'data."client-cidr-block-allow-list"' --output json); \
	if ! python3 -c 'import ipaddress,json,sys; ip=ipaddress.ip_interface(sys.argv[1]).ip; sys.exit(0 if any(ip in ipaddress.ip_network(cidr) for cidr in json.load(sys.stdin)) else 1)' "$$OCI_BASTION_CLIENT_CIDR" <<< "$$allowed"; then \
	  printf 'Bastion does not allow your current IP. Run from oracle/:\nmake bastion-allow OCI_BASTION_CLIENT_CIDR=%s\n' "$$OCI_BASTION_CLIENT_CIDR" >&2; \
	  exit 2; \
	fi; \
	(cd "$(INSTANCE_DIR)" && terragrunt run -- init -input=false); \
	private_ips=$$(cd "$(INSTANCE_DIR)" && terragrunt output -json private_ips); \
	ip=$$(python3 -c 'import json,sys; print(json.load(sys.stdin)[$(INSTANCE_INDEX)])' <<< "$$private_ips"); \
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
	  if ssh -M -S "$$socket" -fN -i "$(SSH_KEY)" -o IdentitiesOnly=yes -o ExitOnForwardFailure=yes -o ConnectTimeout=15 -L "$(LOCAL_PORT):$$ip:22" "$$session@$(BASTION_HOST)"; then \
	    for ready in {1..5}; do \
	      if ssh -S "$$socket" -O check "$$session@$(BASTION_HOST)" >/dev/null 2>&1; then break 2; fi; \
	      sleep 1; \
	    done; \
	  fi; \
	  sleep 2; \
	done; \
	ssh -S "$$socket" -O check "$$session@$(BASTION_HOST)"; \
	ssh -i "$(SSH_KEY)" -o IdentitiesOnly=yes -o ConnectTimeout=15 -o HostKeyAlias="oci-$(OCI_REGION)-$$ip" -p $(LOCAL_PORT) ubuntu@127.0.0.1;
