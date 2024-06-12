#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -o posix -o errexit -o pipefail -x

# Base

chmod +x ./base/01-env/deb/01-config.sh
./base/01-env/deb/01-config.sh

chmod +x ./base/01-env/deb/02-allow-port.sh
./base/01-env/deb/02-allow-port.sh

chmod +x ./base/02-cri/containerd/binarymode/01-install.sh
./base/02-cri/containerd/binarymode/01-install.sh

chmod +x ./base/02-cri/containerd/binarymode/02-config.sh
./base/02-cri/containerd/binarymode/02-config.sh

# --proxy 可选值: y, n
# y: 使用国内的Github代理
# n: 不使用国内的Github代理
# --install 可选值: y, n
# y: 当前系统是否安装, 都重新下载并安装
# n: 如果当前系统存在, 那么跳过下载与安装
chmod +x ./base/02-cri/containerd/binarymode/03-install-runc.sh
./base/02-cri/containerd/binarymode/03-install-runc.sh --proxy=y --install=y

chmod +x ./base/02-cri/containerd/binarymode/03-repo.sh
./base/02-cri/containerd/binarymode/03-repo.sh

# --remove 可选值: y, n
# y: 删除旧安装
# n: 保留旧安装, 但会重新下载安装覆盖
# --version Kubernetes版本, 以vX.Y定义, 例如"v1.30"
chmod +x ./base/03-components/deb/template.sh
./base/03-components/deb/template.sh --remove=n --version="v1.30"

