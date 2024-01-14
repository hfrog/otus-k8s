#!/bin/bash
set -x
set -e

. scripts/environment_vars.sh

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/terraform/terraform-output.json .
LBS=$(jq -r '.external_ip.value|with_entries(select(.key|startswith("lb-")))|.[]' terraform-output.json)
for f in $LBS; do
  scp -o StrictHostKeyChecking=no scripts/local_install_haproxy.sh terraform-output.json ubuntu@${f}:
  ssh ubuntu@$f sudo API_SERVER_PORT=$API_SERVER_PORT ./local_install_haproxy.sh
done
