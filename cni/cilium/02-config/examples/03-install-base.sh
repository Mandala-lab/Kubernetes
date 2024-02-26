#!/usr/bin/env bash

helm repo add cilium https://helm.cilium.io/
helm repo update

# operator-api-serve-addr: 127.0.0.1:9234

# 特权eBPF
# 结果值为 1 或 2 表示禁用非特权 eBPF。
#https://discourse.ubuntu.com/t/unprivileged-ebpf-disabled-by-default-for-ubuntu-20-04-lts-18-04-lts-16-04-esm/27047
sysctl kernel.unprivileged_bpf_disabled
sudo sysctl kernel.unprivileged_bpf_disabled=0

# 当configmap更新时，自动推出ciilium agent pods。
--set rollOutCiliumPods=true \

# 在eBPF中启用本机IP伪装支持 https://ewhisper.cn/posts/58548/
--set bpf.masquerade=true \
# 启用BPF时钟源探测以获得更有效的刻度检索。
--set bpfClockProbe=true \
# 使能eBPF映射值的预分配。这增加了内存使用，但可以减少延迟。
--set bpf.preallocateMaps=true \
#  配置基于ebpf的TPROXY，减少对iptables规则的依赖，实现七层策略。
--set bpf.tproxy=true \
# 配置直接路由模式是应该通过主机堆栈路由流量(true)，还是在内核支持的情况下直接且更有效地从BPF路由流量(false)。后者意味着它还将绕过主机名称空间中的netfilter。
# grep BPF /boot/config-$(uname -r) 包含"CONFIG_BPF=y"或者"CONFIG_BPF=m"，则表示您的内核支持BPP
--set bpf.hostLegacyRouting=true \
# 如果工作节点共享公共L2网段，则启用在工作节点之间安装PodCIDR路由
--set autoDirectNodeRoutes=true \
# 表示启用本地重定向策略。在Cilium中，本地重定向策略允许将流量重定向到同一节点上的后端Pod，而无需经过网络层。这可以提高网络性能和效率，特别是在需要在同一节点上处理流量时。
--set localRedirectPolicy=true \
# "enableCiliumEndpointSlice" 是一个Cilium中的功能开关，用于启用 CiliumEndpointSlice 特性。CiliumEndpointSlice 是 Kubernetes 中的一种自定义资源类型，用于管理和组织 Cilium 管理的每个 Pod 的终端。启用此功能可以让 Cilium 使用 CiliumEndpointSlice 来管理和组织终端，从而提高控制平面的负载能力，并支持更大规模的集群。
--set enableCiliumEndpointSlice=false \
# 启用外部IP服务支持。启用此功能可以让Kubernetes服务支持外部IP地址，这些IP地址可以不受Kubernetes管理，而是由用户负责确保流量到达具有这些IP地址的节点。常见的例子是外部负载均衡器，它们不属于Kubernetes系统的一部分
--set externalIPs.enabled=false \
# 启用了主机端口支持，允许容器使用主机的端口
--set hostPort.enabled=false \

# 启用了节点端口支持，允许将服务公开到节点的端口上
--set nodePort.enabled=true \
# 用于在初始化时使用 Cilium 的元数据对 Kubernetes 节点进行注释。启用此功能可以在节点级别添加 Cilium 的元数据，以便在整个集群中跟踪和识别节点
--set annotateK8sNode=true \

