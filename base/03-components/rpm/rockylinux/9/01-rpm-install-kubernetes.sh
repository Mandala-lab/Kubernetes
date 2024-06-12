#!/bin/sh

set -o posix -o errexit -o pipefail

yum update -y && yum -y install wget psmisc vim net-tools nfs-utils telnet yum-utils device-mapper-persistent-data lvm2 git network-scripts tar curl
cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf

# HTTP/S Proxy
export PROXY_ADDR="192.168.3.220:7890"
cat >> ~/.bashrc <<EOF
alias vpnon="export http_proxy='$PROXY_ADDR';export https_proxy='$PROXY_ADDR'"
alias vpnoff="unset http_proxy;unset https_proxy"
EOF
# shellcheck source=~/root/.bashrc
. ~/.bashrc
vpnon

# runc
VERSION="v1.1.12"
ARCH="arm64"
wget -t 2 -T 240 -N -S https://github.com/opencontainers/runc/releases/download/${VERSION}/runc.${ARCH}
cp runc.${ARCH} /usr/local/sbin/runc
chmod 755 /usr/local/sbin/runc
cp -p /usr/local/sbin/runc /usr/local/bin/runc
cp -p /usr/local/sbin/runc /usr/bin/runc

# socat
yum install -y socat
#dnf install -y socat

# conntrack
yum install -y conntrack
#dnf install -y conntrack

CONTAINERD_VERSION='1.7.13'
ARCH="arm64"
wget -t 2 -T 240 -N -S https://github.com/containerd/containerd/releases/download/${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
tar Czvf containerd-*-linux-arm64.tar.gz /usr/local

cat > /etc/systemd/system/containerd.service <<EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

# containerd是一个容器运行时，用于管理和运行容器。它支持多种不同的参数配置来自定义容器运行时的行为和功能。
# 1. overlay：overlay是容器d默认使用的存储驱动，它提供了一种轻量级的、可堆叠的、逐层增量的文件系统。
# 它通过在现有文件系统上叠加文件系统层来创建容器的文件系统视图。每个容器可以有自己的一组文件系统层，这些层可以共享基础镜像中的文件，并在容器内部进行修改。
# 使用overlay可以有效地使用磁盘空间，并使容器更加轻量级。
# 2. br_netfilter：br_netfilter是Linux内核提供的一个网络过滤器模块，用于在容器网络中进行网络过滤和NAT转发。
# 当容器和主机之间的网络通信需要进行DNAT或者SNAT时，br_netfilter模块可以将IP地址进行转换。
# 它还可以提供基于iptables规则的网络过滤功能，用于限制容器之间或容器与外部网络之间的通信。
# 这些参数可以在containerd的配置文件或者命令行中指定。
# 例如，可以通过设置--storage-driver参数来选择使用overlay作为存储驱动，通过设置--iptables参数来启用或禁用br_netfilter模块。
# 具体的使用方法和配置细节可以参考containerd的官方文档。
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
systemctl restart systemd-modules-load.service

# 参数解释：
#
# 这些参数是Linux操作系统中用于网络和网络桥接设置的参数。
#
# - net.bridge.bridge-nf-call-iptables：这个参数控制网络桥接设备是否调用iptables规则处理网络数据包。当该参数设置为1时，网络数据包将被传递到iptables进行处理；当该参数设置为0时，网络数据包将绕过iptables直接传递。默认情况下，这个参数的值是1，即启用iptables规则处理网络数据包。
#
# - net.ipv4.ip_forward：这个参数用于控制是否启用IP转发功能。IP转发使得操作系统可以将接收到的数据包从一个网络接口转发到另一个网络接口。当该参数设置为1时，启用IP转发功能；当该参数设置为0时，禁用IP转发功能。在网络环境中，通常需要启用IP转发功能来实现不同网络之间的通信。默认情况下，这个参数的值是0，即禁用IP转发功能。
#
# - net.bridge.bridge-nf-call-ip6tables：这个参数与net.bridge.bridge-nf-call-iptables类似，但是它用于IPv6数据包的处理。当该参数设置为1时，IPv6数据包将被传递到ip6tables进行处理；当该参数设置为0时，IPv6数据包将绕过ip6tables直接传递。默认情况下，这个参数的值是1，即启用ip6tables规则处理IPv6数据包。
#
# 这些参数的值可以通过修改操作系统的配置文件（通常是'/etc/sysctl.conf'）来进行设置。修改完成后，需要使用'sysctl -p'命令重载配置文件使参数生效。
# RockyLinux9 最小安装化版本需要启用bridge模块
sudo modprobe ip_conntrack
sudo modprobe br_netfilter
lsmod | grep bridge
lsmod | grep br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
# 加载内核
sysctl -p /etc/sysctl.d/99-kubernetes-cri.conf
sysctl --system

