#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail
HTTP_PROXY="https://mirror.ghproxy.com/"
NERDCTL_VERSION=1.7.3
wget ${HTTP_PROXY}https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz -O nerdctl-linux-amd64.tar.gz
tar Czxvf /usr/local/bin/  nerdctl-linux-amd64.tar.gz
nerdctl -h
