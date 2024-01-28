#!/bin/bash
set -x
set -e

. environment_vars.sh

function wait_for_readiness {
  echo Waiting for node readiness
  i=0
  while ! kubectl get nodes | grep -qw Ready; do
    sleep 1
    i=$(( i + 1 ))
    [ $i -ge 60 ] && break
  done || true
}

function install_yq {
  local BINARY=yq_linux_amd64
  wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${BINARY}.tar.gz -O - | \
    tar xz && mv ${BINARY} /usr/local/bin/yq && ./install-man-page.sh && rm -f install-man-page.sh yq.1
}

function install_helm {
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
  sudo apt-get update
  sudo apt-get -y install helm
}

function install_prometheus_crds {
  install_yq
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm template prometheus prometheus-community/kube-prometheus-stack --include-crds --version $PROMETHEUS_HELM_VERSION | \
    yq 'select(.kind == "CustomResourceDefinition")' | kubectl create -f -
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
  install_cilium_client # It won't be used for installation, just a useful utility

  # -N for wget is to overwrite existing file
  wget -N https://github.com/cilium/charts/raw/master/cilium-$CILIUM_VERSION.tgz
  tar xzf cilium-$CILIUM_VERSION.tgz

  expand_vars k8s/cilium/values.yaml.tmpl
  helm upgrade --install cilium ./cilium --wait \
    --namespace kube-system --values k8s/cilium/values.yaml

  cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "lb-pool"
spec:
  cidrs:
  - cidr: "$LB_IP_POOL"
EOF

  rm -fr cilium-$CILIUM_VERSION.tgz cilium
}

function install_csi {
  [ -d k8s-csi-s3 ] && rm -fr k8s-csi-s3 || true
  git clone https://github.com/yandex-cloud/k8s-csi-s3.git
  git -C k8s-csi-s3 checkout $K8S_CSI_S3_VERSION
  expand_vars k8s/csi-s3/values.yaml.tmpl
  helm upgrade --install csi-s3 ./k8s-csi-s3/deploy/helm/csi-s3 \
    --namespace kube-system --values=k8s/csi-s3/values.yaml
  rm -fr k8s-csi-s3
}

function expand_vars {
  cat $1 | envsubst > ${1%.tmpl}
}

expand_vars k8s/kubeadm/config.yaml.tmpl
kubeadm init --config=k8s/kubeadm/config.yaml

export KUBECONFIG=/etc/kubernetes/admin.conf

install_helm
install_prometheus_crds # To create CRDs, especially ServiceMonitor
install_cilium
install_csi

wait_for_readiness
kubectl get nodes -o wide

# prepare admin.conf for downloading and then uploading to the Yandex S3 cloud
cp /etc/kubernetes/admin.conf ~ubuntu && chown ubuntu: ~ubuntu/admin.conf && chmod go-rw ~ubuntu/admin.conf
