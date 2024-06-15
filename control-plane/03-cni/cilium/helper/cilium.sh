#!/bin/bash

set -e -o posix -o pipefail

cilium uninstall

kubectl -n kube-system rollout restart ds/cilium

kubectl -n kube-system rollout restart deployment coredns

kubectl -n monitoring rollout restart deployment prometheus-operator
kubectl -n monitoring rollout restart deployment kube-state-metrics
kubectl -n monitoring rollout restart deployment grafana
kubectl -n monitoring rollout restart deployment blackbox-exporter
kubectl -n monitoring rollout restart deployment prometheus-adapter

cilium status --wait

nohup cilium connectivity test&

watch kubectl get po,svc -n kube-system -owide

# 查看安装的配置和默认的配置
kubectl edit configmap cilium-config -n kube-system
kubectl get configmap cilium-config -n kube-system -o yaml
# Cilium 信息
kubectl -n kube-system exec pod/cilium-79qdl -- cilium status --verbose
kubectl -n kube-system exec pod/cilium-jbrds -- cilium status --verbose
kubectl -n kube-system exec pod/cilium-r4pbz -- cilium status --verbose

# 检查集群连接运行状况 
kubectl -n kube-system exec pod/cilium-5g2k4 -- cilium-health status
# 监控数据路径状态 
kubectl -n kube-system exec pod/cilium-5g2k4 -- cilium monitor --type drop

cilium upgrade cilium cilium/cilium \
--version v1.15.1 \
--namespace kube-system \
--reuse-values \

helm repo add cilium https://helm.cilium.io/
helm repo update
helm upgrade \
--version v1.15.1 \
--namespace kube-system \
cilium cilium/cilium \
--reuse-values \

# 镜像地址
--set image.repository=registry.cn-shenzhen.aliyuncs.com/liweilun1/cilium \
--set operator.image.repository=registry.cn-shenzhen.aliyuncs.com/liweilun1/operator \

# 带宽管理器 BBR
--set devices=ens160 \
--set bandwidthManager.enabled=true \
--set bandwidthManager.bbr=true \

# hubble设置
--set hubble.enabled=false \
--set hubble.ui.enabled=false \
--set hubble.relay.enabled=false \
--set hubble.relay.service.type=LoadBalancer \
--set hubble.relay.service.nodePort=31234 \

# 允许ClusterIP对外访问,需要写对应的路由信息, 例如
# ip route add 192.168.3.22/32 via 192.168.1.149
--set bfp.lbExternalClusterIP=true \

# PBG模式, 不能与L2同时使用
--set bgp.enabled=true \
--set bgp.announce.loadbalancerIP=true

# 启用externalIPs
--set externalIPs.enable=true \ # 启用externalIPs.enable

# 对于创建服务时默认的 Cluster 策略，存在多个选项来实现外部流量的客户端源 IP 保留，
# 即，如果后者仅向外界公开基于 TCP 的服务，则在 DSR 或混合模式下操作 kube-proxy 替换。
--set externalTrafficPolicy=Cluster \

# 负载均衡的磁悬浮哈希
--set loadBalancer.algorithm=maglev \ # 启用服务负载均衡的磁悬浮哈希

# K8s 服务拓扑感知,允许 Cilium 节点首选位于同一区域中的服务端
--set loadBalancer.serviceTopology=true \ # K8s 服务拓扑感知,允许 Cilium 节点首选位于同一区域中的服务端

# 从集群外部访问 ClusterIP 服务
--set bpf.lbExternalClusterIP=true \ # 允许从集群外部访问 ClusterIP 服务,默认为false

# 带宽管理器 负责更有效地管理网络流量，以改善整体应用程序延迟和吞吐量
--set devices=ens+ # NodePort 设备、端口和绑定设置
--set bpf.masquerade=true # 用于 Pod 的 IPv4 地址通常是从RFC1918专用地址块分配的，因此不可公开路由。Cilium 会自动将离开集群的所有流量的源 IP 地址伪装到节点的 IPv4 地址 https://docs.cilium.io/en/stable/network/concepts/masquerading/
--set bandwidthManager.enabled=true \ # 是否启用带宽管理器, 默认为false
--set bandwidthManager.bbr=true \ #当 Pod 暴露在 Kubernetes 服务后面时，BBR 特别适合，这些服务面向来自 Internet 的外部客户端。BBR 实现了更高的带宽和更低的互联网流量延迟，例如，已经证明 BBR 的吞吐量可以达到比当今最好的基于丢失的拥塞控制高出 2,700 倍，排队延迟可以降低 25 倍
## 在现有的cilium时添加必须要重启:
kubectl -n kube-system rollout restart ds/cilium

--set tunnel=disabled \

# ipam 这个参数是使用node 节点分配的子网
# (IP Address Management), 选择 Cilium 的 IP 管理策略，支持如下选择：
# cluster-pool: 默认的IP管理策略，会为每个节点分配一段 CIDR，然后分配 IP 时从这个节点的子网中选择IP，但是不如 calico 一点的是，这并不是动态分配的 IP 池，每个节点的 IP 之后不会自动补充新的 CIDR 进去
# crd:用户手动通过 CRD 定义每个节点可用的 IP 池，方便扩展开发，自定义IP管理策略
# kubernetes: 从 k8s v1.Node 对象的 podCIDR 字段读取可用 IP 池，不再自己维护 IP 池，在 1.11 使用 cilium 自己集成的 BGP Speaker 宣告 CIDR 时就只支持这种模式

