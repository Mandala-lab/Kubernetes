#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix -o errexit -o pipefail -x

# 函数：显示错误消息并退出
error_exit() {
    echo "Error: Invalid argument value for $1. Expected 'y' or 'n'."
    exit 1
}

# 解析命令行参数
remove=""
VERSION=""
proxy=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --proxy=*)
            value="${1#*=}"  # 提取等号后的值
            if [ "$value" = "y" ]; then
                proxy="y"
            elif [ "$value" = "n" ]; then
                proxy="n"
            else
                error_exit "$1"
            fi
            shift
            ;;
        --remove=*)
            value="${1#*=}"  # 提取等号后的值
            if [ "$value" = "y" ]; then
                remove="y"
            elif [ "$value" = "n" ]; then
                remove="n"
            else
                error_exit "$1"
            fi
            shift
            ;;
        --version=*)
            VERSION="${1#*=}"  # 提取等号后的值
            shift
            ;;
    esac
done

# 是否清除旧安装
if [ $remove = "y" ]; then
  systemctl stop kubeadm
  systemctl stop kubelet
  systemctl stop kubectl
  sudo apt purge -y kubeadm kubectl kubelet kubernetes-cni kube*
  sudo apt-mark unhold kubeadm
  sudo apt-mark unhold kubelet
  sudo apt-mark unhold kubectl
  sudo apt remove -y kubeadm kubelet kubectl
  rm -rf /usr/local/bin/kube*
  rm -rf /usr/bin/kube*
  rm -rf /var/lib/kube*
  rm -rf /etc/sysconfig/kubelet
  rm -rf /etc/kubernetes
  rm -rf /etc/apt/sources.list.d/kubernetes.list
  rm -rf /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.confkub
  sudo apt autoremove -y
fi

# 输出用户定义的Kubernetes版本
echo "version: $VERSION"
if [ "$VERSION" = "" ]; then
  VERSION="v1.30"
fi

unset http_proxy
unset https_proxy

# 安装基础工具
sudo apt install -y apt-transport-https ca-certificates curl

# 配置kubernetes 源按照安装版本区分不同仓库: https://developer.aliyun.com/mirror/kubernetes
if [ -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ];then
    rm -rf /etc/apt/keyrings/kubernetes-apt-keyring.gpg
fi

if [ "$proxy" = "n" ];then
  ## 服务器可以访问pkgs.k8s.io时使用官方镜像:
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$VERSION/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
  mkdir -p /etc/apt/keyrings/
  curl -fsSL https://pkgs.k8s.io/core:/stable:/"$VERSION"/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  else
  ## 国内代理:
  if [ -f /etc/apt/sources.list.d/kubernetes.list ];then
    rm -rf /etc/apt/sources.list.d/kubernetes.list
  fi
  curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/"$VERSION"/deb/Release.key |
      gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/$VERSION/deb/ /" |
      tee /etc/apt/sources.list.d/kubernetes.list
fi

# 遇到
# Reading package lists... Done
# E: Method https has died unexpectedly!
# E: Sub-process https received signal 4.
# GNUTLS_CPUID_OVERRIDE=0x1 apt update -y
apt update -y
# GNUTLS_CPUID_OVERRIDE=0x1 apt install -y conntrack socat kubelet kubeadm
apt install -y conntrack socat kubelet kubeadm

# 配置 cgroup 驱动与CRI一致
if [ -f /etc/sysconfig/kubelet ];then
  cp /etc/sysconfig/kubelet{,.back}
fi

mkdir -p /etc/sysconfig
cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
EOF

cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
cat /etc/sysconfig/kubelet

# 清理旧的安装信息
which kubeadm kubelet
hash -r

systemctl daemon-reload

systemctl enable --now kubelet
#systemctl status kubelet

systemctl restart

kubeadm version
kubelet --version

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
