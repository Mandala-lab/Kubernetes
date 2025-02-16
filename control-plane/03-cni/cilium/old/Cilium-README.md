# Cilium

## 介绍

> 引用于https:
> //isovalent.com/blog/post/why-replace-iptables-with-ebpf/#h-how-to-replace-iptables-and-bring-ebpf-into-kubernetes
> Cilium 数据平面提供了 kube-proxy 的全面替代品，使从 iptables 程序过渡到 eBPF 程序变得容易。在右侧，Cilium 在每个
> Kubernetes
> 节点上安装 eBPF 和 XDP（eXpress 数据路径）程序，绕过了 iptables 的开销。这种方法最大限度地减少了开销和上下文切换要求，从而实现了高效的数据包处理，从而降低了延迟和
> CPU 开销。

## 优缺点

### 优点

1. 高性能: Cilium的使用eBPF技术可以实现卓越的性能，减少了网络包处理的性能开销。
2. 强大的安全性: Cilium支持网络层面的安全策略，可以保护集群中的应用程序免受网络攻击。
3. 应用层负载均衡: 可以实现应用层面的负载均衡，使流量分发更智能。
4. Service Identity: 提供了强大的服务标识，有助于精细控制应用程序之间的通信。
5. 可扩展性: Cilium支持大规模集群，并且易于扩展以适应不断增长的需求。

### 缺点

1. 学习曲线: 对于不熟悉eBPF和Cilium的用户来说，上手可能会有一定难度。
2. 复杂性: 在复杂的网络环境中，配置和管理Cilium可能会变得复杂。

## 快速入门

### 先决条件

1. 一个Kubernetes集群
2. 2个可以运行Pod的节点

1. 安装cilium CLI

```shell
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
# wget -t 2 -T 240 -N -S https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt
#CILIUM_CLI_VERSION="v0.15.19"
CLI_ARCH="amd64"
#CLI_ARCH="arm64"
## if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
## curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
## sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
wget -t 2 -T 240 -N -S https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
```

- 使用cilium CLI安装cilium
    ```shell
    cilium install 1.14.5 \
    -n kube-system
    ```

- Helm安装cilium:
    ```shell
    helm repo add cilium https://helm.cilium.io/
    helm install cilium cilium/cilium --version 1.14.5 \
    -n kube-system
    ```

2. 检查cilium的连接情况,这是判断配置是否成功的重要指标, 共运行60+项测试
   如果全部通过,则说明配置成功
   这个过程需要几分钟到十几分钟不等

> 在机器无法访问境外IP的情况时, 由于网络环境所限，可能部分测试会失败（如访问 1.1.1.1:443). 属于正常情况。
> 连接性测试需要至少两个 worker node 才能在群集中成功部署。连接性测试 pod 不会在以控制面角色运行的节点上调度。如果您没有为群集配置两个
> worker node，连接性测试命令可能会在等待测试环境部署完成时停滞。

```shell
nohup cilium connectivity test&
tail -f nohup.out
```

3. 等到Pod就绪:
    ```shell
    watch kubectl get pods -n cilium-test
    watch kubectl get pods -n kube-system
    ```

4. 等到Pod就绪完成之后, 查看 Cilium Install 具体启用了哪些功能：
    ```shell
    kubectl -n kube-system exec ds/cilium -- cilium status --verbose
    ```

## 概念

1. eBPF: Cilium使用eBPF技术来拦截和处理网络数据包，允许在数据包级别实施安全策略和路由。
1. Flannel：Flannel是一个流行的CNI插件，它使用虚拟网络覆盖技术（overlay
   network）来连接不同节点上的容器。Flannel支持多种后端驱动，如VXLAN、UDP、Host-GW等。
2. Calico：Calico是一个开源的网络和安全解决方案，它使用BGP协议来实现容器之间的路由。Calico支持灵活的网络策略和安全规则，可用于大规模部署。
3. Weave Net：Weave Net是一个轻量级的CNI插件，通过创建虚拟网络设备和网络代理来连接不同节点上的容器。Weave
   Net支持overlay模式和直连模式，具有灵活性。
4. Canal：Canal是一个综合性的CNI插件，结合了Calico和Flannel的功能。它可以使用Flannel提供overlay网络，同时使用Calico的网络策略和安全性功能。
5. Antrea：Antrea是一个基于Open vSwitch的CNI插件，专为Kubernetes网络和安全性而设计。它提供了高性能的网络连接和网络策略功能。
6. kube-router：kube-router是一个开源的CNI插件，它结合了网络和服务代理功能。它支持BGP和IPIP协议，并具有负载均衡的特性
7. Cilium: 是面向Kubernetes的高性能网络和安全解决方案，利用eBPF（Extended Berkeley Packet Filter）技术来提供快速的容器间通信和网络策略实施
8. Weave Net: 是一个轻量级的CNI插件，通过创建虚拟网络设备和网络代理来连接不同节点上的容器。Weave Net支持overlay模式和直连模式，具有灵活性
9. XDP：这是网络驱动程序中的一个钩子，可以在收到网络数据包时触发 BPF
   程序，并且是最早的拦截点。由于此时尚未执行其他操作，例如将网络数据包写入内存，因此它非常适合运行过滤器以丢弃恶意或意外流量，以及其他常见的DDOS保护机制
10. Traffic Control Ingress/Egress(流量控制入口/出口)：附加到流量控制（缩写为 tc）入口钩子的 BPF 程序也可以连接到网络接口。此钩子在第
    3 层 （L3） 的网络堆栈之前执行，可以访问网络数据包的大部分元数据。它适用于处理本地节点上的操作，例如应用 L3/L4
    端点策略[¹]、将流量转发到端点。CNI 通常使用虚拟以太网接口 （ veth ） 将容器连接到主机的网络命名空间。通过使用附加到主机端
    veth 的 tc 入口钩子，可以监控离开容器的所有流量并强制执行策略。同时，通过将另一个 BPF 程序附加到 tc 出口钩子上，Cilium
    可以监控进出节点的所有流量并强制执行策略
