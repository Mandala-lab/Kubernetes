#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

helm upgrade cilium cilium/cilium \
  -reuse-values \
  --set l2announcements.enabled=true \
