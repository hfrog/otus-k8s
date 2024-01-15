#!/bin/bash
set -x
set -e

. scripts/environment_vars.sh

cd terraform
terraform plan -var="ssh-keys='$SSH_KEYS'" -var="lb_ip_pool=$LB_IP_POOL"