11. Direct Routing 直接路由：移交给内核网络堆栈进行处理，或由底层 SDN 支持
12. Tunneling 隧道：重新封装网络数据包，并通过隧道（如vxlan）传输
13. OSI（开放系统互联）网络模型，OSI是一个分层的网络架构模型，共有七层。
14. Service Identity: Cilium基于应用层的服务标识来管理网络策略，而不是仅仅依赖IP地址或端口号。
14. Distributed L3/L4 Load Balancing: Cilium可以自动进行负载均衡，以分发流量到后端服务实例。
15. L3: 是网络层，路由和寻址
15. L4:
    （四层负载均衡）：L4工作在OSI模型的第四层，即传输层。四层负载均衡器主要分析IP层及TCP/UDP层的信息，通过修改数据包的地址信息将流量转发到应用服务器。这种负载均衡方式不理解应用协议（如HTTP/FTP/MySQL等），因此无法对流量内容进行深入的分析和处理。常见的四层负载均衡器有LVS、F5等。
16. L7:
    负载均衡（七层负载均衡）：L7工作在OSI模型的第七层，即应用层。七层负载均衡器能够理解应用协议，对应用层的流量进行分析和处理。在接收到客户端的流量后，七层负载均衡器会建立一条完整的连接，将应用层的请求流量解析出来，再按照调度算法选择应用服务器，最后与应用服务器建立连接将请求发送过去。这种负载均衡方式能够实现对流量的更细致的控制，但相对于四层负载均衡来说，处理效率可能会稍低一些。常见的七层负载均衡器有haproxy、Nginx等。

## 先决条件

