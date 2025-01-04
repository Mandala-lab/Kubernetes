#!/bin/bash
set -e -o posix -o pipefail

# TODO 切换为动态获取
VERSION="v1.6.1"

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
echo $ARCH

# 跟随重定向, 状态码为400就失败, 设置超时300秒, 使用远程文件的名称
curl -Lfm 300 -O https://github.com/containernetworking/plugins/releases/download/${VERSION}/cni-plugins-linux-${ARCH}-${VERSION}.tgz{,.sha256}
# 校验文件是否完整
sha256sum -c cni-plugins-linux-${ARCH}-${VERSION}.tgz.sha256

mkdir -p /opt/cni/bin
tar -xzvf cni-plugins-linux-${ARCH}-${VERSION}.tgz -C /opt/cni/bin

set +x
