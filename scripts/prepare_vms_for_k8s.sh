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
  ssh -o 'StrictHostKeyChecking=no' ubuntu@$f ip -br -c a
done
