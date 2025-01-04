#!/usr/bin/env bash

helm repo add cilium https://helm.cilium.io/
helm repo update
export DEVICES="enp0s5"
export HOST="192.168.3.160"
export K8S_API_SERVER_PORT="6443"
export CILIUM_VERSION="1.15.0-rc.0"
export CLUSTER_NAME="prvite-kubernetes"
export CLUSTER_ID=1
helm install cilium cilium/cilium --version $CILIUM_VERSION \
--namespace kube-system \
--set k8sServiceHost=$HOST \
--set k8sServicePort=$K8S_API_SERVER_PORT \
--set cluster.name=$CLUSTER_NAME \
--set cluster.id="$CLUSTER_ID" \
--set nodeinit.enabled=true \
--set rollOutCiliumPods=true \
--set kubeProxyReplacement=true \
--set l2announcements.enabled=true \
--set externalIPs.enabled=true \
--set k8sClientRateLimit.qps=50 \
--set k8sClientRateLimit.burst=100
