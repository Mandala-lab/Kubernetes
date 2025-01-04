#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix errexit -o pipefail

echo "正在下载基础的软件包"
sudo apt update -y
sudo apt install -y apt-transport-https ca-certificates curl gpg wget git
