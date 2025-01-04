#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail

# https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#support-traffic-shaping
# CNI 网络插件还支持 Pod 入口和出口流量整形。您可以使用 CNI 插件团队提供的官方带宽插件，也可以使用您自己的具有带宽控制功能的插件
# 如果要启用流量整形支持，则必须将 bandwidth 插件添加到 CNI 配置文件（默认）并确保二进制文件包含在 CNI bin 目录（/etc/cni/net.d 或 /opt/cni/bin ）中。

mkdir -p /home/kubernetes
cd /home/kubernetes || exit

# 使用uname -m获取系统架构
arch_raw=$(uname -m)

# 根据获取的原始架构信息映射到规范的架构名称
case $arch_raw in
  x86_64)
    ARCH="amd64"
    ;;
  aarch64)
    ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: $arch_raw"
    exit 1
    ;;
esac

# 输出最终的架构名称
echo "Detected architecture: $ARCH"

if command -v go &> /dev/null
then
    echo "Go is installed."
else
    echo "Go is not installed."
    wget -t 2 -T 240 -N -S https://golang.google.cn/dl/go1.22.3.linux-${ARCH}.tar.gz
    tar -zxvf go1.22.3.linux-arm64.tar.gz -C /usr/local
    mv /usr/local/go/bin/* /usr/local/bin/
fi

git clone --depth 1 https://github.com/containerd/containerd.git
cd containerd/

chmod +x ./script/setup/install-cni && ./script/setup/install-cni
