#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

# Kubernetes要求net.bridge.bridge-nf-call-iptables = 1,但是为了使用Cilium,我们需要将其设置为0
# 使用 --ignore-preflight-errors=all  忽略预检错误net.bridge.bridge-nf-call-iptables = 0这个错误
# 不使用Cilium这个CNI则设置net.bridge.bridge-nf-call-iptables = 1
#--ignore-preflight-errors=all \
mkdir -p /etc/kubernetes/manifests
HOME="/home/kubernetes"
cd $HOME || exit

kubeadm init \
  --kubernetes-version=1.31.1 \
  --control-plane-endpoint="192.168.3.100" \
  --apiserver-bind-port="6443" \
  --image-repository=registry.aliyuncs.com/google_containers \
  --service-cidr=10.96.0.0/12 \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket=unix:///var/run/containerd/containerd.sock \
  --upload-certs \
  --v=7

# 重新生成token
# kubeadm token create --print-join-command
