#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

if grep swap /etc/fstab; then
  echo "swap没有关闭, 建议关闭"
  exit 1
fi

if sudo blkid | grep swap; then
  echo "swap没有关闭, 建议关闭"
  exit 1
fi

cat /etc/security/limits.conf
cat /etc/security/limits.d/20-nproc.conf
cat /etc/profile
cat /etc/sysconfig/modules/k8s.modules
cat /etc/sysctl.d/99-kubernetes-cri.conf

if [ -z "${CONTAINERD_CONFIG_FILE_PATH}" ]; then
  export CONTAINERD_CONFIG_FILE_PATH="/etc/containerd/config.toml"
fi
grep -nE "sandbox_image|SystemdCgroup" "$CONTAINERD_CONFIG_FILE_PATH"
cat -n /etc/containerd/config.toml | grep -A 1 "\[plugins\.\"io\.containerd\.grpc\.v1\.cri\"\.registry\]"

lsmod | grep br_netfilter
lsmod | grep overlay

hash -r
which kubeadm kubelet kubectl
ctr -v
runc -v
kubeadm version
kubelet --version
kubectl version --client

cat /etc/systemd/system/kubelet.service
cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
cat /etc/sysconfig/kubelet