#
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

# TODO 修改Containerd的配置文件
sed -i "s#SystemdCgroup\ \=\ false#SystemdCgroup\ \=\ true#g" /etc/containerd/config.toml
cat /etc/containerd/config.toml | grep SystemdCgroup
sed -i "s#registry.k8s.io#m.daocloud.io/registry.k8s.io#g" /etc/containerd/config.toml
cat /etc/containerd/config.toml | grep sandbox

# 配置加速器
# SystemdCgroup参数是containerd中的一个配置参数，用于设置containerd在运行过程中使用的Cgroup（控制组）路径。
# Containerd使用SystemdCgroup参数来指定应该使用哪个Cgroup来跟踪和管理容器的资源使用。
# Cgroup是Linux内核提供的一种资源隔离和管理机制，可以用于限制、分配和监控进程组的资源使用。
# 使用Cgroup，可以将容器的资源限制和隔离，以防止容器之间的资源争用和不公平的竞争。
# 通过设置SystemdCgroup参数，可以确保containerd能够找到正确的Cgroup路径，并正确地限制和隔离容器的资源使用，确保容器可以按照预期的方式运行。
# 如果未正确设置SystemdCgroup参数，可能会导致容器无法正确地使用资源，或者无法保证资源的公平分配和隔离。
# 总而言之，SystemdCgroup参数的作用是为了确保containerd能够正确地管理容器的资源使用，以实现资源的限制、隔离和公平分配。
mkdir /etc/containerd/certs.d/docker.io -pv
cat > /etc/containerd/certs.d/docker.io/hosts.toml << EOF
server = "https://docker.io"
[host."https://docker.mirrors.ustc.edu.cn"]
  capabilities = ["pull", "resolve"]
EOF


#cni_plugins_version='v1.4.0'
#wget -t 2 -T 240 -N -S https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-arm64-v1.4.0.tgz

# URLs
base_url='https://mirrors.chenby.cn/https://github.com'
kernel_url="http://mirrors.tuna.tsinghua.edu.cn/elrepo/kernel/el7/x86_64/RPMS/kernel-lt-${kernel_version}-1.el7.elrepo.x86_64.rpm"
runc_url="${base_url}/opencontainers/runc/releases/download/v${runc_version}/runc.amd64"
docker_url="https://mirrors.ustc.edu.cn/docker-ce/linux/static/stable/x86_64/docker-${docker_version}.tgz"
cni_plugins_url="${base_url}/containernetworking/plugins/releases/download/${cni_plugins_version}/cni-plugins-linux-amd64-${cni_plugins_version}.tgz"
cri_containerd_cni_url="${base_url}/containerd/containerd/releases/download/v${cri_containerd_cni_version}/cri-containerd-cni-${cri_containerd_cni_version}-linux-amd64.tar.gz"
crictl_url="${base_url}/kubernetes-sigs/cri-tools/releases/download/${crictl_version}/crictl-${crictl_version}-linux-amd64.tar.gz"
cri_dockerd_url="${base_url}/Mirantis/cri-dockerd/releases/download/v${cri_dockerd_version}/cri-dockerd-${cri_dockerd_version}.amd64.tgz"
etcd_url="${base_url}/etcd-io/etcd/releases/download/${etcd_version}/etcd-${etcd_version}-linux-amd64.tar.gz"
cfssl_url="${base_url}/cloudflare/cfssl/releases/download/v${cfssl_version}/cfssl_${cfssl_version}_linux_amd64"
cfssljson_url="${base_url}/cloudflare/cfssl/releases/download/v${cfssl_version}/cfssljson_${cfssl_version}_linux_amd64"
helm_url="https://mirrors.huaweicloud.com/helm/v${helm_version}/helm-v${helm_version}-linux-amd64.tar.gz"
kubernetes_server_url="https://storage.googleapis.com/kubernetes-release/release/v${kubernetes_server_version}/kubernetes-server-linux-amd64.tar.gz"
nginx_url="http://nginx.org/download/nginx-${nginx_version}.tar.gz"

