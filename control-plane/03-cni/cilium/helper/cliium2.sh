# 本地路由

#Helm Chart 启用本地路由
helm repo add cilium https://helm.cilium.io/
helm repo update
helm upgrade cilium cilium/cilium \
--namespace kube-system \
--reuse-values \

export DEVICES="eth0"
cilium install --version 1.14.5 \
--set k8sServiceHost=192.168.2.152 \
--set k8sServicePort=6443 \
--set cluster.name=prvite-kubernetes \
--set cluster.id=1 \
--set kubeProxyReplacement=true \
--set hubble.enabled=true \
--set hubble.ui.enabled=true \
--set hubble.relay.enabled=true \
--set hubble.relay.service.type=NodePort \
--set hubble.relay.service.nodePort=31234 \
--set nodeinit.enabled=true \
--set rollOutCiliumPods=true \
--set bpfClockProbe=true \

--set localRedirectPolicy=false \
--set enableCiliumEndpointSlice=false \
--set enableK8sEventHandover=false \
--set nodePort.enabled=true \
--set socketLB.enabled=true \
--set annotateK8sNode=true \
--set nat46x64Gateway.enabled=false \
--set pmtuDiscovery.enabled=true \
--set enableIPv4BIGTCP=false \
--set enableIPv6BIGTCP=false \
--set egressGateway.enabled=false \
--set highScaleIPcache.enabled=false \
--set operator.replicas=2 \

# 关闭隧道
--set tunnel=disabled \
--set autoDirectNodeRoutes=true \
--set ipam.mode="multi-pool" \
--set ipv4NativeRoutingCIDR="10.10.0.0/16" \
--set ipam.operator.autoCreateCiliumPodIPPools.default.ipv4.cidrs='{10.10.0.0/16}' \
--set ipam.operator.autoCreateCiliumPodIPPools.default.ipv4.maskSize=24 \

--set bpf.masquerade=true \
--set enableIpv4Masquerade=true \
--set enableIpv6Masquerade=false \
--set endpointRoutes.enabled=true \
--set-string extraConfig.enable-local-node-route=false \
--set ipMasqAgent.config.nonMasqueradeCIDRs='{10.10.0.0/16}' \
--set ipMasqAgent.config.masqLinkLocal=false \
--set devices=$DEVICES \

--set bpf.preallocateMaps=true \

# 允许群集外部访问InternetIP服务。
--set bpf.lbExternalClusterIP=true \

--set routingMode=native \

--set sessionAffinity=true \

## L2 test
cilium upgrade cilium ./cilium \
--namespace kube-system \
--reuse-values \
--set l2announcements.enabled=true \
--set k8sClientRateLimit.qps=10 \
--set k8sClientRateLimit.burst=20 \
--set kubeProxyReplacement=true \
--set l2podAnnouncements.enabled=true \
--set l2podAnnouncements.interface=ens160 \
--set l2announcements.leaseDuration=3s \
--set l2announcements.leaseRenewDeadline=1s \
--set l2announcements.leaseRetryPeriod=200ms \

# [Prometheus](https://docs.cilium.io/en/stable/observability/metrics/#metrics)
##  给cilium的启用指标
--set prometheus.enabled=true
## 给cilium的operator启用指标
--set operator.prometheus.enabled=true
# 指定 Operator 副本数为 1, 默认为 2
--set operator.replicas=1

# 启用本地路由模式
--set tunnel=disabled \
# 每个节点都知道所有其他节点的所有 pod IP，
# 并在 Linux 内核路由表中插入路由来表示这一点。
# 如果所有节点共享一个 L2 网络，启用下面选项来解决这个问题
--set autoDirectNodeRoutes=true \

# 配置直接路由模式是否应该通过主机堆栈路由流量（true），
# 或者如果内核支持，则直接更有效地从BPF路由流量（false）。
# false意味着它也将绕过主机命名空间中的netfilter。默认值为false。
--set bpf.hostLegacyRouting=false

# 设置可执行本地路由的 CIDR
--set ipv4NativeRoutingCIDR=10.10.0.0/16

# DSR, 必须以本地路由模式部署(tunnel=disabled)，也就是说，它不能在任何一种隧道模式下工作
--set loadBalancer.mode=dsr \

# eBPF IP 地址伪装, Cilium 会自动将离开群集的所有流量的源 IP 地址伪装成 node 的 IPv4 地址
# 提升网络效率, https://ewhisper.cn/posts/58548/
# 当前的实现依赖于 BPF NodePort 功能。查看[GitHub问题](https://github.com/cilium/cilium/issues/13732)
# 未来将移除该依赖关系
bpf.masquerade=true \
#enableIpv4Masquerade=false
#enableIpv6Masquerade=false

