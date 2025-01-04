#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

# 配置helm chart源
helm repo add cilium https://helm.cilium.io/

API_SERVER_IP="192.168.3.160"
API_SERVER_PORT="6443"
helm install cilium cilium/cilium --version 1.15.5 \
    --namespace kube-system \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT} \
    --set ipam.operator.clusterPoolIPv4PodCIDRList=10.0.0.0/16

#基于 eBPF 的 IP 地址伪装模式
helm upgrade cilium cilium/cilium \
   --namespace kube-system \
   --reuse-values \
   --set bpf.masquerade=true \
   --set devices=enp0s5

helm upgrade cilium cilium/cilium \
   --namespace kube-system \
   --reuse-values \
   --set nodeinit.enabled=true \
   --set rollOutCiliumPods=true \
   --set bpf.masquerade=true \
   --set ipMasqAgent.enabled=true \
   --set ipMasqAgent.nonMasqueradeCIDRs=["192.0.0.0/24"] \
   --set ipMasqAgent.masqLinkLocalIPv6=false \
   --set ipMasqAgent.masqLinkLocal=true \
   --set hubble.ui.enabled=true \
   --set hubble.relay.enabled=true \
   --set routingMode=native \
   --set autoDirectNodeRoutes=true \
   --set ipv4NativeRoutingCIDR="10.0.0.0/20" \
