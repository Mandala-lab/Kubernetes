#!/bin/bash
# 此文件是用于下载二进制的Containerd
# 并针对国内服务器进行优化
# 添加镜像拉取的源替换为国内的镜像源

set -o posix errexit -o pipefail

# 设置containerd.service的默认路径
if [ -z "${CONTAINERD_SERVICE}" ]; then
  export CONTAINERD_SERVICE="/etc/systemd/system/containerd.service"
fi
# 设置containerd配置文件config.toml的路径
if [ -z "${CONTAINERD_CONFIG_FILE_PATH}" ]; then
  export CONTAINERD_CONFIG_FILE_PATH="/etc/containerd/config.toml"
fi

# 删除之前的
rm -rf /opt/containerd/
rm -rf /usr/bin/ctr
rm -rf /etc/containerd/
rm -rf $CONTAINERD_SERVICE
rm -rf $CONTAINERD_CONFIG_FILE_PATH
rm -rf /etc/modules-load.d/containerd.conf
rm -rf /etc/sysctl.d/99-kubernetes-cri.conf

hash -r

# 安装containerd
# TODO 编写可动态获取版本的shell
export VERSION="1.7.17"
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

echo "ARCH=${ARCH}"

# 定义containerd的保存路径, 用于保存下载的Containerd二进制文件
export CONTAINERD_HOME="/home/containerd"
mkdir -p $CONTAINERD_HOME
cd $CONTAINERD_HOME || exit
if [ -f "containerd-$VERSION-linux-$ARCH.tar.gz" ]; then
    echo "文件存在"
    tar -zxvf containerd-$VERSION-linux-$ARCH.tar.gz -C /usr/local/
else
    echo "文件不存在"
    wget -t 2 -T 240 -N -S -progress=dot https://github.com/containerd/containerd/releases/download/v${VERSION}/containerd-${VERSION}-linux-${ARCH}.tar.gz
    tar -zxvf containerd-$VERSION-linux-$ARCH.tar.gz -C /usr/local/
fi

set +x
