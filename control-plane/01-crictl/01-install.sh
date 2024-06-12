#!/bin/sh

# 删除之前的
rm -rf /etc/crictl.yaml

export CRICTL_VERSION="v1.30.0"

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

export DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"

wget -t 2 -T 240 -N -S –progress=TYPE "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz"
tar -zxvf crictl*.tar.gz -C $DOWNLOAD_DIR
crictl -v
