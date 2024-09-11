#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail -x

# Base

chmod +x ./base/01-env/deb/01-config.sh
./base/01-env/deb/01-config.sh

chmod +x ./base/01-env/deb/02-ipvs.sh
./base/01-env/deb/02-ipvs.sh

chmod +x ./base/01-env/deb/03-allow-port.sh
./base/01-env/deb/03-allow-port.sh

chmod +x ./base/02-cri/containerd/binarymode/01-install.sh
#./base/02-cri/containerd/binarymode/01-install.sh --proxy=y --install=n --version="1.7.21"
# 国内镜像
./base/02-cri/containerd/binarymode/01-install.sh --proxy --install --version="1.7.21" --sandbox_image_url="registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.10"
# 原版镜像
./base/02-cri/containerd/binarymode/01-install.sh --proxy --install --version="1.7.21"

chmod +x ./base/02-cri/containerd/binarymode/02-config.sh
./base/02-cri/containerd/binarymode/02-config.sh

# --proxy 可选值: y, n
# y: 使用国内的Github代理
# n: 不使用国内的Github代理
# --install 可选值: y, n
# y: 当前系统是否安装, 都重新下载并安装
# n: 如果当前系统存在, 那么跳过下载与安装
chmod +x ./base/02-cri/containerd/binarymode/03-install-runc.sh
#./base/02-cri/containerd/binarymode/03-install-runc.sh --proxy=y --install
./base/02-cri/containerd/binarymode/03-install-runc.sh --install

chmod +x ./base/03-components/03-socat/deb/install.sh
./base/03-components/03-socat/deb/install.sh

#chmod +x ./base/02-cri/containerd/binarymode/03-repo.sh
#./base/02-cri/containerd/binarymode/03-repo.sh --http_proxy="http://192.168.3.220:7890" --https_proxy="http://192.168.3.220:7890"

# 如果需要手动上传, 那么请上传二进制文件到/tmp, 文件名为: crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz
# CRICTL_VERSION: 版本, 例如v1.30.0
# ARCH: 架构, 例如, amd64
chmod +x ./base/03-components/01-crictl/01-install.sh
#./base/03-components/01-crictl/01-install.sh --proxy=y --install --version="v1.31.1"
./base/03-components/01-crictl/01-install.sh --install --version="v1.31.1"

chmod +x ./base/03-components/02-comm/binarymode/01-install-components.sh
./base/03-components/02-comm/binarymode/01-install-components.sh --remove=n --version="v1.31.1"
