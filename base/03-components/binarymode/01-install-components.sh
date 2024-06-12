#!/bin/bash

set -o posix -o errexit -o pipefail

# 清除旧安装
systemctl stop kubeadm
systemctl stop kubelet
systemctl stop kubectl
sudo apt purge -y kubeadm kubectl kubelet kubernetes-cni kube*
sudo apt-mark unhold kubeadm
sudo apt-mark unhold kubelet
sudo apt-mark unhold kubectl
sudo apt remove -y kubeadm kubelet kubectl
sudo apt remove -y containerd
rm -rf /usr/local/bin/kube*
rm -rf /usr/bin/kube*
rm -rf /etc/systemd/system/kubelet.service.d
rm -rf /var/lib/kube*
rm -rf /etc/sysconfig/kubelet
rm -rf /etc/kubernetes
rm -rf /etc/sysctl.d/99-kubernetes-cri.conf

# 安装 kubeadm、kubelet
# https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
export DOWNLOAD_HOME="/home/kubernetes"
mkdir -p $DOWNLOAD_HOME
cd "$DOWNLOAD_HOME" || exit

RELEASE=$(wget -qO- https://dl.k8s.io/release/stable.txt)
#RELEASE="$(curl -LO https://dl.k8s.io/release/stable.txt)"

# 使用uname -m获取系统架构
arch_raw=$(uname -m)

# 根据获取的原始架构信息映射到规范的架构名称
case $arch_raw in
  x86_64)
    ARCH="amd64"
    ;;
  aarch64)
    ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: $arch_raw"
    exit 1
    ;;
esac

# 输出最终的架构名称
echo "Detected architecture: $ARCH"

# kubeadm
if [ -f "$DOWNLOAD_HOME/kubeadm" ] && [ -f "$DOWNLOAD_HOME/kubeadm.sha256" ]; then
    if echo "$(cat kubeadm.sha256) kubeadm" | sha256sum -c; then
      echo "kubeadm 的SHA256 校验成功"
    else
      echo "kubeadm 的SHA256 校验失败，退出并报错"
      rm -rf kubeadm kubeadm.sha256
      exit 1
    fi
    sudo cp ./kubeadm /usr/local/bin/
    sudo chmod +x /usr/local/bin/kubeadm
else
    echo "kubelet.service 不存在"
    curl -LO "https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubeadm.sha256}"
    #sudo wget https://dl.k8s.io/release/"${RELEASE}"/bin/linux/${ARCH}/{kubeadm,kubeadm.sha256}
    if echo "$(cat kubeadm.sha256) kubeadm" | sha256sum -c; then
      echo "kubeadm 的SHA256 校验成功"
    else
      echo "kubeadm 的SHA256 校验失败，退出并报错"
      rm -rf kubeadm kubeadm.sha256
      exit 1
    fi
fi

# kubelet
if [ -f "$DOWNLOAD_HOME/kubelet" ] && [ -f "$DOWNLOAD_HOME/kubelet.sha256" ]; then
    if echo "$(cat kubelet.sha256) kubelet" | sha256sum -c; then
      echo "kubelet 的SHA256 校验成功"
    else
      echo "kubelet 的SHA256 校验失败，退出并报错"
      rm -rf kubelet kubelet.sha256
      exit 1
    fi
    sudo cp ./kubelet /usr/local/bin/
    sudo chmod +x /usr/local/bin/kubelet
else
    echo "kubelet.service 不存在"
    sudo curl -LO "https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubelet,kubelet.sha256}"
    #sudo wget https://dl.k8s.io/release/"${RELEASE}"/bin/linux/${ARCH}/{kubelet,kubelet.sha256}
    if echo "$(cat kubelet.sha256) kubelet" | sha256sum -c; then
      echo "kubelet 的SHA256 校验成功"
    else
      echo "kubelet 的SHA256 校验失败，退出并报错"
      rm -rf kubelet kubelet.sha256
      exit 1
    fi
fi

# kubectl
if [ -f "$DOWNLOAD_HOME/kubectl" ] && [ -f "$DOWNLOAD_HOME/kubectl.sha256" ]; then
    if echo "$(cat kubectl.sha256) kubectl" | sha256sum -c; then
      echo "kubectl 的SHA256 校验成功"
    else
      echo "kubectl 的SHA256 校验失败，退出并报错"
      rm -rf kubectl kubectl.sha256
      exit 1
    fi
    DOWNLOAD_DIR="/usr/local/bin"
    rm -rf $DOWNLOAD_DIR/kubectl
    sudo install -o root -g root -m 0755 kubectl $DOWNLOAD_DIR/kubectl
else
    echo "kubectl.service 不存在"
    #sudo curl -LO "https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubectl,kubectl.sha256}"
    sudo wget -t 2 -T 240 -N -S https://dl.k8s.io/release/"${RELEASE}"/bin/linux/${ARCH}/{kubectl,kubectl.sha256}
    if echo "$(cat kubectl.sha256) kubectl" | sha256sum -c; then
      echo "kubectl 的SHA256 校验成功"
    else
      echo "kubectl 的SHA256 校验失败，退出并报错"
      rm -rf kubectl kubectl.sha256
      exit 1
    fi
    DOWNLOAD_DIR="/usr/local/bin"
    sudo install -o root -g root -m 0755 kubectl $DOWNLOAD_DIR/kubectl
fi

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

DOWNLOAD_DIR="/usr/bin"
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

# 清理旧的安装信息
which kubeadm kubelet kubectl
hash -r

systemctl daemon-reload

systemctl enable --now kubelet
systemctl status kubelet

systemctl restart containerd

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

set +x
