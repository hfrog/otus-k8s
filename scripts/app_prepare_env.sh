#!/bin/bash
set -e
# set -x  # Don't show commands because of secrets

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/k8s/admin.conf .
WERF_KUBECONFIG_BASE64=$(base64 -w 0 < admin.conf)
echo "::add-mask::$WERF_KUBECONFIG_BASE64"
echo "WERF_KUBECONFIG_BASE64=$WERF_KUBECONFIG_BASE64" >> $GITHUB_ENV

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/terraform/terraform-output.json .
LB1_EXTERNAL_IP=$(jq -r '.external_ip.value."lb-1"' terraform-output.json)
echo "LB1_EXTERNAL_IP=$LB1_EXTERNAL_IP" >> $GITHUB_ENV