# Download packages
packages=(
  $kernel_url
  $runc_url
  $docker_url
  $cni_plugins_url
  $cri_containerd_cni_url
  $crictl_url
  $cri_dockerd_url
  $etcd_url
  $cfssl_url
  $cfssljson_url
  $helm_url
  $kubernetes_server_url
  $nginx_url
)

for package_url in "${packages[@]}"; do
  filename=$(basename "$package_url")
  if curl --parallel --parallel-immediate -k -L -C - -o "$filename" "$package_url"; then
    echo "Downloaded $filename"
  else
    echo "Failed to download $filename"
    exit 1
  fi
done

sed -ri 's/.*swap.*/#&/' /etc/fstab
swapoff -a && sysctl -w vm.swappiness=0

cat /etc/fstab

systemctl disable --now firewalld

setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config

cat > /etc/NetworkManager/conf.d/calico.conf << EOF
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:tunl*
EOF
systemctl restart NetworkManager

yum install chrony -y
cat > /etc/chrony.conf << EOF
pool ntp.aliyun.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.1.0/24
local stratum 10
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF

systemctl restart chronyd ; systemctl enable chronyd

ulimit -SHn 65535

cat >> /etc/security/limits.conf <<EOF
* soft nofile 655360
* hard nofile 131072
* soft nproc 655350
* hard nproc 655350
* seft memlock unlimited
* hard memlock unlimitedd
EOF

yum install -y sshpass
ssh-keygen -f /root/.ssh/id_rsa -P ''
# TODO client IPs
export IP="192.168.3.160"
export SSHPASS=root
for HOST in $IP;do
     sshpass -e ssh-copy-id -o StrictHostKeyChecking=no $HOST
done

# 内核升级

# 内核参数
# 这些是Linux系统的一些参数设置，用于配置和优化网络、文件系统和虚拟内存等方面的功能。以下是每个参数的详细解释：
#
# 1. net.ipv4.ip_forward = 1
#    - 这个参数启用了IPv4的IP转发功能，允许服务器作为网络路由器转发数据包。
#
# 2. net.bridge.bridge-nf-call-iptables = 1
#    - 当使用网络桥接技术时，将数据包传递到iptables进行处理。
#
# 3. fs.may_detach_mounts = 1
#    - 允许在挂载文件系统时，允许被其他进程使用。
#
# 4. vm.overcommit_memory=1
#    - 该设置允许原始的内存过量分配策略，当系统的内存已经被完全使用时，系统仍然会分配额外的内存。
#
# 5. vm.panic_on_oom=0
#    - 当系统内存不足（OOM）时，禁用系统崩溃和重启。
#
# 6. fs.inotify.max_user_watches=89100
#    - 设置系统允许一个用户的inotify实例可以监控的文件数目的上限。
#
# 7. fs.file-max=52706963
#    - 设置系统同时打开的文件数的上限。
#
# 8. fs.nr_open=52706963
#    - 设置系统同时打开的文件描述符数的上限。
#
# 9. net.netfilter.nf_conntrack_max=2310720
#    - 设置系统可以创建的网络连接跟踪表项的最大数量。
#
# 10. net.ipv4.tcp_keepalive_time = 600
#     - 设置TCP套接字的空闲超时时间（秒），超过该时间没有活动数据时，内核会发送心跳包。
#
# 11. net.ipv4.tcp_keepalive_probes = 3
#     - 设置未收到响应的TCP心跳探测次数。
#
# 12. net.ipv4.tcp_keepalive_intvl = 15
#     - 设置TCP心跳探测的时间间隔（秒）。
#
# 13. net.ipv4.tcp_max_tw_buckets = 36000
#     - 设置系统可以使用的TIME_WAIT套接字的最大数量。
#
# 14. net.ipv4.tcp_tw_reuse = 1
#     - 启用TIME_WAIT套接字的重新利用，允许新的套接字使用旧的TIME_WAIT套接字。
#
# 15. net.ipv4.tcp_max_orphans = 327680
#     - 设置系统可以同时存在的TCP套接字垃圾回收包裹数的最大数量。
#
# 16. net.ipv4.tcp_orphan_retries = 3
#     - 设置系统对于孤立的TCP套接字的重试次数。
#
# 17. net.ipv4.tcp_syncookies = 1
#     - 启用TCP SYN cookies保护，用于防止SYN洪泛攻击。
#
# 18. net.ipv4.tcp_max_syn_backlog = 16384
#     - 设置新的TCP连接的半连接数（半连接队列）的最大长度。
#
# 19. net.ipv4.ip_conntrack_max = 65536
#     - 设置系统可以创建的网络连接跟踪表项的最大数量。
#
# 20. net.ipv4.tcp_timestamps = 0
#     - 关闭TCP时间戳功能，用于提供更好的安全性。
#
# 21. net.core.somaxconn = 16384
#     - 设置系统核心层的连接队列的最大值。
#
# 22. net.ipv6.conf.all.disable_ipv6 = 0
#     - 启用IPv6协议。
#
# 23. net.ipv6.conf.default.disable_ipv6 = 0
#     - 启用IPv6协议。
#
# 24. net.ipv6.conf.lo.disable_ipv6 = 0
#     - 启用IPv6协议。
#
# 25. net.ipv6.conf.all.forwarding = 1
#     - 允许IPv6数据包转发。
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
fs.may_detach_mounts = 1
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.netfilter.nf_conntrack_max=2310720

