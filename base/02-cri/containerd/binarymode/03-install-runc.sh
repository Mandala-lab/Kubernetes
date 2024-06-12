#!/bin/bash

rm -rf /usr/local/sbin/runc

set -x
# runc 是操作系统级别的软件包, 用于与Containerd Docker Podman等CRI底层的OCI工具
# Containerd -> runc
# 少数情况下, 系统可能没有安装runc或者配置不正确
# TODO 切换为动态获取
VERSION="v1.1.12"

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
wget -t 2 -T 240 -N -S –progress=TYPE https://github.com/opencontainers/runc/releases/download/${VERSION}/runc.${ARCH}
install -m 755 ./runc.${ARCH} /usr/local/sbin/runc

rm -rf ./runc.${ARCH}

runc -v

set +x
