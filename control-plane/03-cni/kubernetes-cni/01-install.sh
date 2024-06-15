#!/bin/bash

set -e -o posix -o pipefail

# CNI: Container Network Interface 是 Kubernetes 用来委托网络配置的插件层

# 访问 https://github.com/containernetworking/plugins/releases 获取 CNI_PLUGINS_VERSION 的版本号
CNI_PLUGINS_VERSION="v1.5.0"
#ARCH="amd64"
ARCH="arm64"
DEST="/opt/cni/bin"
sudo mkdir -p "$DEST"

# 安装 CNI 插件（大多数 Pod 网络都需要）：
wget -t 2 -T 240 -N -S "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz"
sudo tar cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz -C "$DEST" -xz

ls /opt/cni/bin

set +x
