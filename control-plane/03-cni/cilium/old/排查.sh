#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

kubectl -n kube-system exec ds/cilium -- cilium status
kubectl -n kube-system exec ds/cilium -- cilium status | grep Masquerading
kubectl -n kube-system exec po/cilium-8qfj7 -- cilium status
kubectl get daemonsets -n kube-system
kubectl get deployments -n kube-system
