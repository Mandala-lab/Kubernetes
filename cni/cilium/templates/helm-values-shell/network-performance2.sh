#!/usr/bin/env bash

#export DEVICES="eth0"
export DEVICES="ens160"
export HOST="192.168.2.152"
export K8S_API_SERVER_PORT="6443"
export CILIUM_VERSION="1.14.5"
export CLUSTER_NAME="prvite-kubernetes"
ens160 CLUSTER_ID="1"

cilium install --version $CILIUM_VERSION \
--set k8sServiceHost=$HOST \
--set k8sServicePort=$K8S_API_SERVER_PORT \
--set cluster.name=$CLUSTER_NAME \
--set cluster.id=$CLUSTER_ID \
--set kubeProxyReplacement=true \
--set nodeinit.enabled=true \
--set rollOutCiliumPods=true \
--set bpfClockProbe=true \

# 允许群集外部访问InternetIP服务。
--set bpf.lbExternalClusterIP=true \

# 启用本地路由模式
--set tunnel=disabled \
# 配置直接路由模式是否应该通过主机堆栈路由流量（true），
# 或者如果内核支持，则直接更有效地从BPF路由流量（false）。
# false意味着它也将绕过主机命名空间中的netfilter。默认值为false。
--set bpf.hostLegacyRouting=false

# 如果所有节点共享一个 L2 网络，启用下面选项来解决这个问题
--set autoDirectNodeRoutes=true

# 多池
--set ipam.mode='multi-pool' \
--set ipv4NativeRoutingCIDR='10.0.0.0/8' \
--set endpointRoutes.enabled=true \
--set-string extraConfig.enable-local-node-route=false \
--set bpf.masquerade=true \

--set ipam.operator.autoCreateCiliumPodIPPools.default.ipv4.cidrs='{10.10.0.0/16}'
--set ipam.operator.autoCreateCiliumPodIPPools.default.ipv4.maskSize=27

# IP伪装
--set ipMasqAgent.config.nonMasqueradeCIDRs='{10.10.0.0/16}' \
--set ipMasqAgent.config.masqLinkLocal=false \
--set ipMasqAgent.config.masqLinkLocalIPv6=false \

# DSR
# 对于创建服务时默认的 Cluster 策略，存在多个选项来实现外部流量的客户端源 IP 保留，
# 即，如果后者仅向外界公开基于 TCP 的服务，则在 DSR 或混合模式下操作 kube-proxy 替换。
--set externalTrafficPolicy=Cluster \
--set loadBalancer.mode=dsr \

# 带宽管理器 BBR
--set routingMode=native \
--set devices=$DEVICES \
--set bandwidthManager.enabled=true \
--set bandwidthManager.bbr=true \

# hubble设置
##--set hubble.enabled=false \
##--set hubble.ui.enabled=false \
##--set hubble.relay.enabled=false \
##--set hubble.relay.service.type=LoadBalancer \
##--set hubble.relay.service.nodePort=31234 \

# example:
export DEVICES="ens160"
export HOST="192.168.2.152"
export K8S_API_SERVER_PORT="6443"
export CILIUM_VERSION="v1.15.0-rc.0"
export CLUSTER_NAME="prvite-kubernetes"
export CLUSTER_ID="1"
helm install cilium cilium/cilium --version v1.15.0-rc.0 \
--namespace=kube-system \
--set k8sServiceHost=$HOST \
--set k8sServicePort=$K8S_API_SERVER_PORT \
--set nodeinit.enabled=true \
--set routingMode=native \
--set tunnel=disabled \
--set rollOutCiliumPods=true \
--set bpf.masquerade=true \
--set bpfClockProbe=true \
--set bpf.preallocateMaps=true \
--set bpf.tproxy=true \
--set bpf.hostLegacyRouting=false \
--set autoDirectNodeRoutes=true \
--set localRedirectPolicy=true \
--set enableCiliumEndpointSlice=true \
--set enableK8sEventHandover=true \
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
--set sctp.enabled=true \
--set wellKnownIdentities.enabled=true \
--set hubble.enabled=false \
--set ipv4NativeRoutingCIDR=10.244.0.0/12 \
--set ipam.mode=kubernetes \
--set ipam.operator.clusterPoolIPv4PodCIDRList[0]="10.244.0.0/12" \
--set installNoConntrackIptablesRules=true \
--set enableIPv4BIGTCP=false \
--set egressGateway.enabled=false \
--set endpointRoutes.enabled=false \
--set kubeProxyReplacement=true \
--set highScaleIPcache.enabled=false \
--set l2announcements.enabled=true \
--set k8sClientRateLimit.qps=30 \
--set k8sClientRateLimit.burst=40 \
--set l2podAnnouncements.interface=$DEVICES \
--set l2announcements.leaseDuration=3s \
--set l2announcements.leaseRenewDeadline=1s \
--set l2announcements.leaseRetryPeriod=200ms \
--set image.useDigest=false \
--set operator.image.useDigest=false \
--set operator.rollOutPods=true \
--set authentication.enabled=false \
--set bandwidthManager.enabled=true \
--set bandwidthManager.bbr=true
