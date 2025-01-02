#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

# 配置helm chart源
helm repo add cilium https://helm.cilium.io/13667

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

# https://blog.csdn.net/sinat_32188225/article/details/108614704
# --set devices=enp0s5 \
helm repo add cilium https://helm.cilium.io
helm upgrade -i cilium cilium/cilium --namespace kube-system \
     --set nodeinit.enabled=true \
	 --set routingMode=native \
	 --set k8sClientRateLimit.qps=30 \
	 --set k8sClientRateLimit.burst=40 \
	 --set rollOutCiliumPods=true \
	 --set bpf.masquerade=true \
	 --set bpfClockProbe=true \
	 --set bpf.preallocateMaps=true \
	 --set bpf.tproxy=true \
	 --set bpf.hostLegacyRouting=false \
	 --set autoDirectNodeRoutes=true \
	 --set localRedirectPolicy=true \
	 --set ciliumEndpointSlice.enabled=true \
	 --set externalIPs.enabled=true \
	 --set hostPort.enabled=true \
	 --set socketLB.enabled=true \
	 --set nodePort.enabled=true \
	 --set sessionAffinity=true \
	 --set annotateK8sNode=true \
	 --set devices=enp0s5 \
	 --set nat46x64Gateway.enabled=false \
	 --set ipv6.enabled=false \
	 --set pmtuDiscovery.enabled=true \
	 --set enableIPv6BIGTCP=false \
	 --set sctp.enabled=false \
	 --set wellKnownIdentities.enabled=true \
	 --set hubble.enabled=true \
	 --set ipv4NativeRoutingCIDR=192.168.3.100/32 \
	 --set ipam.operator.clusterPoolIPv4PodCIDRList[0]="10.244.0.0/16" \
	 --set installNoConntrackIptablesRules=true \
	 --set enableIPv4BIGTCP=false \
	 --set egressGateway.enabled=false \
	 --set endpointRoutes.enabled=false \
	 --set kubeProxyReplacement=true \
	 --set loadBalancer.mode=dsr \
	 --set bandwidthManager.enabled=true \
	 --set bandwidthManager.bbr=true \
	 --set highScaleIPcache.enabled=false \
	 --set l2announcements.enabled=false \
	 --set l2podAnnouncements.interface=enp0s5 \
	 --set operator.rollOutPods=true \
	 --set authentication.enabled=false \
	 --set k8sServiceHost=192.168.3.100 \
	 --set k8sServicePort=6443