# 默认行为是排除本地节点 IP 分配 CIDR 范围内的任何目的地。
# 如果 pod IP 可通过更广泛的网络进行路由，则可使用选项: ipv4-native-routing-cidr
# 指定该网络，在这种情况下，该 CIDR 范围内的所有目的地都 不会 被伪装
ipv4NativeRoutingCIDR=10.10.0.0/16

# 默认情况下，除了发往其他集群节点的数据包外，
# 所有从 pod 发往 ipv4NativeRoutingCIDR范围之外 IP 地址的数据包都会被伪装
# 如果配置文件为空，agent 将提供以下非伪装 CIDR
# 10.0.0.0/8
# 172.16.0.0/12
# 192.168.0.0/16
# 100.64.0.0/10
# 192.0.0.0/24
# 192.0.2.0/24
# 192.88.99.0/24
# 198.18.0.0/15
# 198.51.100.0/24
# 203.0.113.0/24
# 240.0.0.0/4
# 从 pod 发送到属于 nonMasqueradeCIDRs 中任何 CIDR 的目的地的数据包都不会被伪装
# 如果 masqLinkLocal 未设置或设置为 false，则 169.254.0.0/16 会被附加到非屏蔽 CIDR 列表中。
--set ipMasqAgent.config.nonMasqueradeCIDRs='{10.244.0.0/16}'
--set ipMasqAgent.config.masqLinkLocal=false
--set ipMasqAgent.config.masqLinkLocalIPv6=false

# [Host-Routing 主机路由](https://ewhisper.cn/posts/56721/)
# 完全绕过 iptables 和上层主机堆栈，并实现比常规 veth 设备操作更快的网络命名空间切换。
# 要求
# 1. Kernel >= 5.10
# 2. 直接路由 (Direct-routing) 配置或隧道
# 3. 基于 eBPF 的 kube-proxy
# 4. 基于 eBPF 的伪装(masquerading)
# 如上所述, “如果内核支持该选项，它将自动启用”.

# [绕过iptables连接跟踪](https://ewhisper.cn/posts/58823/
# 在无法使用 eBPF 主机路由 (Host-Routing) 的情况下，网络数据包仍需在主机命名空间中穿越常规网络堆栈，iptables 会增加大量成本。
# 通过禁用所有 Pod 流量的连接跟踪 (connection tracking) 要求，
# 从而绕过 iptables 连接跟踪器(iptables connection tracker)，可将这种遍历成本降至最低
# 要求:
# 1. 内核 >= 4.19.57, >= 5.1.16, >= 5.2
# 2. 直接路由 (Direct-routing) 配置
# 3. 基于 eBPF 的 kube-proxy 替换
# 4. 基于 eBPF 的伪装 (masquerading) 或无伪装
--set installNoConntrackIptablesRules=true

# [带宽管理器](https://ewhisper.cn/posts/56757/)
# 要求:
# Kernel >= 5.1
# Direct-routing 配置 或 隧道
# 基于 eBPF 的 kube-proxy 替换
# 启用带宽管理器, 以更有效地管理网络流量，改善整体应用的延迟和吞吐量
# 默认情况下会将 TCP 拥塞控制算法切换为 BBR，从而实现更高的带宽和更低的延迟，尤其是面向互联网的流量。
# 它将内核网络堆栈配置为更面向服务器的 sysctl 设置，这些设置已在生产环境中证明是有益的
# 还重新配置了流量控制队列规则（Qdisc）层，以便在 Cilium 使用的所有面向外部的网络设备上使用多队列 Qdiscs 和公平队列（FQ）。
# 切换到公平队列后，带宽管理器还在 eBPF 的帮助下实现了对最早出发时间 Earliest Departure Time（EDT）速率限制的支持，
# 并且现在原生支持 kubernetes.io/egress-bandwidth Pod 注释
# 当 eBPF 和 FQ 结合使用时，第 95 百分位的延迟降低了约 20 倍，第 99 百分位的延迟降低了约 10 倍
--set bandwidthManager.enabled=true \

# [BBR 拥塞控制](https://ewhisper.cn/posts/50029/)
# 要求:
# 内核 >= 5.18
# 带宽管理器
# eBPF 主机路由
--set bandwidthManager.bbr=true \
