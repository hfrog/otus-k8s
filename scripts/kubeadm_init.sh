#!/bin/bash
set -x
set -e

. scripts/environment_vars.sh

function fetch_and_upload_file {
  filename=$1
  scp ubuntu@${MASTER1}:$filename .
  aws s3 --endpoint-url=https://storage.yandexcloud.net cp $filename s3://$BUCKET/k8s/$filename
}

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/terraform/terraform-output.json .
MASTER1=$(jq -r '.external_ip.value."master-1"' terraform-output.json)
scp -o StrictHostKeyChecking=no scripts/local_kubeadm_init.sh scripts/environment_vars.sh k8s/kubeadm/kubeadm-config.tmpl ubuntu@${MASTER1}:
LB1=$(jq -r '.external_ip.value."lb-1"' terraform-output.json)
ssh ubuntu@$MASTER1 sudo \
  API_SERVER_IP=$LB1 \
  AWS_CSI_ACCESS_KEY_ID=$AWS_CSI_ACCESS_KEY_ID \
  AWS_CSI_SECRET_ACCESS_KEY=$AWS_CSI_SECRET_ACCESS_KEY \
  CSI_BUCKET=$CSI_BUCKET \
  ./local_kubeadm_init.sh

fetch_and_upload_file admin.conf