# 启用wellKnownIdentities.enabled参数时，Cilium将使用这些预定义的身份来识别和授权特定的网络流量。这可以帮助简化网络策略的管理，并提供更高级别的安全性。如果禁用了wellKnownIdentities.enabled参数，Cilium将不使用预定义的身份，而是依赖于其他身份识别和授权机制
--set wellKnownIdentities.enabled=true \
# 启用 Hubble（默认为 true）
--set hubble.enabled=false \
# 允许动态查找远程节点标识。当使用隧道或直接路由并且节点 CIDR 和 Pod CIDR 重叠时，这是必需的。默认false
--set encryption.strictMode.allowRemoteNodeIdentities=true \
# 用于隧道模式和临时隧道的隧道协议。可能的值： - “” - vxlan - geneve
--set tunnelProtocol="" \
# 在初始化时使用 Cilium 的元数据注释 k8s 节点。默认f
--set annotateK8sNode=true \
# 群集的名称。仅对 Cluster Mesh 和 SPIRE 的相互身份验证需要。
--set cluster.name="k8s-cluster-1" \
#cni.chaining模式, 可能的值： - none - aws-cni - flannel - generic-veth - portmap
--set cni.chainingMode="none" \
# 让 Cilium 接管节点上的 /etc/cni/net.d 目录，将所有非 Cilium CNI 配置重命名为 *.cilium_bak 。这确保了在 Cilium 代理停机期间不能使用其他 CNI 插件调度任何 Pod。
--set cni.exclusive=true \
# 将 CNI 配置和二进制文件安装到文件系统中。
--set cni.install=true \
# 在代理关闭时删除 CNI 配置和二进制文件。如果要从群集中删除 Cilium，请启用此功能。禁用此选项可防止在代理升级期间删除 CNI 配置文件，这可能会导致节点无法管理。
--set cni.uninstall=false \
# 指定 cni initContainer 的资源, 默认{"requests":{"cpu":"100m","memory":"10Mi"}}
#cni.resources={"requests":{"cpu":"100m","memory":"10Mi"}}
--set cni.resources.requests.cpu="300m" \
--set cni.resources.requests.memory="30Mi" \
# 启用调式
--set debug.enabled=true \
#配置调试日志记录的详细级别 此选项用于为与此类子系统相关的操作（例如 kvstore、envoy、datapath 或策略）启用调试消息，而 flow 用于启用每个请求、消息和连接发出的调试消息。可以通过空格分隔的字符串（例如“datapath envoy”）设置多个值。适用值：flow - kvstore - envoy - datapath - policy
--set debug.verbose="datapath" \
# 启用从端点离开节点的 IPv4 流量的伪装。默认t
--set enableIPv4Masquerade=true \
# 启用从端点离开节点的 IPv6 流量的伪装。默认t
--set enableIPv6Masquerade=false \
# 允许伪装到路由源，以便从端点离开节点的流量。于配置Cilium的masquerading路由源。当设置为true时，它会使masquerading到源地址，而不是到主要接口地址。这意味着对于高级用例，路由层可能会根据目标CIDR选择不同的源地址，而不是使用主要接口地址。这对于特定的网络配置可能很有用，但需要确保在相关的masquerading接口上没有重叠的目标CIDR路由
--set enableMasqueradeRouteSource=false \
# 为检测新的和已移除的数据路径设备提供实验性支持。当设备发生更改时，将重新加载 eBPF 数据路径并更新服务。如果设置了“设备”，则仅考虑那些设备或与通配符匹配的设备。
--set enableRuntimeDeviceDetection=true \
# 启用透明网络加密。
--set encryption.enabled=false \
# 启用虚拟端点之间的连接运行状况检查。默认true
--set endpointHealthChecking.enabled=true \
# 启用使用每个端点路由，而不是通过cilium_host接口路由。默认false
--set endpointRoutes.enabled=false \
# 启用端点状态, 状态可以是： policy, health, controllers, log and / or state. 两个以上使用空格区分
--set endpointStatus.enabled=true \
--set endpointStatus.status="log health" \

# 代理运行状况 API 的 TCP 端口。这不是cilium健康的端口。
--set healthPort=9879 \
# 主机的防火墙
#hostFirewall={"enabled":false}
--set hostFirewall.enabled=false \
#配置基于eBPF的ip-masq-agent
#ipMasqAgent={"enabled":false}
--set ipMasqAgent.enabled=false \
# 配置 IP 地址管理模式 https://docs.cilium.io/en/stable/network/concepts/ipam/ 默认cluster-pool
--set ipam.mode=kubernetes \
# 要委派给 IPAM 的各个节点的 IPv4 CIDR 列表范围。
--set ipam.operator.clusterPoolIPv4PodCIDRList=["10.10.0.0/17"] \
# IPv4 CIDR 掩码大小，以委派给 IPAM 的各个节点。
--set ipam.operator.clusterPoolIPv4MaskSize=17 \

# 允许显式指定本机路由的 IPv4 CIDR。指定后，Cilium 假定此 CIDR 的网络已预先配置，并将发往该范围的流量传递给 Linux 网络堆栈，
# 而不应用任何 SNAT。一般来说，指定本机路由 CIDR 意味着 Cilium 可以依赖底层网络堆栈将数据包路由到其目的地。
# 举个具体的例子，如果 Cilium 配置为使用直接路由，并且 Kubernetes CIDR 包含在原生路由 CIDR 中，
# 则用户必须手动或通过设置 auto-direct-node-routes 标志来配置路由以访问 Pod。
--set ipv4NativeRoutingCIDR="10.10.0.0/17" \

