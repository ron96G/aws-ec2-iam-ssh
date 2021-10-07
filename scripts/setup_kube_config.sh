#!/bin/bash

KUBE_CONFIG_DIR="/home/$1/.kube"

mkdir -p $KUBE_CONFIG_DIR
aws eks update-kubeconfig --name $CLUSTER_NAME --region $DEFAULT_REGION --kubeconfig $KUBE_CONFIG_DIR/config
grep -q "source <(kubectl completion bash)" /home/$1/.bashrc || echo 'source <(kubectl completion bash)' >> /home/$1/.bashrc
chown -R $1:$1 $KUBE_CONFIG_DIR