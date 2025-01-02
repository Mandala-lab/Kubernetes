#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail -x

# 基础环境设置
# TODO 默认关闭ufw防火墙
chmod +x ./base/01-env/deb/01-config.sh
./base/01-env/deb/01-config.sh

# IPVS
chmod +x ./base/01-env/deb/02-ipvs.sh
./base/01-env/deb/02-ipvs.sh

# 放行kubernetes所需的端口
chmod +x ./base/01-env/deb/03-allow-port.sh
./base/01-env/deb/03-allow-port.sh

# 安装containerd
# --proxy: 使用国内github代理
# --github_proxy_url: 如果使用了--proxy 国内的github的代理, 请填写此项, 否则请删除该项或者填值位空字符串
# --install: 覆盖安装, 无论是否已经安装了containerd
# --version: containerd的版本, 从 https://github.com/containerd/containerd/releases 查找版本
chmod +x ./base/02-cri/containerd/binarymode/01-install.sh
# 下载前检查containerd是否已经存在于环境变量, 如果存在则不下载
#./base/02-cri/containerd/binarymode/01-install.sh --proxy --install=n --version="1.7.21"
# 不使用任何代理, 适用于可以直接访问github的服务器
./base/02-cri/containerd/binarymode/01-install.sh --github_proxy_url="" --install --version="1.7.21"
# 使用国内github代理
./base/02-cri/containerd/binarymode/01-install.sh --proxy --github_proxy_url="https://mirror.ghproxy.com/" --install --version="1.7.21"

# 配置containerd参数
# --proxy: 使用国内github代理
# --github_proxy_url: 如果使用了--proxy 国内的github的代理, 请填写此项, 否则请删除该项或者填值位空字符串
# --sandbox_image_url: k8s组件的镜像url, 默认值为 registry.k8s.io/pause:3.10
chmod +x ./base/02-cri/containerd/binarymode/02-config.sh
# 原版镜像
./base/02-cri/containerd/binarymode/02-config.sh
# 国内镜像
./base/02-cri/containerd/binarymode/02-config.sh --sandbox_image_url="registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.10"

# 安装runc
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

# 全部节点安装kubernetes组件
# --kubernetes_version: kubernetes仓库版本, 默认v1.31, 也可以是 v1.30, v1.28
chmod +x ./base/03-components/02-comm/deb/01-install-kubernetes-components.sh
./base/03-components/02-comm/deb/01-install-kubernetes-components.sh --kubernetes_version="v1.31"

# 控制平面安装kubectl组件
chmod +x ./control-plane/01-kubectl/apt/01-install-control-plane-components.sh
./control-plane/01-kubectl/apt/01-install-control-plane-components.sh

# 控制平面安装crictl组件,用于调试
# 如果需要手动上传, 那么请上传二进制文件到/tmp, 文件名为: crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz
# CRICTL_VERSION: 版本, 例如v1.30.0
# ARCH: 架构, 例如, amd64
chmod +x ./base/03-components/01-crictl/01-install.sh
#./base/03-components/01-crictl/01-install.sh --proxy=y --install --version="v1.31.1"
./base/03-components/01-crictl/01-install.sh --install --version="v1.31.1"