#启用对 K8s NetworkPolicy 的支持
--set k8sNetworkPolicy.enabled=true \
# Kubernetes 服务主机
--set k8sServiceHost= \
# 端口
--set k8sServicePort= \

# L2 在代理中启用 L2 邻居发现 默认t
--set l2NeighDiscovery.enabled=true \
# L2公告
# s 启用 L2 公告
--set l2announcements.enabled=true \
# 配置 L2 容器公告
#l2podAnnouncements={"enabled":false,"interface":"eth0"}
# 启用 L2 容器公告
--set l2podAnnouncements.enabled=true \
# L2 容器接口, 默认eth0
--set l2podAnnouncements.interface=$DEVICES \

# 启用第 7 层网络策略。
--set l7Proxy=true \

# loadBalancer
# 加速是通过XDP加速服务处理的选项 适用的值可以是：disabled（不使用XDP）、本机（XDP BPF程序直接从网络驱动程序的早期接收路径运行）或尽力而为（在支持它的设备上使用本机模式XDP加速）。
--set loadBalancer.acceleration=disabled \
# 默认 LB 算法,默认round_robin, 用于服务的默认 LB 算法，可以被服务注解覆盖（例如service.cilium.io/lb-l7-algorithm)
# 可选择值: round_robin, least_request, random
--set loadBalancer.l7.algorithm="round_robin" \
# 通过 envoy 代理启用 L7 服务负载均衡。对具有特定注解（例如 service.cilium.io/lb-l7）的 k8s 服务的请求将被转发到本地后端代理，
# 以便对服务端点进行负载均衡。有关更多配置，请参阅文档了解支持的注解。
# 适用值：
# - envoy: 通过 envoy 代理启用 L7 负载均衡。这也会自动设置 enable-envoy-config
# - disabled: 通过服务注解的方式禁用 L7 负载均衡
--set loadBalancer.l7.backend=envoy \
# 要自动重定向到上述后端的服务端口列表。公开这些端口之一的任何服务都将自动重定向。通过使用服务注解可以实现细粒度控制。
--set loadBalancer.l7.port=[] \

# 启用本地重定向策略。 https://docs.cilium.io/en/v1.15/network/kubernetes/local-redirect-policy/
--set localRedirectPolicy=false \

# 配置磁悬浮一致性哈希
maglev

# 监控,默认false
--set monitor.enabled=false \
# Agent container name. 代理容器名称。
--set name="cilium" \

# 网关
#nat46x64Gateway={"enabled":false}
# 启用以RFC8215为前缀的翻译
--set nat46x64Gateway.enabled=false \

# Node节点
# 如果检测到与临时端口冲突，则将 NodePort 范围附加到 ip_local_reserved_ports。默认t
--set nodePort.autoProtectPortRange=true \
# 设置为 true 可防止应用程序绑定到服务端口。默认true
--set nodePort.bindProtection=true \
# 为 NodePort 类型的服务启用运行状况检查
--set nodePort.enableHealthCheck=true \
# 在 LoadBalancerIP 上启用运行状况检查 nodePort 的访问。需要启用 nodePort.enableHealthCheck=true
--set nodePort.enableHealthCheckLoadBalancerIP=true \
# 启用 Cilium NodePort service实现。默认f
--set nodePort.enabled=false \
# 启用节点初始化, 默认f
--set nodeinit.enabled=true \

# operator启用 cilium-operator 组件（必需）。
--set operator.enabled=true \
# 从运行正常 Cilium pod 的 Kubernetes 节点中删除 Cilium 节点污点。默认t
--set operator.removeNodeTaints=true \
# 要为 cilium-operator 部署运行的副本数, 默认2
--set operator.replicas=2 \
# 更新 configmap 时自动重启 cilium-operator pod。默认f
--set operator.rollOutPods=true \
# 重新启动任何不受 Cilium 管理的 Pod。默认值t
--set operator.unmanagedPodWatcher.restart=true \
# 用于启用路径 MTU 发现，以便向客户端发送 ICMP 分段所需的回复。当设置为 true 时，表示启用路径 MTU 发现功能。路径 MTU 发现是一种网络协议，用于发现两个主机之间的最大传输单元（MTU），以便在发送数据时进行适当的分段
--set pmtuDiscovery.enabled=true \

