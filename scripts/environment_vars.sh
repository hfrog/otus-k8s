# External apiserver port
export API_SERVER_PORT=6443

# Kubernetes version
export K8S_VERSION=1.28

export POD_NETWORK_CIDR=10.244.0.0/16

# IP Pool for LoadBalancer type services
export LB_IP_POOL=10.200.0.0/24

export CILIUM_VERSION=1.15.0-rc.1
export K8S_CSI_S3_VERSION=v0.40.0
export INGRESS_NGINX_HELM_VERSION=4.9.0
export CERT_MANAGER_HELM_VERSION=v1.13.3
export PROMETHEUS_HELM_VERSION=56.0.1
export LOKI_HELM_VERSION=5.41.7
export PROMTAIL_HELM_VERSION=6.15.3
