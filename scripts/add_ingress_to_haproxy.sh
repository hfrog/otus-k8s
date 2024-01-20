#!/bin/bash
set -x
set -e

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/k8s/admin.conf .
INGRESS_EXTERNAL_IP=$(kubectl --kubeconfig=admin.conf get svc ingress-nginx-controller -n ingress-nginx -o=jsonpath='{.status.loadBalancer.ingress[].ip}')

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/terraform/terraform-output.json .
LBS=$(jq -r '.external_ip.value|with_entries(select(.key|startswith("lb-")))|.[]' terraform-output.json)
for f in $LBS; do
  scp -o StrictHostKeyChecking=no scripts/local_add_ingress_to_haproxy.sh ubuntu@${f}:
  ssh ubuntu@$f sudo INGRESS_EXTERNAL_IP=$INGRESS_EXTERNAL_IP ./local_add_ingress_to_haproxy.sh
done
