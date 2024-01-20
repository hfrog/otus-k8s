# External apiserver port
export API_SERVER_PORT=6443

# Kubernetes version
export K8S_VERSION=1.28

export POD_NETWORK_CIDR=10.244.0.0/16

# IP Pool for LoadBalancer type services
export LB_IP_POOL=10.200.0.0/24

export INGRESS_NGINX_HELM_VERSION=4.9.0
export CERT_MANAGER_HELM_VERSION=v1.13.3
