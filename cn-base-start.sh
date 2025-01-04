#!/usr/bin/env bash
# 启用 POSIX 模式并设置严格的错误处理机制
set -e -o posix -o pipefail -x

# 基础环境设置

# TODO 默认关闭ufw防火墙
# --resolve_dns: /etc/resolv.conf的DNS值
chmod +x ./base/01-env/01-config.sh
./base/01-env/01-config.sh --resolve_dns=119.29.29.29

# IPVS, 可选, 如果不需要IPVS,只需在执行时到该脚本时输入n即可
chmod +x ./base/01-env/02-ipvs.sh
./base/01-env/02-ipvs.sh

# 放行kubernetes所需的端口
chmod +x ./base/01-env/03-allow-port.sh
./base/01-env/03-allow-port.sh

# 基础软件包
chmod +x ./base/01-env/tools/01-install-tools.sh
./base/01-env/tools/01-install-tools.sh

# 安装runc
# --proxy 可选值: y, n
# --version 必选值: 版本号
# y: 使用国内的Github代理
# n: 不使用国内的Github代理
# --install 可选值: y, n
# y: 当前系统是否安装, 都重新下载并安装
# n: 如果当前系统存在, 那么跳过下载与安装
chmod +x ./base/01-env/tools/02-install-runc.sh
#./base/02-cri/containerd/binarymode/03-install-runc.sh --proxy=y --install
./base/01-env/tools/02-install-runc.sh \
  --proxy \
  --install \
  --version="v1.2.3"

# socat
chmod +x ./base/01-env/tools/03-socat.sh
./base/01-env/tools/03-socat.sh

# 安装containerd
# --proxy: 使用国内github代理
# --github_proxy_url: 如果使用了--proxy 国内的github的代理, 请填写此项, 否则请删除该项或者填值位空字符串
# --install: 覆盖安装, 无论是否已经安装了containerd
# --version: containerd的版本, 从 https://github.com/containerd/containerd/releases 查找版本
chmod +x ./base/02-cri/containerd/binarymode/01-install.sh
# 下载前检查containerd是否已经存在于环境变量, 如果存在则不下载
# 使用国内github代理
./base/02-cri/containerd/binarymode/01-install.sh \
  --proxy \
  --github_proxy_url="https://mirror.ghproxy.com/" \
  --install \
  --version="2.0.1"

# 配置containerd参数
# --proxy: 使用github代理, 适用于无法直接访问github的情况
# --github_proxy_url: 如果使用了--proxy github的代理, 可以添加该选项, 值为github的代理URL, 例如https://mirror.ghproxy.com/ 不要忽略/
# --sandbox_image_url: k8s组件的镜像url, 默认值为 registry.k8s.io/pause:3.10
chmod +x ./base/02-cri/containerd/binarymode/02-config.sh
./base/02-cri/containerd/binarymode/02-config.sh \
  --proxy \
  --sandbox_image_url="registry.aliyuncs.com/google_containers/pause:3.10"

# 配置拉取镜像的proxy URL
chmod +x ./base/02-cri/containerd/binarymode/repo-proxy.sh
./base/02-cri/containerd/binarymode/repo-proxy.sh \
  --http_proxy="http://192.168.3.220:7890" \
  --https_proxy="http://192.168.3.220:7890"

# CNI二进制文件, 大多数的环境都需要, 但少数的CNI插件不需要
chmod +x ./control-plane/03-cni/cni-plugins/01-install.sh
./control-plane/03-cni/cni-plugins/01-install.sh \
  --proxy \
  --version="v1.6.1"

# 全部节点安装kubernetes组件
chmod +x ./base/03-components/apt/aliyun/01-install.sh
./base/03-components/apt/aliyun/01-install.sh

# 控制平面安装kubectl组件
chmod +x ./control-plane/01-kubectl/apt/01-install-control-plane-components.sh
./control-plane/01-kubectl/apt/01-install-control-plane-components.sh
