#!/bin/bash
set -x
set -e

if [ "$RESET" = "yes" ]; then
  kubeadm reset
fi
kubeadm init --upload-certs --pod-network-cidr=10.244.0.0/16
#export KUBECONFIG=/etc/kubernetes/admin.conf
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
#kubectl get nodes -o wide
#cp /etc/kubernetes/admin.conf ~ubuntu && chown ubuntu: ~ubuntu/admin.conf
#kubeadm token list
