#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

MASTER_HOST_IP="192.168.3.100"
MASTER_HOST_PORT=6443
CONTROL_PLANE_ENDPOINT=$MASTER_HOST_IP:$MASTER_HOST_PORT
MASTER_NODE_NAME="node1"
CERT_SA_NS=(192.168.3.100 node1)
KUBERNETES_VERSION="1.31.1"
IMAGE_REPOSITORY="registry.aliyuncs.com/google_containers"
POD_SUBNET="10.244.0.0/24"
SERVICE_SUBNET="10.96.0.0/16"

# 初始化 certSANs 变量
certSANs="["

# 循环遍历数组，为每个元素添加引号并用逗号分隔
for ip in "${CERT_SA_NS[@]}"; do
    certSANs+=" \"$ip\","
done

# 移除最后一个逗号并关闭括号
certSANs="${certSANs%,} ]"

cat > kubeadm-init-conf.yaml <<EOF
# Source: https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
bootstrapTokens:
  - groups:
      # 指定用于节点引导的安全组
      - system:bootstrappers:kubeadm:default-node-token
    token: "9a08jv.c0izixklcxtmnze7"
    ttl: 24h0m0s # 令牌的有效期限
#    usages:
#      - signing # 用于签名请求
#      - authentication # 用于身份验证
localAPIEndpoint:
  # masterIP 主节点用于广播的地址
  advertiseAddress: $MASTER_HOST_IP
  # Kubernetes API 服务器监听的端口
  bindPort: $MASTER_HOST_PORT
nodeRegistration:
  name: $MASTER_NODE_NAME # 该控制节点的名称, 也就是出现在kubectl get no的名称
  # CRI（容器运行时接口）的通信 socket 用来读取容器运行时的信息。 此信息会被以注解的方式添加到 Node API 对象至上，用于后续用途。
  criSocket: unix:///var/run/containerd/containerd.sock
  # 镜像拉取策略。 这两个字段的值必须是 "Always"、"Never" 或 "IfNotPresent" 之一。 默认值是 "IfNotPresent"，也是添加此字段之前的默认行为
  imagePullPolicy: IfNotPresent
  # 定 Node API 对象被注册时要附带的污点。 若未设置此字段（即字段值为 null），默认为控制平面节点添加控制平面污点。 如果你不想污染你的控制平面节点，可以将此字段设置为空列表
  taints:
    - effect: PreferNoSchedule
      key: node-role.kubernetes.io/master
  # 提供一组在当前节点被注册时可以忽略掉的预检错误。 例如：IsPrevilegedUser,Swap。 取值 all 忽略所有检查的错误。
  #ignorePreflightErrors:
  #  - IsPrivilegedUser
---
apiServer:
  # certSANs 为 API 服务器签名证书设置额外的使用者备用名称（Subject Alternative Name，SAN）。
  certSANs: $certSANs
  extraArgs:
    # API 服务器的授权模式
    authorization-mode: Node,RBAC
  #  extraVolumes:
  #    - name: "some-volume"
  #      hostPath: "/etc/some-path"
  #      mountPath: "/etc/some-pod-path"
  #      readOnly: false
  #      pathType: File
  # 控制平面的超时时间
  timeoutForControlPlane: 1m0s
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
# 版本信息
kubernetesVersion: $KUBERNETES_VERSION
# 证书目录路径
certificatesDir: /etc/kubernetes/pki
# 集群名称。
clusterName: kubernetes
# 控制器管理器配置
controllerManager: { }
# DNS 配置
dns: { }
# etcd 数据库的配置。例如使用这个部分可以定制本地 etcd 或者配置 API 服务器 使用一个外部的 etcd 集群。
etcd:
  local:
  # etcd 数据存储目录
#    dataDir: /var/lib/etcd
#    imageRepository: "registry.k8s.io"
#    imageTag: "3.2.24"
#    extraArgs:
#      listen-client-urls: "http://10.100.0.1:2379"
#    serverCertSANs:
#      - "ec2-10-100-0-1.compute-1.amazonaws.com"
#    peerCertSANs:
#      - "10.100.0.1"
# external:
#   endpoints:
#   - "10.100.0.1:2379"
#   - "10.100.0.2:2379"
#   caFile: "/etcd/kubernetes/pki/etcd/etcd-ca.crt"
#   certFile: "/etcd/kubernetes/pki/etcd/etcd.crt"
#   keyFile: "/etcd/kubernetes/pki/etcd/etcd.key"
#imageRepository: k8s.kubesre.xyz # 镜像源
imageRepository: $IMAGE_REPOSITORY # 镜像源
# 为控制面设置一个稳定的 IP 地址或 DNS 名称。
# 取值可以是一个合法的 IP 地址或者 RFC-1123 形式的 DNS 子域名，二者均可以带一个 可选的 TCP 端口号。
# 如果 controlPlaneEndpoint 未设置，则使用 advertiseAddress + bindPort。 如果设置了 controlPlaneEndpoint，但未指定 TCP 端口号，则使用 bindPort。
# 可能的用法有：
# 在一个包含不止一个控制面实例的集群中，该字段应该设置为放置在控制面 实例之前的外部负载均衡器的地址。
# 在带有强制性节点回收的环境中，controlPlaneEndpoint 可以用来 为控制面设置一个稳定的 DNS。
# 负载均衡地址或者master的主机
controlPlaneEndpoint: $CONTROL_PLANE_ENDPOINT
# 其中包含集群的网络拓扑配置。使用这一部分可以定制 Pod 的 子网或者 Service 的子网。
networking:
  # Kubernetes 服务所使用的的 DNS 域名。 默认值为 "cluster.local"。
  dnsDomain: cluster.local
  # 为 Pod 所使用的子网 默认为: 10.244.0.0/16
  # 10.10.0.0到10.10.63.255，共有16384个IP地址
  # 如果是flannel插件, 需要修改flannel的yaml文件的net-conf.json为当前的podSubnet值
  podSubnet: $POD_SUBNET
  # Kubernetes 服务所使用的的子网。 默认值为 "10.96.0.0/12"
  #  serviceSubnet: "10.10.0.0/20"
  serviceSubnet: $SERVICE_SUBNET
# 调度器配置
scheduler: { }
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
#address: "192.168.2.155" # kubelet 将在 192.168.0.8 IP 地址上提供服务
#port: 20250 # kubelet 将在 20250 端口上提供服务
serializeImagePulls: true # 并行拉取镜像, 默认值false
# kubelet 将在以下情况之一驱逐 Pod:
evictionHard:
  # 可用内存低于设定的值时
  memory.available: "100Mi"
  nodefs.available: "10%"
  # 当节点主文件系统的已使用 inode超过设定的值时
  nodefs.inodesFree: "5%"
  # 当镜像文件系统的可用空间小于
  imagefs.available: "15%"
# 是 kubelet 用来操控宿主系统上控制组（CGroup） 的驱动程序（cgroupfs 或 systemd）
# 当 systemd 是初始化系统时， 不 推荐使用 cgroupfs 驱动，因为 systemd 期望系统上只有一个 cgroup 管理器。
# 此外，如果你使用 cgroup v2， 则使用systemd值, 从 v1.22 及更高版本开始，使用 kubeadm 创建集群时默认值为systemd
cgroupDriver: systemd
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
# kube-proxy specific options here
mode: ipvs
EOF
