#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

systemctl daemon-reload

echo "使用命令查看是否已经正确加载所需的内核模块:"
lsmod | grep br_netfilter
lsmod | grep overlay
lsmod | grep -e ip_vs -e nf_conntrack
cut -f1 -d " "  /proc/modules | grep -e ip_vs -e nf_conntrack

echo "请查看系统时间是否与真实时间一致"
date

echo "正在检测文件: /etc/security/limits.conf"
cat /etc/security/limits.conf

echo "正在检测文件: /etc/security/limits.d/20-nproc.conf, 该文件不存在属于正常范畴"
cat /etc/security/limits.d/20-nproc.conf || true

echo "正在检测文件: /etc/profile"
cat /etc/profile

echo "正在检测文件: $CONTAINERD_CONFIG_FILE_PATH"
if [ -z "${CONTAINERD_CONFIG_FILE_PATH}" ]; then
  export CONTAINERD_CONFIG_FILE_PATH="/etc/containerd/config.toml"
fi

grep -nE "sandbox|SystemdCgroup" "$CONTAINERD_CONFIG_FILE_PATH"
cat -n $CONTAINERD_CONFIG_FILE_PATH | grep -A 1 "\[plugins\.\"io\.containerd\.grpc\.v1\.cri\"\.registry\]"

echo "检查是否存在对应的仓库目录, 不使用代理忽略即可"
ls  /etc/containerd/certs.d || true

hash -r
which kubeadm kubelet kubectl
ctr -v
runc -v

if ! which crictl > /dev/null 2>&1; then
    crictl pull registry.k8s.io/prometheus-adapter/prometheus-adapter:v0.11.2
fi
echo "crictl 未安装，跳过测试..."

kubeadm version
kubelet --version
kubectl version --client

cat /etc/systemd/system/kubelet.service
cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
cat /etc/sysconfig/kubelet