net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_conntrack_max = 65536
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_timestamps = 0
net.core.somaxconn = 16384
EOF

cat > /etc/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.3.160 node-160
192.168.3.152 node-152
192.168.3.155 node-155
192.168.3.100 node-100
192.168.3.101 node-101
192.168.3.102 node-102
EOF



# 安装 kubeadm、kubelet
# https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
export DOWNLOAD_HOME="/home/kubernetes"
mkdir -p $DOWNLOAD_HOME
cd "$DOWNLOAD_HOME" || exit

RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
#ARCH="amd64"
ARCH="arm64"

# https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubeadm
# https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubelet
# https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl
sudo curl -LO "https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubeadm.sha256}"
if echo "$(cat kubeadm.sha256) kubeadm" | sha256sum -c; then
  echo "kubeadm 的SHA256 校验成功"
else
  echo "kubeadm 的SHA256 校验失败，退出并报错"
  exit 1
fi

sudo mv ./kubeadm /usr/local/bin/
sudo chmod +x /usr/local/bin/kubeadm

sudo curl -LO "https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubelet,kubelet.sha256}"

echo "$(cat kubelet.sha256) kubelet" | sha256sum -c

sudo mv ./kubelet /usr/local/bin/
sudo chmod +x /usr/local/bin/kubelet

# kubectl
sudo curl -LO "https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubectl,kubectl.sha256}"
if echo "$(cat kubectl.sha256) kubectl" | sha256sum -c; then
  echo "kubectl 的SHA256 校验失败，退出并报错"
#  exit 1
fi
echo "kubectl 的SHA256 校验成功"
DOWNLOAD_DIR="/usr/local/bin"
sudo install -o root -g root -m 0755 kubectl $DOWNLOAD_DIR/kubectl

# 并添加 kubelet 系统服务
# 查看 https://github.com/kubernetes/release/tree/master 获取RELEASE_VERSION的版本号
DOWNLOAD_DIR="/usr/local/bin"
RELEASE_VERSION="v0.16.4"

# 判断当前目录kubelet.service文件是否存在, 存在则删除
if [ -f "$DOWNLOAD_HOME/kubelet.service" ]; then
    echo "kubelet.service 存在，将其删除"
    rm $DOWNLOAD_HOME/kubelet.service
else
    echo "kubelet.service 不存在"
fi

# v0.16.4的https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service文件内容是:
# [Unit]
# Description=kubelet: The Kubernetes Node Agent
# Documentation=https://kubernetes.io/docs/
# Wants=network-online.target
# After=network-online.target
#
# [Service]
# ExecStart=/usr/bin/kubelet
# Restart=always
# StartLimitInterval=0
# RestartSec=10
#
# [Install]
# WantedBy=multi-user.target

DOWNLOAD_DIR="/usr/bin"
rm -rf /usr/lib/systemd/system/kubelet.service
rm -rf /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
if ! wget -t 2 -T 240 -N -S -q "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service"; then
  echo "下载失败, 正在使用内置的文件进行替换, 但可能不是最新的, 可以进行手动替换"
  cat > /etc/systemd/system/kubelet.service <<EOF
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=$DOWNLOAD_DIR/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
else
  echo "正在替换"
  sed -i "s:/usr/bin:${DOWNLOAD_DIR}:g" kubelet.service
  cp kubelet.service /etc/systemd/system/kubelet.service
