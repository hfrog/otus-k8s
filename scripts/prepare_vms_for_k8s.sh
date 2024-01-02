#!/bin/bash
set -x
set -e

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/terraform/terraform-output.json .

mkdir ~/.ssh
VMS=$(jq -r .external_ip.value[] terraform-output.json)
echo $VMS