0. [挂载eBPF](https://docs.cilium.io/en/v1.12/operations/system_requirements/#mounted-ebpf-filesystem)

```shell
mount bpffs /sys/fs/bpf -t bpf
```

1. [验证验证 BPF cgroup 程序附件](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#validate-bpf-cgroup-programs-attachment)

```shell
mount | grep cgroup2
```

输出示例:

```
none on /run/cilium/cgroupv2 type cgroup2 (rw,relatime)
```

```shell
bpftool cgroup tree /run/cilium/cgroupv2/
```

输出示例:

```
-> groupPath
ID       AttachType      AttachFlags     Name
/run/cilium/cgroupv2
10613    device          multi
48497    connect4
48493    connect6
48499    sendmsg4
48495    sendmsg6
48500    recvmsg4
48496    recvmsg6
48498    getpeername4
48494    getpeername6
```

### 内核参数

```shell
cp /etc/sysctl.d/99-sysctl.conf{,back}

# 待测试
# https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#network-plugin-requirements
cat << EOF > /etc/sysctl.d/98-cilium.conf
# 禁用 IPv4/6 数据包通过网络桥接时对 ip6tables 的调用
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
# 网络接口的反向路径筛选行为
# net.ipv4.conf.lxc*.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
# net.ipv4.conf.*.rp_filter = 0
EOF

sysctl -p /etc/sysctl.d/98-cilium.conf

cat > /etc/sysctl.d/99-sysctl.conf <<EOF
# sysctl settings are defined through files in
# /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
#
# Vendors settings live in /usr/lib/sysctl.d/.
# To override a whole file, create a new file with the same in
# /etc/sysctl.d/ and put new settings there. To override
# only specific settings, add a file with a lexically later
# name in /etc/sysctl.d/ and put new settings there.
#
# For more information, see sysctl.conf(5) and sysctl.d(5).
net.ipv4.tcp_slow_start_after_idle=0
net.core.rmem_max=16777216
fs.inotify.max_user_watches=1048576
kernel.softlockup_all_cpu_backtrace=1
kernel.softlockup_panic=1
fs.file-max=2097152
fs.nr_open=2097152
fs.inotify.max_user_instances=8192
fs.inotify.max_queued_events=16384
vm.max_map_count=262144
net.core.netdev_max_backlog=16384
net.ipv4.tcp_wmem=4096 12582912 16777216
net.core.wmem_max=16777216
net.core.somaxconn=32768
net.ipv4.ip_forward=1
net.ipv4.tcp_max_syn_backlog=8096
# net.bridge.bridge-nf-call-iptables=1
# net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.tcp_rmem=4096 12582912 16777216
vm.swappiness=0
kernel.sysrq=1
net.ipv4.neigh.default.gc_stale_time=120
net.ipv4.conf.all.route_localnet=1
net.ipv4.tcp_max_tw_buckets=5000
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_synack_retries=2
net.ipv6.conf.lo.disable_ipv6=1
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.all.forwarding=0
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_keepalive_probes=10
net.ipv4.tcp_keepalive_intvl=30
net.nf_conntrack_max=25000000
net.netfilter.nf_conntrack_max=25000000
net.netfilter.nf_conntrack_tcp_timeout_established=180
net.netfilter.nf_conntrack_tcp_timeout_time_wait=120
net.netfilter.nf_conntrack_tcp_timeout_close_wait=60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait=12
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_orphan_retries=3
kernel.pid_max=4194303
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=1
vm.min_free_kbytes=262144
kernel.msgmnb=65535
kernel.msgmax=65535
kernel.shmmax=68719476736
kernel.shmall=4294967296
kernel.core_uses_pid=1
net.ipv4.neigh.default.gc_thresh1=0
net.ipv4.neigh.default.gc_thresh2=4096
net.ipv4.neigh.default.gc_thresh3=8192
net.netfilter.nf_conntrack_tcp_timeout_close=3
EOF

sysctl -p /etc/sysctl.d/99-sysctl.conf
```

### 挂载eBPF

挂载此 BPF 文件系统允许在 cilium-agent 代理重新启动后保留 eBPF 资源，以便数据路径可以在随后重新启动或升级代理时继续运行

[检查是否挂载eBPF](https://docs.cilium.io/en/v1.12/operations/system_requirements/#mounted-ebpf-filesystem)

```shell
mount | grep /sys/fs/bpf
# if present should output, e.g. "none on /sys/fs/bpf type bpf"...
```

#### 使用 systemd 安装 BPFFS

如果您使用 systemd 来管理 kubelet，在启动kubelet时同时挂载eBPF

请参阅使用 [systemd 挂载 BPFFS 一节](https://docs.cilium.io/en/v1.12/concepts/kubernetes/configuration/#mounting-bpffs-with-systemd):

```shell
cat <<EOF | sudo tee /etc/systemd/system/sys-fs-bpf.mount
[Unit]
Description=Cilium BPF mounts
Documentation=https://docs.cilium.io/
DefaultDependencies=no
Before=local-fs.target umount.target
After=swap.target

[Mount]
What=bpffs
Where=/sys/fs/bpf
Type=bpf
Options=rw,nosuid,nodev,noexec,relatime,mode=700

[Install]
WantedBy=multi-user.target
EOF
```

- 开放[端口](https://docs.cilium.io/en/v1.12/operations/system_requirements/#firewall-rules)

全部节点:

- 4240/TCP系列 集群运行状况检查 （ cilium-health ）
-

```shell
sudo ufw allow 4240/tcp 
sudo ufw allow 4244/tcp
sudo ufw allow 4245/tcp
sudo ufw allow 6060/tcp
sudo ufw allow 6062/tcp
sudo ufw allow 9879/tcp
sudo ufw allow 9890/tcp
sudo ufw allow 9891/tcp
sudo ufw allow 9892/tcp
sudo ufw allow 9893/tcp
sudo ufw allow 9962/tcp
sudo ufw allow 9964/tcp
sudo ufw allow 51871/udp
```

master:

```shell
sudo ufw allow 2379:2380/tcp
sudo ufw allow 8472/udp
sudo ufw allow 4240/tcp
sudo iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
sudo iptables -A OUTPUT -p icmp --icmp-type 8 -j ACCEPT
sudo ufw status
```

workernode:

```shell
sudo ufw allow 8472/tcp
sudo ufw allow 4240/tcp
sudo ufw allow 8472/udp
sudo ufw allow 2379-2380/tcp
sudo iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
sudo iptables -A OUTPUT -p icmp --icmp-type 8 -j ACCEPT
```

## 安装HUBBLE(可选)

```shell
HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
if [ $? != 0 ];then
  echo "访问失败, 设置本地版本"
  HUBBLE_VERSION="v0.12.3"
fi

HUBBLE_ARCH=amd64
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
```

## 配置

### 本地路由

```shell
helm upgrade cilium cilium/cilium \
--namespace kube-system \
--reuse-values \
--set tunnel=disabled \
--set autoDirectNodeRoutes=true \
--set ipv4NativeRoutingCIDR=10.0.0.0/22
```

```shell
验证本地路由是否启用
首先, 未启用之前, 也就是通过 VXLan 封装时, 会有一个对应的 VXLan 网卡 cilium_vxlan. 示例如下:
```

5: cilium_vxlan: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
link/ether 52:5b:dd:37:f5:45 brd ff:ff:ff:ff:ff:ff
inet6 fe80::505b:ddff:fe37:f545/64 scope link
valid_lft forever preferred_lft forever

```
可以查看 Cilium Agent 的日志:
```

kubectl logs -f cilium-nxbsn -n kube-system|grep datapath-mode
Defaulted container "cilium-agent" out of: cilium-agent, config (init), mount-cgroup (init), apply-sysctl-overwrites (
init), mount-bpf-fs (init), clean-cilium-state (init), install-cni-binaries (init)
level=info msg="  --datapath-mode='veth'" subsys=daemon
level=info msg="clang (10.0.0) and kernel (6.2.0) versions: OK!" subsys=linux-datapath
level=info msg="linking environment: OK!" subsys=linux-datapath
level=info msg="Restored 1 node IDs from the BPF map" subsys=linux-datapath
level=info msg="Detected devices" devices="[]" subsys=linux-datapath
level=info msg="Setting up BPF datapath" bpfClockSource=jiffies bpfInsnSet=v3 subsys=datapath-loader

```
通过 --datapath-mode='veth' 可以判断已经成功启用本地路由.

也可以查看网卡的 mtu, cilium 的 vslan 网卡没有了, 如下:
ip a
...
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:02:20:22 brd ff:ff:ff:ff:ff:ff
    inet 172.17.236.121/20 brd 172.17.239.255 scope global dynamic noprefixroute eth0
       valid_lft 84958sec preferred_lft 84958sec
    inet6 fe80::e4ed:31d3:3101:3265/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
3: cilium_net@cilium_host: <BROADCAST,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether f6:e6:97:fa:8a:d9 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::f4e6:97ff:fefa:8ad9/64 scope link
       valid_lft forever preferred_lft forever
4: cilium_host@cilium_net: <BROADCAST,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 72:f7:bb:f9:31:0b brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.172/32 scope global cilium_host
       valid_lft forever preferred_lft forever
    inet6 fe80::70f7:bbff:fef9:310b/64 scope link
       valid_lft forever preferred_lft forever
15: lxca13b12696333@if14: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether de:89:24:7b:86:e0 brd ff:ff:ff:ff:ff:ff link-netns cni-0253f30e-07bc-2273-640c-7ec96f0a30dd
    inet6 fe80::dc89:24ff:fe7b:86e0/64 scope link
       valid_lft forever preferred_lft forever
...
可以看到 cilium 和 lxc 相关的网卡, mtu 已经和 eth0 保持一致, 为: mtu 1500. 而在没启用之前, mtu 1280.

没启用本地路由, 使用 VXLan 封装的 mtu 如下:
ip a
...
3: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether aa:94:b7:b4:25:ac brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.44/24 brd 192.168.2.255 scope global dynamic noprefixroute eth0
       valid_lft 74264sec preferred_lft 74264sec
    inet6 240e:3a1:166d:dd70:4ea1:7c0c:13de:aa3/64 scope global dynamic noprefixroute
       valid_lft 208339sec preferred_lft 121939sec
    inet6 fe80::b0:3f98:e4e1:1d16/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
6: cilium_net@cilium_host: <BROADCAST,MULTICAST,NOARP,UP,LOWER_UP> mtu 1280 qdisc noqueue state UP group default qlen 1000
    link/ether be:0f:af:14:c7:05 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::bc0f:afff:fe14:c705/64 scope link
       valid_lft forever preferred_lft forever
7: cilium_host@cilium_net: <BROADCAST,MULTICAST,NOARP,UP,LOWER_UP> mtu 1280 qdisc noqueue state UP group default qlen 1000
    link/ether 1e:96:a5:af:3c:a3 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.109/32 scope global cilium_host
       valid_lft forever preferred_lft forever
    inet6 fe80::1c96:a5ff:feaf:3ca3/64 scope link
       valid_lft forever preferred_lft forever
98: lxc_health@if97: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1280 qdisc noqueue state UP group default qlen 1000
    link/ether 1a:41:2c:3b:18:0b brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::1841:2cff:fe3b:180b/64 scope link
       valid_lft forever preferred_lft forever
...
```

### 完全代替kube-proxy

```shell
kubectl -n kube-system delete ds kube-proxy
# Delete the configmap as well to avoid kube-proxy being reinstalled during a Kubeadm upgrade (works only for K8s 1.19 and newer)
kubectl -n kube-system delete cm kube-proxy
# Run on each node with root permissions:
iptables-save | grep -v KUBE | iptables-restore
```

验证

```shell
kubectl -n kube-system exec ds/cilium -- cilium status | grep KubeProxyReplacement
```

```
KubeProxyReplacement:    Strict   [eth0 192.168.2.3 (Direct Routing)]
```

[官方values]配置(https://github.com/cilium/cilium/blob/main/install/kubernetes/cilium/values.yaml.tmpl)

启用HostPort, 如果kubeProxyReplacement不是true情况下, 需要手动设置helm参数:`--set hostPort.enabled=true`

1. 启用选项
2. 测试

```shell
kubectl -n kube-system exec ds/cilium -- cilium status --verbose | grep HostPort
```

```shell
cat > hostpost-test.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 1
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
          hostPort: 8080
EOF

k apply -f hostpost-test.yaml

# 把<cilium-xx>替换为你的cilium Pod名称
kubectl exec -it -n kube-system <cilium-xx> -- cilium service list
```

### 增强设置(已验证)

kubeProxyReplacement=true \ #完全替换kube-proxy \
hubble.enabled=true \ # 启用Hubble \
hubble.ui.enabled=true \
hubble.relay.enabled=true \
hubble.relay.service.type=LoadBalancer \
hubble.relay.service.nodePort=31234 \
nodeinit.enabled=true \ # 启用节点初始化 DaemonSet \
tunnel=disabled \ # 配置节点间通信的封装配置, 可能的值： - disabled - vxlan - geneve, 默认vxlan   \
k8sClientRateLimit.qps=30 \
k8sClientRateLimit.burst=40 \
rollOutCiliumPods=true \ # 更新 configmap 时自动重启 cilium 代理 pod  \
bpfClockProbe=true \ #启用 BPF 时钟源探测，实现更高效的滴答检索  \
bpf.masquerade=true \ # 在 eBPF 中启用原生 IP 伪装支持  \
bpf.preallocateMaps=true \ # 启用 eBPF 映射值的预分配。这会增加内存使用量，但可以减少延迟  \
bpf.tproxy=true \ # 配置基于 eBPF 的 TPROXY，减少对 iptables 规则的依赖，实现第 7 层策略  \
bpf.hostLegacyRouting=false \ # true: 配置直接路由模式是应该通过主机堆栈 路由流量. false: 直接更有效地从
BPF路由流量（如果内核支持）。后者意味着它还将绕过主机命名空间中的 netfilter \
autoDirectNodeRoutes=true \ # 如果 Worker 节点共享一个公共 L2 网段，则启用 Worker 节点之间的 PodCIDR 路由安装,
默认false \
localRedirectPolicy=false \ # 启用本地重定向策略, 默认false \
externalIPs.enabled=false \ # 启用 ExternalIPs 服务支持, 这是使用L2的必要条件, 默认false. 如果指定了 hostPort 而没有额外的
hostIP ，那么 Pod 将使用来自节点的相同本地地址向外界公开，这些地址与检测到并用于公开 NodePort 服务的本地地址相同，例如
Kubernetes InternalIP 或 ExternalIP（如果设置了）。此外，Pod 也可以通过节点上的环回地址访问 ，例如 127.0.0.1:hostPort 。如果除了还为
Pod 指定了 a hostIP 之外 hostPort ，那么 Pod 将只在给定 hostIP 的 Pod 上公开。A hostIP of 0.0.0.0 将具有与未指定 a hostIP
相同的行为。不得 hostPort 驻留在配置的 NodePort 端口范围内，以避免冲突 \
hostPort.enabled=true \ # 如果指定了kubeProxyReplacement=true,那么该项默认使用,否则得显式启用 hostPort 服务支持,
默认false \
enableCiliumEndpointSlice=true \ # 启用 CiliumEndpointSlice 端点切片功能, 默认false \
enableK8sEventHandover=false \ # beta特性, 支持对集群中的CiliumEndpoint（CEP）对象进行批处理，以实现更好的可扩展性,
默认false \
socketLB.enabled=true \
nodePort.enabled=true \ # 启用 Cilium NodePort 服务实现 \
sessionAffinity=true 会话亲和性, 不稳定的参数 \
annotateK8sNode=true \ # 在初始化时使用 Cilium 的元数据注释 k8s 节点。 \
nat46x64Gateway.enabled=false \ # 启用以RFC8215为前缀的翻译, 默认false \
pmtuDiscovery.enabled=true \ # 启用路径 MTU 发现以向客户端发送需要 ICMP 分段的回复. 默认false \
enableIPv4BIGTCP=true \ # 启用 IPv4 BIG TCP 支持，从而增加节点和 Pod 的最大 IPv4 GSO/GRO 限制 \
enableIPv6BIGTCP=false \ # 启用 IPv6 BIG TCP 支持，从而增加节点和 Pod 的最大 IPv6 GSO/GRO 限制, 默认false \
wellKnownIdentities.enabled=true \ # 允许使用已知标识 \
installNoConntrackIptablesRules=true \ # 安装 Iptables 规则以跳过所有 Pod 流量的 netfilter 连接跟踪。仅当 Cilium 在直接路由和完整
KPR 模式下运行时，此选项才有效。此外，当 Cilium 在托管 Kubernetes 环境或链式 CNI 设置中运行时，无法启用此选项, 默认false \
egressGateway.enabled=false \ # 启用出口网关重定向和SNAT离开的流量, 默认false \
loadBalancer.mode=dsr \ # 让 Cilium 的 eBPF NodePort 实现在 DSR 模式下运行。在这种模式下，后端直接回复外部客户端，而不采取额外的跃点，这意味着后端使用服务
IP/端口作为源进行回复 \
loadBalancer.serviceTopology=true \ # 实现了 K8s 服务拓扑感知提示。这允许 Cilium 节点首选位于同一区域中的服务端点,
默认false \
highScaleIPcache.enabled=false \ # 为 ipcache 启用高缩放模式, 默认false \
l2announcements.enabled=false \ # 是否启用 L2 Pod 公告, 默认false \
operator.rollOutPods=true \ # 更新configmap 时自动重启 operator cilium 代理 pod, 默认false \
authentication.enabled=false \ #
启用身份验证处理和垃圾回收。请注意，如果禁用，策略实施仍将阻止需要身份验证的请求。但是，不会处理这些请求生成的身份验证请求，因此不允许这些请求。默认false \
bandwidthManager.enabled=true \ # 启用带宽管理器以优化 TCP 和 UDP 工作负载，并允许通过“kubernetes.io/egress-bandwidth”Pod
注释使用 EDT（最早出发时间）限制来自各个 Pod 的流量. 当 Pod 暴露在 Kubernetes 服务后面时，BBR 特别适合，这些服务面向来自
Internet 的外部客户端。BBR 实现了更高的带宽和更低的互联网流量延迟，例如，已经证明 BBR 的吞吐量可以达到比当今最好的基于丢失的拥塞控制高出
2,700 倍，排队延迟可以降低 25 倍 \
bandwidthManager.bbr=true \ # 是否激活 Pod 的 BBR TCP 拥塞控制, 默认false \
bgp.enabled=true \ #在ciilium内部启用BGP支持;为BGP嵌入一个新的ConfigMap \
bgp.announce.loadbalancerIP=true \ #开启服务负载均衡器ip的分配和通告 \
ipv4NativeRoutingCIDR=10.10.0.0/16 \
ipv6.enabled=false \
ipam.mode=kubernetes \
ipam.operator.clusterPoolIPv4PodCIDRList=["10.10.0.0/16"]

```shell
cilium install --version 1.14.5 \
--set k8sServiceHost=192.168.2.152 \
--set k8sServicePort=6443 \
--set cluster.name=prvite-kubernetes \
--set cluster.id=1 \
--set kubeProxyReplacement=true \
--set hubble.enabled=true \
--set hubble.ui.enabled=true \
--set hubble.relay.enabled=true \
--set hubble.relay.service.type=LoadBalancer \
--set hubble.relay.service.nodePort=31234 \
--set nodeinit.enabled=true \
--set k8sClientRateLimit.qps=30 \
--set k8sClientRateLimit.burst=40 \
--set rollOutCiliumPods=true \
--set bpfClockProbe=true \
--set bpf.masquerade=true \
--set bpf.preallocateMaps=true \
--set bpf.tproxy=true \
--set bpf.hostLegacyRouting=false \ 
--set autoDirectNodeRoutes=true \ 
--set localRedirectPolicy=true \ 
--set externalIPs.enabled=true \ 
--set hostPort.enabled=true \ 
--set enableCiliumEndpointSlice=true \ 
--set enableK8sEventHandover=false \
--set nodePort.enabled=true \ # 启用 Cilium NodePort 服务实现 \ 
--set socketLB.enabled=true \
#--set sessionAffinity=true 会话亲和性, 不稳定的参数 \ 

--set annotateK8sNode=true \
--set nat46x64Gateway.enabled=false \
--set pmtuDiscovery.enabled=true \
--set enableIPv4BIGTCP=true \
--set enableIPv6BIGTCP=false \
--set wellKnownIdentities.enabled=true \
--set installNoConntrackIptablesRules=true \ 
--set egressGateway.enabled=false \
--set loadBalancer.mode=dsr \ 
--set loadBalancer.serviceTopology=true \ 
--set highScaleIPcache.enabled=false \ 
--set l2announcements.enabled=false \ 
--set operator.rollOutPods=true \ 
--set authentication.enabled=false \ 
--set bandwidthManager.enabled=true \ 
--set bandwidthManager.bbr=true \

--set bgp.enabled=true \
--set bgp.announce.loadbalancerIP=true \

--set ipv4NativeRoutingCIDR=10.10.0.0/16 \
--set ipv6.enabled=false \
--set ipam.mode=kubernetes \
--set ipam.operator.clusterPoolIPv4PodCIDRList=["10.10.0.0/16"]
```

## 集成

### [istio](https://docs.cilium.io/en/stable/network/servicemesh/istio/#gsg-istio)

```shell
cilium upgrade cilium cilium/cilium \
--version 1.14.5 \
--namespace kube-system \
--reuse-values \
--set socketLB.hostNamespaceOnly=true
```

### [Prometheus & Grafana](https://docs.cilium.io/en/stable/observability/grafana/#install-prometheus-grafana)

## 杂项设置

### [Pools IP池](https://docs.cilium.io/en/stable/network/lb-ipam/)

```shell
cat > lb-ipam.yaml << EOF
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "blue-pool"
spec:
  cidrs:
  - cidr: "10.0.10.0/24"
EOF
```

### IPAM

验证 Cilium 是否已正确启动

```shell
cilium status --all-addresses
```

```
KVStore:                Ok   etcd: 1/1 connected, has-quorum=true: https://192.168.60.11:2379 - 3.3.12 (Leader)
[...]
IPAM:                   IPv4: 2/256 allocated,
Allocated addresses:
  10.0.0.1 (router)
  10.0.0.3 (health)
```

验证该 spec.ipam.podCIDRs 部分：

```shell
kubectl get cn k8s1 -o yaml
```

```
apiVersion: cilium.io/v2
kind: CiliumNode
metadata:
  name: k8s1
  [...]
spec:
  ipam:
    podCIDRs:
      - 10.0.0.0/24
```

### 启用hubble

现有升级:

```shell
helm upgrade cilium cilium/cilium --version 1.14.5 \
   --namespace kube-system \
   --reuse-values \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true
```

### 启用UI

```shell
cilium hubble ui
```

### 启用带宽管理器

ciilium关于带宽管理器的文档解释了以下概念和术语:
带宽管理器:一个帮助管理网络流量带宽的ciilium功能，特别是对于Kubernetes pods。
eBPF (Extended Berkeley Packet Filter):一种允许在Linux内核中高效地过滤和操作网络流量的技术。
HTB(层次化令牌桶):一种网络流量控制机制，用于将可用带宽分配给特定的流量类。
tc (Traffic Control): Linux内核中配置网络流量控制的工具。
带宽管理器的优点包括改善了网络性能和效率，因为它保证了带宽的公平分配和防止网络拥塞。但是，它需要eBPF和Linux内核功能，这可能会限制它与某些系统的兼容性。有关更深入的信息，请参阅ciilium的带宽管理器文档。
CONFIG_NET_SCH_FQ=m

#### 先决条件

1. 参考https://docs.cilium.io/en/v1.12/operations/system_requirements/#requirements-for-the-bandwidth-manager
2. 要求: 内核>= 5.1

现有升级: 如果没安装, 只需要多添加 bandwidthManager.enabled=true 即可

```shell
helm upgrade cilium cilium/cilium \
--version 1.14.5 \
--namespace kube-system \
--reuse-values \
--set bandwidthManager.enabled=true
```

重启cilium

```shell
kubectl -n kube-system rollout restart ds/cilium
```

重启Coredns:

```shell
kubectl -n kube-system rollout restart deployment coredns
```

### DSR

在Kubernetes默认模式是SNAT:
client -> Worknode1 -> Worknode2
Worknode2 -> Worknode1 -> client

https://miro.medium.com/v2/resize:fit:1400/format:webp/1*2GvlZqXHvm71XJ9L7m4Ggg.png

DSR之后就是, 数据包可以从目标 Pod 直接返回到客户端:
client -> Worknode1 -> Worknode2
Worknode2 -> client

[!https://miro.medium.com/v2/resize:fit:1400/format:webp/1*MciW1vUnwyho6N3wHT5Sag.png]

启用DSR:

```shell
--set loadBalancer.mode=dsr \
--set --set kubeProxyReplacement=true
```

### Tunnel mode 隧道模式

要使客户端的 IP 地址显示在目标 Pod 中，您必须在 Cilium 中禁用隧道模式，该模式默认启用。但是，为什么客户端 IP 地址很重要？请考虑以下示例
Nginx 访问日志：

```
192.168.1.4 - - [18/Jan/2017:20:34:02 +0000] "GET / HTTP/1.0" 200 700 "https://example.com/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"
```

将显示 192.168.1.4 日志的初始部分，指示来自此 IP 地址的客户端向容器发送了请求，您应保留该请求以供将来分析。但是，如果不禁用隧道模式会发生什么？如果您启用隧道模式，上述日志将显示如下：

10.42.0.2 - - [18/Jan/2017:20:34:02 +0000] "GET / HTTP/1.0" 200 700 "https://example.com/" "Mozilla/5.0 (Windows NT
10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"
IP 地址是分配给 Kubernetes 工作节点的虚拟地址 10.42.0.2 之一，它充当请求到达其目标 Pod 的途径。在某些情况下，您可能不知道目标
Pod 在 Kubernetes 集群中的位置，但 Kubernetes 将通过充当代理服务器来转发您的请求来为您处理这个问题。
使用以下参数在 Helm 图表中禁用隧道模式非常重要

```shell
--set tunnel=disabled \
--set autoDirectNodeRoutes=true
```

### LoadBalancer

```shell
cat > lb-ipam.yaml <<EOF
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "ip-pool"
spec:
  cidrs:
  - cidr: ["192.168.2.170", "192.168.2.171", "192.168.2.172", "192.168.2.173", "192.168.2.174", "192.168.2.175", "192.168.2.176", "192.168.2.177", "192.168.2.178", "192.168.2.179", "192.168.2.180", "192.168.2.181", "192.168.2.182", "192.168.2.183", "192.168.2.184", "192.168.2.185", "192.168.2.186", "192.168.2.187", "192.168.2.188", "192.168.2.189", "192.168.2.190", "192.168.2.191", "192.168.2.192", "192.168.2.193", "192.168.2.194", "192.168.2.195", "192.168.2.196", "192.168.2.197", "192.168.2.198", "192.168.2.199"]
EOF
```

检查ip是否存在错误或冲突

```shell
kubectl get ippools/ip-pool -o jsonpath='{.status.conditions[?(@.type=="io.cilium/conflict")].message}'
```

### BBR for Pods

#### 先决条件

要求: Linux 内核v5.18.x 或更高版本的 Linux 内核

优点: 当 Pod 暴露在 Kubernetes 服务后面时，BBR 特别适合，这些服务面向来自 Internet 的外部客户端。
BBR 实现了更高的带宽和更低的互联网流量延迟，例如，已经证明 BBR 的吞吐量可以达到比当今最好的基于丢失的拥塞控制高出 2,700
倍，排队延迟可以降低 25 倍。
缺点: Bandwidth enforcement 目前不能与 L7 Cilium 网络策略结合使用。如果他们在出口处选择了 Pod，则将对这些 Pod 禁用带宽强制
宽强制不适用于嵌套网络命名空间环境（如 Kind）。这是因为它们通常无法访问全局 sysctl， /proc/sys/net/core 并且带宽实施取决于它们

现有升级:

```shell
helm upgrade cilium cilium/cilium \
--version 1.14.5 \
--namespace kube-system \
--reuse-values \
--set bandwidthManager.enabled=true \
--set bandwidthManager.bbr=true
```

重启

```shell
kubectl -n kube-system rollout restart ds/cilium
```

#### 检查:

```shell
kubectl -n kube-system exec ds/cilium -- cilium status | grep BandwidthManager
```

应该有如下输出: 如果包含 EDT with BPF [CUBIC] [ens160, flannel.1, kube-ipvs0] 则会对仍在使用 CUBIC 的其他连接产生潜在的不公平问题

```
BandwidthManager:       EDT with BPF [BBR] [eth0]
```

启用Hubble:

- helm:

```shell
helm upgrade cilium cilium/cilium --version 1.14.5 \
   --namespace kube-system \
   --reuse-values \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true
```

- cilium:

```shell
cilium hubble enable
```

### [Maglev Consistent Hashing](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#maglev-consistent-hashing)

Cilium 的 eBPF kube-proxy 替代品通过在其负载均衡器中实现磁悬浮哈希的变体来支持一致的哈希，以进行后端选择。这提高了发生故障时的复原能力。此外，它还提供了更好的负载均衡属性，因为添加到集群的节点将在整个集群中为给定的
5 元组进行一致的后端选择，而无需与其他节点同步状态。同样，在删除后端时，将对后端查找表进行重新编程，同时将对给定服务的不相关后端的中断降至最低（重新分配的差异最多为
1%）。

```shell
SEED=$(head -c12 /dev/urandom | base64 -w0)
API_SERVER_IP=192.168.2.155
API_SERVER_PORT=6443
helm upgrade cilium cilium/cilium \
--version 1.14.5 \
--namespace kube-system \
--reuse-values \
--set loadBalancer.algorithm=maglev \
--set maglev.tableSize=65521 \
--set maglev.hashSeed=$SEED \
--set k8sServiceHost=${API_SERVER_IP} \
--set k8sServicePort=${API_SERVER_PORT}
```

### [Socket LoadBalancer Bypass in Pod Namespace](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#socket-loadbalancer-bypass-in-pod-namespace)

套接字负载均衡器旁路: 在高流量的Kubernetes环境中特别有用，因为性能和低延迟是至关重要的。它简化了路由网络请求到合适pod的过程，提高了整体效率。

```shell
helm upgrade cilium cilium/cilium \
--version 1.14.5 \
--namespace kube-system \
--reuse-values \
--set routingMode=native \
--set kubeProxyReplacement=true \
--set socketLB.hostNamespaceOnly=true
```

### [LoadBalancer 和 NodePort XDP 加速](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#loadbalancer-nodeport-xdp-acceleration)

[检查](https://docs.cilium.io/en/stable/bpf/progtypes/#xdp-drivers):

```shellinstallNoConntrackIptablesRules
$ ethtool -i ens160

driver: vmxnet3
version: 1.7.0.0-k-NAPI
firmware-version:
expansion-rom-version:
bus-info: 0000:03:00.0
supports-statistics: yes
supports-test: no
supports-eeprom-access: no
supports-register-dump: yes
supports-priv-flags: no
```

可以看出机器支持vmxnet3 驱动，该驱动支持 register dump，这意味着您的机器支持 XDP（eXpress Data Path）。 XDP 是 Linux
内核中的一种高性能数据包处理框架，通过在网络设备驱动层上执行数据包处理程序，可以实现非常低延迟的数据包处理。

Cilium 内置了对加速 NodePort、LoadBalancer 服务和具有 externalIP 的服务的支持，用于需要转发到达的请求并且后端位于远程节点上的情况。此功能是在
Cilium 1.8 版的 XDP（eXpress 数据路径）层引入的，其中 eBPF 直接在网络驱动程序中运行，而不是在更高层中运行。

```shell
API_SERVER_IP=192.168.2.155
API_SERVER_PORT=6443
helm upgrade cilium cilium/cilium \
    --version 1.14.5 \
    --namespace kube-system \
    --reuse-values \
    --set routingMode=native \
    --set kubeProxyReplacement=true \
    --set loadBalancer.acceleration=native \
    --set loadBalancer.mode=hybrid \    
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT}
```

当前的 Cilium kube-proxy XDP 加速模式也可以通过 cilium status CLI 命令进行内省。如果已成功启用， Native 则显示：

```shell
kubectl -n kube-system exec ds/cilium -- cilium status --verbose | grep XDP
 
XDP Acceleration:    Native
```

### 启用L7:

https://docs.cilium.io/en/v1.12/operations/system_requirements/#requirements-for-l7-and-fqdn-policies

#### 先决条件

```shell
CONFIG_NETFILTER_XT_TARGET_TPROXY=m
CONFIG_NETFILTER_XT_TARGET_CT=m
CONFIG_NETFILTER_XT_MATCH_MARK=m
CONFIG_NETFILTER_XT_MATCH_SOCKET=m
```

## 测试

[调试和测试](https://docs.cilium.io/en/latest/bpf/debug_and_test/):

```shell
bpftool prog

bpftool map
```

检查是否附加了bpf_sock程序。确保纤毛已安装并正确[设置](https://github.com/cilium/cilium/issues/10067#issuecomment-782833809):

```shell
sudo bpftool cgroup show /var/run/cilium/cgroupv2
```

[参考](https://www.cnblogs.com/east4ming/p/17573776.html)

```shell
nouhp cilium connectivity test --request-timeout 30s --connect-timeout 10s&
tail -f nouhp.out
```

## 排错

### [诊断cilium在Pod中的信息](https://docs.cilium.io/en/stable/gettingstarted/demo/)

```shell
kubectl -n kube-system get pods -l k8s-app=cilium -owide

kubectl -n kube-system exec <cilium-pod-name> -- cilium endpoint list
```

### 查看cilium配置

```shell
kubectl -n kube-system get daemonsets.apps  cilium -o yaml
```

```shell
kubectl -n kube-system exec ds/cilium -- cilium status --verbose
```

service日志:

```shell
kubectl -n kube-system exec ds/cilium -- cilium service list
```

```shell
cat /var/run/cilium/cilium-cni.helper
```

### 检查/etc/cni/net.d/05-cilium.conflist文件是否存在

如果不存在, 清除现有安装

- 通过helm安装的:

```shell
helm uninstall cilium -n kube-system
```

然后通过cilium-cli工具安装就有该文件

```shell
cilium install --version 1.14.5
```

### 要验证 Cilium 是否已正确安装，您可以运行

cilium status --wait

### 运行以下命令以验证群集是否具有正确的网络连接：

cilium connectivity test

### Ubuntu22.04 问题: https://github.com/cilium/cilium/issues/18706

```
systemctl --version
```

设置用于保护策略规则不被 systemd-networkd 移除
Cilium 用于 Kubernetes 并启用 L7Proxy 时，systemd-networkd 可能会将本地路由策略规则视为外部策略并删除它们
这会导致主机无法识别 localhost。使用 ManageForeignRoutingPolicyRules=no 可防止这种情况发生。
但在 systemd v249.4 版本中，由于一个 bug，还需要同时设置 IgnoreCarrierLoss=yes 和 KeepConfiguration=yes，
并避免使用 networkctl reconfigure 或 networkctl reload。
在 systemd v249.5 版本中，只需设置 ManageForeignRoutingPolicyRules=no 即可

```
ManageForeignRoutingPolicyRules=no
```

### 恢复默认值:

备份:

```shell
cp /etc/systemd/networkd.conf /etc/systemd/networkd.conf.back
```

查看配置文件:

```shell
systemd-delta --type=extended
```

如果做了这些操作:

```shell
CONFIG_BPF=y
CONFIG_BPF_SYSCALL=y
CONFIG_NET_CLS_BPF=y
CONFIG_BPF_JIT=y
CONFIG_NET_CLS_ACT=y
CONFIG_NET_SCH_INGRESS=y
CONFIG_CRYPTO_SHA1=y
CONFIG_CRYPTO_USER_API_HASH=y
CONFIG_CGROUPS=Y
CONFIG_CGROUP_BPF=y
CONFIG_PERF_EVENTS=Y
```

查看:

```shell
cat /boot/config-$(uname -r) | grep CONFIG_BPF
```

CONFIG_XXX的配置, 备份:

```shell
cp /boot/config-$(uname -r) /boot/config-$(uname -r).back
```

可以通过备份之后的配置恢复

```shell
cat /boot/config-$(uname -r) | grep CONFIG_BPF
cp /boot/config-$(uname -r).back /boot/config-$(uname -r)
```

## 资料

1. https://docs.cilium.io/en/v1.12/operations/system_requirements/#mounted-ebpf-filesystem
2. https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#kubeproxy-free
3. https://docs.cilium.io/en/stable/network/concepts/ipam/
4. https://docs.cilium.io/en/stable/network/lb-ipam/
5. https://docs.cilium.io/en/stable/gettingstarted/hubble_cli/
6. https://docs.cilium.io/en/stable/gettingstarted/demo/
7. https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/#hubble-setup
8. https://docs.cilium.io/en/stable/observability/metrics/
9. https://docs.cilium.io/en/stable/configuration/
10. https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#nodeport-devices-port-and-bind-settings
11. https://docs.cilium.io/en/stable/network/kubernetes/
12. https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
13. https://docs.cilium.io/en/stable/gettingstarted/hubble/#hubble-ui
14. https://docs.cilium.io/en/v1.12/operations/system_requirements/#mounted-ebpf-filesystem
15. https://docs.cilium.io/en/v1.12/gettingstarted/ipam-crd/
16. https://docs.cilium.io/en/v1.12/gettingstarted/ipam-cluster-pool/
17. https://docs.cilium.io/en/v1.12/operations/troubleshooting/
18. [helm values参数](https://docs.cilium.io/en/stable/helm-reference/)
19. [helm values参数](https://github.com/cilium/cilium/blob/main/install/kubernetes/cilium/values.yaml.tmpl)
20. [从cilium角度理解L3、L4、L7层网络策略的区别](https://www.cnblogs.com/janeysj/p/14548015.html)