fi

# kubeadm 包自带了关于 systemd 如何运行 kubelet 的配置文件。 请注意 kubeadm 客户端命令行工具永远不会修改这份 systemd 配置文件。 这份 systemd 配置文件属于 kubeadm DEB/RPM 包
# https://kubernetes.io/zh-cn/docs/reference/setup-tools/kubeadm/kubeadm-init/#kubelet-drop-in

# 获取配置文件内容并修改该文件的内容, 把kubelet二进制文件的路径替换为用户定义的路径
# 并输出到 /etc/systemd/system/kubelet.service.d/10-kubeadm.conf 文件中

# 10-kubeadm.conf 存在，将其删除
if [ -f "$DOWNLOAD_HOME/10-kubeadm.conf" ]; then
    echo "$DOWNLOAD_HOME/10-kubeadm.conf 存在，将其删除"
    rm $DOWNLOAD_HOME/kubelet.service
fi

DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p /etc/systemd/system/kubelet.service.d
if ! wget -t 2 -T 240 -N -S -q "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf"; then
  echo "下载失败, 正在使用内置的文件进行替换, 但可能不是最新的, 可以进行手动替换"
  cat > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf << EOF
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/sysconfig/kubelet
ExecStart=
ExecStart=$DOWNLOAD_DIR/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
EOF
else
  echo "下载成功"
  sed -i "s:/usr/bin:${DOWNLOAD_DIR}:g" 10-kubeadm.conf
  sudo cp 10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi

# 配置 cgroup 驱动与CRI一致
cp /etc/sysconfig/kubelet{,.back}
cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
EOF

cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# crictl
VERSION="v1.29.0"
ARCH="arm64"
wget -t 2 -T 240 -N -S https://github.com/kubernetes-sigs/cri-tools/releases/download/${VERSION}/crictl-${VERSION}-linux-${ARCH}.tar.gz

tar xf crictl-$VERSION-linux-$ARCH.tar.gz -C /usr/bin/
#生成配置文件
# `crictl`是一个用于与容器运行时通信的命令行工具。它是容器运行时接口（CRI）工具的一个实现，可以对容器运行时进行管理和操作。
# 1. `runtime-endpoint: unix:///run/containerd/containerd.sock`
# 指定容器运行时的终端套接字地址。在这个例子中，指定的地址是`unix:///run/containerd/containerd.sock`，这是一个Unix域套接字地址。
# 2. `image-endpoint: unix:///run/containerd/containerd.sock`
# 指定容器镜像服务的终端套接字地址。在这个例子中，指定的地址是`unix:///run/containerd/containerd.sock`，这是一个Unix域套接字地址。
# 3. `timeout: 10`
# 设置与容器运行时通信的超时时间，单位是秒。在这个例子中，超时时间被设置为10秒。
# 4. `debug: false`
# 指定是否开启调式模式。在这个例子中，调式模式被设置为关闭，即`false`。如果设置为`true`，则会输出更详细的调试信息。
# 这些参数可以根据需要进行修改，以便与容器运行时进行有效的通信和管理。
cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

#测试
systemctl restart  containerd
crictl info


# ETCD https://github.com/etcd-io/etcd/releases/
#VERSION="v3.5.12"
#ARCH="arm64"
#wget -t 2 -T 240 -N -S https://github.com/etcd-io/etcd/releases/download/${VERSION}/etcd-${VERSION}-linux-${ARCH}.tar.gz
#tar -zxvf etcd-${VERSION}-linux-${ARCH}.tar.gz
#cp etcd-${VERSION}-linux-${ARCH}/etcd /usr/local/bin/
#cp etcd-${VERSION}-linux-${ARCH}/etcdctl /usr/local/bin/
#etcdctl version



# 清理旧的安装信息
which kubeadm kubelet kubectl
hash -r

# helm
VERSION="v3.13.2"
ARCH="arm64"
wget -t 2 -T 240 -N -S https://mirrors.huaweicloud.com/helm/${VERSION}/helm-${VERSION}-linux-${ARCH}.tar.gz
tar -zxvf helm-${VERSION}-linux-${ARCH}.tar.gz
cp linux-$ARCH/helm /usr/local/bin/


