#!/bin/bash
set -x
set -e

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/terraform/terraform-output.json .

mkdir ~/.ssh
echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
chmod 400 ~/.ssh/id_ed25519

VMS=$(jq -r .external_ip.value[] terraform-output.json)
for f in $VMS; do
  echo $f
  scp -o StrictHostKeyChecking=no scripts/prepare_local_for_k8s.sh ubuntu@${f}:
  ssh ubuntu@$f sudo K8S_VERSION=$K8S_VERSION ./prepare_local_for_k8s.sh
done
