#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

#/Users/mandala/Public/Golang/project/kubernetes/base/01-env/tools/02-install-runc.sh
rm -rf /usr/local/sbin/runc || true

# /Users/mandala/Public/Golang/project/kubernetes/base/01-env/tools/03-socat.sh
apt uninstall -y socat || true

#/Users/mandala/Public/Golang/project/kubernetes/base/01-env/02-ipvs.sh
apt uninstall -y \
  conntrack \
  ipvsadm \
  ipset || true

systemctl stop containerd || true
rm -rf /usr/local/containerd

apt uninstall -y kubeadm kubelet kubectl || true