systemctl daemon-reload
# 用于重新加载systemd管理的单位文件。当你新增或修改了某个单位文件（如.service文件、.socket文件等），需要运行该命令来刷新systemd对该文件的配置。

systemctl enable --now containerd.service
# 启用并立即启动docker.service单元。docker.service是Docker守护进程的systemd服务单元。

systemctl stop containerd.service
# 停止运行中的docker.service单元，即停止Docker守护进程。

systemctl start containerd.service
# 启动docker.service单元，即启动Docker守护进程。

systemctl restart containerd.service
# 重启docker.service单元，即重新启动Docker守护进程。

systemctl status containerd.service
# 显示docker.service单元的当前状态，包括运行状态、是否启用等信息。

systemctl enable --now kubelet
systemctl status kubelet

kubeadm version
kubelet --version
kubectl version --client

# 查看版本的详细视图
# kubectl version --client --output=yaml

# 注意：如果 ipvs 模式成功打开，您应该会看到 IPVS 代理规则（使用 ipvsadm ），例如
# ipvsadm -ln
# IP Virtual Server version 1.2.1 (size=4096)
# Prot LocalAddress:Port Scheduler Flags
#   -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
# TCP  10.0.0.1:443 rr persistent 10800
#   -> 192.168.0.1:6443             Masq    1      1          0

# 或类似的日志出现在 kube-proxy 日志中（例如， /tmp/kube-proxy.log 对于本地集群），当本地集群正在运行时：
# Using ipvs Proxier.
# While there is no IPVS proxy rules or the following logs occurs indicate that the kube-proxy fails to use IPVS mode:
# 虽然没有 IPVS 代理规则或出现以下日志，但表明 kube-proxy 无法使用 IPVS 模式：
# Can't use ipvs proxier, trying iptables proxier
# Using iptables Proxier.

# 命令行补全
yum install bash-completion -y
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

# CNI
# 添加源
helm repo add cilium https://helm.cilium.io

# 修改为国内源
mkdir -p /home/kubernetes/cilium
cd /home/kubernetes/cilium || exit

helm pull cilium/cilium
tar xvf cilium-*.tgz
cd cilium/ || exit
sed -i "s#quay.io/#m.daocloud.io/quay.io/#g" values.yaml

# 默认参数安装
#helm install  cilium ./cilium/ -n kube-system

# 启用ipv6
# helm install cilium cilium/cilium --namespace kube-system --set ipv6.enabled=true

# 启用路由信息和监控插件
helm install cilium cilium/cilium --namespace kube-system \
--set hubble.relay.enabled=true \
--set hubble.ui.enabled=true \
--set prometheus.enabled=true \
--set operator.prometheus.enabled=true \
--set hubble.enabled=true \
--set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,http}"

kubectl  get pod -A | grep cil

# 下载专属监控面板
wget -t 2 -T 240 -N -S https://mirrors.chenby.cn/https://raw.githubusercontent.com/cilium/cilium/1.12.1/examples/kubernetes/addons/prometheus/monitoring-example.yaml
sed -i "s#docker.io/#m.daocloud.io/docker.io/#g" monitoring-example.yaml
kubectl  apply -f monitoring-example.yaml

wget -t 2 -T 240 -N -S https://mirrors.chenby.cn/https://raw.githubusercontent.com/cilium/cilium/master/examples/kubernetes/connectivity-check/connectivity-check.yaml

# 说明 测试用例 需要在 安装CoreDNS 之后即可完成
sed -i "s#google.com#baidu.cn#g" connectivity-check.yaml
sed -i "s#quay.io/#m.daocloud.io/quay.io/#g" connectivity-check.yaml
kubectl  apply -f connectivity-check.yaml
kubectl  get pod -A

kubectl get svc -A | grep monit
kubectl get svc -A | grep hubble

# Metrics-server
# 在新版的Kubernetes中系统资源的采集均使用Metrics-server，可以通过Metrics采集节点和Pod的内存、磁盘、CPU和网络的使用率
# 下载
wget -t 2 -T 240 -N -S https://mirrors.chenby.cn/https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 修改配置
vim components.yaml

---
# 1
defaultArgs:
        - --cert-dir=/tmp
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
        - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.pem
        - --requestheader-username-headers=X-Remote-User
        - --requestheader-group-headers=X-Remote-Group
        - --requestheader-extra-headers-prefix=X-Remote-Extra-

