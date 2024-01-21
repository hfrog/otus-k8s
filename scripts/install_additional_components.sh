#!/bin/bash
set -x
set -e

. scripts/environment_vars.sh

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/k8s/admin.conf .
chmod go-rw admin.conf
export KUBECONFIG=admin.conf

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/terraform/terraform-output.json .
export LB1_EXTERNAL_IP=$(jq -r '.external_ip.value|with_entries(select(.key == "lb-1"))|.[]' terraform-output.json)

function expand_yaml {
  cat $1 | envsubst > ${1/tmpl/yaml}
}

function install_helm {
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
  sudo apt-get update
  sudo apt-get -y install helm
}

function install_ingress_controller {
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace=ingress-nginx --create-namespace \
    --values k8s/ingress-nginx/values.yaml --version $INGRESS_NGINX_HELM_VERSION
}

function install_cert_manager {
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/$CERT_MANAGER_HELM_VERSION/cert-manager.crds.yaml
  helm repo add jetstack https://charts.jetstack.io
  helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version $CERT_MANAGER_HELM_VERSION
  kubectl apply -f k8s/cert-manager/manifests
}

function install_prometheus {
  expand_yaml k8s/prometheus/values.tmpl
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace=observability --create-namespace \
    --values k8s/prometheus/values.yaml --set grafana.adminPassword="$GRAFANA_PASSWORD" --version $PROMETHEUS_HELM_VERSION
}

function install_loki {
  helm repo add grafana https://grafana.github.io/helm-charts
  helm upgrade --install loki grafana/loki --namespace observability --create-namespace --values k8s/loki/values.yaml --version $LOKI_HELM_VERSION
}

function install_promtail {
  helm repo add grafana https://grafana.github.io/helm-charts
  helm upgrade --install promtail grafana/promtail --namespace observability --create-namespace --version $PROMTAIL_HELM_VERSION
}

install_helm
install_prometheus  # Install prometheus before ingress-nginx to create necessary CRD definitions
install_ingress_controller
install_cert_manager
install_loki
install_promtail
