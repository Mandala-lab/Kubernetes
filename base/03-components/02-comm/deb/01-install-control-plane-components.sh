#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

apt install -y kubectl
kubectl version --client

# 查看版本的详细视图
# kubectl version --client --output=yaml
