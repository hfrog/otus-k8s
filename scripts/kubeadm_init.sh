#!/bin/bash
set -x
set -e

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/terraform/terraform-output.json .
MASTER1=$(jq -r '.external_ip.value."master-1"' terraform-output.json)
scp -o StrictHostKeyChecking=no scripts/local_kubeadm_init.sh ubuntu@${MASTER1}:
ssh ubuntu@$MASTER1 sudo ./local_kubeadm_init.sh
scp ubuntu@${MASTER1}:admin.conf .
aws s3 --endpoint-url=https://storage.yandexcloud.net cp admin.conf s3://$BUCKET/k8s/admin.conf
