#!/bin/bash

CILIUM_CLI_VERSION=$(curl -s curl --connect-timeout 10 https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
#CILIUM_CLI_VERSION=v0.16.9
CLI_ARCH=""
# 使用uname -m获取架构信息
machine=$(uname -m)
# 判断架构信息并设置变量的值
if [ "$machine" = "aarch64" ]; then
    CLI_ARCH="arm64"
elif [ "$machine" = "x86_64" ]; then
    CLI_ARCH="amd64"
else
    echo "请手动定义你的发行版的架构"
fi
wget -t 2 -T 240 -N -S https://github.com/cilium/cilium-cli/releases/download/"${CILIUM_CLI_VERSION}"/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

#wget https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
#wget https://github.com/cilium/cilium-cli/releases/download/v0.15.20/cilium-linux-arm64.tar.gz{,.sha256sum}
