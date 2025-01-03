#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

k8sServiceHost="192.168.3.100"
k8sServicePort=6443
podCIDR="172.0.0.0/16"
devices="eth0"
cilium install cilium cilium/cilium --namespace kube-system \
   --set nodeinit.enabled=true \
	 --set k8sClientRateLimit.qps=30 \
	 --set k8sClientRateLimit.burst=40 \
	 --set rollOutCiliumPods=true \
	 --set bpf.masquerade=false \
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
	 --set nat46x64Gateway.enabled=false \
	 --set ipv6.enabled=false \
	 --set pmtuDiscovery.enabled=true \
	 --set enableIPv6BIGTCP=false \
	 --set sctp.enabled=false \
	 --set wellKnownIdentities.enabled=true \
	 --set hubble.enabled=true \
	 --set ipam.mode=cluster-pool \
	 --set ipam.podCIDR=$podCIDR \
	 --set ipv4NativeRoutingCIDR=$podCIDR \
	 --set autoDirectNodeRoutes=true \
	 --set installNoConntrackIptablesRules=true \
	 --set enableIPv4BIGTCP=false \
	 --set egressGateway.enabled=false \
	 --set endpointRoutes.enabled=false \
	 --set kubeProxyReplacement=true \
	 --set routingMode=native \
	 --set loadBalancer.mode=dsr \
	 --set bandwidthManager.enabled=true \
	 --set bandwidthManager.bbr=true \
	 --set highScaleIPcache.enabled=false \
	 --set l2announcements.enabled=false \
	 --set devices=$devices \
	 --set l2podAnnouncements.interface=$devices \
	 --set operator.rollOutPods=true \
	 --set authentication.enabled=false


k8sServiceHost="192.168.3.100"
k8sServicePort=6443
podCIDR="10.244.0.0/16"
devices="eth0"
cilium install cilium cilium/cilium --namespace kube-system \
   --set nodeinit.enabled=true \
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
	 --set nat46x64Gateway.enabled=false \
	 --set ipv6.enabled=false \
	 --set pmtuDiscovery.enabled=true \
	 --set enableIPv6BIGTCP=false \
	 --set sctp.enabled=false \
	 --set wellKnownIdentities.enabled=true \
	 --set hubble.enabled=true \
	 --set routingMode=native \
	 --set ipv4NativeRoutingCIDR=10.244.0.0/16 \
	 --set ipam.mode=kubernetes \
	 --set k8s.requireIPv4PodCIDR=true \
	 --set autoDirectNodeRoutes=true \
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
	 --set devices=eth0 \
	 --set l2podAnnouncements.interface=eth0 \
	 --set operator.rollOutPods=true \
	 --set authentication.enabled=false

#--set ipv4NativeRoutingCIDR=10.244.0.0/16 \
cilium install cilium cilium/cilium --namespace kube-system \
   --set nodeinit.enabled=true \
	 --set k8sClientRateLimit.qps=30 \
	 --set k8sClientRateLimit.burst=40 \
	 --set rollOutCiliumPods=true \
	 --set bpf.masquerade=true \
	 --set installNoConntrackIptablesRules=false \
	 --set bpf.datapathMode=netkit \
	 --set bpfClockProbe=true \
	 --set bpf.preallocateMaps=true \
	 --set bpf.tproxy=false \
	 --set bpf.hostLegacyRouting=false \
	 --set enableIPv4BIGTCP=true \
	 --set enableIPv6BIGTCP=false \
	 --set autoDirectNodeRoutes=true \
	 --set localRedirectPolicy=true \
	 --set ciliumEndpointSlice.enabled=false \
	 --set externalIPs.enabled=true \
	 --set hostPort.enabled=true \
	 --set socketLB.enabled=true \
	 --set nodePort.enabled=true \
	 --set sessionAffinity=false \
	 --set annotateK8sNode=true \
	 --set ipv6.enabled=false \
	 --set sctp.enabled=false \
	 --set wellKnownIdentities.enabled=true \
	 --set hubble.enabled=false \
	 --set routingMode=native \
	 --set ipam.mode=kubernetes \
	 --set k8s.requireIPv4PodCIDR=true \
	 --set autoDirectNodeRoutes=true \
	 --set egressGateway.enabled=true \
	 --set endpointRoutes.enabled=true \
	 --set kubeProxyReplacement=true \
	 --set loadBalancer.mode=dsr \
	 --set bandwidthManager.enabled=true \
	 --set bandwidthManager.bbr=true \
	 --set devices=eth0 \
	 --set operator.rollOutPods=true \
	 --set k8sServiceHost="45.207.192.132" \
   --set k8sServicePort=6443
