#!/bin/bash
set -x
set -e

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/terraform/terraform-output.json .

# renew join information
MASTER=$(jq -r '.external_ip.value."master-1"' terraform-output.json)
join_command=$(ssh -o StrictHostKeyChecking=no ubuntu@$MASTER sudo kubeadm token create --print-join-command)
certificate_key=$(ssh -o StrictHostKeyChecking=no ubuntu@$MASTER sudo kubeadm init phase upload-certs --upload-certs | grep -Ei '^[0-9a-f]+$')

# join masters except the first one
MASTERS=$(jq -r '.external_ip.value|with_entries(select(.key|startswith("master-")))|with_entries(select(.key != "master-1"))|.[]' terraform-output.json)
for f in $MASTERS; do
  ssh -o StrictHostKeyChecking=no ubuntu@$f sudo $join_command --control-plane --certificate-key $certificate_key
done

# join workers
WORKERS=$(jq -r '.external_ip.value|with_entries(select(.key|startswith("worker-")))|.[]' terraform-output.json)
for f in $WORKERS; do
  ssh -o StrictHostKeyChecking=no ubuntu@$f sudo $join_command
done
