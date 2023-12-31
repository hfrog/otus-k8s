#!/bin/bash
set -x
set -e

cd terraform
terraform apply -auto-approve -var="ssh-keys=ubuntu:$SSH_KEYS"
