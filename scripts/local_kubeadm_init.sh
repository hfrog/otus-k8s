#!/bin/bash
set -x
set -e

function install_helm {
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
  sudo apt-get update
  sudo apt-get -y install helm
}

function install_cilium_client {
  CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
  CLI_ARCH=$(dpkg --print-architecture)
  curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
  sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
  sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
  rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
}

function install_cilium {
  install_cilium_client # it won't be used for installation
  install_helm
  API_SERVER_IP=$(kubectl config view --minify -o json | jq -r .clusters[].cluster.server | awk -F'[/:]' '{print $4}')
  API_SERVER_PORT=$(kubectl config view --minify -o json | jq -r .clusters[].cluster.server | awk -F'[/:]' '{print $5}')
  helm repo add cilium https://helm.cilium.io/
  helm install cilium cilium/cilium --version 1.14.5 \
    --namespace kube-system \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT} \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true
}

function wait_for_readiness {
  echo Waiting for node readiness
  i=0
  while ! kubectl get nodes | grep -qw Ready; do
    sleep 1
    i=$(( i + 1 ))
    [ $i -ge 60 ] && break
  done || true
}

kubeadm init --pod-network-cidr=10.244.0.0/16 --skip-phases=addon/kube-proxy --control-plane-endpoint $APISERVER_IP:6443

export KUBECONFIG=/etc/kubernetes/admin.conf

wait_for_readiness
kubectl get nodes -o wide

install_cilium

# prepare admin.conf for downloading and then uploading to the Yandex S3 cloud
cp /etc/kubernetes/admin.conf ~ubuntu && chown ubuntu: ~ubuntu/admin.conf && chmod go-rw ~ubuntu/admin.conf