# 启用 SCTP 支持。注意：目前，SCTP 支持不支持重写端口或多宿主。
--set sctp.enabled=false \
# 启用服务源范围检查（目前仅适用于 LoadBalancer）默认t
--set  svcSourceRangeCheck=true \


#启用本地路由模式或隧道模式。取值范围:- " " - native - tunnel
# 配置native时需要ipv4NativeRoutingCIDR
--set routingMode=native \

# 启用了套接字负载均衡支持，允许在套接字级别进行负载均衡
--set socketLB.enabled=false \

helm repo add cilium https://helm.cilium.io/
helm repo update

export DEVICES="enp0s5"
export HOST="192.168.3.161"
export K8S_API_SERVER_PORT="6443"
export CILIUM_VERSION="1.15.1"
export CLUSTER_NAME="mesh-cluster-1"
export CLUSTER_ID=1
export CIDRList=["10.10.0.0/17"]
export RoutingCIDR="10.10.0.0/17"
export MakeSize=17
#helm install cilium cilium/cilium --version $CILIUM_VERSION \
helm install cilium . --version $CILIUM_VERSION \
--namespace kube-system \
--set kubeProxyReplacement=true \
--set annotateK8sNode=true \
--set autoDirectNodeRoutes=true \
--set bpf.masquerade=true \
--set bpfClockProbe=true \
--set bpf.preallocateMaps=true \
--set bpf.tproxy=true \
--set bpf.hostLegacyRouting=false \
--set cluster.name="$CLUSTER_NAME" \
--set cni.chainingMode="none" \
--set cni.exclusive=true \
--set cni.install=true \
--set cni.uninstall=false \
--set cni.resources.requests.cpu="300m" \
--set cni.resources.requests.memory="30Mi" \
--set debug.enabled=true \
--set debug.verbose="datapath" \
--set enableCiliumEndpointSlice=false \
--set enableIPv4Masquerade=true \
--set enableIPv6Masquerade=false \
--set enableMasqueradeRouteSource=false \
--set enableRuntimeDeviceDetection=true \
--set encryption.enabled=false \
--set encryption.strictMode.allowRemoteNodeIdentities=true \
--set endpointHealthChecking.enabled=true \
--set endpointRoutes.enabled=false \
--set endpointStatus.enabled=true \
--set endpointStatus.status="log health" \
--set externalIPs.enabled=false \
--set healthPort=9879 \
--set hostPort.enabled=true \
--set hostFirewall.enabled=false \
--set hubble.enabled=false \
--set ipam.mode=kubernetes \
--set ipam.operator.clusterPoolIPv4PodCIDRList="$CIDRList" \
--set ipam.operator.clusterPoolIPv4MaskSize=$MakeSize \
--set ipv4NativeRoutingCIDR=$RoutingCIDR \
--set ipv6.enabled=false \
--set ipMasqAgent.enabled=false \
--set k8sNetworkPolicy.enabled=true \
--set k8sServiceHost=$HOST \
--set k8sServicePort=$K8S_API_SERVER_PORT \
--set l2NeighDiscovery.enabled=true \
--set l2announcements.enabled=true \
--set l2podAnnouncements.enabled=true \
--set l2podAnnouncements.interface=$DEVICES \
--set l7Proxy=true \
--set loadBalancer.acceleration=disabled \
--set loadBalancer.l7.algorithm="round_robin" \
--set loadBalancer.l7.backend=envoy \
--set loadBalancer.l7.port=[] \
--set localRedirectPolicy=false \
--set monitor.enabled=false \
--set name="cilium" \
--set tunnel=disabled \
--set tunnelProtocol="" \
--set nat46x64Gateway.enabled=false \
--set nodePort.enabled=false \
--set nodePort.autoProtectPortRange=true \
--set nodePort.bindProtection=true \
--set nodePort.enableHealthCheck=true \
--set nodePort.enableHealthCheckLoadBalancerIP=true \
--set nodeinit.enabled=true \
--set operator.enabled=true \
--set operator.removeNodeTaints=true \
--set operator.replicas=2 \
--set operator.rollOutPods=true \
--set operator.unmanagedPodWatcher.restart=true \
--set pmtuDiscovery.enabled=true \
--set sctp.enabled=false \
--set routingMode=native \
--set socketLB.enabled=false \
--set svcSourceRangeCheck=true \
--set rollOutCiliumPods=true \
--set wellKnownIdentities.enabled=true