## [多池](https://docs.cilium.io/en/stable/network/kubernetes/ipam-multi-pool/#gsg-ipam-crd-multi-pool)
--set ipam.mode=multi-pool \
--set tunnel=disabled \
--set autoDirectNodeRoutes=true \
--set ipv4NativeRoutingCIDR=10.0.0.0/8 \
--set endpointRoutes.enabled=true \
--set-string extraConfig.enable-local-node-route=false \
--set kubeProxyReplacement=true \
--set bpf.masquerade=true \
--set ipam.operator.autoCreateCiliumPodIPPools.default.ipv4.cidrs='{10.10.0.0/16}' \
--set ipam.operator.autoCreateCiliumPodIPPools.default.ipv4.maskSize=27 \

## Kubernetes池
--set ipv4NativeRoutingCIDR=10.10.0.0/16 \
--set ipv6.enabled=false \
--set ipam.mode=kubernetes \
--set ipam.operator.clusterPoolIPv4PodCIDRList=["10.10.0.0/16"]

# BGP
--set bgp.enabled=true \ #在ciilium内部启用BGP支持;为BGP嵌入一个新的ConfigMap
--set bgp.announce.loadbalancerIP=true \ #开启服务负载均衡器ip的分配和通告
--version v1.15.1
--set ipam.mode=kubernetes \
--set tunnel=disabled \
--set ipv4NativeRoutingCIDR="10.0.0.0/8" \
--set bgpControlPlane.enabled=true \
--set k8s.requireIPv4PodCIDR=true \

#  hubble.relay
--set hubble.relay.enabled=true \
--set hubble.relay.service.type=NodePort \
--set hubble.relay.service.nodePort=31234 \

# 仅 DSR 模式的无 kube-proxy-free 环境中
--set tunnel=disabled \
--set routingMode=native \
--set loadBalancer.mode=dsr \
--set loadBalancer.dsrDispatch=opt \

# Geneve 的直接服务器返回 （DSR）
--set tunnel=disabled \
--set loadBalancer.mode=dsr \
--set loadBalancer.dsrDispatch=geneve \ #  启用了 DSR 和 Geneve 调度的无 kube-proxy-free 环境中

# DSR 中具有 Geneve 调度和隧道模式
--set tunnel=geneve \
--set loadBalancer.mode=dsr \
--set loadBalancer.dsrDispatch=geneve \

# 混合 DSR 和 SNAT 模式
--set routingMode=native \
--set kubeProxyReplacement=true \
--set loadBalancer.mode=hybrid \

# [Pod 命名空间中的套接字 LoadBalancer 旁路](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#socket-loadbalancer-bypass-in-pod-namespace)
--set routingMode=native \
--set socketLB.hostNamespaceOnly=true

# LoadBalancer 和 NodePort XDP 加速
# 加速是通过XDP加速服务处理的选项, 值可以是:
# disabled, 不使用XDP
# native, (XDP BPF程序直接通过网络驱动程序的早期接收运行path)，或者尽最大努力(在设备上使用原生模式XDP加速支持它)。
# 设置为 loadBalancer.acceleration 选项 native 可启用此加速。该选项 disabled 为默认值，并禁用加速。
# 大多数支持 10G 或更高速率的驱动程序在最近的内核上也支持 native XDP。对于基于云的部署，这些驱动程序中的大多数都具有支持本机XDP的SR-IOV变体。
# 对于本地部署，Cilium XDP 加速可以与 Kubernetes 的 LoadBalancer 服务实现（如 MetalLB）结合使用。加速只能在用于直接路由的单个设备上启用
# https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#advanced-configuration
--set routingMode=native \
--set loadBalancer.acceleration=native # oadBalancer 和 NodePort XDP 加速, 默认为disabled

# BGP 控制平面, 只有ipam.mode=kubernetes或者
--set bgpControlPlane.enabled=true

--set routing-mode=native \ # 多池 IPAM不能与routing-mode: native 本机路由一起使用
--set ipv4NativeRoutingCIDR=10.0.0.0/8 \

--set kubeProxyReplacementHealthzBindAddr='0.0.0.0:10256' # kube-proxy 替换健康检查服务器

--set sctp.enabled=true \ # Cilium 的 eBPF kube-proxy 替代品不支持 SCTP 传输协议。目前仅支持 TCP 和 UDP 作为服务的传输

# L2
# https://docs.cilium.io/en/stable/network/l2-announcements/
--set devices=ens+ \
--set l2announcements.enabled=true \
--set k8sClientRateLimit.qps=10 \
--set k8sClientRateLimit.burst=20 \
## L2公告
--set l2podAnnouncements.enabled=true
--set l2podAnnouncements.interface=ens+
## L2 续约
--set l2announcements.leaseDuration=3s \
--set l2announcements.leaseRenewDeadline=1s \
--set l2announcements.leaseRetryPeriod=200ms \


# 是否分配、宣告LoadBalancer服务的IP地址
--set bgp.announce.loadbalancerIP=false

# 允许集群外部访问ClusterIP服务 default: false
--set bpf.lbExternalClusterIP=true

--set bgpControlPlane.enabled=false

set +x
