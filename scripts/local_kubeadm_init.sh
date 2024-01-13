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
  helm upgrade --install cilium cilium/cilium --wait --version 1.14.5 \
    --namespace kube-system \
    --set ipam.operator.clusterPoolIPv4PodCIDRList='["10.244.0.0/16"]' \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT} \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set bgpControlPlane.enabled=true \
    --set autoDirectNodeRoutes=true \
    --set routingMode=native \
    --set ipv4NativeRoutingCIDR="10.244.0.0/16"

#    --set ingressController.enabled=true
#    --set ingressController.service.type=NodePort

  cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "lb-pool"
spec:
  cidrs:
  - cidr: "10.200.0.0/24"
EOF

  cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2alpha1"
kind: CiliumBGPPeeringPolicy
metadata:
  name: bgp-policy-all-services
spec:
  nodeSelector:
    matchExpressions:
    - {key: somekey, operator: NotIn, values: ['never-used-value']} # all nodes
  virtualRouters:
  - localASN: 64512
    exportPodCIDR: true
    serviceSelector:
      matchExpressions:
      - {key: somekey, operator: NotIn, values: ['never-used-value']} # all services
    neighbors:
    - peerAddress: "192.168.10.35/32" # XXX
      peerASN: 64512
      connectRetryTimeSeconds: 30
      keepAliveTimeSeconds: 30
      gracefulRestart:
        enabled: true
        restartTimeSeconds: 60
EOF

  # enable ingress separately, because its LoadBalancer without CiliumLoadBalancerIPPool never goes out from pending state
  helm upgrade --install cilium cilium/cilium --wait --version 1.14.5 \
    --namespace kube-system \
    --reuse-values \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT} \
    --set ingressController.enabled=true
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