# 2
        volumeMounts:
        - mountPath: /tmp
          name: tmp-dir
        - name: ca-ssl
          mountPath: /etc/kubernetes/pki

# 3
      volumes:
      - emptyDir: {}
        name: tmp-dir
      - name: ca-ssl
        hostPath:
          path: /etc/kubernetes/pki
---


# 修改为国内源 docker源可选
sed -i "s#registry.k8s.io/#m.daocloud.io/registry.k8s.io/#g" *.yaml

# 执行部署
kubectl apply -f components.yaml

kubectl  top node

# 集群验证
cat<<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - name: busybox
    image: docker.io/library/busybox:1.28
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
EOF
kubectl  get pod
kubectl get svc
kubectl exec  busybox -n default -- nslookup kubernetes

kubectl  get svc -A
kubectl exec  busybox -n default -- nslookup coredns-coredns.kube-system

# Pod和Pod之前要能通
kubectl get po -owide
kubectl get po -n kube-system -owide
kubectl exec -ti busybox -- sh
# ping 192.168.1.34

# 测试部署到每个节点上
cat<<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

kubectl  get pod
## 测试完成删除
kubectl delete deployments nginx-deployment

# 安装dashboard
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --namespace kube-system

kubectl get svc kubernetes-dashboard -n kube-system
## 创建token
cat > dashboard-user.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF

kubectl  apply -f dashboard-user.yaml

## 创建token
kubectl -n kube-system create token admin-user

# ingress安装
wget -t 2 -T 240 -N -S https://mirrors.chenby.cn/https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# 修改为国内源 docker源可选
sed -i "s#registry.k8s.io/#m.daocloud.io/registry.k8s.io/#g" *.yaml

cat > backend.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-http-backend
  labels:
    app.kubernetes.io/name: default-http-backend
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: default-http-backend
  template:
    metadata:
      labels:
        app.kubernetes.io/name: default-http-backend
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: default-http-backend
        image: registry.cn-hangzhou.aliyuncs.com/chenby/defaultbackend-amd64:1.5
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: 10m
            memory: 20Mi
          requests:
            cpu: 10m
            memory: 20Mi
---
apiVersion: v1
kind: Service
metadata:
  name: default-http-backend
  namespace: kube-system
  labels:
    app.kubernetes.io/name: default-http-backend
spec:
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app.kubernetes.io/name: default-http-backend
EOF

kubectl  apply -f deploy.yaml
kubectl  apply -f backend.yaml


cat > ingress-demo-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-server
  template:
    metadata:
      labels:
        app: hello-server
    spec:
      containers:
      - name: hello-server
        image: registry.cn-hangzhou.aliyuncs.com/lfy_k8s_images/hello-server
        ports:
        - containerPort: 9000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx-demo
  name: nginx-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
      - image: nginx
        name: nginx
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx-demo
  name: nginx-demo
spec:
  selector:
    app: nginx-demo
  ports:
  - port: 8000
    protocol: TCP
    targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: hello-server
  name: hello-server
spec:
  selector:
    app: hello-server
  ports:
  - port: 8000
    protocol: TCP
    targetPort: 9000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-host-bar
spec:
  ingressClassName: nginx
  rules:
  - host: "hello.chenby.cn"
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: hello-server
            port:
              number: 8000
  - host: "demo.chenby.cn"
    http:
      paths:
      - pathType: Prefix
        path: "/nginx"
        backend:
          service:
            name: nginx-demo
            port:
              number: 8000
EOF

# 等创建完成后在执行：
kubectl  apply -f ingress-demo-app.yaml

kubectl  get ingress
NAME               CLASS   HOSTS                            ADDRESS     PORTS   AGE
ingress-host-bar   nginx   hello.chenby.cn,demo.chenby.cn   192.168.1.32   80      7s

# 过滤查看ingress端口
# 修改为nodeport
kubectl edit svc -n ingress-nginx   ingress-nginx-controller
#type: NodePort

kubectl  get svc -A | grep ingress
# ingress-nginx          ingress-nginx-controller             NodePort    10.104.231.36    <none>        80:32636/TCP,443:30579/TCP   104s
# ingress-nginx          ingress-nginx-controller-admission   ClusterIP   10.101.85.88     <none>        443/TCP                      105s

set +x
