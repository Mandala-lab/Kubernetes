#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix -o errexit -o pipefail

ARCH=""
# 使用uname -m获取架构信息
machine=$(uname -m)
# 判断架构信息并设置变量的值
if [ "$machine" = "aarch64" ]; then
    ARCH="arm64"
elif [ "$machine" = "x86_64" ]; then
    ARCH="amd64"
else
    echo "请手动定义你的发行版的架构"
fi

wget -t 2 -T 240 -N -S https://get.helm.sh/helm-v3.14.0-linux-"${ARCH}".tar.gz
tar xf  helm-v3.14.0-linux-"${ARCH}".tar.gz
mv linux-"${ARCH}"/helm /usr/bin/ && rm -rf linux-"${ARCH}"

# 验证
helm version
